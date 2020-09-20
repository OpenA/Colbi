#ifndef MAIN_H
#define MAIN_H

#include <QCoreApplication>
#include <QtConcurrent/QtConcurrentRun>
#include <QMimeDatabase>
#include <QFileInfo>
#include <QFuture>
#include <QObject>
#include <QString>
#include <QList>
#include <QFile>
#include <QDir>

#ifdef QT_DEBUG
#include <QDebug>
#endif

enum {
	S_Idle = 0,
	S_Working ,
	S_Complete,
	S_Error   ,
	S_Unknown
};

enum {
	PNG = 0,
	JPG,
	GIF,
	BMP,
	WebP
} IMG;

/* QEvent extends for tasks */
class TaskEvent : public QEvent
{
public:
	qint64  m_origSz, m_newSz;
	quint16 m_index;
	quint8  m_status;

	TaskEvent(quint16 i, quint8 s, qint64 o = 0, qint64 n = 0) : QEvent( User )
	{
		m_status = s, m_index = i;
		m_origSz = o, m_newSz = n;
	}
};

/* Task Abstract Class */
class TWrk
{
public:
	bool is_busy;

	 TWrk(bool y = true) { is_busy = y; }
	~TWrk() {}

	virtual void start() {}
	virtual void pause() {}
	virtual void stop () {}
	virtual void restart(QString, qint64) {}
};

/* Main Class */
class Colbi : public QObject
{
	Q_OBJECT

private:
	QStringList  fileList;
	QList<TWrk*> taskList;

	void taskWorker( QString, QString, QString, qint64 );

public:
	~Colbi() {};
	bool event(QEvent *event) override;

signals:
	void taskProgress( unsigned short num, long long orig_size, long long new_size  );
	void statusUpdate( unsigned short num, unsigned char status );
	void taskAdded   ( unsigned short num, unsigned char status, long long file_size, QString file_name );

public slots:
	void addTask  ( const QString );
	void runTask  ( const quint16 );
	void waitTask ( const quint16 );
	void killTask ( const quint16 );
};

/* Image Worker Base Class */
class ImgWrk : public TWrk
{
protected:
	quint16 m_index;
	Colbi*  m_parent;
	QFuture <void>     m_future;
	QString m_inFile , m_outFile;
	qint64  m_rawSize, m_optSize;

	virtual bool optim() = 0;
	virtual void work();

public:
	explicit ImgWrk(Colbi *p, quint16 n, qint64 s, QString i, QString o) : TWrk(false)
	{
		m_parent = p, m_rawSize = s, m_inFile  = i;
		m_index  = n, m_optSize = 0, m_outFile = o;
	}
	~ImgWrk() { stop(); }

	void start () override;
	void pause () override;
	void stop  () override;
	void restart (QString, qint64) override;
};

/* PNG Worker Extends */
class PngWrk : public ImgWrk
{
private:
	//int quantz(const U8ClampVec&, U8ClampVec&);
protected:
	bool optim() override;
public:
	using ImgWrk::ImgWrk;
};

/* JPEG Worker Extends */
class JpgWrk : public ImgWrk
{
private:
	//int optim(const U8ClampVec&, U8ClampVec&);
protected:
	bool optim() override;
public:
	using ImgWrk::ImgWrk;
};
#endif // MAIN_H
