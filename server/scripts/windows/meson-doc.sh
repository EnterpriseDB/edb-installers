#!/bin/sh

echo "==== Installing libxml2 and libxslt using pacman ===="
pacman -S libxml2 libxslt

echo "==== Installing docbook-xml and docbook-xsl using pacman ===="
pacman -S docbook-xml docbook-xsl

echo "==== Rename the link.exe ===="
mv /c/msys64/usr/bin/link.exe /c/msys64/usr/bin/link.exe_bk

export PATH=/C/hostedtoolcache/windows/Python/3.12.3/x64:/C/hostedtoolcache/windows/Python/3.12.3/x64/Scripts:$PATH

mkdir /D/a/postgresql-packaging-foundation/postgresql-packaging-foundation/postgresql-17beta2/meson-build-doc

meson setup /D/a/postgresql-packaging-foundation/postgresql-packaging-foundation/postgresql-17beta2 /D/a/postgresql-packaging-foundation/postgresql-packaging-foundation/postgresql-17beta2/meson-build-doc --prefix=/D/a/postgresql-packaging-foundation/postgresql-packaging-foundation/postgresql-17beta2/meson-build/meson-install

cd /D/a/postgresql-packaging-foundation/postgresql-packaging-foundation/postgresql-17beta2/meson-build-doc
ninja docs
ls -l /D/a/postgresql-packaging-foundation/postgresql-packaging-foundation/postgresql-17beta2/meson-build-doc/doc/src/sgml/html/a*.html

