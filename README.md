PostgreSQL Installer build system 
=================================

This is the PostgreSQL Installer build system. This document attempts to 
describe how the system is architected, how to set it up and how to extend 
it. It is a work in progress and will no doubt require further refinement
over time. There there is one goal however:

Build all PostgresSQL & add-on package installers for all supported platforms
with a single command.

Note that this system is not intended to replace the existing installer system 
used on Windows (pgInstaller) - it is intended to mirror it's basic functionality
however.

Modular system design
---------------------

The modular system is designed to be as flexible as possible and allow package
authors as much freedom as possible in the way they design their installers. 
There are some basic rules about how we design add-on packages however - it 
remains up  to the individual author to determine whether or not breaking any 
rules will break their package. They had better not break the system though!

* Registration:

A central registry file is used in which packages should register themselves. This
data will be used by StackBuilder to locate installed packages. The registry 
file is /etc/postgres-reg.ini, and should be considered analagous in function to
the sections of the Windows registry used for the same purposes on that platform.

StackBuilder requires specific entries for the PostgreSQL server, as well as an
entry indicating the installed version of each unique package. An example file
is show below.

; This section is for a server, and is analagous to the PostgreSQL key under
; HKEY_CURRENT_USER\Software on Windows
[PostgreSQL/19]
InstallationDirectory=/Library/PostgreSQL/19
Version=19-Beta3
Shortcuts=1
DataDirectory=/Library/PostgreSQL/19/data
Port=5433
ServiceID=postgresql-19
Locale=C
Superuser=postgres
Serviceaccount=postgres
Description=PostgreSQL 19
Branding=PostgreSQL 19
SB_Version=4.2.2
pgAdmin_Version=9.17
CLT_Version=19-Beta3
DisableStackBuilder=
[edb_languagepack_v6]
Description=
InstallationDirectory=
Version=
[PostGIS_PG19]
Description=PostGIS adds support for geographic objects to PostgreSQL.
InstallationDirectory=/Library/PostgreSQL/19
Version=3.6.3-1
Branding=PostgreSQL 19
[pgAgent_PG19]
Description=pgAgent is a job scheduler for PostgreSQL which may be managed using pgAdmin.
InstallationDirectory=/Library/PostgreSQL/19
Version=4.2.3-1
ServiceManager=postgres
PGUSER=postgres
PGHOST=localhost
PGPORT=5432
PGDATABASE=postgres
UpgradeMode=0

It is up to the uninstaller for each package to leave or clean the data during 
uninstallation. The version number for a package should *always* be
cleared, but other data may be retained. For example, the server package will
not remove the data directory, thus it is appropriate to leave the 
DataDirectory, Port and Superuser values intact.

* Installers:

Each package installer should be capable of being silently or interactively 
installing and uninstalling the package. When uninstalling, as much of the package
as possible should be removed, however it is not always possible (through
lack of reference counting between packages) or desirable to remove everything.

Build platform
--------------

The build platform for macOS is macOS 15 (Sequoia), used to produce the
universal (arm64 + x86_64) macOS packages - unlike the other supported
platforms, macOS binaries can only be built on macOS itself.

Setting up a new build machine:

- Install the Xcode Command Line Tools:

xcode-select --install

  This provides the compiler toolchain and the macOS SDK the build links
  against.

- Install Homebrew (https://brew.sh/), then install the utilities actually
  needed to build the installer:

$ brew install cmake bison flex

  bison and flex are required to build PostgreSQL's own grammar (the
  versions Apple ships under /usr/bin are too old); cmake is needed for
  the handful of dependencies below that use a CMake-based build instead
  of autotools. (See "Set up DocBook" further down for the one other
  Homebrew package needed.)

  The old MacPorts-based setup, and its ossp-uuid dependency, are no
  longer used - PostgreSQL is now built with --with-uuid=e2fs against the
  e2fsprogs library, which is one of the third-party dependencies built
  below.

Dependency libraries must be built with a little more control to ensure they
use the correct SDK and are built as universal (arm64 + x86_64) binaries,
usable on macOS 12 (Monterey) and above.

