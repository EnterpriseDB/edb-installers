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

response=`sudo "@@APACHE_HOME@@/bin/apachectl" $action`
if [ "x$response" == "x" ]; then
    if [ $action == "stop" ]; then
         echo "Apache stopped Sucessfully"
    else
         echo "Apache" "$action"ed "Successfully"
    fi
else
    if [ $action == "restart" ]; then
        #Wait for process to start - give up after 15 attempts
        done="false"
	for i in $(seq 15)
	do
		apache_status=`ps ax | grep @@APACHE_HOME@@/bin/httpd | grep -v "grep"`
		if [ "x$apache_status" != "x" ];
		then
			#httpd Started - we are done
			done="true"
			break
		else
			sleep 2;
		fi
	done

        if [ "done" == "false" ]; then
                echo "Error Restarting Apache."
        else
                echo "Apache restarted successfully."
        fi
    else
        echo ERROR: $response
    fi
fi

printf "\n\n"

exit 0
