#!/bin/bash
# Copyright (c) 2012, EnterpriseDB Corporation.  All rights reserved

os=`uname | awk '{print $1}'`
if [ "$os" = "Linux" ]
then
	# Get distribution name
	if [ -e /etc/debian_version ]
	then
		osFile=/etc/issue
	else
		osFile=`ls -al --time-style=full-iso /etc/*-release |grep -v lsb |grep -v ^l |awk '{print $9}' | head -n 1`
	fi
	osVersion=`cat $osFile | sed q | awk 'BEGIN { FS="@"
						    	} 
						    { 
							newlineIndex = index ($1,"\\\\n")
							if (newlineIndex == 0)
							  print $1
							else
							  print (substr($1,1,newlineIndex-1))
						     	}'`
							
	# Get number of processor cores
	nProc=`cat /proc/cpuinfo | grep ^processor | wc -l`
	# Get processor Type
	procType=`awk '/model name/ {for(i=1;i<=NF;i=i+1) printf("%s ",$i);}' /proc/cpuinfo`
	procType=`echo ${procType#model name : }`
#	procType=`echo ${procType\"/model name : */}`
	# Get processor level (model)
	procLevel=` cat /proc/cpuinfo | grep model | grep -v name | awk -F':' '{print $2}' | sed 's/^[ \t]*//'`
	# Get ram
	totalMem=`cat /proc/meminfo | grep MemTotal | awk -F':' '{print $2}'| sed 's/^[ \t]*//' |sed 's/k[bB]//'`
	
elif [ "$os" = "SunOS" ]
then
	os="Solaris"
	osVersion=`uname -r`
	# Get the number of processor cores

	nProc=`/usr/sbin/psrinfo | wc -l | sed 's/^[ \t]*//'`
	# Get the Processor type
	procType=`/usr/sbin/psrinfo -v 0 | grep operates | awk '{printf("%s %s %s",$2,$6,$7)}' | awk -F',' '{printf ("%s",$1)}'`
	# Note, there really isn't a good distinction here for 
	# solaris machines.  It can be derived, but will come later 
	# as a patch to this script.
	procLevel="0"
	
elif [ "$os" = "Darwin" ]
then
	os="Macintosh"
	osVersion=`sysctl -n kern.osrelease`
	# Get number of processor cores
	nProc=`sysctl -n hw.ncpu`
	# Get Processor type
	t=`uname -m`
	if [ "$t" = "i386" ]
	then
		procType=`sysctl -n machdep.cpu.brand_string | awk '{printf("%s %s %s",$1,$2,$3)}'`
		procSpd=`sysctl -n machdep.cpu.brand_string | awk -F'@' '{printf("%s",$2)}'`
		procType="$procType$procSpd"
		procLevel=`sysctl -n machdep.cpu.model`
	else
		
		procType=`sysctl -n hw.machine`
		procSpd=`sysctl -n hw.cpufrequency_max`
		procSpd=`expr $procSpd / 1000000`
		# Convert Proc spd from Hz to MHz
		procType=$procType" "$procSpd" MHz"
		procLevel=`sysctl -n hw.cputype`
	fi
		
	# Get ram
	totalMem=`sysctl -n hw.memsize`
fi

# Common pieces
if [ -e /etc/debian_version ]
then
procArch=`uname -m`
else
procArch=`uname -p`
fi

# Make sure that ram is a numeric
totalMemRound=`expr $totalMem`

totalMeminGB=`echo "scale=2;$totalMemRound/1048576"|bc`

# Dynatune's variables
OS="$os $osVersion"

NUMBER_OF_PROCESSORS="$nProc"



PROCESSOR_IDENTIFIER="$procType"

PROCESSOR_LEVEL="$procLevel"

shared_memory=`cat /proc/sys/kernel/shmmax`
SHARED_MEM="$shared_memory"

SHARED_MEM_IN_MB=`echo "scale=0;$SHARED_MEM/1048576"|bc`


echo PROCESSOR_ARCH =$procArch >> ./sysinfo.properties
echo TOTAL_MEM_IN_GB =$totalMeminGB >> ./sysinfo.properties
echo OS =$OS >> ./sysinfo.properties
echo NUMBER_OF_PROCESSORS =$NUMBER_OF_PROCESSORS >> ./sysinfo.properties
echo PROCESSOR_TYPE =$PROCESSOR_IDENTIFIER >> ./sysinfo.properties
echo PROCESSOR_LEVEL =$PROCESSOR_LEVEL >> ./sysinfo.properties
echo LANGUAGE = ${LANG%%.*} >> ./sysinfo.properties
echo SHARED_MEMORY_IN_MB =$SHARED_MEM_IN_MB >> ./sysinfo.properties

