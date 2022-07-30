#!/usr/bin/env bash

# Important: set -ex causes this whole script to terminate with error if
# any command in it fails. This is crucial for CI tests.
set -ex

if [[ "$USE_SIMD" != "" ]] ; then
    MY_CMAKE_FLAGS="$MY_CMAKE_FLAGS -DUSE_SIMD=$USE_SIMD"
fi

if [[ -n "$FMT_VERSION" ]] ; then
    MY_CMAKE_FLAGS="$MY_CMAKE_FLAGS -DBUILD_FMT_VERSION=$FMT_VERSION"
fi

# On GHA, we can reduce build time with "unity" builds.
if [[ ${GITHUB_ACTIONS} == true ]] ; then
    MY_CMAKE_FLAGS+=" -DCMAKE_UNITY_BUILD=${CMAKE_UNITY_BUILD:=ON} -DCMAKE_UNITY_BUILD_MODE=${CMAKE_UNITY_BUILD_MODE:=BATCH}"
fi

pushd build

if [[ $(conan profile list | grep default) == '' ]]; then
    conan profile new default --detect
fi
conan profile update settings.compiler=gcc default
conan profile update settings.compiler.version=8 default
conan profile update settings.compiler.libcxx=libstdc++11 default
echo -e '[conf]\ntools.system.package_manager:mode=install' >> ~/.conan/profiles/default
if [[ "$USE_FFMPEG" == '1' ]]; then
    CONAN_SYSREQUIRES_SUDO=0 CONAN_SYSREQUIRES_MODE=enabled conan install .. --build=openjpeg --build=libx264 --build=ffmpeg --build=libx265
else
    CONAN_SYSREQUIRES_SUDO=0 CONAN_SYSREQUIRES_MODE=enabled conan install ..
fi

cmake .. -G "$CMAKE_GENERATOR" \
        -DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE}" \
        -DCMAKE_PREFIX_PATH="$CMAKE_PREFIX_PATH" \
        -DCMAKE_INSTALL_PREFIX="$OpenImageIO_ROOT" \
        -DPYTHON_VERSION="$PYTHON_VERSION" \
        -DCMAKE_INSTALL_LIBDIR="$OpenImageIO_ROOT/lib" \
        -DCMAKE_CXX_STANDARD="$CMAKE_CXX_STANDARD" \
        -DOIIO_DOWNLOAD_MISSING_TESTDATA=ON \
        -DEXTRA_CPP_ARGS="${OIIO_EXTRA_CPP_ARGS}" \
        $MY_CMAKE_FLAGS -DVERBOSE=1

# Save a copy of the generated files for debugging broken CI builds.
mkdir cmake-save || /bin/true
cp -r CMake* *.cmake cmake-save

if [[ "$BUILDTARGET" != "none" ]] ; then
    echo "Parallel build " ${CMAKE_BUILD_PARALLEL_LEVEL}
    time cmake --build . --target ${BUILDTARGET:=install} --config ${CMAKE_BUILD_TYPE}
fi
popd

if [[ "${DEBUG_CI:=0}" != "0" ]] ; then
    echo "PATH=$PATH"
    echo "LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
    echo "PYTHONPATH=$PYTHONPATH"
    echo "ldd oiiotool"
    ldd $OpenImageIO_ROOT/bin/oiiotool
fi

if [[ "$BUILDTARGET" == clang-format ]] ; then
    git diff --color
    THEDIFF=`git diff`
    if [[ "$THEDIFF" != "" ]] ; then
        echo "git diff was not empty. Failing clang-format or clang-tidy check."
        exit 1
    fi
fi
