#!/bin/bash

PORT=`grep APACHE_PORT /etc/postgres-reg.ini | cut -f 2 -d "="`
URL=http://localhost:$PORT/Drupal7
echo $URL
