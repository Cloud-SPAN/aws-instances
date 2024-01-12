#!/usr/bin/env bash
# associates ip addresses to instances
#
#--------------------------
source colour_utils_functions.sh	 # to add colour to some messages

case $# in
    1) ;; ### just continue below
    0|*) ### display message on use
	message "\n$(colour gl $(basename $0)) associates IP addresses to the instances specified as below.

$(colour bl "Usage:                $(basename $0)   instancesNamesFile")

 - provide the full or relative path to the file containing the names of the instances to associate 
   IP addresses.
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
				 # following "inputs", then adds "/outputs"
				 # mssage "outputsdir: $outputsDir"

# directory for the results of associating ip addresses to instances
outputsDirThisRun=${outputsDir}/ip-addresses-association-output			# may be later `date '+%Y%m%d.%H%M%S'`

message "\n$(colour cyan "Associating elastic IPs to instances:")"

check_instancesNamesFile_format "$(basename $0)" "$instancesNamesFile" || exit 1

if [ ! -d $outputsDirThisRun ]; then
    message "$(colour brown "Creating directory to hold the results of associating IP addresses to instances:")"
    message $outputsDirThisRun
    mkdir -p $outputsDirThisRun
fi

check_created_resources_results_files "DO-NOT-EXIST" "$(basename $0)" "$outputsDirThisRun" "$instancesNamesFile" || exit 1
### tests exit 1

instancesNames=( `cat $instancesNamesFile` )

for instance in ${instancesNames[@]}
do
    # get the elastic ip out of the instance id.
    # message "`colour brown "instance name:"` $instance"
    eipAllocationFile="$outputsDir/ip-addresses-allocation-output/elastic-IPaddress-for-${instance%-src*}.txt"
    eipAllocID=`awk -F " " '$1 == "\"AllocationId\":" {print substr($2, 2, length($2) -3)}' $eipAllocationFile`
    # and we get the IP similarly
    eip=`awk -F " " '$1 == "\"PublicIp\":" {print substr($2, 2, length($2) -3)}' $eipAllocationFile`
    
    instanceCreationFile="$outputsDir/instances-creation-output/$instance.txt"
    instanceID=`awk -F " " '$1 == "\"InstanceId\":" {print substr($2, 2, length($2) -3)}' $instanceCreationFile`
     
    eipAssociationFile="$outputsDirThisRun/${instance%-src*}-ip-associationID.txt"
    
    message "Checking ${instance%-src*} is running: "
    ### tmpfile="/tmp/${instance%-src*}.txt"
    while true 
    do
	echo -n "."
	### worked fine but better withoug /tmpfile because in windows users it will not work.
	### aws ec2 describe-instance-status --instance-id $instanceID > $tmpfile
	### instanceState=`awk -F " " '$1 == "\"Code\":" {print substr($2, 1, length($2) -1)}' $tmpfile`
	instanceState=`aws ec2 describe-instance-status --instance-id $instanceID | awk -F " " '$1 == "\"Code\":" {print substr($2, 1, length($2) -1)}'`
	if [[ $instanceState == "16" ]]; then
	    #16 is running: https://awscli.amazonaws.com/v2/documentation/api/latest/reference/ec2/describe-instance-status.html
	    message " - instanceState $instanceState (running)"; break ;
	else
	    sleep 4
	fi
    done

    aws ec2 associate-address --instance-id $instanceID --allocation-id $eipAllocID > $eipAssociationFile 2>&1
    
    if [ $? -eq 0 ]; then
	message "`colour gl Success` associating `colour bl "eip:"` $eip; `colour bl "instance:"` ${instance%-src*}"  $eipAssociationFile
    else
	message "`colour red Error` ($?) associating `colour bl "eip:"` $eip; `colour bl "instance:"` ${instance%-src*}"  $eipAssociationFile
    fi
done
exit 0
