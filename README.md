The PostgreSQL Installer Framework
=================================

Welcome to the PostgreSQL Installer Build System! This repository is designed
to build PostgreSQL and its add-on installers for all supported platforms with
a single, unified command.\
\
Our primary objective is to create a streamlined, one-command solution for building
all PostgreSQL and add-on package installers across various platforms.\
\
This document describes the system's architecture, setup, and extensibility. It is a
work in progress and will undergo continuous refinement. This system is not intended 
to replace the existing Windows installer (pgInstaller), but rather to replicate its
core functionality in a more unified build environment.\
\

Modular system design\
------------------------\
\
The modular system gives package authors a high degree of flexibility and freedom when 
designing their installers. While there are some basic guidelines for creating add-on
packages, authors ultimately decide whether their design choices break these rules. The
one firm rule is this: do not break the build system itself.\
\
* Registration:\
\
A central registry file, /etc/postgres-reg.ini, is used for packages to register themselves.
This data allows StackBuilder to locate installed packages. This file is functionally
analogous to a central registry used by the operating system to track installed applications
and their settings.\
\
StackBuilder requires a specific entry for the PostgreSQL server and an entry indicating the
installed version of each unique package.\
\
An example of this file is shown below.\
\
[PostgreSQL/18]\
InstallationDirectory=/Library/PostgreSQL/18\
Version=18.0-rc1\
Shortcuts=1\
DataDirectory=/Library/PostgreSQL/18/data\
Port=5432\
ServiceID=postgresql-18\
Locale=C\
Superuser=postgres\
Serviceaccount=postgres\
Description=PostgreSQL 18\
Branding=PostgreSQL 18\
SB_Version=4.2.2\
pgAdmin_Version=9.8\
CLT_Version=18.0.rc1\
DisableStackBuilder=\
[edb_languagepack_v6]\
Description=Language Pack for EDB Postgres Advanced Server, by EnterpriseDB.\
InstallationDirectory=/Library/edb/languagepack/v6\
Version=6.0rc1-1\
\

Uninstaller for each package can either leave or clean up data during uninstallation.
While a package's version number should **always** be cleared, other data may be retained.
For instance, the server package won't remove the data directory, so it's appropriate
to leave the `DataDirectory`,`Port`, and `Superuser` values intact.

* Installers:\
\
Each package installer must support both silent and interactive modes for installation
and uninstallation.\
When uninstalling, the goal is to remove as much of the package as possible. However,
due to shared dependencies or the need to preserve user data, it may not be possible
or desirable to remove all files.\
\
Build platform\
----------------\
\
The build platform is Mac OS X Sonoma. The macOS Sonoma platform is used for building
because it can efficiently run all other Intel-based operating systems on the same
machine. This provides a single, centralized environment for developing and testing
software across a range of operating systems.\
\
To ensure successful Universal binary builds on all supported macOS versions(10.13 and
above), a number of additional dependencies are required. These include libraries such
as libxml2 and libxslt, as well as common utilities like wget. Proper installation of these
dependencies is essential for the build system to function correctly.\
\
Utilities should be installed using MacPorts:

- Download the installer from http://www.macports.org/ and install the package.

- Add /opt/local/bin:/opt/local/sbin to the **end** of the path. Add the following
  line to ~/.bash_profile for the buildfarm user:

export PATH=$PATH:/opt/local/bin:/opt/local/sbin

- Install packages:\
\
$ sudo port install cmake\
$ sudo port install wget\
$ sudo port install apache-ant\
$ sudo port install bison\
$ sudo port install flex\
$ sudo port install ossp-uuid\
\
Dependency libraries must be built with a little more control to ensure they 
use the correct SDK to allow them to be used on Tiger and above. We manually
build and install these packages into /usr/local/

- Download the source for each library (eg. libxml2 & libxslt).

- Unpack the source into /usr/local/src

- Configure the source with a command such as:

CFLAGS="-isysroot /Developer/SDKs/MacOSX14.sdk -mmacosx-version-min=13 -arch i386 -arch x86_64 -arch ppc" LDFLAGS="-arch i386 -arch x86_64" ./configure --prefix=/usr/local/ --disable-dependency-tracking

- Build and install:\
\
make all\
sudo make install\
\
Note that we must make sure all additional libraries link against these
libraries, and not the older, system copies. In the case of libxslt, we can
do this by configuring with --with-libxml-prefix=/usr/local

- Install unix2dos utility:
$sudo port install unix2dos

- Set up DocBook SGML

Configuring DocBook SGML on Mac OS X with MacPorts.
 1) Install the following packages using MacPorts:\
    opensp\
    openjade\
    docbook-xsl\
    docbook2X
    
 3) Download the docbook-dsssl stylesheets from 
