#! /bin/sh
set -xeu
NAME=postgresql
: ${SOURCE_VERSION:?The SOURCE_VERSION environment variable is required}
WORKDIR=$(pwd)
TARNAME="${NAME}-${SOURCE_VERSION}"
cd ${WORKDIR}
tar -cjf "${TARNAME}.tar.bz2" src/         # ✅ pack git checkout directly
md5sum "${TARNAME}.tar.bz2" > "${TARNAME}.tar.bz2.md5"
                                            # ✅ no mv needed, already in workspace root
