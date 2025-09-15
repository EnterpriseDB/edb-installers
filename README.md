PostgreSQL Installer build systemThis document describes how the PostgreSQL Installer build system is architected, how to set it up, and how to extend it. It is a work in progress and will no doubt require further refinement over time. There is one goal, however:Build all PostgreSQL & add-on package installers for all supported platforms with a single command.Note that this system is not intended to replace the existing installer system used on Windows (pgInstaller) - it is intended to mirror its basic functionality, however.Modular System DesignThe modular system is designed to be as flexible as possible and allow package authors as much freedom as possible in the way they design their installers. There are some basic rules about how we design add-on packages, however; it remains up to the individual author to determine whether or not breaking any rules will break their package. They had better not break the system, though!RegistrationA central registry file is used in which packages should register themselves. This data will be used by StackBuilder to locate installed packages. The registry file is /etc/postgres-reg.ini, and should be considered analogous in function to the sections of the Windows registry used for the same purposes on that platform.StackBuilder requires specific entries for the PostgreSQL server, as well as an entry indicating the installed version of each unique package. An example file is shown below.; This section is for a server, and is analagous to the PostgreSQL key under
; HKEY_CURRENT_USER\Software on Windows
[PostgreSQL\8.3]
Version=8.3.3
InstallationDirectory=/opt/PostgreSQL/8.3
DataDirectory=/opt/PostgreSQL/8.3/data
Port=5432
Superuser=postgres

[PostGIS_1_3_PG83]
Version=1.3.2

[pgAdmin3]
Version=1.8.4
InstallationDirectory=/opt/pgAdmin3

It is up to the uninstaller for each package to leave or clean the data during uninstallation. The version number for a package should always be cleared, but other data may be retained. For example, the server package will not remove the data directory, thus it is appropriate to leave the DataDirectory, Port, and Superuser values intact.InstallersEach package installer should be capable of silently or interactively installing and uninstalling the package. When uninstalling, as much of the package as possible should be removed, however, it is not always possible (through lack of reference counting between packages) or desirable to remove everything.Build PlatformThe build platform is Mac OS X Sonoma. We use OS X because it allows us to run all other Intel-based OS's on the same machine.DependenciesA number of additional dependencies are required when setting up the system, such as libxml2 and libxslt, as well as useful utilities such as wget. Setting these up correctly is essential to ensuring future Universal binary builds will work as expected on all supported OS X versions (10.5/Leopard and above).Utilities should be installed using MacPorts:Download the installer from http://www.macports.org/ and install the package.Add /opt/local/bin:/opt/local/sbin to the end of the path. Add the following line to ~/.bash_profile for the buildfarm user:export PATH=$PATH:/opt/local/bin:/opt/local/sbin

Install packages:sudo port install cmake
sudo port install wget
sudo port install apache-ant
sudo port install bison
sudo port install flex
sudo port install ossp-uuid

Dependency libraries must be built with a little more control:These must be built with the correct SDK to allow them to be used on Tiger and above. We manually build and install these packages into /usr/local/.Download the source for each library (e.g., libxml2 & libxslt).Unpack the source into /usr/local/src.Configure the source with a command such as:CFLAGS="-isysroot /Developer/SDKs/MacOSX14.sdk -mmacosx-version-min=13 -arch i386 -arch x86_64 -arch ppc" LDFLAGS="-arch i386 -arch x86_64" ./configure --prefix=/usr/local/ --disable-dependency-tracking

Build and install:make all
sudo make install

Note that we must make sure all additional libraries link against these libraries, and not the older, system copies. In the case of libxslt, we can do this by configuring with --with-libxml-prefix=/usr/local.Install unix2dos utility:$sudo port install unix2dos

Set up DocBook SGMLConfiguring DocBook SGML on Mac OS X with MacPorts.Install the following packages using MacPorts:openspopenjadedocbook-xsldocbook2XDownload the docbook-dsssl stylesheets from http://sourceforge.net/project/showfiles.php?group_id=21935&package_id=16611 and then unpack the archive in /opt/local/share/sgml.Add a symlink so PostgreSQL can find the stylesheets:sudo ln -s  /opt/local/share/sgml/docbook-dsssl-1.79 \
            /usr/local/share/sgml/docbook-dsssl