http://sourceforge.net/project/showfiles.php?group_id=21935&package_id=16611 
and then unpack the archive in /opt/local/share/sgml

 4) Add a symlink so PostgreSQL can find the stylesheets:

     sudo ln -s  /opt/local/share/sgml/docbook-dsssl-1.79 
                 /usr/local/share/sgml/docbook-dsssl

 5) Download DockBook 4.2 (http://www.docbook.org/sgml/4.2/docbook-4.2.zip) 
   and the ISO 8879 character entities (http://www.oasis-open.org/cover/ISOEnts.zip)

 6) Unzip both archives into /opt/local/share/sgml/docbook-4.2

 7) Ensure that all the unpacked files are world readable.

 8) Run the following command in the docbook-4.2 directory:

    perl -pi -e 's/iso-(.*).gml/ISO\\1/g' docbook.cat

 9) Create the file /opt/local/share/sgml/catalog, with the following contents:\
    CATALOG "openjade/catalog"    \
    CATALOG "docbook-4.2/docbook.cat"\
    CATALOG "docbook-dsssl-1.79/catalog"

 10) Make sure that settings.sh is updated with docbook installation path.

Build VMs\
---------\
\
All VMs (and in fact, the host machine) are setup to use user accounts called
'buildfarm'. In order to access each, the VMs must be setup with fixed IP
addresses which are recorded with an appropriate hostname in DNS. Each hostname 
is specified in settings.sh. It may be necessary to manually configure VMWare 
Fusion to bridge the network adaptor instead of using NAT.\
\
The top level 'pginstaller' directory is shared with all the VMs using the VMware
shared folders feature. The path to this directory is specified in settings.h
for each VM. Note that VMware doesn't map UIDs/GIDs between the host and the VMs
so it may be necessary to mount the shared directory using the UID/GID of the
user in the VM, eg using the following in /etc/fstab:\
\
.host:/  /mnt/hgfs  vmhgfs  defaults,ttl=5,uid=500,gid=500     0 0\
\
SSH authentication between hosts is achieved using certificates. These can be
generated on the host machine using:
\
ssh-keygen -t rsa\
\
Copy the resulting id_rsa.pub file to ~/.ssh/authorized_keys on each VM.
* Windows\
The Windows VM is the most tricky to setup:
- Install Windows 7
- Install Microsoft Sercurity Essentials
- Install Visual Studio 2008, and update to the latest service pack
- Create the 'buildfarm' user account, as a limited user.
- Install the a basic installation of Cygwin from http://www.cygwin.com/. 
  Include the OpenSSH package.
- Configure sshd with ssh-host-config, using the buildfarm user account as
  the service account. Make sure that openssh log file has correct ownership
  and permissions. It is absolotely necessary NOT to use default local account
  with sshd because compilation will fail when invoked via ssh.
- Make sure that port 22/TCP is open in the Windows Firewall configuration.
- Install the public ssh key in C:\\Cygwin\\home\\buildfarm\\.ssh
- Install zip.exe and unzip.exe into the System32 directory. These utilities
  can be found at ftp://ftp.tex.ac.uk/tex-archive/tools/zip/info-zip/WIN32/
