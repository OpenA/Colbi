cmake_minimum_required(VERSION 3.14)

project(Colbi
	VERSION 0.2
	LANGUAGES CXX
)

set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(QT NAMES Qt6 Qt5 COMPONENTS Core Quick LinguistTools REQUIRED)
find_package(Qt${QT_VERSION_MAJOR} COMPONENTS Core Quick LinguistTools REQUIRED)

set(TS_FILES
	ts/ru_RU.xml
)
set(PROJECT_DEPENDENCIES "")
set(PROJECT_EXTRA_LIBS   "")
set(PROJECT_INCLUDE_DIRS "src")
set(PROJECT_EXTRA_DEFS   "")
set(PROJECT_SOURCES
	main.cpp
	src/Colbi.hpp
	src/Colbi.cpp
	GifWorker.cpp
	JpgWorker.cpp
	PngWorker.cpp
	qml.qrc
	${TS_FILES}
)
add_subdirectory(lib)

if(${QT_VERSION_MAJOR} GREATER_EQUAL 6)
	qt_add_executable(Colbi
		MANUAL_FINALIZATION
		${PROJECT_SOURCES}
	)
# Define target properties for Android with Qt 6 as:
#    set_property(TARGET Colbi APPEND PROPERTY QT_ANDROID_PACKAGE_SOURCE_DIR
#                 ${CMAKE_CURRENT_SOURCE_DIR}/android)
# For more information, see https://doc.qt.io/qt-6/qt-add-executable.html#target-creation

qt_create_translation(QM_FILES ${CMAKE_SOURCE_DIR} ${TS_FILES})
else()
	if(ANDROID)
		add_library(Colbi SHARED
			${PROJECT_SOURCES}
		)
# Define properties for Android with Qt 5 after find_package() calls as:
#    set(ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/android")
	else()
		add_executable(Colbi
			${PROJECT_SOURCES}
		)
	endif()
	qt5_create_translation(QM_FILES ${CMAKE_SOURCE_DIR} ${TS_FILES})
endif()

message(STATUS "dependencies: ${PROJECT_DEPENDENCIES}")
add_dependencies(Colbi ${PROJECT_DEPENDENCIES})

target_include_directories(Colbi SYSTEM AFTER PUBLIC ${PROJECT_INCLUDE_DIRS})
target_compile_definitions(Colbi PRIVATE $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:QT_QML_DEBUG> ${PROJECT_EXTRA_DEFS})
target_link_libraries     (Colbi PRIVATE Qt${QT_VERSION_MAJOR}::Core Qt${QT_VERSION_MAJOR}::Quick ${PROJECT_EXTRA_LIBS})

set_target_properties(Colbi PROPERTIES
	MACOSX_BUNDLE_GUI_IDENTIFIER my.example.com
	MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
	MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
	MACOSX_BUNDLE TRUE
	WIN32_EXECUTABLE TRUE
)

if(QT_VERSION_MAJOR EQUAL 6)
	qt_import_qml_plugins(Colbi)
	qt_finalize_executable(Colbi)
endif()
