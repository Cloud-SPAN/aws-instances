#!/usr/bin/env bash
# delete/terminate (run!?) AWS instances
#------------------------------------------------
source colour_utils_functions.sh	 # to add colour to some messages

case $# in
    1) ;; ### continue below 
    0|*) ### display message on use
	message "\n`colour gl $(basename $0)` deletes the instances specified as below.

$(colour bl "Usage:                $(basename $0)  instancesNamesFile")

 - provide the full or relative path to the file containing the names of the instances to delete.
 - example:  $(colour bl "$(basename $0)  courses/genomics01/")$(colour r inputs)$(colour bl /instancesNames.txt)
 - the $(colour bl inputs) directory must be specified as such and inside one or more directories of your choice.
 - an $(colour bl outputs) directory will be created at the same level of the inputs directory where the results 
   of the aws commands will be stored.\n"
	exit 2;;
esac


# instancesNamesFile=${1##*/}	 #; delete everything (*) up to last / and return the rest = (`basename $1`) but more efficient
instancesNamesFile=${1}		 #; actually need the full path ; message "instancesNameFile: $instancesNamesFile"

# general inputs directory	 # return what is left after eliminating the last / and any character following it
inputsDir=${1%/*}		 # message "inputsdir: $inputsDir"
				 
# general outputs directory	 # note that some data in the outpus directory (from creating instances) is needed as input
outputsDir=${1%/inputs*}/outputs # return what is left after eliminating the second to last / and "inputs" and any character
				 # following "inputs", then adds "/outputs" # message "outputsdir: $outputsDir"

# directory for the results of creating instances, labelled with the date and time
outputsDirThisRun=${outputsDir}/instances-delete-output`date '+%Y%m%d.%H%M%S'`

message "$(colour cyan "Terminating instances:")"
check_instancesNamesFile_format "$(basename $0)" "$instancesNamesFile" || exit 1
check_created_resources_results_files "DO-EXIST" "$(basename $0)" "$outputsDir/instances-creation-output" "$instancesNamesFile" || exit 1
### tests exit 1

if [ ! -d $outputsDirThisRun ]; then
    message "$(colour brown "Creating directory to hold the results of deleting instances:")"
    message $outputsDirThisRun
    mkdir -p $outputsDirThisRun
fi

instancesNames=( `cat $instancesNamesFile` )

for instance in ${instancesNames[@]}
do
    instanceID=`awk -F " " '$1 == "\"InstanceId\":" {print substr($2, 2, length($2) -3)}' $outputsDir/instances-creation-output/$instance.txt`
    aws  ec2  terminate-instances  --instance-ids $instanceID  > $outputsDirThisRun/$instance.txt 2>&1
    if [ $? -eq 0 ]; then
	message "`colour gl Success` terminating instance: ${instance%-src*}"  $outputsDirThisRun/$instance.txt
    else
	message "`colour red Error` ($?) terminating instance: ${instance%-src*}"  $outputsDirThisRun/$instance.txt
    fi
done