- Create folder 'c:\\pgBuild'
- Depending upon the modules to build, install various utilities in c:\\pgBuild
- Install bison, flex, diffutils in c:\\pgBuild (Available from http://gnuwin32.sourceforge.net)
- Prebuilt iconv, libxml2, libxslt, openssl and zlib from http://zlatkovic.com/pub/libxml,
  install them in c:\\pgBuild
- gettext (Please consult developer for specific version for PostgreSQL)
- Mingw (gcc and g++). 
- MSys 1.0 
- Compile and install ZLib in Msys using --prefix=/mingw
- krb5 in c:\\pgBuild
- vcredist in c:\\pgBuild
- apache ANT in c:\\pgBuild
- wxWidgets in c:\\pgBuild
\
Note: In case of Windows-64 setup you may get errors related to: 
LINK : fatal error LNK1181: cannot open input file 'bufferoverflowU.lib'^M
Main reason of this issue is bufferoverflowU.lib file missing in parallel directory structures of VC installation. To reslove this copy said file into parallel structure e.g.:
cp /cygdrive/c/Program\\ Files\\ \\(x86\\)/Microsoft\\ SDKs/Windows/v5.0/Lib/IA64/bufferoverflowu.lib  /cygdrive/c/Program\\ Files/Microsoft\\ SDKs/Windows/v6.0A/Lib/x64/.

* Mac OS X\
\
Creating a new VM for new codepath from an existing VM on the same machine:
- Shutdown the VM
- Right click the VM and click 'show in finder' and then right click on the bundle to copy to another name
- Double Click the bundle to power it on and choose "I copied it" when Fusion asks
- Change the HostName, ComputerName using below commands:\
  sudo scutil --set ComputerName "newname"\
  sudo scutil --set LocalHostName "newname"\
  sudo scutil --set HostName "newname"
  System Preferences->Users&Groups and Change full name to the new name
- Restart the VM
  
Build Machines as external machines
-------------------------------------\
In order to set build machines as external machines, Create NFS share pointing to 
top level 'pginstaller' directory on Mac. For this purpose free tool 'NFS Manager' 
can be used. On linux side, update /etc/fstab to create nfs mount to this NFS share.

Build scripts
-------------

* settings.sh

This script is derived from settings.sh.in which is stored in source control. It
is configured for the specific build machine, and allows us to specify what
platforms and modules we're building, and some global configuration options.

This script (_and_ the source version, settings.h.in) must be edited whenever\
new platforms or packages are added.\

* common.sh

This script contains common utility functions that may be used throughout the
build system.\

* build.sh

This script is the main build script. To build everything, simply run the
following command on the build host:\
\
sh build.sh
\
For quick rebuilds, an option is provided to rebuild just the installers from
the existing code in the staging directories:\
\
sh build.sh -skipbuild
\
This script must be edited whenever a new module is added to call the appropriate
functions in the package build script.\
\
Directories\
------------\

* output/\
\
This directory will contain all the completed installers.

* scripts/

This directory contains miscellaneous scripts that may be useful to multiple
modules or the overall build system.

* resources/

This directory contains installer resources that may be useful to multiple
modules or the overall build system.

* tarballs/

This directory contains all the tarballs we use for builds

* <everything else>/\

Each additional directory contains a single package. These may be internally built
as required, though the interface should remain consistent - ie. a single build
script called build.sh, exposing functions called _prep_<packagename>, 
_build_< packagename > and _postprocess_< packagename >.
\
For a description fo the build system for a single package, see server/README.\
\
Additional configuration in the VM's :\
--------------------------------------\

* Adding gd module to php in Windows

   * Prequisites:

     1) jpeg     (http://nchc.dl.sourceforge.net/sourceforge/gnuwin32/jpeg-6b-4.exe)
     2) libpng   (http://nchc.dl.sourceforge.net/sourceforge/gnuwin32/libpng-1.2.36-setup.exe)
     3) freetype (http://nchc.dl.sourceforge.net/sourceforge/gnuwin32/freetype-2.3.5-1-setup.exe)
\
     Install these in the pgBuild directory as jpeg, libpng and freetype respectively.

   * Modifications:

      Freetype:

       1) Modify the directory structure as:\
\
          freetype --> include --> freetype2 --> freetype\
          to\
          freetype --> include --> freetype\
\
          (leave the ft2build.h file in include directory as it is.)

       2) Copy the files:\
\
          freetype/lib/freetype.lib to freetype/lib/freetype2.lib
\
      jpeg:\

       1) Copy the files:\
\
          jpeg/lib/jpeg.lib to jpeg/lib/libjpeg.lib


* Adding gd module to php in osx\

   * Prequisites:
       1) Install jpeg libraries\
       Download and extract jpeg from http://www.ijg.org/\
       Compile and install: 
       >env CFLAGS="-isysroot /Developer/SDKs/MacOSX10.5.sdk -mmacosx-version-min=10.5 -arch i386 -arch ppc -arch x86_64" LDFLAGS="-arch i386 -arch ppc -arch x86_64" ./configure --prefix=/usr/local --disable-dependency-tracking\
       >make\
       >sudo make install
      
      2) Install libpng (User only 1.2.x version - php-5.2.1 has not yet include support for 1.4.x version)\
      Download and extract libpng from http://www.libpng.org/pub/png/pngcode.html\
      Compile and install:
      >env CFLAGS="-isysroot /Developer/SDKs/MacOSX10.5.sdk -mmacosx-version-min=10.5 -arch i386 -arch ppc -arch x86_64" LDFLAGS="-arch i386 -arch ppc -arch x86_64" ./configure --prefix=/usr/local --disable-dependency-tracking\
      >make\
      >sudo make install

      3) Install freetype\
      Download and extract freetype from http://freetype.org/download.html
      >env CFLAGS="-isysroot /Developer/SDKs/MacOSX10.5.sdk -mmacosx-version-min=10.5 -arch i386 -arch ppc -arch x86_64" LDFLAGS="-arch i386 -arch ppc -arch x86_64" ./configure --prefix=/usr/local --disable-dependency-tracking\
      >make\
      >sudo make install

* Install the latest version of ActiveState Python, Perl & TCL/Tk on all\
  the platforms.\
\
Trouble-Shooting:\
\
\
Further info\
------------\
\
Contact dpage@pgadmin.org for further info.

