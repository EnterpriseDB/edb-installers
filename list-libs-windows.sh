#!/bin/bash

find * -type f | xargs -I{} file "{}" | grep -i "\(\.dll:\|\.exe:\|\.ini:\)" | cut -f1 -d":" | sed "s:^.*/::g" | sort -u

