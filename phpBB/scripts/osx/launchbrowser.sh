#!/bin/bash

PORT=`grep APACHE_PORT /etc/postgres-reg.ini | cut -f 2 -d "="`

URL=http://localhost:$PORT/phpBB

open -a Safari $URL
