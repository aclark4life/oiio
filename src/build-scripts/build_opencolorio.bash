#!/usr/bin/env bash

# Utility script to download and build OpenColorIO

# Exit the whole script if any command fails.
set -ex

# Which OCIO to retrieve, how to build it
OPENCOLORIO_REPO=${OPENCOLORIO_REPO:=https://github.com/AcademySoftwareFoundation/OpenColorIO.git}
OPENCOLORIO_VERSION=${OPENCOLORIO_VERSION:=v2.1.2}

# Where to install the final results
LOCAL_DEPS_DIR=${LOCAL_DEPS_DIR:=${PWD}/ext}
OPENCOLORIO_SOURCE_DIR=${OPENCOLORIO_SOURCE_DIR:=${LOCAL_DEPS_DIR}/OpenColorIO}
OPENCOLORIO_BUILD_DIR=${OPENCOLORIO_BUILD_DIR:=${LOCAL_DEPS_DIR}/OpenColorIO-build}
OPENCOLORIO_INSTALL_DIR=${OPENCOLORIO_INSTALL_DIR:=${LOCAL_DEPS_DIR}/dist}
OPENCOLORIO_YAML_CXX_FLAGS=${OPENCOLORIO_YAML_CXX_FLAGS:=''}
if [[ "$OSTYPE" != "msys" ]]; then
    # TODO: Does this apply to non Linux builds?
    OPENCOLORIO_CXX_FLAGS=${OPENCOLORIO_CXX_FLAGS:="-Wno-unused-function -Wno-deprecated-declarations -Wno-cast-qual -Wno-write-strings"}
    OPENCOLORIO_YAML_CXX_FLAGS=${OPENCOLORIO_YAML_CXX_FLAGS:=''}
else
    if [[ "${OPENCOLORIO_BUILD_SHARED_LIBS}" != "ON" ]]; then
        OPENCOLORIO_CXX_FLAGS=${OPENCOLORIO_CXX_FLAGS:="//MT"}
        OPENCOLORIO_YAML_CXX_FLAGS=${OPENCOLORIO_YAML_CXX_FLAGS:='//MT'}
    fi
fi
# Just need libs:
OPENCOLORIO_BUILDOPTS="-DOCIO_BUILD_APPS=OFF -DOCIO_BUILD_NUKE=OFF \
                       -DOCIO_BUILD_DOCS=OFF -DOCIO_BUILD_TESTS=OFF \
                       -DOCIO_BUILD_GPU_TESTS=OFF \
                       -DOCIO_BUILD_PYTHON=OFF -DOCIO_BUILD_PYGLUE=OFF \
                       -DOCIO_BUILD_JAVA=OFF \
                       -DBUILD_SHARED_LIBS=${OPENCOLORIO_BUILD_SHARED_LIBS:=ON}"

if [ "${OPENCOLORIO_BUILD_SHARED_LIBS}" != "ON" ]; then
    OPENCOLORIO_BUILDOPTS="${OPENCOLORIO_BUILDOPTS} -DCMAKE_POSITION_INDEPENDENT_CODE=ON"
fi

BASEDIR=`pwd`
pwd
echo "OpenColorIO install dir will be: ${OPENCOLORIO_INSTALL_DIR}"

mkdir -p ${LOCAL_DEPS_DIR}
pushd ${LOCAL_DEPS_DIR}

# Clone OpenColorIO project from GitHub and build
if [[ ! -e ${OPENCOLORIO_SOURCE_DIR} ]] ; then
    echo "git clone ${OPENCOLORIO_REPO} ${OPENCOLORIO_SOURCE_DIR}"
    git clone ${OPENCOLORIO_REPO} ${OPENCOLORIO_SOURCE_DIR}
fi
cd ${OPENCOLORIO_SOURCE_DIR}

echo "git checkout ${OPENCOLORIO_VERSION} --force"
git checkout ${OPENCOLORIO_VERSION} --force

# Apply https://github.com/AcademySoftwareFoundation/OpenColorIO/pull/1599
git apply "${BASEDIR}/ocio.patch"

mkdir -p ${OPENCOLORIO_BUILD_DIR}
cd ${OPENCOLORIO_BUILD_DIR}
# # TODO: Is yaml-cpp_CXX_FLAGS and DCMAKE_CXX_FLAGS_RELEASE really needed? I don't remember
time cmake -DCMAKE_BUILD_TYPE=Release \
           -DCMAKE_INSTALL_PREFIX=${OPENCOLORIO_INSTALL_DIR} \
           -DCMAKE_CXX_FLAGS_RELEASE="${OPENCOLORIO_CXX_FLAGS}" \
           -Dyaml-cpp_CXX_FLAGS="${OPENCOLORIO_YAML_CXX_FLAGS}" \
           ${OPENCOLORIO_BUILDOPTS} ${OPENCOLORIO_SOURCE_DIR}
time cmake --build . --config Release --target install
popd

# ls -R ${OPENCOLORIO_INSTALL_DIR}

#echo "listing .."
#ls ..

# Set up paths. These will only affect the caller if this script is
# run with 'source' rather than in a separate shell.
export OpenColorIO_ROOT=$OPENCOLORIO_INSTALL_DIR
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${OPENCOLORIO_INSTALL_DIR}/lib

