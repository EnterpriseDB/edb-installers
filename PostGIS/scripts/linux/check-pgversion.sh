#!/bin/bash

export LD_LIBRARY_PATH=$1/lib:$LD_LIBRARY_PATH
ver=`$1/bin/pg_config --version | cut -f2 -d " " | cut -f1,2 -d "."`
echo $ver | sed -e 's:\([0-9].[0-9]\).*:\1:g'
