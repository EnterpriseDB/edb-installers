#! /bin/sh
set -xeu
NAME=postgresql
: ${SOURCE_VERSION:?The SOURCE_VERSION environment variable is required}
WORKDIR=$(pwd)                      
TARNAME="${NAME}-${SOURCE_VERSION}"
cd ${WORKDIR}
cp -r src/ "${TARNAME}"      
tar -cjf "${TARNAME}.tar.bz2" "${TARNAME}/" 
md5sum "${TARNAME}.tar.bz2" > "${TARNAME}.tar.bz2.md5"
rm -rf "${TARNAME}"
