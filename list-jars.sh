#!/bin/bash

find * -type f | grep "\.jar$" | cut -f1 -d"." |sed "s:^.*/::g" | sort -u

