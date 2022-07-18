#!/usr/bin/env bash
set -ex
apt update
# apt upgrade -y
apt install sudo wget gzip software-properties-common -y

if [[ ! -d /opt/cmake ]]; then
    currentPath=$(pwd)
    wget https://github.com/Kitware/CMake/releases/download/v3.23.2/cmake-3.23.2-linux-x86_64.tar.gz
    mkdir -p /opt/cmake
    cd /opt
    tar -xzf "${currentPath}/cmake-3.23.2-linux-x86_64.tar.gz"
    rm "${currentPath}/cmake-3.23.2-linux-x86_64.tar.gz"
    mv cmake-3.23.2-linux-x86_64/* cmake/
    rm -rf cmake-3.23.2-linux-x86_64/
    cd "${currentPath}"
fi

export PATH=/opt/cmake/bin:$PATH

export CXX=g++-11
export CC=gcc-11
export COMPILER=gcc-11
export CMAKE_CXX_STANDARD=17


export BUILD_SHARED_LIBS=OFF

export USE_OPENVDB=0
export USE_QT5=0
export USE_OPENGL=0
export USE_NUKE=0
export USE_R3DSDK=0
export USE_JPEGTURBO=0

export LIBRAW_VERSION=0.20.2
export LIBTIFF_VERSION=v4.4.0
export OPENCOLORIO_VERSION=v2.1.2
export OPENJPEG_VERSION=v2.4.0
export PTEX_VERSION=v2.4.0
export PUGIXML_VERSION=v1.11.4
export WEBP_VERSION=v1.2.1
export FMT_VERSION=9.0.0
export OPENEXR_VERSION=v3.1.5
export PYBIND11_VERSION=v2.9.2
export LIBAOM_VERSION=v3.4.0
export LIBDE265_VERSION=v1.0.8
export LIBHEIF_VERSION=v1.12.0

export LIBTIFF_BUILDOPTS=-DBUILD_SHARED_LIBS=OFF
export OPENCOLORIO_BUILD_SHARED_LIBS=OFF
export OPENJPEG_CONFIG_OPTS=-DBUILD_SHARED_LIBS=OFF
export OPENEXR_CMAKE_FLAGS=-DBUILD_SHARED_LIBS=OFF
export LIBPNG_CONFIG_OPTS=-DBUILD_SHARED_LIBS=OFF
export OPENJPEG_CONFIG_OPTS=-DBUILD_SHARED_LIBS=OFF
export PTEX_CONFIG_OPTS=-DBUILD_SHARED_LIBS=OFF
export PUGIXML_BUILD_OPTS=-DBUILD_SHARED_LIBS=OFF
export WEBP_CONFIG_OPTS=-DBUILD_SHARED_LIBS=OFF
export ZLIB_CONFIG_OPTS=-DBUILD_SHARED_LIBS=OFF
export AOM_BUILD_OPTS=-DBUILD_SHARED_LIBS=OFF
export LIBHEIF_BUILD_OPTS=-DBUILD_SHARED_LIBS=OFF

export MY_CMAKE_FLAGS="${MY_CMAKE_FLAGS} -DBUILD_SHARED_LIBS=OFF -DLINKSTATIC=ON -DOpenJPEG_ROOT=/root/ext/dist/lib/ -DOIIO_BUILD_TESTS=OFF -DLIBHEIF_INCLUDE_PATH=/root/ext/dist/include -DLIBHEIF_LIBRARY_PATH=/root/ext/dist/lib"
export PYTHON_VERSION=3.9

export OPENIMAGEIO_OPTIONS="openexr:core=1"

source src/build-scripts/ci-startup.bash
# export CCACHE_DISABLE=1

export CMAKE_BUILD_PARALLEL_LEVEL=16

unset TERM

source src/build-scripts/gh-installdeps.bash

source src/build-scripts/ci-build.bash
