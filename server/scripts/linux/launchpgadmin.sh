#!/bin/sh

LD_LIBRARY_PATH=PG_INSTALLDIR/pgAdmin3/lib:PG_INSTALLDIR/lib:$LD_LIBRARY_PATH G_SLICE=always-malloc PG_INSTALLDIR/pgAdmin3/bin/pgadmin3


