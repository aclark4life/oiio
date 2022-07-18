#!/usr/bin/env bash

# Utility script to download and build libaom

# Exit the whole script if any command fails.
set -ex

# Repo and branch/tag/commit of LIBHEIF to download if we don't have it yet
LIBHEIF_REPO=${LIBHEIF_REPO:=https://github.com/strukturag/libheif.git}
LIBHEIF_VERSION=${LIBHEIF_VERSION:=v1.12.0}

# Where to put libaom repo source (default to the ext area)
LIBHEIF_SRC_DIR=${LIBHEIF_SRC_DIR:=${PWD}/ext/libheif}
# Temp build area (default to a build/ subdir under source)
LIBHEIF_BUILD_DIR=${LIBHEIF_BUILD_DIR:=${LIBHEIF_SRC_DIR}/build}
# Install area for libaom (default to ext/dist)
LOCAL_DEPS_DIR=${LOCAL_DEPS_DIR:=${PWD}/ext}
LIBHEIF_INSTALL_DIR=${LIBHEIF_INSTALL_DIR:=${LOCAL_DEPS_DIR}/dist}
LIBHEIF_BUILD_OPTS=${LIBHEIF_BUILD_OPTS:=}

pwd
echo "libaom install dir will be: ${LIBHEIF_INSTALL_DIR}"

mkdir -p ./ext
pushd ./ext

# Clone libaom project from GitHub and build
if [[ ! -e ${LIBHEIF_SRC_DIR} ]] ; then
    echo "git clone ${LIBHEIF_REPO} ${LIBHEIF_SRC_DIR}"
    git clone ${LIBHEIF_REPO} ${LIBHEIF_SRC_DIR}
fi
cd ${LIBHEIF_SRC_DIR}

echo "git checkout ${LIBHEIF_VERSION} --force"
git checkout ${LIBHEIF_VERSION} --force

mkdir -p ${LIBHEIF_BUILD_DIR}
cd ${LIBHEIF_BUILD_DIR}

if [[ -z $DEP_DOWNLOAD_ONLY ]]; then
    time cmake -DCMAKE_BUILD_TYPE=Release \
               -DCMAKE_INSTALL_PREFIX=${LIBHEIF_INSTALL_DIR} \
               -DWITH_RAV1E=OFF \
               -WITH_DAV1D=OFF \
               -DCMAKE_FIND_LIBRARY_SUFFIXES=.a \
               ${LIBHEIF_BUILD_OPTS} ..
    time cmake --build . --config Release --target install
fi

# ls -R ${LIBHEIF_INSTALL_DIR}
popd

#echo "listing .."
#ls ..

# Set up paths. These will only affect the caller if this script is
# run with 'source' rather than in a separate shell.
export Libheif_ROOT=$LIBHEIF_INSTALL_DIR

