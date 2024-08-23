#!/bin/sh

echo "==== Installing libxml2 and libxslt using pacman ===="
pacman -S libxml2 libxslt

echo "==== Installing docbook-xml and docbook-xsl using pacman ===="
pacman -S docbook-xml docbook-xsl

ECHO pg source = $SOURCE_DIR
ECHO python version = $PYTHON_VERSION

export PATH=/C/hostedtoolcache/windows/Python/$PYTHON_VERSION/x64:/C/hostedtoolcache/windows/Python/$PYTHON_VERSION/x64/Scripts:$PATH

mkdir /D/a/postgresql-packaging-foundation/postgresql-packaging-foundation/$SOURCE_DIR/meson-build-doc

meson setup /D/a/postgresql-packaging-foundation/postgresql-packaging-foundation/$SOURCE_DIR /D/a/postgresql-packaging-foundation/postgresql-packaging-foundation/$SOURCE_DIR/meson-build-doc --prefix=/D/a/postgresql-packaging-foundation/postgresql-packaging-foundation/$SOURCE_DIR/meson-build/meson-install

cd /D/a/postgresql-packaging-foundation/postgresql-packaging-foundation/$SOURCE_DIR/meson-build-doc
ninja docs
mv /D/a/postgresql-packaging-foundation/postgresql-packaging-foundation/$SOURCE_DIR/meson-build-doc/doc /D/a/postgresql-packaging-foundation/postgresql-packaging-foundation/$SOURCE_DIR/meson-install/
ls -l /D/a/postgresql-packaging-foundation/postgresql-packaging-foundation/$SOURCE_DIR/meson-install/doc/src/sgml/html/a*.html
