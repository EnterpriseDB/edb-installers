#!/bin/sh

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
        echo "Please enter the root password."
    fi
else
    echo "Please enter your password."
fi

# Run selected operation
if [ $USE_SUDO != "1" ];
then
    su -m -c "@@INSTALLDIR@@/scripts/launchTuningWizard.sh $action"
else
    sudo @@INSTALLDIR@@/scripts/launchTuningWizard.sh $action
fi

printf "\n\n"

n=5
while [ "$n" -gt 0 ]
do
    echo -e -n "\rClosing in $n"
    sleep 1
    n=`expr $n - 1 `
done

