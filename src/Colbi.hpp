#ifndef _COLBI_H_
#define _COLBI_H_

# include <QCoreApplication>
# include <QSettings>
# include <QObject>
# include <QFuture>
# include <QString>
# include <QList>
# include <QFile>
# include <QDir>

# ifdef QT_DEBUG
#  include <QDebug>
# endif

enum stat_t {
	S_Idle = 0,
	S_Working ,
	S_Complete,
	S_Paused  ,
	S_Error   ,
	S_Unknown
};

enum type_t {
	/* IMG formats */
	UnknownFile, ImgPNG, ImgJPG, ImgGIF
};

/* QEvent extends for tasks */
class TaskEvent : public QEvent
{
public:
	long long m_origSz, m_newSz;
	int m_index, m_status;

	TaskEvent(int i, stat_t s, long long o = 0, long long n = 0) : QEvent( User )
	{
		m_status = s, m_index = i;
		m_origSz = o, m_newSz = n;
	}
};

/* Task Base Class */
class TaskWrk : public QFuture<void>
{
private:
	type_t m_type;
	size_t m_size;

public:
	TaskWrk(size_t s, type_t x) {
		m_size = s, m_type = x;
	}
	~TaskWrk() {}

	size_t size() const { return m_size; };
	type_t type() const { return m_type; };

	QFuture<void>& bind(const QFuture<void> &o) {
		return QFuture<void>::operator=(o);
	}
	TaskWrk& operator=(const TaskWrk &o) {
		m_size = o.m_size;
		m_type = o.m_type, bind(o);
		return *this;
	}
};

/* Main Class */
class Colbi : public QObject
{
	Q_OBJECT
private:
	QSettings *m_settings;
	QStringList  fileList;
	QList<TaskWrk> taskList;

	QMap<QString, QString> m_OptStr;
	QMap<QString, bool>    m_OptBool;
	QMap<QString, int>     m_OptInt;
	QMap<QString, double>  m_OptReal;

	const QDir saveOrigDir;

	void taskCreate( QString, QString, size_t );
	void taskWorker( const int );

public:
	explicit Colbi( QObject *parent = nullptr );
	        ~Colbi();
	bool event(QEvent *event) override;

	bool qFileLoad (const QString, QByteArray &);
	bool qFileStore(const QString, QByteArray &, type_t);

	static const QSettings::Format ThLFormat;

	enum   Act { ACancel, AStart, APause };
	Q_ENUM(Act);

signals:
	void taskProgress( int num, long long orig_size, long long new_size );
	void statusUpdate( int num, int status );
	void taskAdded   ( int num, int status, long long file_size, QString file_name );

public slots:
	void addTask( const QString );
	void  doTask( const int, enum Act );

	QStringList loadTheme( const QString );
	void        saveTheme( const QString, QStringList );

	QString getOptionStr ( const QString key ) const { return m_OptStr [key]; }
	bool    getOptionBool( const QString key ) const { return m_OptBool[key]; }
	int     getOptionInt ( const QString key ) const { return m_OptInt [key]; }
	double  getOptionReal( const QString key ) const { return m_OptReal[key]; }

	void setOptionStr ( const QString key, QString s ) { m_settings->setValue(key, (m_OptStr [key] = s)); }
	void setOptionBool( const QString key, bool    b ) { m_settings->setValue(key, (m_OptBool[key] = b)); }
	void setOptionInt ( const QString key, int     i ) { m_settings->setValue(key, (m_OptInt [key] = i)); }
	void setOptionReal( const QString key, double  f ) { m_settings->setValue(key, (m_OptReal[key] = f)); }
public:

	stat_t Png_optim(int index, QByteArray &src_png, bool rgb8b, int  qmin);
# ifdef WITH_JPG
	stat_t Jpg_optim(int index, QByteArray &src_jpg, bool progss, bool arith, int qmax);
# endif
# ifdef WITH_GIF
	stat_t Gif_optim(int index, QByteArray &gif_src, int colors, int plan, float lossy);
# endif
};

template<typename A, typename B>
static inline void MergeSmaller(A& dst_dat, B& src_dat, int src_sz, bool force) {
	int i;
	if (dst_dat.size() > src_sz || force) {
		dst_dat.resize(  src_sz  );
		for (i = 0; i  < src_sz; i++)
			dst_dat[i] = src_dat[i];
	}
}

#endif // _COLBI_H_
