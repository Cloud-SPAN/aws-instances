#!/bin/bash
# deallocates (releases/delete) elastic ip addresses
# NB:
# - if the eip address to deallocate is associated to a dns record/domain,
# - the eip address must first disassociated running elastic_IPs_reset_domain_name.sh
#
# Output:  in directorty $outputsDirThisRun
###################
source colours_msg_functions.sh	 # to add colour to some messages

case $# in
    1) ;; ### continue below
    0|*) ### display message on use
	message "\n`colour gl $(basename $0)` deallocates (deletes) the IP addresses of the instances specified as below.

$(colour bl "Usage:                $(basename $0)  instancesNamesFile")

 - provide the full or relative path to the file containing the names of the instances whose 
   IP addresses will be deallocated.
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
				 # message "outputsdir: $outputsDir"

# directory for the results of deallocating addresses labelled with the date and time
outputsDirThisRun=${outputsDir}/ip-addresses-deallocate-output`date '+%Y%m%d.%H%M%S'`

message "$(colour cyan "Deallocating elastic IP addresses:")"

if [ ! -d $outputsDirThisRun ]; then
    message "$(colour brown "Creating directory to hold the results of deallocating IP addresses:")"
    message $outputsDirThisRun
    mkdir -p $outputsDirThisRun
fi

instancesNames=( `cat $instancesNamesFile` )

for instance in ${instancesNames[@]}
do
    # get the elastic ip out of the instance id.
    #message "`colour brown "instance name:"` $instance"
    eipAllocationFile="$outputsDir/ip-addresses-allocation-output/elastic-IPaddress-for-${instance%-src*}.txt"
    eipDeallocationFile="$outputsDirThisRun/eip-addr-dealloc-${instance%-src*}.txt"
    # get the eip allocation id (eipAllocID) from within the file eipAllocationFile with awk:
    # -F is the field separator (single space " ") within each line;
    # /AllocationId/ is the field we are looking for, which precedes the actual eipAllocID.
    # $2 is (the 2nd field and) the eipAllocId itself which is dirty (e.g.: "eipalloc-060adb8fb72b1aa94",) and with
    # substr we are unpacking it thus: eipalloc-060adb8fb72b1aa94
    eipAllocID=`awk -F " " '$1 == "\"AllocationId\":" {print substr($2, 2, length($2) -3)}' $eipAllocationFile`
    # and we get the IP similarly
    eip=`awk -F " " '$1 == "\"PublicIp\":" {print substr($2, 2, length($2) -3)}' $eipAllocationFile`
    #message "`colour brown "eip:"` $eip ; `colour brown eipAllocationId:` $eipAllocID"

    aws ec2 release-address --allocation-id $eipAllocID > $eipDeallocationFile  2>&1
    if [ $? -eq 0 ]; then
	message "`colour gl Success` deallocating `colour bl "eip:"` $eip; `colour bl "instance:"` $instance; `colour bl eipAllocationId:` $eipAllocID"  $eipDeallocationFile
    else
	message "`colour red Error` ($?) deallocating `colour bl "eip:"` $eip; `colour bl "instance:"` $instance; `colour bl eipAllocationId:` $eipAllocID"  $eipDeallocationFile
    fi
done
