#!/bin/bash

find * -type f | xargs -I{} file "{}" | grep DLL | cut -f1 -d":" | sed "s:^.*/::g" | sort -u

