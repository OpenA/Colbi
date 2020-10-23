#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QStandardPaths>
#include <QMimeDatabase>
#include <QDateTime>
#include <QFileInfo>
#include <main.h>

QMap<QString, QString> STR_Param;
QMap<QString, bool>   BOOL_Param;
QMap<QString, int>     INT_Param;

const QDir SAVE_ORI_DIR = QDir( QStandardPaths::writableLocation(QStandardPaths::TempLocation) +"/Colbi~saveOriginals" );
const bool SYS_CASE_INS = SAVE_ORI_DIR.exists(QDir::homePath().toUpper());

auto ImgWrk::work() -> void {
	is_busy = true;
	QCoreApplication::postEvent(m_parent, new TaskEvent(m_index, S_Working));
	bool ok = optim();
	QCoreApplication::postEvent(m_parent, new TaskEvent(m_index, (ok ? S_Complete : S_Error), m_rawSize, m_optSize));
	is_busy = false;
}
auto ImgWrk::start () -> void { m_future = QtConcurrent::run(this, &ImgWrk::work); }
auto ImgWrk::stop  () -> void { m_future.cancel(); }
auto ImgWrk::pause () -> void {
	if(!m_future.isFinished() && !m_future.isCanceled()) {
		const bool paused = !m_future.isPaused();
		QCoreApplication::postEvent(m_parent,
			new TaskEvent(m_index, paused ? S_Paused : m_future.isStarted() ? S_Working : S_Idle));
		m_future.setPaused(paused);
	}
}
auto PngWrk::reload(size_t size) -> void {
	m_rawSize = size, m_optSize = 0;
	m_quality = INT_Param["PNG/minQuality"];
}
auto JpgWrk::reload(size_t size) -> void {
	m_rawSize     = size, m_optSize = 0;
	m_quality     =  INT_Param["JPEG/maxQuality"];
	m_progressive = BOOL_Param["JPEG/progressive"];
	m_arithmetic  = BOOL_Param["JPEG/arithmetic" ];
}

Colbi::Colbi(QObject *parent) : QObject(parent)
{
	m_settings = new QSettings(QSettings::IniFormat, QSettings::UserScope, "Colbi", "settings");

	for (QString key : STR_Param.keys()) {
		if (m_settings->contains(key))
			STR_Param[key] = m_settings->value(key).toString();
	}
	for (QString key : BOOL_Param.keys()) {
		if (m_settings->contains(key))
		   BOOL_Param[key] = m_settings->value(key).toBool();
	}
	for (QString key : INT_Param.keys()) {
		if (m_settings->contains(key))
			INT_Param[key] = m_settings->value(key).toInt();
	}
}
Colbi::~Colbi() {
	/*for (TWrk *wk : taskList) {
		wk->stop();
	}*/
}

auto Colbi::getParamStr  ( const QString key ) -> QString { return  STR_Param[key]; }
auto Colbi::getParamBool ( const QString key ) -> bool    { return BOOL_Param[key]; }
auto Colbi::getParamInt  ( const QString key ) -> int     { return  INT_Param[key]; }

void Colbi::setOptionStr ( const QString key, QString str ) { m_settings->setValue(key,  (STR_Param[key] = str));    }
void Colbi::setOptionBool( const QString key, bool flag   ) { m_settings->setValue(key, (BOOL_Param[key] = flag));   }
void Colbi::setOptionInt ( const QString key, int number  ) { m_settings->setValue(key,  (INT_Param[key] = number)); }

auto Colbi::event(QEvent *event) -> bool {

	if (event->type() != QEvent::User) {
		return QObject::event(event);
	}

	TaskEvent *e = (TaskEvent *)event;

	if (e->m_status > 0)
		emit statusUpdate((unsigned short)e->m_index, (unsigned char)e->m_status);
	if (e->m_newSz  > 0)
		emit taskProgress((unsigned short)e->m_index, (long long)e->m_origSz, (long long)e->m_newSz);

	return true;
}