Download DocBook 4.2 (http://www.docbook.org/sgml/4.2/docbook-4.2.zip) and the ISO 8879 character entities (http://www.oasis-open.org/cover/ISOEnts.zip).Unzip both archives into /opt/local/share/sgml/docbook-4.2.Ensure that all the unpacked files are world-readable.Run the following command in the docbook-4.2 directory:perl -pi -e 's/iso-(.*).gml/ISO\1/g' docbook.cat

Create the file /opt/local/share/sgml/catalog, with the following contents:CATALOG "openjade/catalog"    
CATALOG "docbook-4.2/docbook.cat"
CATALOG "docbook-dsssl-1.79/catalog"

Make sure that settings.sh is updated with the docbook installation path.Build VMsAll VMs (and in fact, the host machine) are set up to use user accounts called 'buildfarm'. In order to access each, the VMs must be set up with fixed IP addresses which are recorded with an appropriate hostname in DNS. Each hostname is specified in settings.sh. It may be necessary to manually configure VMWare Fusion to bridge the network adaptor instead of using NAT.The top-level pginstaller directory is shared with all the VMs using the VMware shared folders feature. The path to this directory is specified in settings.h for each VM. Note that VMware doesn't map UIDs/GIDs between the host and the VMs so it may be necessary to mount the shared directory using the UID/GID of the user in the VM, e.g., using the following in /etc/fstab:.host:/  /mnt/hgfs  vmhgfs  defaults,ttl=5,uid=500,gid=500     0 0

SSH authentication between hosts is achieved using certificates. These can be generated on the host machine using:ssh-keygen -t rsa

Copy the resulting id_rsa.pub file to ~/.ssh/authorized_keys on each VM.WindowsThe Windows VM is the most tricky to set up:Install Windows 7Install Microsoft Security EssentialsInstall Visual Studio 2008, and update to the latest service packCreate the 'buildfarm' user account, as a limited user.Install a basic installation of Cygwin from http://www.cygwin.com/. Include the OpenSSH package.Configure sshd with ssh-host-config, using the buildfarm user account as the service account. Make sure that the openssh log file has correct ownership and permissions. It is absolutely necessary NOT to use the default local account with sshd because compilation will fail when invoked via ssh.Make sure that port 22/TCP is open in the Windows Firewall configuration.Install the public ssh key in C:\Cygwin\home\buildfarm\.sshInstall zip.exe and unzip.exe into the System32 directory. These utilities can be found at ftp://ftp.tex.ac.uk/tex-archive/tools/zip/info-zip/WIN32/Create folder c:\pgBuildDepending on the modules to build, install various utilities in c:\pgBuildInstall bison, flex, diffutils in c:\pgBuild (Available from http://gnuwin32.sourceforge.net)Prebuilt iconv, libxml2, libxslt, openssl and zlib from http://zlatkovic.com/pub/libxml, install them in c:\pgBuildgettext (Please consult a developer for the specific version for PostgreSQL)Mingw (gcc and g++).MSys 1.0Compile and install ZLib in Msys using --prefix=/mingwkrb5 in c:\pgBuildvcredist in c:\pgBuildapache ANT in c:\pgBuildwxWidgets in c:\pgBuildNote: In the case of a Windows-64 setup you may get errors related to:LINK : fatal error LNK1181: cannot open input file 'bufferoverflowU.lib'^MThe main reason for this issue is the bufferoverflowU.lib file missing in parallel directory structures of the VC installation. To resolve this, copy said file into the parallel structure, e.g.:cp /cygdrive/c/Program\ Files\ \(x86\)/Microsoft\ SDKs/Windows/v5.0/Lib/IA64/bufferoverflowu.lib  /cygdrive/c/Program\ Files/Microsoft\ SDKs/Windows/v6.0A/Lib/x64/.

Mac OS XCreating a new VM for a new codepath from an existing VM on the same machine:Shut down the VM.Right-click the VM and click show in finder, then right-click on the bundle to copy to another name.Double-click the bundle to power it on and choose "I copied it" when Fusion asks.Change the HostName, ComputerName using the below commands:sudo scutil --set ComputerName "newname"
sudo scutil --set LocalHostName "newname"
sudo scutil --set HostName "newname"

In System Preferences -> Users & Groups, change the full name to the new name.Restart the VM.Build Machines as External MachinesIn order to set up build machines as external machines, create an NFS share pointing to the top-level 'pginstaller' directory on Mac. For this purpose, the free tool 'NFS Manager' can be used. On the Linux side, update /etc/fstab to create an nfs mount to this NFS share.Build Scriptssettings.shThis script is derived from settings.sh.in which is stored in source control. It is configured for the specific build machine and allows us to specify what platforms and modules we're building, and some global configuration options. This script (and the source version, settings.h.in) must be edited whenever new platforms or packages are added.common.shThis script contains common utility functions that may be used throughout the build system.build.shThis script is the main build script. To build everything, simply run the following command on the build host:sh build.sh

For quick rebuilds, an option is provided to rebuild just the installers from the existing code in the staging directories:sh build.sh -skipbuild

This script must be edited whenever a new module is added to call the appropriate functions in the package build script.Directoriesoutput/This directory will contain all the completed installers.scripts/This directory contains miscellaneous scripts that may be useful to multiple modules or the overall build system.resources/This directory contains installer resources that may be useful to multiple modules or the overall build system.tarballs/This directory contains all the tarballs we use for builds.<everything else>/Each additional directory contains a single package. These may be internally built as required, though the interface should remain consistent - i.e., a single build script called build.sh, exposing functions called _prep_<packagename>, _build_<packagename>, and _postprocess_<packagename>.For a description of the build system for a single package, see server/README.Additional configuration in the VM'sAdding gd module to php in WindowsPrerequisites:jpeg (http://nchc.dl.sourceforge.net/sourceforge/gnuwin32/jpeg-6b-4.exe)libpng (http://nchc.dl.sourceforge.net/sourceforge/gnuwin32/libpng-1.2.36-setup.exe)freetype (http://nchc.dl.sourceforge.net/sourceforge/gnuwin32/freetype-2.3.5-1-setup.exe)Install these in the pgBuild directory as jpeg, libpng, and freetype respectively.Modifications:Freetype:Modify the directory structure as: freetype --> include --> freetype2 --> freetype to freetype --> include --> freetype (leave the ft2build.h file in the include directory as it is.)Copy the files: freetype/lib/freetype.lib to freetype/lib/freetype2.libjpeg:Copy the files: jpeg/lib/jpeg.lib to jpeg/lib/libjpeg.libAdding gd module to php in osxPrerequisites:Install jpeg librariesDownload and extract jpeg from http://www.ijg.org/Compile and install:env CFLAGS="-isysroot /Developer/SDKs/MacOSX10.5.sdk -mmacosx-version-min=10.5 -arch i386 -arch ppc -arch x86_64" LDFLAGS="-arch i386 -arch ppc -arch x86_64" ./configure --prefix=/usr/local --disable-dependency-tracking
make
sudo make install

Install libpng (User only 1.2.x version - php-5.2.1 has not yet included support for 1.4.x version)Download and extract libpng from http://www.libpng.org/pub/png/pngcode.htmlCompile and install:env CFLAGS="-isysroot /Developer/SDKs/MacOSX10.5.sdk -mmacosx-version-min=10.5 -arch i386 -arch ppc -arch x86_64" LDFLAGS="-arch i386 -arch ppc -arch x86_64" ./configure --prefix=/usr/local --disable-dependency-tracking
make
sudo make install

Install freetypeDownload and extract freetype from http://freetype.org/download.htmlenv CFLAGS="-isysroot /Developer/SDKs/MacOSX10.5.sdk -mmacosx-version-min=10.5 -arch i386 -arch ppc -arch x86_64" LDFLAGS="-arch i386 -arch ppc -arch x86_64" ./configure --prefix=/usr/local --disable-dependency-tracking
make
sudo make install

Install the latest version of ActiveState Python, Perl & TCL/Tk on all the platforms.Trouble-ShootingFurther infoContact dpage@pgadmin.org for further info.
