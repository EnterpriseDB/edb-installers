#! /bin/sh
set -xeu
NAME=postgresql
: ${SOURCE_VERSION:?The SOURCE_VERSION environment variable is required}
WORKDIR=$(pwd)
TARNAME="${NAME}-${SOURCE_VERSION}"
cd ${WORKDIR}

# Rename src/ to postgresql-18.4/ so compile.ps1 finds the right directory
cp -r src/ "${TARNAME}"                         # ✅ copy src to postgresql-18.4/
tar -cjf "${TARNAME}.tar.bz2" "${TARNAME}/"    # ✅ pack as postgresql-18.4/
md5sum "${TARNAME}.tar.bz2" > "${TARNAME}.tar.bz2.md5"
rm -rf "${TARNAME}"                             # cleanup temp dir
