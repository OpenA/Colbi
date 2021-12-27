#ifndef MAIN_H
#define MAIN_H

#include <QCoreApplication>
#include <QtConcurrent/QtConcurrentRun>
#include <QSettings>
#include <QFuture>
#include <QObject>
#include <QString>
#include <QList>
#include <QFile>
#include <QDir>

#ifdef QT_DEBUG
#include <QDebug>
#endif

enum STAT_T {
	S_Idle = 0,
	S_Working ,
	S_Complete,
	S_Paused  ,
	S_Error   ,
	S_Unknown
};

enum EXT_T {
	/* IMG formats */
	PNG, JPG, GIF
};

/* QEvent extends for tasks */
class TaskEvent : public QEvent
{
public:
	size_t  m_origSz, m_newSz;
	quint16 m_index;
	STAT_T  m_status;

	TaskEvent(quint16 i, STAT_T s, size_t o = 0, size_t n = 0) : QEvent( User )
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

	virtual void reload(size_t) {}
};

/* Main Class */
class Colbi : public QObject
{
	Q_OBJECT
private:
	QSettings *m_settings;
	QStringList  fileList;
	QList<TWrk*> taskList;

	void taskWorker( QString, QString, qint64 );

public:
	explicit Colbi( QObject *parent = nullptr ); ~Colbi();
	bool event(QEvent *event) override;

	bool qFileLoad (const quint16, QByteArray &);
	bool qFileStore(const quint16, QByteArray &, EXT_T);

signals:
	void taskProgress( unsigned short num, long long orig_size, long long new_size  );
	void statusUpdate( unsigned short num, unsigned char status );
	void taskAdded   ( unsigned short num, unsigned char status, long long file_size, QString file_name );

public slots:
	void addTask  ( const QString );
	void runTask  ( const quint16 );
	void waitTask ( const quint16 );
	void killTask ( const quint16 );

	QStringList loadTheme( const QString );
	void        saveTheme( const QString, QStringList );

	QString getParamStr ( const QString );
	bool    getParamBool( const QString );
	int     getParamInt ( const QString );
	double  getParamReal( const QString );

	void setOptionStr ( const QString, QString );
	void setOptionBool( const QString, bool    );
	void setOptionInt ( const QString, int     );
	void setOptionReal( const QString, double  );
};

/* Image Worker Base Class */
class ImgWrk : public TWrk
{
protected:
	quint16 m_index;
	Colbi*  m_parent;
	QFuture <void> m_future;
	size_t  m_rawSize, m_optSize;

	virtual bool optim() = 0;
	virtual void work();

public:
	explicit ImgWrk(Colbi *p, quint16 n, size_t s) : TWrk(false)
	{
		m_parent = p, m_rawSize = s;
		m_index  = n, m_optSize = 0;
	}
	~ImgWrk() { stop(); }

	void start() override;
	void pause() override;
	void stop () override;
};

/* GIF Worker Extends */
class GifWrk : public ImgWrk
{
protected:
	qint16 m_colors;
	quint8 m_dither;
	float  m_lossy;
	bool   optim() override;
public:
	explicit GifWrk(Colbi *p, quint16 n, size_t s, qint16 c, quint8 d, float l) : ImgWrk(p,n,s)
	{
		m_colors = c, m_dither = d, m_lossy = l;
	}
	void reload(size_t) override;
};

/* PNG Worker Extends */
class PngWrk : public ImgWrk
{
protected:
	quint8 m_quality, m_deflate;
	bool   m_rgb8bit;
	bool   optim() override;
public:
	explicit PngWrk(Colbi *p, quint16 n, size_t s, quint8 q, quint8 d, bool b) : ImgWrk(p,n,s)
	{
		m_quality = q, m_deflate = d, m_rgb8bit = b;
	}

	void reload(size_t) override;
};

/* JPEG Worker Extends */
class JpgWrk : public ImgWrk
{
protected:
	quint8 m_algorithm;
	qint8  m_quality;
	bool   m_progressive;
	bool   optim() override;
public:
	explicit JpgWrk(Colbi *p, quint16 n, size_t s, qint8 q, quint8 a, bool o) : ImgWrk(p,n,s)
	{
		m_quality = q, m_algorithm = a, m_progressive = o;
	}
	void reload(size_t) override;
};

#endif // MAIN_H
