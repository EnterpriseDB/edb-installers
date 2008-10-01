#!/bin/bash

for f in xterm konsole gnome-terminal
do
        fpath=`which $f`
        if [ x"$fpath" = x"" ]
        then
                        continue
                else
                        $fpath -e @@INSTALLDIR@@/scripts/runTuningWizard.sh
                        exit 0
                fi
done

