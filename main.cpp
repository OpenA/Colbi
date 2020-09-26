#include <QGuiApplication>
#include <QQmlApplicationEngine>

#include <main.h>

namespace GlobalOpts {
	QString pattern = "__optim__";
}

auto ImgWrk::work() -> void {
	is_busy = true;
	QCoreApplication::postEvent(m_parent, new TaskEvent(m_index, S_Working));
	bool ok = optim();
	QCoreApplication::postEvent(m_parent, new TaskEvent(m_index, (ok ? S_Complete : S_Error), m_rawSize, m_optSize));
	is_busy = false;
}
auto ImgWrk::start () -> void { m_future = QtConcurrent::run(this, &ImgWrk::work); }
auto ImgWrk::pause () -> void { m_future.togglePaused(); }
auto ImgWrk::stop  () -> void { m_future.cancel();       }
auto ImgWrk::restart (QString out, qint64 size) -> void {
	m_outFile = out;
	m_rawSize = size;
	m_optSize = 0;
	stop(), start();
}

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

auto Colbi::taskWorker( QString name, QString absfile, QString outfile, qint64 size) -> void {

	const QMimeDatabase db;
	const QMimeType mime = db.mimeTypeForFile( absfile );
			quint16 num  = taskList.length();

	unsigned char status = S_Idle;

	if (mime.inherits("image/jpeg")) {
		taskList.append( new JpgWrk( this, num, size, absfile, outfile) );
	} else if (mime.inherits("image/png")) {
		taskList.append( new PngWrk( this, num, size, absfile, outfile) );
	} else if (mime.inherits("image/gif")) {
		taskList.append( new PngWrk( this, num, size, absfile, outfile) );
	} else if (mime.inherits("image/bmp")) {
		taskList.append( new PngWrk( this, num, size, absfile, outfile) );
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

	if (!fi.exists() && !fi.permission(QFile::WriteUser | QFile::ReadGroup))
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

		QString outfile = fi.absolutePath() +"/"+ fi.completeBaseName() + GlobalOpts::pattern +"."+ fi.suffix();
		qint64  size    = fi.size();

		if (idx >= 0) {
			if (taskList[idx]->is_busy != true) {
				taskList[idx]->restart(outfile, size);
			};
		} else {
			taskWorker(fi.fileName(), absfile, outfile, size );
		}
	}
}

int main(int argc, char *argv[])
{
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
