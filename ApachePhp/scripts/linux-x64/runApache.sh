#!/bin/sh

if [ -z "$1" ]
then
        printf "No option supplied\n"
        exit 1
fi

# action function to perform Apache start, stop, restart
_action() {

     echo "Trying to $1 Apache ....."
     response=`su -m -c "/opt/PostgreSQL/EnterpriseDB-ApachePhp/apache/bin/apachectl $1"`
     if [ "x$response" == "x" ]; then
         if [ $1 == "stop" ]; then
             echo "Apache stopped Sucessfully"
         else
             echo "Apache started Successfully"
         fi
     else
               echo ERROR: $response
     fi
}


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

# Try to figure out if this is a 'sudo' platform such as Ubuntu
USE_SUDO=0
if [ -f /etc/lsb-release ];
then
    if [ `grep -E '^DISTRIB_ID=[a-zA-Z]?buntu$' /etc/lsb-release | wc -l` != "0" ];
    then
        USE_SUDO=1
    fi
fi

if [ $USE_SUDO != "1" ];
then
    if [ `whoami` != "root" ];
    then
        echo "Please enter the root password if requested."
    fi
else
    echo "Please enter your password if requested."
fi

# Run selected operation
if [ $USE_SUDO != "1" ];
then
        if [ $action == "restart" ]; then
                _action "stop"
         echo "" 
                _action "start"
        else
                _action "$action"
        fi
    
else
    if [ $action == "restart" ]; then
                _action "stop" 
                 echo ""
                _action "start"
        else
                _action "$action"
        fi

fi

printf "\n\n"

n=5
while [ "$n" -gt 0 ]
do
    echo -e -n "\rClosing in $n"
    sleep 1
    n=`expr $n - 1 `
done

