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
	message "\n$(colour gl $(basename $0)) disassociate the IP addresses of the instances specified as below.

$(colour bl "Usage:                $(basename $0)  instancesNamesFile")

 - provide the full or relative path to the file containing the names of the instances whose 
   IP addresses will be disassociated.
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

# directory for the results of disassociating ip addresses  labelled with the date and time
outputsDirThisRun=${outputsDir}/ip-addresses-disassociate-output`date '+%Y%m%d.%H%M%S'`

message "$(colour cyan "Disassociating following elastic IP addresses:")"

if [ ! -d $outputsDirThisRun ]; then
    message "$(colour brown "Creating directory to hold the results of disassociating IP addresses:")"
    message $outputsDirThisRun
    mkdir -p $outputsDirThisRun
fi

instancesNames=( `cat $instancesNamesFile` )

for instance in ${instancesNames[@]}
do
    # get the elastic ip out of the instance id.
    #message "`colour brown "instance name:"` $instance"
    eipAssociationFile="$outputsDir/ip-addresses-association-output/${instance%-src*}-ip-associationID.txt"
    eipDisassociationFile="$outputsDirThisRun/eip-addr-disassoc-${instance%-src*}.txt"
    eipAssocID=`awk -F " " '$1 == "\"AssociationId\":" {print substr($2, 2, length($2) -2)}' $eipAssociationFile`
    #message "`colour bl "instance:"` ${instance%-src*}; `colour brown eipAssociationId:` $eipAssocID"
    
    aws ec2 disassociate-address  --association-id  $eipAssocID > $eipDisassociationFile 2>&1
    
    if [ $? -eq 0 ]; then
	message "`colour gl Success` disassociating elasticIP, `colour bl "instance:"` ${instance%-src*}; `colour bl eipAssociationId:` $eipAssocID"  $eipDisassociationFile
    else
	message "`colour lightred Error` disassociating elasticIP, `colour bl "instance:"` ${instance%-src*}; `colour bl eipAssociationId:` $eipAssocID"  $eipDisassociationFile
    fi
done
