#!/usr/bin/env bash

set -ex
apt update
# apt upgrade -y
DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt install sudo wget gzip software-properties-common -y

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

export CXX=g++-8
export CC=gcc-8
export COMPILER=gcc-8
export CMAKE_CXX_STANDARD=17

export USE_OPENVDB=0
export USE_QT5=0
export USE_OPENGL=0
export USE_NUKE=0
export USE_R3DSDK=0
export USE_JPEGTURBO=0

export USE_FFMPEG=1
export USE_PNG=1
export USE_OPENCV=0
export USE_GIF=1
export USE_PTEX=1
export USE_WEBP=1
export USE_OPENCOLORIO=1
export USE_OPENEXR=1
export USE_LIBHEIF=1
export USE_TIFF=1
export USE_LIBRAW=1
export USE_OPENJPEG=1
export USE_FREETYPE=1

export OPENCOLORIO_VERSION=v2.1.2
export PUGIXML_VERSION=v1.11.4
export FMT_VERSION=9.0.0
export OPENEXR_VERSION=v3.1.5
export PYBIND11_VERSION=v2.9.2

export OPENCOLORIO_BUILD_SHARED_LIBS=OFF
export OPENEXR_CMAKE_FLAGS=-DBUILD_SHARED_LIBS=OFF
export PUGIXML_BUILD_OPTS=-DBUILD_SHARED_LIBS=OFF

export MY_CMAKE_FLAGS="${MY_CMAKE_FLAGS} -DBUILD_SHARED_LIBS=OFF -DLINKSTATIC=ON -DOIIO_BUILD_TESTS=OFF -DOPENCOLORIO_NO_CONFIG=ON -DOIIO_BUILD_TOOLS=ON"
export PYTHON_VERSION=3.9

export OPENIMAGEIO_OPTIONS="openexr:core=1"

source src/build-scripts/ci-startup.bash

export CMAKE_BUILD_PARALLEL_LEVEL=16

unset TERM

apt install python3 python3-pip cmake pkg-config -y
python3 -m pip install conan

source src/build-scripts/gh-installdeps.bash

source src/build-scripts/ci-build.bash
