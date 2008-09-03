#!/bin/sh

# PostgreSQL stackbuilder runner script for Linux
# Dave Page, EnterpriseDB

LD_LIBRARY_PATH="PG_INSTALLDIR/pgAdmin3/lib":$LD_LIBRARY_PATH G_SLICE=always-malloc "PG_INSTALLDIR/stackbuilder/bin/stackbuilder"


