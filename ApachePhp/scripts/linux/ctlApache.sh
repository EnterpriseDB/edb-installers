#!/bin/bash

if [ -z "$1" ]
then
        printf "No option supplied\n"
        exit 1
fi

case $1 in
        start) action=start
                ;;
        stop)  action=stop
                ;;
        restart) action=restart
                ;;
        reload) action=reload
                ;;
        *)      printf "Invalid option!\n"
                exit 1
                ;;
esac

for f in xterm konsole gnome-terminal
do
        fpath=`which $f`
        if [ x"$fpath" = x"" ]
        then
                continue
        elif [ x"$fpath" = x"konsole" ]
        then
                $fpath -e "@@INSTALL_DIR@@/scripts/runApache.sh" $action
                exit 0
        else
                $fpath -e "@@INSTALL_DIR@@/scripts/runApache.sh $action"
                exit 0
        fi
done