The exact list of third-party libraries PostgreSQL links against on macOS,
and the exact version of each, is pinned in server/packages-osx.txt. At the
time of writing that's: openssl, zlib, curl, zstd, lz4, libxml2, libxslt,
libiconv, icu, gettext, e2fsprogs, krb5, libedit.

To build one of these yourself:

- Download the library's source tarball, matching the version pinned in
  server/packages-osx.txt, and unpack it.

- Configure it to build as a universal binary against a fixed SDK. For a
  typical autotools-based library:

SDK=$(xcrun --sdk macosx --show-sdk-path)
CFLAGS="-arch arm64 -arch x86_64 -isysroot $SDK -mmacosx-version-min=12" \
LDFLAGS="-arch arm64 -arch x86_64 -isysroot $SDK -mmacosx-version-min=12" \
./configure --prefix=/path/to/deps

  A few of these (eg. zstd) use cmake instead - pass the equivalent flags
  as -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64"
  -DCMAKE_OSX_DEPLOYMENT_TARGET=12 -DCMAKE_OSX_SYSROOT="$SDK". openssl uses
  its own Configure script and is typically built once per architecture
  and combined into a universal binary with lipo, rather than a single
  configure line.

- Build and install it into a single common prefix (the --prefix above)
  that all the other dependencies, and PostgreSQL itself, will be built
  against:

make -j"$(sysctl -n hw.ncpu)"
make install

Repeat this for every library listed in server/packages-osx.txt, installing
each into that same prefix.

Note that we must make sure all additional libraries link against these
freshly-built libraries, and not the older, system copies. In the case of
libxslt, we can do this by configuring with option --with-libxml-prefix.

Once every dependency is installed into that prefix, build PostgreSQL
itself against it - see server/scripts/osx/compile.sh for the exact
./configure flags and environment PostgreSQL is built with, and
server/scripts/osx/rewrite-dylib-refs.sh for making the resulting binaries
relocatable.

- Language interpreters

PostgreSQL is also configured with --with-python, --with-perl and
--with-tcl, so three more things need to be in place first (see
server/version.txt for the exact versions currently pinned, and
server/scripts/osx/compile.sh for how each is passed in):

  * Python - install the official universal2 installer from python.org
    for the version pinned by the `python=` entry in server/version.txt,
    e.g.:

    https://www.python.org/ftp/python/<version>/python-<version>-macos11.pkg

    This installs a proper Python.framework under
    /Library/Frameworks - a Homebrew Python install will not work here,
    as plpython3 needs the framework layout.

    Only the build itself needs this exact pinned version: compile.sh
    rewires the resulting plpython3.dylib to link against
    Python.framework/Versions/Current rather than a fixed version, so any
    python.org install >=3.9 already on the end user's Mac satisfies it
    at runtime - they don't need to match the version built against.

  * Perl and Tcl - either build your own universal (arm64 + x86_64) Perl
    and Tcl, matching the `perl=`/`tcl=` entries in server/version.txt,
    the same way as the other dependencies above, or install the EDB
    Language Pack (which bundles both as universal builds already). Either
    way, point compile.sh at the resulting PERL_DIR (containing bin/perl)
    and TCL_DIR (containing lib/tclConfig.sh).

- Set up DocBook

    brew install docbook docbook-xsl

Homebrew's docbook-xsl formula sets up a working XML catalog for you (at
/opt/homebrew/etc/xml/catalog on Apple Silicon, /usr/local/etc/xml/catalog
on Intel - see the XML_CATALOG_FILES line in compile.sh). There's no need
to manually download DocBook 4.2, patch its catalog, or hand-write a
catalog file.

Build VMs
---------

All VMs (and in fact, the host machine) are setup to use user accounts called
'buildfarm'. In order to access each, the VMs must be setup with fixed IP
addresses which are recorded with an appropriate hostname in DNS. Each hostname 
is specified in settings.sh. It may be necessary to manually configure VMWare 
Fusion to bridge the network adaptor instead of using NAT.

The top level 'pginstaller' directory is shared with all the VMs using the VMware
shared folders feature. The path to this directory is specified in settings.h
for each VM. Note that VMware doesn't map UIDs/GIDs between the host and the VMs
so it may be necessary to mount the shared directory using the UID/GID of the
user in the VM, eg using the following in /etc/fstab:

