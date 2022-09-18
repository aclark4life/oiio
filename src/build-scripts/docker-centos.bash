# docker run -ti --rm -v $(pwd):/jc quay.io/pypa/manylinux2014_x86_64:latest bash
set -ex

_PYTHON_VERSION=$(python3 --version | grep -o '[[:digit:]].[[:digit:]][[:digit:]]')

if [[ "$OSTYPE" == linux-* ]]; then
    yum install ninja-build wget less ccache -y
    PATH="~/.local/bin:$PATH"

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

    cp $(which ccache) /usr/local/bin/ || true
    ln -sf $(which ccache) /usr/local/bin/gcc
    ln -sf $(which ccache) /usr/local/bin/g++
    ln -sf $(which ccache) /usr/local/bin/cc
    ln -sf $(which ccache) /usr/local/bin/c++
    ccache --max-files 0 --max-size 0

elif [[ "$OSTYPE" == darwin* ]]; then
    brew install wget ccache cmake pkg-config ninja

    export PATH="/usr/local/opt/ccache/libexec:~/Library/Python/${_PYTHON_VERSION}/bin:$PATH"

elif [[ "$OSTYPE" == 'msys' ]]; then
    _PYTHON_VERSION=$(echo $_PYTHON_VERSION | tr '.' '')
    export PATH="$PATH:~/AppData/Roaming/Python/Python${_PYTHON_VERSION}/Scripts"
fi

python3 -m pip install conan numpy --user

# TODO: Switch to C++14?
export CMAKE_CXX_STANDARD=17

export USE_OPENVDB=0
export USE_QT5=0
export USE_OPENGL=0
export USE_NUKE=0
export USE_R3DSDK=0
export USE_JPEGTURBO=0

export USE_FFMPEG=1
export USE_PNG=1
export USE_OPENCV=0 # Always disable
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
export USE_CONAN=1  # Where is this used? I don't remember. But could be a CMake var instead.

# TODO: Is it required?
export LINKSTATIC=1

export OPENCOLORIO_VERSION=v2.1.2
export PUGIXML_VERSION=v1.11.4
export FMT_VERSION=9.0.0
export OPENEXR_VERSION=v3.1.5
export PYBIND11_VERSION=v2.9.2

export OPENCOLORIO_BUILD_SHARED_LIBS=OFF
export PUGIXML_BUILD_SHARED_LIBS=OFF
export OPENEXR_BUILD_SHARED_LIBS=OFF

export MY_CMAKE_FLAGS="${MY_CMAKE_FLAGS} -DBUILD_SHARED_LIBS=OFF -DLINKSTATIC=ON -DOIIO_BUILD_TESTS=OFF -DOIIO_BUILD_TOOLS=ON"

# TODO: Is it needed?
export PYTHON_VERSION=$_PYTHON_VERSION

export MACOSX_DEPLOYMENT_TARGET=10.13

export OPENIMAGEIO_OPTIONS="openexr:core=1"

source src/build-scripts/ci-startup.bash

# TODO: Is it needed?
export CMAKE_BUILD_PARALLEL_LEVEL=16

unset TERM  # Required to have "non smart" cmake output.

mkdir -p build

pushd build
if [[ $(conan profile list | grep default) == '' ]]; then
    conan profile new default --detect
fi

if [[ "$OSTYPE" == linux-* ]]; then
    conan profile update settings.compiler=gcc default
    # TODO: Should we use an older version? Or we don't care ebcause we recompile everything anyway?
    conan profile update settings.compiler.version=10 default
    conan profile update settings.compiler.libcxx=libstdc++ default
elif [[ "$OSTYPE" == darwin* ]]; then
    conan profile update settings.os.version=10.13 default  # Deployment target
    conan profile update settings.compiler=apple-clang default
    conan profile update settings.compiler.version=13.1 default
    conan profile update settings.compiler.libcxx=libc++ default
elif [[ "$OSTYPE" == "msys" ]]; then
    conan profile update settings.compiler='Visual Studio' default
    # TODO: Is /MT required if we don't build for Python 2.7?
    conan profile update settings.compiler.runtime=MT default
    conan profile update settings.compiler.version=16 default
    conan profile update settings.arch=x86_64 default

    export CONAN_CMAKE_FILES=$(pwd)
fi

conanArgs=''

if [[ "$USE_FFMPEG" == '1' ]]; then
    cp ../conanfile.txt .
    conanArgs='--build=openjpeg --build=libx264 --build=ffmpeg --build=libx265 --build expat --build boost -c tools.system.package_manager:mode=install -c tools.system.package_manager:tool=yum'
    if [[ "$OSTYPE" == "msys" ]]; then
        cat ../conanfile.txt | grep -v with_vulkan | grep -v with_pulse > conanfile.txt
    fi

    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == darwin* ]]; then
        cat ../conanfile.txt | grep -v '.*\:\(with_vulkan\|with_pulse\|with_stacktrace_backtrace\|with_vaapi\|with_vdpau\|with_xcb\)\=.*' > conanfile.txt
        sed -i '.bak' 's/boost\:.*//g' conanfile.txt
        conanArgs=''
    fi

    if [[ "$OSTYPE" == darwin* ]]; then
        conanArgs='--build'
    fi
else
    cat ../conanfile.txt | grep -v 'ffmpeg/' > conanfile.txt
fi

export CONAN_SYSREQUIRES_SUDO=0
export CONAN_SYSREQUIRES_MODE=enabled

conan install . --build #$conanArgs

popd

source src/build-scripts/gh-installdeps.bash

# TODO: Replace with either pip wheel or we need to use cibuildwheel.
python3 setup.py bdist_wheel

# To bundle the OIIO libs and other needed libs: auditwheel repair dist/*.whl --lib-sdir /libs
# On macOS: delocate-wheel dist/OpenImageIO-2.4.0.dev1-cp310-cp310-macosx_12_0_x86_64.whl --lib-sdir libs
# Note that on macOS, delocate doesn't mark the wheel as macosx_10.13 ...
# On windows, delvewheel can be used.
