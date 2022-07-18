#!/usr/bin/env bash

# Utility script to download and build libaom

# Exit the whole script if any command fails.
set -ex

# Repo and branch/tag/commit of LIBDE265 to download if we don't have it yet
LIBDE265_REPO=${LIBDE265_REPO:=https://github.com/strukturag/libde265.git}
LIBDE265_VERSION=${LIBDE265_VERSION:=v1.0.8}

# Where to put libaom repo source (default to the ext area)
LIBDE265_SRC_DIR=${LIBDE265_SRC_DIR:=${PWD}/ext/libde265}
# Temp build area (default to a build/ subdir under source)
LIBDE265_BUILD_DIR=${LIBDE265_BUILD_DIR:=${LIBDE265_SRC_DIR}/build}
# Install area for libaom (default to ext/dist)
LOCAL_DEPS_DIR=${LOCAL_DEPS_DIR:=${PWD}/ext}
LIBDE265_INSTALL_DIR=${LIBDE265_INSTALL_DIR:=${LOCAL_DEPS_DIR}/dist}
LIBDE265_BUILD_OPTS=${LIBDE265_BUILD_OPTS:=}

pwd
echo "libaom install dir will be: ${LIBDE265_INSTALL_DIR}"

mkdir -p ./ext
pushd ./ext

# Clone libaom project from GitHub and build
if [[ ! -e ${LIBDE265_SRC_DIR} ]] ; then
    echo "git clone ${LIBDE265_REPO} ${LIBDE265_SRC_DIR}"
    git clone ${LIBDE265_REPO} ${LIBDE265_SRC_DIR}
fi
cd ${LIBDE265_SRC_DIR}

echo "git checkout ${LIBDE265_VERSION} --force"
git checkout ${LIBDE265_VERSION} --force

if [[ -z $DEP_DOWNLOAD_ONLY ]]; then
    time ./autogen.sh

    time ./configure --prefix=${LIBDE265_INSTALL_DIR} --disable-dec265 --disable-sherlock265
    time make -j 16

    # mkdir -p ${LIBDE265_BUILD_DIR}
    # cd ${LIBDE265_BUILD_DIR}

    # time cmake -DCMAKE_BUILD_TYPE=Release \
    #            -DCMAKE_INSTALL_PREFIX=${LIBDE265_INSTALL_DIR} \
    #            -DENABLE_SDL=OFF \
    #            ${LIBDE265_BUILD_OPTS} ..
    # time 
    # time cmake --build . --config Release --target install
fi

# ls -R ${LIBDE265_INSTALL_DIR}
popd

#echo "listing .."
#ls ..

# Set up paths. These will only affect the caller if this script is
# run with 'source' rather than in a separate shell.
export LibDe265_ROOT=$LIBDE265_INSTALL_DIR