.host:/  /mnt/hgfs  vmhgfs  defaults,ttl=5,uid=500,gid=500     0 0

SSH authentication between hosts is achieved using certificates. These can be
generated on the host machine using:

ssh-keygen -t rsa

Copy the resulting id_rsa.pub file to ~/.ssh/authorized_keys on each VM. 

* Linux/Linux-x64
- Install chrpath utility in order to change the rpath of the installed PostgreSQL binaries in the staging directory.
  Use the following command to install the chrpath:
  * yum install chrpath

* Windows

Building PostgreSQL on a Windows VM using the Meson build system:

Prerequisites & Environment Setup:
- Windows OS: Windows Server 2019/2022 or Windows 10/11 (64-bit).
- Compiler: Visual Studio 2019 or newer with the "Desktop development with C++" workload installed.
- Python: Python 3.10+ (Ensure "Add Python to PATH" is checked during installation).
- Build System: Install Meson and Ninja via Python pip:
    pip install meson ninja
- Perl: Strawberry Perl (Required for script generation and builds).
    Download from https://strawberryperl.com/
- Flex & Bison: win_flex_bison binaries.
    1. Download from https://github.com/lexxmark/winflexbison
    2. Extract to a dedicated folder (e.g., C:\3rd_Party_Libraries\win_flex_bison)
    3. Add the extraction path to your System PATH environment variable.
- Optional Dependencies (For full feature support):
    Install libraries like OpenSSL, Zlib, ICU, or LibXML2 using vcpkg:
    vcpkg install zlib:x64-windows openssl:x64-windows icu:x64-windows

Setting Up SSH Access (Optional / Build Farm Automation):
- Enable OpenSSH Server natively via PowerShell:
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
- Start and configure the sshd service to run automatically:
    Start-Service sshd
    Set-Service -Name sshd -StartupType 'Automatic'
- Ensure Port 22/TCP is allowed in the Windows Defender Firewall.
- Place public SSH keys in `C:\Users\<build-user>\.ssh\authorized_keys`.

Repository Preparation:
Ensure Git handles CRLF line endings correctly to avoid flex/bison parser errors:
    git config core.autocrlf true
    git rm --cached -r .
    git reset --hard

Build Instructions:
Always execute build commands from the "x64 Native Tools Command Prompt for VS <version>" (run as Administrator) to load compiler environment variables (`cl.exe`).

1. Configure the build directory:
   :: Minimal Build (No external compression/SSL dependencies)
   meson setup build --prefix=C:\PG_install ^
     -DFLEX=C:\3rd_Party_Libraries\win_flex_bison\win_flex.exe ^
     -DBISON=C:\3rd_Party_Libraries\win_flex_bison\win_bison.exe ^
     -Dreadline=disabled ^
     -Dzlib=disabled

   :: Full Featured Build (If vcpkg dependencies are installed)
   meson setup build --prefix=C:\PG_install ^
     -DFLEX=C:\3rd_Party_Libraries\win_flex_bison\win_flex.exe ^
     -DBISON=C:\3rd_Party_Libraries\win_flex_bison\win_bison.exe ^
     -Dcmake_prefix_path=C:\vcpkg\installed\x64-windows

2. Compile and Deploy:
   ninja -C build install

3. Run Regression Tests (Optional):
   meson test -C build

4. Initialize and Start Database:
   cd C:\PG_install\bin
   initdb.exe -D C:\PG_install\data -U administrator --auth=trust
   pg_ctl.exe -D C:\PG_install\data -l C:\PG_install\data\server.log start

Troubleshooting Notes:
- Flex EOF Errors ("end of file in string"):
  Caused by Unix line endings in `.l` files. Re-run the repository preparation Git commands above.
- Permission Errors on initdb:
  If `initdb` fails on directory permissions, grant explicit access to the admin user:
    takeown /f C:\PG_install\data /r /d y
    icacls C:\PG_install\data /grant Administrator:(OI)(CI)F /t

