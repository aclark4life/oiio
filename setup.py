import os
import sys
import shlex
import shutil
import subprocess

import setuptools
import setuptools.command.build_ext


class CMakeExtension(setuptools.Extension):
    def __init__(self, name):
        setuptools.Extension.__init__(self, name, sources=[])


class OIIO_build_ext(setuptools.command.build_ext.build_ext):

    def run(self):
        self.build_temp_dir = (
            os.environ.get("OIIO_CXX_BUILD_TMP_DIR")
            or os.path.abspath(self.build_temp)
        )

        if not os.path.exists(self.build_temp_dir):
            os.makedirs(self.build_temp_dir)

        pythonSiteDir = os.path.join(os.path.abspath(self.build_lib), self.distribution.get_name())

        self.announce('running cmake generation', level=2)
        cmakeGenerateArgs = [
            'cmake', os.path.abspath(os.path.dirname(__file__)),
            '-G={0}'.format(os.environ.get('CMAKE_GENERATOR', 'Ninja')),
            '-DCMAKE_BUILD_TYPE={0}'.format(os.environ.get('CMAKE_BUILD_TYPE', 'Release')),
            '-DCMAKE_PREFIX_PATH={0}'.format(os.environ.get('CMAKE_PREFIX_PATH', '')),
            '-DCMAKE_INSTALL_PREFIX=/oiio/dist',
            '-DCMAKE_INSTALL_LIBDIR=/oiio/dist/lib',
            '-DCMAKE_CXX_STANDARD={0}'.format(os.environ.get('CMAKE_CXX_STANDARD', '17')),
            '-DBUILD_SHARED_LIBS=ON',
            '-DPython_EXECUTABLE={0}'.format(sys.executable),
            '-DPYTHON_SITE_DIR={0}'.format(pythonSiteDir),
            '-DLINKSTATIC=ON',
            '-DEXTRA_CPP_ARGS={0}'.format(os.environ.get('OIIO_EXTRA_CPP_ARGS', '')),
            '-DOIIO_DOWNLOAD_MISSING_TESTDATA=OFF',
            '-DOIIO_BUILD_TESTS=OFF',
            '-DOPENCOLORIO_NO_CONFIG=ON',
            '-DOIIO_BUILD_TOOLS=ON',
            '-DUSE_EXTERNAL_PUGIXML=1',
            '-DBUILD_FMT_VERSION=9.0.0',
            '-DVERBOSE=1'
            ]
        print(shlex.join(cmakeGenerateArgs))
        subprocess.check_call(
            cmakeGenerateArgs,
            cwd=self.build_temp_dir,
            env=os.environ.copy()
        )

        self.announce('running cmake build', level=2)
        cmakeInstallArgs = ['cmake', '--build', '.', '--target', 'install', '--config', 'Release']
        print(shlex.join(cmakeInstallArgs))
        subprocess.check_call(
            ['cmake', '--build', '.', '--target', 'install', '--config', 'Release'],
            cwd=self.build_temp_dir,
            env=os.environ.copy()
        )

        executablesPath = os.path.join(
            os.path.dirname(__file__),
            'dist',
            'bin'
        )

        commandsDir = os.path.join(pythonSiteDir, 'commands')
        if not os.path.exists(commandsDir):
            os.mkdir(commandsDir)

        for executable in os.listdir(executablesPath):
            sourcePath = os.path.join(executablesPath, executable)
            targetPath = os.path.join(commandsDir, executable)
            self.announce('copying {0} to {1}'.format(sourcePath, targetPath), level=2)
            shutil.copy(sourcePath, targetPath)


setuptools.setup(
    name='OpenImageIO',
    version='2.4.0.dev1',
    description='Reading, writing, and processing images in a wide variety of file formats, using a format-agnostic API, aimed at VFX applications.',
    author='Larry Gritz',
    author_email='lg@larrygritz.com',
    maintainer='Larry Gritz',
    maintainer_email='lg@larrygritz.com',
    license='',
    # long_description=LONG_DESCRIPTION,
    long_description_content_type='text/markdown',
    url='http://openimageio.org/',
    project_urls={
        'Source':
            'https://github.com/OpenImageIO/oiio',
        'Documentation':
            'https://openimageio.readthedocs.io',
        'Issues':
            'https://github.com/OpenImageIO/oiio/issues',
    },

    classifiers=[
        'Development Status :: 4 - Beta',
        'Topic :: Multimedia :: Graphics',
        'Topic :: Multimedia :: Video',
        'Topic :: Multimedia :: Video :: Display',
        'Topic :: Software Development :: Libraries :: Python Modules',
        # 'License :: Other/Proprietary License',
        'Programming Language :: Python :: 2',
        'Programming Language :: Python :: 2.7',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.7',
        'Programming Language :: Python :: 3.8',
        'Programming Language :: Python :: 3.9',
        'Programming Language :: Python :: 3.10',
        'Operating System :: OS Independent',
        'Natural Language :: English',
    ],

    keywords='',

    platforms='any',

    ext_modules=[
        CMakeExtension('OpenImageIO'),
    ],

    packages=(
        setuptools.find_packages(where='src/python')
    ),

    package_dir={
        'OpenImageIO': 'src/python/OpenImageIO',
    },

    # Disallow 3.9.0 because of https://github.com/python/cpython/pull/22670
    python_requires='>2.7, !=3.0.*, !=3.1.*, !=3.2.*, !=3.3.*, !=3.4.*, !=3.5.*, !=3.6.*, !=3.9.0',

    entry_points={
        'console_scripts': [
            'oiiotool = OpenImageIO._commands:oiiotool',
            'iinfo = OpenImageIO_commands:iinfo',
            'testtex = OpenImageIO_commands:testtex',
            'maketx = OpenImageIO_commands:maketx',
            'idiff = OpenImageIO_commands:idiff',
            'igrep = OpenImageIO_commands:igrep',
            'iconvert = OpenImageIO_commands:iconvert',
        ]
    },

    zip_safe=False,

    cmdclass={
        'build_ext': OIIO_build_ext,
    },
)
