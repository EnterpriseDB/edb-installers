#!/bin/bash

find * -type f | xargs -I{} echo "file \"{}\" | grep -i ELF" | sh | cut -f1 -d":" | sed "s:^.*/::g" | cut -f1 -d"." | sort -u

