#!/bin/sh

if [ -z "$1" ]
then
        printf "No option supplied\n"
        exit 1
fi

selinux=`getenforce 2>/dev/null`
if [ "x"$selinux != "x" -a $selinux != "Disabled" ];
then
    printf "SELinux is enabled on the system, which might cause apache start/stop/restart to fail.\n"
    printf "Please ensure proper access privileges to apache.\n"
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

     response=`su -m -c "@@APACHE_HOME@@/bin/apachectl $action"`
 
else
     response=`sudo "@@APACHE_HOME@@/bin/apachectl" $action`

fi

CODE=`echo $?`

if [ "$CODE" = 0 ] ; then
    if [ "x$response" = "x" ] ; then
         if [ $action = "stop" ] ; then
                echo "Apache stopped Sucessfully"
         else
                echo "Apache" "$action"ed "Successfully"
         fi
    else
         if [ $action = "restart" ] ; then
                apache_status=`ps -ef | grep @@APACHE_HOME@@/bin/httpd | grep -v "grep"`
                if [ "x$apache_status" = "x" ] ; then
                	 echo "Error Starting Apache."
                else
                	echo "Apache restarted successfully."
        	fi
    	else
       		echo ERROR: $response
    	fi
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

