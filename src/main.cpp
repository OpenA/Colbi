#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include "Colbi.hpp"

int main(int argc, char *argv[])
{
	if (Colbi::ThLFormat == QSettings::InvalidFormat) {
		qCritical() << "Error create theme format";
		return 0;
	}
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
