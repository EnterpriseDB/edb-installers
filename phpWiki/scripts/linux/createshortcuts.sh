#!/bin/sh

# Check the command line
if [ $# -ne 2 ]; 
then
    echo "Usage: $0 <Install dir> <Branding>"
    exit 127
fi

INSTALLDIR=$1
BRANDING=$2

# Branding string, for the xdg filenames. If the branding is 'PostgreSQL',
# Don't do anything to ensure we remain backwards compatible.
if [ "x$BRANDING" = "xPostgreSQL" ];
then
    BRANDING_STR="postgresql"
    BRANDED=0
else
    BRANDING_STR=`echo $BRANDING | sed 's/\./_/g' | sed 's/ /_/g'`
	BRANDED=1
fi

# Exit code
WARN=0

# Working directory
WD=`pwd`

# Error handlers
_die() {
    echo $1
    exit 1
}

_warn() {
    echo $1
    WARN=2
}

# Search & replace in a file - _replace($find, $replace, $file) 
_replace() {
    sed -e "s^$1^$2^g" $3 > "/tmp/$$.tmp" || _die "Failed for search and replace '$1' with '$2' in $3"
    mv /tmp/$$.tmp $3 || _die "Failed to move /tmp/$$.tmp to $3"
}

# Substitute values into a file ($in)
_fixup_file() {
    _replace INSTALL_DIR "$INSTALLDIR" $1
    _replace PG_BRANDING "$BRANDING" $1  
}

# Create the icon resources
"$INSTALLDIR/phpWiki/installer/xdg/xdg-icon-resource" install --size 32 "$INSTALLDIR/phpWiki/scripts/images/pg-postgresql.png"
"$INSTALLDIR/phpWiki/installer/xdg/xdg-icon-resource" install --size 32 "$INSTALLDIR/phpWiki/scripts/images/pg-launchPhpWiki.png"

# Fixup the scripts
_fixup_file "$INSTALLDIR/phpWiki/scripts/launchbrowser.sh"
_fixup_file "$INSTALLDIR/phpWiki/scripts/launchPhpWiki.sh"

chmod ugo+x "$INSTALLDIR/phpWiki/scripts/"*.sh
chmod ugo+x "$INSTALLDIR/phpWiki/installer/phpWiki/"*.sh

# Fixup the XDG files (don't just loop in case we have old entries we no longer want)
_fixup_file "$INSTALLDIR/phpWiki/scripts/xdg/pg-postgresql.directory"
_fixup_file "$INSTALLDIR/phpWiki/scripts/xdg/pg-launchPhpWiki.desktop"

# Copy the primary desktop file to the branded version. We don't do this if
# the installation is not branded, to retain backwards compatibility.
if [ $BRANDED -ne 0 ];
then
    cp "$INSTALLDIR/scripts/xdg/pg-postgresql.directory" "$INSTALLDIR/scripts/xdg/pg-$BRANDING_STR.directory"
fi

# Create the menu shortcuts - first the top level, then the documentation menu.
"$INSTALLDIR/phpWiki/installer/xdg/xdg-desktop-menu" install --mode system \
      "$INSTALLDIR/phpWiki/scripts/xdg/pg-$BRANDING_STR.directory"  \
      "$INSTALLDIR/phpWiki/scripts/xdg/pg-launchPhpWiki.desktop"  || _warn "Failed to create the phpWiki menu"

echo "$0 ran to completion"
exit 0
