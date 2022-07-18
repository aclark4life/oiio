#!/usr/bin/env bash

# Utility script to download and build libaom

# Exit the whole script if any command fails.
set -ex

# Repo and branch/tag/commit of LIBAOM to download if we don't have it yet
LIBAOM_REPO=${LIBAOM_REPO:=https://aomedia.googlesource.com/aom}
LIBAOM_VERSION=${LIBAOM_VERSION:=v3.4.0}

# Where to put libaom repo source (default to the ext area)
LIBAOM_SRC_DIR=${LIBAOM_SRC_DIR:=${PWD}/ext/libaom}
# Temp build area (default to a build/ subdir under source)
LIBAOM_BUILD_DIR=${LIBAOM_BUILD_DIR:=${LIBAOM_SRC_DIR}/build}
# Install area for libaom (default to ext/dist)
LOCAL_DEPS_DIR=${LOCAL_DEPS_DIR:=${PWD}/ext}
LIBAOM_INSTALL_DIR=${LIBAOM_INSTALL_DIR:=${LOCAL_DEPS_DIR}/dist}
LIBAOM_BUILD_OPTS=${LIBAOM_BUILD_OPTS:=}

pwd
echo "libaom install dir will be: ${LIBAOM_INSTALL_DIR}"

mkdir -p ./ext
pushd ./ext

# Clone libaom project from GitHub and build
if [[ ! -e ${LIBAOM_SRC_DIR} ]] ; then
    echo "git clone ${LIBAOM_REPO} ${LIBAOM_SRC_DIR}"
    git clone ${LIBAOM_REPO} ${LIBAOM_SRC_DIR}
fi
cd ${LIBAOM_SRC_DIR}

echo "git checkout ${LIBAOM_VERSION} --force"
git checkout ${LIBAOM_VERSION} --force

mkdir -p ${LIBAOM_BUILD_DIR}
cd ${LIBAOM_BUILD_DIR}

if [[ -z $DEP_DOWNLOAD_ONLY ]]; then
    time cmake -DCMAKE_BUILD_TYPE=Release \
               -DCMAKE_INSTALL_PREFIX=${LIBAOM_INSTALL_DIR} \
               -DENABLE_DOCS=0 \
               -DAOM_TARGET_CPU=generic \
               ${LIBAOM_BUILD_OPTS} ..
    time cmake --build . --config Release --target install
fi

# ls -R ${LIBAOM_INSTALL_DIR}
popd

#echo "listing .."
#ls ..

# Set up paths. These will only affect the caller if this script is
# run with 'source' rather than in a separate shell.
export LibAom_ROOT=$LIBAOM_INSTALL_DIR

