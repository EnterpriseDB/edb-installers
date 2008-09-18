#!/bin/sh

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
        *)      printf "Invalid option!\n"
                exit 1
                ;;
esac


user=`whoami`
if [ ! "$user" = root ]
then
        printf "Please enter the root password\n"
fi

# Run selected operation
su -m -c "@@INSTALL_DIR@@/apache/bin/apachectl $action"

printf "\n\n"

n=5
while [ "$n" -gt 0 ]
do
    echo -e -n "\rClosing in $n"
    sleep 1
    n=`expr $n - 1 `
done

