#!/bin/bash
spath=$1
a=$2
b=$3
c=$4
d=$5
e=$6
f=$7
g=$8
h=$9
shift 9
i=$1
j=$2
k=$3
l=$4
m=$5

LD_LIBRARY_PATH="$spath/lib" "$spath/validateUserClient.o" "$a" "$b" "$c" "$d" "$e" "$f" "$g" "$h" "$i" "$j" "$k" "$l" "$m"

exit $?
