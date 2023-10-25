
include(ExternalProject)

# = = = = = = = = = = Quantize lib = = = = = = = = #
set(BUILD_WITH_SSE ON CACHE BOOL "")
set(LIB_INSTALL_DIR ${CMAKE_BINARY_DIR}/lib CACHE STRING "")
set(CMAKE_DISABLE_FIND_PACKAGE_OpenMP ON CACHE BOOL "")
add_subdirectory(libimagequant)

# = = = = = = = = = = PNG Optimize lib = = = = = = = = #
#set(BUILD_SHARED_LIBS ON CACHE BOOL "")
add_subdirectory(zopfli)

set(extra_libs
	imagequant_a
	libzopflipng
)
set(include_dirs
	${PROJECT_SOURCE_DIR}/lib/libimagequant
	${PROJECT_SOURCE_DIR}/lib/zopfli/src/zopflipng
)
set(build_deps
	imagequant_a
	zopfli
)

option(ENABLE_GIF "enable GIF Optim module" ON)
if (ENABLE_GIF)

  set(gifsi_params
    -DENABLE_SHARED=0 -DBUILD_GIFSICLE=0 -DWITH_SIMD=1)

	ExternalProject_Add(gifsi
		SOURCE_DIR ${PROJECT_SOURCE_DIR}/lib/libgifsi
		INSTALL_COMMAND ""
		CMAKE_ARGS ${gifsi_params}
	)
	ExternalProject_Get_Property(gifsi binary_dir)
	add_library(libgifsi STATIC IMPORTED GLOBAL)
	set_target_properties(libgifsi PROPERTIES IMPORTED_LOCATION
		${binary_dir}/libgifsi.a
	)
	set(build_deps   ${build_deps} gifsi)
	set(extra_libs   ${extra_libs} libgifsi)
	set(include_dirs ${include_dirs}
		${PROJECT_SOURCE_DIR}/lib/libgifsi/include
	)
	unset(gifsi_params)
	unset(binary_dir)
endif()

option(ENABLE_JPG "enable JPEG Optim module" ON)
if (ENABLE_JPG)

	set(mozjpeg_params
		-DWITH_ARITH_ENC=1 -DENABLE_SHARED=0 -DPNG_SUPPORTED=0 -DWITH_SIMD=1
		-DWITH_ARITH_DEC=1 -DENABLE_STATIC=1 -DWITH_TURBOJPEG=0 -DWITH_JPEG8=1
	)

	ExternalProject_Add(mozjpeg
		SOURCE_DIR ${PROJECT_SOURCE_DIR}/lib/mozjpeg
		INSTALL_COMMAND ""
		CMAKE_ARGS ${mozjpeg_params}
		BUILD_COMMAND make jpeg-static
	)
	ExternalProject_Get_Property(mozjpeg binary_dir)
	add_library(libmozjpeg STATIC IMPORTED GLOBAL)
	set_target_properties(libmozjpeg PROPERTIES IMPORTED_LOCATION
		${binary_dir}/libjpeg.a
	)
	set(build_deps   ${build_deps} mozjpeg)
	set(extra_libs   ${extra_libs} libmozjpeg)
	set(include_dirs ${include_dirs}
		${PROJECT_SOURCE_DIR}/lib/mozjpeg
		${binary_dir}
	)
	unset(mozjpeg_params)
	unset(binary_dir)
endif()

set(PROJECT_EXTRA_LIBS   ${PROJECT_EXTRA_LIBS}   ${extra_libs}   PARENT_SCOPE)
set(PROJECT_INCLUDE_DIRS ${PROJECT_INCLUDE_DIRS} ${include_dirs} PARENT_SCOPE)
set(PROJECT_DEPENDENCIES ${PROJECT_DEPENDENCIES} ${build_deps}   PARENT_SCOPE)