Note: The old "bufferoverflowU.lib missing" LNK1181 error was specific
to older Windows SDK/VC toolchains (SDK v5.0/v6.0A era) and does not
occur with current Visual Studio 2022 installs. Kept here for
historical reference only; can be removed once fully migrated.

* Mac OS X

Creating a new VM for new codepath from an existing VM on the same machine:
- Shutdown the VM
- Right click the VM and click 'show in finder' and then right click on the bundle to copy to another name
- Double Click the bundle to power it on and choose "I copied it" when Fusion asks
- Change the HostName, ComputerName using below commands:
  sudo scutil --set ComputerName "newname"
  sudo scutil --set LocalHostName "newname"
  sudo scutil --set HostName "newname"
  System Preferences->Users&Groups and Change full name to the new name
- Restart the VM
 
Build Machines as external machines
-----------------------------------
In order to set build machines as external machines, Create NFS share pointing to 
top level 'pginstaller' directory on Mac. For this purpose free tool 'NFS Manager' 
can be used. On linux side, update /etc/fstab to create nfs mount to this NFS share. 

Build scripts
-------------

* settings.sh

This script is derived from settings.sh.in which is stored in source control. It
is configured for the specific build machine, and allows us to specify what
platforms and modules we're building, and some global configuration options.

This script (_and_ the source version, settings.h.in) must be edited whenever
new platforms or packages are added.

* common.sh

This script contains common utility functions that may be used throughout the
build system.

* build.sh

This script is the main build script. To build everything, simply run the 
following command on the build host:

sh build.sh

For quick rebuilds, an option is provided to rebuild just the installers from 
the existing code in the staging directories:

sh build.sh -skipbuild

This script must be edited whenever a new module is added to call the appropriate
functions in the package build script.

Directories
-----------

* output/

This directory will contain all the completed installers.

* scripts/

This directory contains miscellaneous scripts that may be useful to multiple
modules or the overall build system.

* resources/

This directory contains installer resources that may be useful to multiple
modules or the overall build system.

* tarballs/

This directory contains all the tarballs we use for builds

* <everything else>/

Each additional directory contains a single package. These may be internally built
as required, though the interface should remain consistent - ie. a single build
script called build.sh, exposing functions called _prep_<packagename>, 
_build_< packagename > and _postprocess_< packagename >.

For a description fo the build system for a single package, see server/README.

Additional configuration in the VM's :
--------------------------------------

* Adding gd module to php in Windows
 
   * Prequisites:

     1) jpeg     (http://nchc.dl.sourceforge.net/sourceforge/gnuwin32/jpeg-6b-4.exe)
     2) libpng   (http://nchc.dl.sourceforge.net/sourceforge/gnuwin32/libpng-1.2.36-setup.exe)
     3) freetype (http://nchc.dl.sourceforge.net/sourceforge/gnuwin32/freetype-2.3.5-1-setup.exe)

     Install these in the pgBuild directory as jpeg, libpng and freetype respectively.

   * Modifications:

      Freetype:

       1) Modify the directory structure as:

          freetype --> include --> freetype2 --> freetype
          to
          freetype --> include --> freetype

          (leave the ft2build.h file in include directory as it is.)

       2) Copy the files:

          freetype/lib/freetype.lib to freetype/lib/freetype2.lib

      jpeg:

       1) Copy the files:

          jpeg/lib/jpeg.lib to jpeg/lib/libjpeg.lib


* Adding gd module to php in osx

   * Prequisites:
       1) Install jpeg libraries
       Download and extract jpeg from http://www.ijg.org/
       Compile and install: 
       >env CFLAGS="-isysroot /Developer/SDKs/MacOSX10.5.sdk -mmacosx-version-min=10.5 -arch i386 -arch ppc -arch x86_64" LDFLAGS="-arch i386 -arch ppc -arch x86_64" ./configure --prefix=/usr/local --disable-dependency-tracking
       >make
       >sudo make install
      
      2) Install libpng (User only 1.2.x version - php-5.2.1 has not yet include support for 1.4.x version)
      Download and extract libpng from http://www.libpng.org/pub/png/pngcode.html
      Compile and install:
      >env CFLAGS="-isysroot /Developer/SDKs/MacOSX10.5.sdk -mmacosx-version-min=10.5 -arch i386 -arch ppc -arch x86_64" LDFLAGS="-arch i386 -arch ppc -arch x86_64" ./configure --prefix=/usr/local --disable-dependency-tracking
      >make
      >sudo make install

      3) Install freetype
      Download and extract freetype from http://freetype.org/download.html
      >env CFLAGS="-isysroot /Developer/SDKs/MacOSX10.5.sdk -mmacosx-version-min=10.5 -arch i386 -arch ppc -arch x86_64" LDFLAGS="-arch i386 -arch ppc -arch x86_64" ./configure --prefix=/usr/local --disable-dependency-tracking
      >make
      >sudo make install

