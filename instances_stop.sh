#!/bin/bash
# stops  AMI instances
#------------------------------------------------
source colours_functions.sh	 # to add colour to some messages

# instancesNamesFile=${1##*/}	 #; delete everything (*) up to last / and return the rest = (`basename $1`) but more efficient
instancesNamesFile=${1}		 #; actually need the full path ; echo instancesNameFile: $instancesNamesFile

# general inputs directory	 # return what is left after eliminating the last / and any character following it
inputsDir=${1%/*}		 # echo inputsdir: $inputsDir
				 
# general outputs directory	 # note that some data in the outpus directory (from creating instances) is needed as input
outputsDir=${1%/inputs*}/outputs # return what is left after eliminating the second to last / and "inputs" and any character
				 # following "inputs", then adds "/outputs" # echo outputsdir: $outputsDir

# directory for the results of creating instances, labelled with the date and time
outputsDirThisRun=${outputsDir}/instances-stop-output`date '+%Y%m%d.%H%M%S'`

echo -e "`colour cyan "Stopping instances:"`"

if [ ! -d $outputsDirThisRun ]; then
    echo -e "$(colour brown "Creating directory to hold the results of stopping instances:")"
    echo $outputsDirThisRun
    mkdir -p $outputsDirThisRun
fi

mapfile instancesNames < $instancesNamesFile

for instance in ${instancesNames[@]}
do
    instanceID=`awk -F " " '$1 == "\"InstanceId\":" {print substr($2, 2, length($2) -3)}' $outputsDir/instances-creation-output/$instance.txt`
    aws  ec2  stop-instances  --instance-ids $instanceID  > $outputsDirThisRun/$instance.txt 2>&1

    if [ $? -eq 0 ]; then
	echo -e "`colour gl Success` stopping instance: ${instance%-srcCSGC-AMI04}"
	echo -e "`colour gl Success` stopping instance: ${instance%-srcCSGC-AMI04}" >> $outputsDirThisRun/$instance.txt
    else
	echo -e "`colour red Error` ($?) stopping instance: ${instance%-srcCSGC-AMI04}}"
	echo -e "`colour red Error` ($?) stopping instance: ${instance%-srcCSGC-AMI04}" >> $outputsDirThisRun/$instance.txt
    fi
done
