#!/bin/sh
# Copyright (c) 2012, EnterpriseDB Corporation.  All rights reserved

LD_LIBRARY_PATH=PG_INSTALLDIR/pgAdmin3/lib:$LD_LIBRARY_PATH G_SLICE=always-malloc PG_INSTALLDIR/pgAdmin3/bin/pgadmin3


