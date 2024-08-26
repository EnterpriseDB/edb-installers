#!/bin/sh

echo "==== Installing libxml2 and libxslt using pacman ===="
pacman -S libxml2 libxslt

echo "==== Installing docbook-xml and docbook-xsl using pacman ===="
pacman -S docbook-xml docbook-xsl

export PATH=/C/hostedtoolcache/windows/Python/$PYTHON_VERSION/x64:/C/hostedtoolcache/windows/Python/$PYTHON_VERSION/x64/Scripts:$PATH

export BASE_PATH=/D/a/postgresql-packaging-foundation/postgresql-packaging-foundation

mkdir $BASE_PATH/$SOURCE_DIR/meson-build-doc

meson setup $BASE_PATH/$SOURCE_DIR $BASE_PATH/$SOURCE_DIR/meson-build-doc --prefix=$BASE_PATH/$SOURCE_DIR/meson-build/meson-install

cd $BASE_PATH/$SOURCE_DIR/meson-build-doc
ninja docs
mv $BASE_PATH/$SOURCE_DIR/meson-build-doc/doc $BASE_PATH/$SOURCE_DIR/meson-install/
ls -l $BASE_PATH/$SOURCE_DIR/meson-install/doc/src/sgml/html/a*.html
