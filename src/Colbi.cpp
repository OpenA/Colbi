#include "Colbi.hpp"

#include <QtConcurrent/QtConcurrentRun>
#include <QStandardPaths>
#include <QMimeDatabase>
#include <QDateTime>
#include <QFileInfo>

#define CHAR_0 '0'

Colbi::Colbi(QObject *parent) : QObject(parent), saveOrigDir(
	QStandardPaths::writableLocation(QStandardPaths::TempLocation) +"/Colbi~saveOriginals"
) {
	m_settings = new QSettings(QSettings::IniFormat, QSettings::UserScope, "Colbi", "settings");

	m_OptBool["moveToTemp" ] = true;
	m_OptStr ["colorTheme" ] = "Light Cream";
	m_OptStr ["namePattern"] = "_optim_";

	m_OptBool["JPEG/progressive"] = true;
	m_OptInt ["JPEG/arithmetic" ] = 0;
	m_OptInt ["JPEG/maxQuality" ] = -90;

	m_OptBool["PNG/rgb8bit"   ] = true;
	m_OptInt ["PNG/deflatelib"] = 0;
	m_OptInt ["PNG/minQuality"] = 100;

	m_OptInt ["GIF/maxColors"  ] = 256;
	m_OptInt ["GIF/ditherPlan" ] = 1;
	m_OptReal["GIF/lossQuality"] = 0;

	for (QString key : m_OptStr.keys()) {
		if (m_settings->contains(key))
			m_OptStr[key] = m_settings->value(key).toString();
	}
	for (QString key : m_OptBool.keys()) {
		if (m_settings->contains(key))
			m_OptBool[key] = m_settings->value(key).toBool();
	}
	for (QString key : m_OptInt.keys()) {
		if (m_settings->contains(key))
			m_OptInt[key] = m_settings->value(key).toInt();
	}
	for (QString key : m_OptReal.keys()) {
		if (m_settings->contains(key))
			m_OptReal[key] = m_settings->value(key).toReal();
	}
}
Colbi::~Colbi() {
	/*for (TWrk *wk : taskList) {
		wk->stop();
	}*/
}

auto Colbi::taskWorker(const int idx) -> void
{
	stat_t status = S_Error;
	TaskWrk task = taskList[idx];
	QString path = fileList[idx];
	QByteArray blob;

	long long orig_sz = task.size();

	emit statusUpdate(idx, S_Working);

	if (qFileLoad(path, blob)) {
		switch (task.type()) {
		case ImgPNG:
			status = Png_optim(this, idx, blob,
				m_OptBool["PNG/rgb8bit"   ],
				m_OptInt ["PNG/minQuality"]);
			break;
		case ImgJPG:
# ifdef WITH_JPG
			status = Jpg_optim(this, idx, blob,
				m_OptBool["JPEG/progressive"],
				m_OptInt ["JPEG/arithmetic" ],
				m_OptInt ["JPEG/maxQuality" ]);
# endif
			break;
		case ImgGIF:
# ifdef WITH_GIF
			status = Gif_optim(this, idx, blob,
				m_OptInt ["GIF/maxColors"  ],
				m_OptInt ["GIF/ditherPlan" ],
				m_OptReal["GIF/lossQuality"]);
# endif
			break;
		case UnknownFile:
		default: /* none */
			break;
		}
		if (status == S_Complete && orig_sz > blob.size()) {
			emit taskProgress(idx, orig_sz, blob.size());
			qFileStore(path, blob, task.type());
		}
	}
	emit statusUpdate(idx, status);
}

auto Colbi::event(QEvent *event) -> bool {

	if (event->type() != QEvent::User) {
		return QObject::event(event);
	}

	TaskEvent *e = (TaskEvent *)event;

	if (e->m_status > 0)
		emit statusUpdate(e->m_index, e->m_status);
	if (e->m_newSz  > 0)
		emit taskProgress(e->m_index, (long long)e->m_origSz, (long long)e->m_newSz);

	return true;
}

auto Colbi::taskCreate(QString name, QString absfile, size_t size) -> void
{
	const QMimeDatabase db;
	const QMimeType mime = db.mimeTypeForFile( absfile );

	const int num = fileList.length();
	stat_t status = S_Idle;
	type_t type   = (
	    mime.inherits("image/png") || mime.inherits("image/bmp") ? ImgPNG
# ifdef WITH_JPG
	  : mime.inherits("image/jpeg") ? ImgJPG
# endif
# ifdef WITH_GIF
	  : mime.inherits("image/gif") ? ImgGIF
# endif
	  : UnknownFile );

	if (type == UnknownFile) {
		status = S_Unknown;
		if (!mime.name().startsWith("image"))
			return;
	}
	taskList.append( TaskWrk(size, type) );
	fileList.append( absfile );

	emit taskAdded(num, status, size, name);
}

auto Colbi::doTask(const int idx, enum Act foo) -> void
{
	TaskWrk task = taskList[idx];
	stat_t status = S_Idle;

	if (task.type() == UnknownFile)
		return;

	bool paused = task.isPaused(),
	    running = task.isRunning() && !(task.isCanceled() || task.isFinished());
	switch (foo) {
	case ACancel:
		if (running)
			task.cancel();
		break;
	case AStart:
		if (running) {
			paused = true;
		} else {
			task.bind( QtConcurrent::run(this, &Colbi::taskWorker, idx) );
			break;
		}
	case APause:
		task.setPaused(!paused);
		!paused ? S_Paused : S_Working;
		break;
	}
	emit statusUpdate(idx, status);
}

