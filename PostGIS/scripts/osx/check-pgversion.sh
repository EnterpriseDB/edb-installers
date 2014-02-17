#!/bin/bash
# Copyright (c) 2012-2014, EnterpriseDB Corporation.  All rights reserved

ver=`$1/bin/pg_config --version | cut -f2 -d " " | cut -f1,2 -d "."`
echo $ver | sed -e 's:\([0-9].[0-9]\).*:\1:g'