* Adding gd module to php in linux

   * Prequisites: (linux/linux-x64)

       1) yum install freetype
       2) yum install libpng
         (libjpeg.so should also be present in /usr/lib and /usr/lib64 for linux and linux-x64 respectively)

* Install the latest version of ActiveState Python, Perl & TCL/Tk on all
  the platforms.
* Install SPHINX for generating documentation for generating documentations for
  pgAdmin3.
  i.e. <PYTHONHOME>/bin/easy_install Sphinx
       For ActiveState Python 2.6, the PYTHONHOME is '/opt/ActivePython-2.6'
       For ActiveState Python 3.2, the PYTHONHOME is '/opt/ActivePython-3.2'
  NOTE: Install the SPHINX as the root user.

Trouble-Shooting:
* I got this error for ActivePython-3.2 on linux/linux-x64
    -----------------------------------------------------------------
      /opt/ActivePython-3.2/bin/python3.2
    ActivePython 3.2.2.3 (ActiveState Software Inc.) based on
    Python 3.2.2 (default, Sep  8 2011, 12:20:28) 
    [GCC 4.0.2 20051125 (Red Hat 4.0.2-8)] on linux2
    Type "help", "copyright", "credits" or "license" for more information.
    >>> import hashlib;
    ERROR:root:code for hash md5 was not found.
    Traceback (most recent call last):
      File "/opt/ActivePython-3.2/lib/python3.2/hashlib.py", line 141, in <module>
        globals()[__func_name] = __get_hash(__func_name)
      File "/opt/ActivePython-3.2/lib/python3.2/hashlib.py", line 91, in
    __get_builtin_constructor
        raise ValueError('unsupported hash type %s' % name)
    ValueError: unsupported hash type md5
    ERROR:root:code for hash sha1 was not found.
    Traceback (most recent call last):
      File "/opt/ActivePython-3.2/lib/python3.2/hashlib.py", line 141, in <module>
        globals()[__func_name] = __get_hash(__func_name)
      File "/opt/ActivePython-3.2/lib/python3.2/hashlib.py", line 91, in
    __get_builtin_constructor
        raise ValueError('unsupported hash type %s' % name)
    ValueError: unsupported hash type sha1
    ERROR:root:code for hash sha224 was not found.
    Traceback (most recent call last):
      File "/opt/ActivePython-3.2/lib/python3.2/hashlib.py", line 141, in <module>
        globals()[__func_name] = __get_hash(__func_name)
      File "/opt/ActivePython-3.2/lib/python3.2/hashlib.py", line 91, in
    __get_builtin_constructor
        raise ValueError('unsupported hash type %s' % name)
    ValueError: unsupported hash type sha224
    ERROR:root:code for hash sha256 was not found.
    Traceback (most recent call last):
      File "/opt/ActivePython-3.2/lib/python3.2/hashlib.py", line 141, in <module>
        globals()[__func_name] = __get_hash(__func_name)
      File "/opt/ActivePython-3.2/lib/python3.2/hashlib.py", line 91, in
    __get_builtin_constructor
        raise ValueError('unsupported hash type %s' % name)
    -----------------------------------------------------------------
  In order to resolve the issue, I had to run the following command as 'root'
  user.
  chcon -t texrel_shlib_t /opt/ActivePython-3.2/lib/python3.2/lib-dynload/_hashlib.cpython-32m.so

Further info
------------

Contact dpage@pgadmin.org for further info.