auto Colbi::taskWorker( QString name, QString absfile, qint64 size) -> void {

	const QMimeDatabase db;
	const QMimeType mime = db.mimeTypeForFile( absfile );
			quint16 num  = taskList.length();

	unsigned char status = S_Idle;

	if (size > 0xFFFFFFFF) {
		taskList.append( new TWrk );
		status = S_Error;
	} else if (mime.inherits("image/jpeg")) {
		taskList.append(
			new JpgWrk( this, num, size, INT_Param["JPEG/maxQuality"], BOOL_Param["JPEG/progressive"], BOOL_Param["JPEG/arithmetic" ] )
		);
	} else if (mime.inherits("image/png") || mime.inherits("image/bmp")) {
		taskList.append(
			new PngWrk( this, num, size, INT_Param["PNG/minQuality"], BOOL_Param["PNG/8bitColors"])
		);
//	} else if (mime.inherits("image/gif")) {
//		taskList.append( new PngWrk( this, num, size, INT_Param["GIF/minQuality"]) );
	} else {
		taskList.append( new TWrk );
		status = S_Error;
	}
	fileList.append( absfile );
	emit taskAdded((unsigned short)num, status, (long long)size, name);
}

auto Colbi::runTask  ( const quint16 idx ) -> void { taskList[idx]->start(); }
auto Colbi::waitTask ( const quint16 idx ) -> void { taskList[idx]->pause(); }
auto Colbi::killTask ( const quint16 idx ) -> void { taskList[idx]->stop();  }
auto Colbi::addTask  ( const QString path) -> void {

	const QFileInfo fi(path);

	if (!fi.exists() || !fi.permission(QFile::WriteUser | QFile::ReadGroup) ||
		 fi.absolutePath().startsWith(SAVE_ORI_DIR.absolutePath(), SYS_CASE_INS ? Qt::CaseInsensitive : Qt::CaseSensitive))
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
		qint16  idx     = fileList.indexOf( absfile );
		qint64 size     = fi.size();

		if (idx >= 0) {
			if (taskList[idx]->is_busy != true) {
				taskList[idx]->reload(size);
				emit taskProgress((unsigned short)idx, 0, (long long)size);
				emit statusUpdate((unsigned short)idx, S_Idle);
				taskList[idx]->start();
			};
		} else {
			taskWorker(fi.fileName(), absfile, size );
		}
	}
}

auto Colbi::qFileLoad(const quint16 idx, QByteArray &blob) -> bool
{
	QFile file(fileList[idx]);
	 bool ok;
	if (( ok = file.open(QIODevice::ReadOnly))) {
		blob = file.readAll();
		file.close();
	}
	return ok;
}

auto Colbi::qFileStore(const quint16 idx, QByteArray &blob, IMG_T type) -> bool
{
	const QFileInfo fi(fileList[idx]);
	const QString src_path = fi.absolutePath() +"/";

	QString name = fi.completeBaseName();
	QString ext  = fi.suffix();

	bool mv_tmp = BOOL_Param["General/moveToTemp"];
	QString pat = STR_Param["General/namePattern"];

	if (mv_tmp) {
		if (!SAVE_ORI_DIR.exists())
			 SAVE_ORI_DIR.mkpath(".");
		QString lastmod = fi.lastModified().toLocalTime().toString("d.MM.yyyy hh:mm");
		QFile::rename(src_path + name +"."+ ext, SAVE_ORI_DIR.absolutePath() +"/"+ name +" ("+ lastmod +")."+ ext);
	}

	QFile file(src_path + name + pat +"."+ ext);
	 bool ok;
	if (( ok = file.open(QIODevice::WriteOnly))) {
		file.write(blob);
		file.close();
	}
	return ok;
}

int main(int argc, char *argv[])
{
	STR_Param["General/namePattern"] = "";
   BOOL_Param["General/moveToTemp" ] = true;
	INT_Param["General/colorTheme" ] = 0;

   BOOL_Param["JPEG/progressive"] = true;
   BOOL_Param["JPEG/arithmetic" ] = false;
	INT_Param["JPEG/maxQuality" ] = -90;

   BOOL_Param["PNG/8bitColors"] = true;
	INT_Param["PNG/minQuality"] = 100;

   BOOL_Param["GIF/convToWebP"] = false;
	INT_Param["GIF/minQuality"] = 100;

	QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

	QGuiApplication app(argc, argv);

	qmlRegisterType<Colbi>    ("git.OpenA.Colbi", 1, 0, "Colbi");
	app.setOrganizationName   ("Some Company");
	app.setOrganizationDomain ("OpenA.git"   );
	app.setApplicationName    ("Colbi"       );

	QQmlApplicationEngine engine;
	const QUrl url(QStringLiteral("qrc:/main.qml"));
	QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
					 &app, [url](QObject *obj, const QUrl &objUrl) {
		if (!obj && url == objUrl)
			QCoreApplication::exit(-1);
	}, Qt::QueuedConnection);
	engine.load(url);

	return app.exec();
}
