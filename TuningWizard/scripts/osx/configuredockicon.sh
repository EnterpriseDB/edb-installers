#!/bin/sh

# Search & replace in a file - _replace($find, $replace, $file)
_replace() {
    sed -e "s^$1^$2^g" "$3" > "/tmp/$$.tmp" || _die "Failed for search and replace '$1' with '$2' in $3"
    mv /tmp/$$.tmp "$3" || _die "Failed to move /tmp/$$.tmp to $3"
}

cd /Applications/PostgreSQL/Tuning\ Wizard.app/Contents

_replace \<\/dict\> "<key>LSUIElement</key><string>1</string></dict>" "Info.plist"

cd $WD

