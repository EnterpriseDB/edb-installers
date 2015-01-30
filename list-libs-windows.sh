#!/bin/bash

find * -type f | xargs file | grep DLL | cut -f1 -d":" | sed "s:^.*/::g" | sort -u