auto Colbi::addTask( const QString path) -> void
{
	const QFileInfo fi(path);

	if (!fi.exists() || !fi.permission(QFile::WriteUser | QFile::ReadGroup) ||
		fi.absolutePath().startsWith(saveOrigDir.absolutePath(), Qt::CaseInsensitive))
		return;

	if (fi.isSymLink()) {
		addTask(fi.symLinkTarget());
	} else if (fi.isDir()) {
		QDir dir(path);

		for (QString file : dir.entryList(QDir::NoDotAndDotDot | QDir::Files | QDir::Dirs)) {
			addTask( path +"/"+ file );
		}
	} else {
		QString absfile = fi.absoluteFilePath();
		const int  idx  = fileList.indexOf( absfile );
		long long size  = fi.size();

		if (idx >= 0) {
			TaskWrk task = taskList[idx];

			if (task.type() != UnknownFile) {
				emit taskProgress(idx, 0, size);
				emit statusUpdate(idx, S_Idle);
			};
		} else {
			taskCreate(fi.fileName(), absfile, size);
		}
	}
}

auto Colbi::qFileLoad(const QString path, QByteArray &blob) -> bool
{
	QFile file(path);
	 bool ok;
	if (( ok = file.open(QIODevice::ReadOnly))) {
		blob = file.readAll();
		file.close();
	}
	return ok;
}

auto Colbi::qFileStore(const QString path, QByteArray &blob, type_t type) -> bool
{
	const QFileInfo fi(path);
	const QString src_path = fi.absolutePath() +"/";

	QString name = fi.completeBaseName();
	QString ext  = fi.suffix();
	QString vex  = (
		type == ImgPNG ? "png" :
		type == ImgJPG ? "jpg" :
		type == ImgGIF ? "gif" : ext
	);

	QString pat = m_OptStr["namePattern"];
	bool mv_tmp = m_OptBool["moveToTemp"],
		 re_ext = mv_tmp || !pat.isEmpty();

	if (mv_tmp) {
		if (!saveOrigDir.exists())
			saveOrigDir.mkpath(".");
		QString lastmod = fi.lastModified().toLocalTime().toString("d.MM.yyyy hh:mm");
		QFile::rename(src_path + name +"."+ ext, saveOrigDir.absolutePath() +"/"+ name +" ("+ lastmod +")."+ ext);
	}

	QFile file(src_path + name + pat +"."+ (re_ext ? vex : ext));
	 bool ok;
	if (( ok = file.open(QIODevice::WriteOnly))) {
		file.write(blob);
		file.close();
		if (!re_ext && ext != vex)
			QFile::rename(src_path + name +"."+ ext, src_path + name +"."+ vex);
	}
	return ok;
}

bool readTheme(QIODevice &dev, QSettings::SettingsMap &map)
{
	if (!dev.isOpen())
		return false;

	QTextStream inStream(&dev);
	QString group;

	for (int idx = CHAR_0; !inStream.atEnd();) {

		QString line = inStream.readLine();
		if (line.isEmpty())
			continue;
		if (line.front() == '[' && line.back() == ']') {
			group = line.mid(1, line.size() - 2);
			idx   = CHAR_0;
		}
		else if (!group.isEmpty()) {

			if (line.contains(":")) {
				map.insert(group +"/"+ QString(idx++), QVariant(line));
			}
		}
	}
	return true;
}

bool writeTheme(QIODevice &dev, const QSettings::SettingsMap &map)
{
	if (!dev.isOpen())
		return false;

	QTextStream outStream(&dev);
	QString lastGroup;

	for (const QString key : map.keys()) {
		int sepi = key.indexOf("/");
		if (sepi == -1) continue;

		QString group  = key.mid(0, sepi);
		if (lastGroup != group) {
			if (!lastGroup.isEmpty())
				outStream << Qt::endl;
			outStream << QString("[%1]").arg(group) << Qt::endl;
			lastGroup = group;
		}
		outStream << map.value(key).toString() << Qt::endl;
	}
	return true;
}

QSettings::Format const Colbi::ThLFormat = QSettings::registerFormat(
	"ini", readTheme, writeTheme, Qt::CaseSensitive
);

auto Colbi::loadTheme( const QString th_name ) -> QStringList
{
	QSettings themes(Colbi::ThLFormat, QSettings::UserScope, "Colbi", "themes");
	QStringList out_list, keys;

	if (!th_name.isEmpty()) {
		themes.beginGroup(th_name);
		keys = themes.childKeys();
		if (!keys.isEmpty()) {
			out_list.push_back(th_name);
			for (int i = 0; i < keys.length(); i++) {
				out_list.push_back(themes.value(QString(CHAR_0 + i)).toString());
			}
		}
		themes.endGroup();
	} else
	if (!(keys = themes.allKeys()).isEmpty()) {
		QString lastGroup;

		for (const QString key : keys) {
			int sepi = key.indexOf("/");
			if (sepi == -1) continue;

			QString group  = key.mid(0, sepi);
			if (lastGroup != group) {
				if (!lastGroup.isEmpty())
					out_list.push_back("");
				out_list.push_back((lastGroup = group));
			}
			out_list.push_back(themes.value(key).toString());
		}
	}
	return out_list;
}

void Colbi::saveTheme( const QString th_name, QStringList th_style )
{
	QSettings themes(Colbi::ThLFormat, QSettings::UserScope, "Colbi", "themes");
	int idx = CHAR_0;

	themes.beginGroup(th_name);
	if (!th_style.isEmpty()) {
		int size = themes.childKeys().length() + CHAR_0;
		for (QString line : th_style) {
			if (line.contains(":")) {
				themes.setValue(QString(idx++), QVariant(line));
			}
		}
		while (idx < size)
			themes.remove(QString(size--));
	}
	if (idx == CHAR_0)
		themes.remove("");
	themes.endGroup();
}
