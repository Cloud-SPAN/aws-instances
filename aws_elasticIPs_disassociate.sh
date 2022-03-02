#!/bin/bash
# deallocates (releases/delete) elastic ip addresses
# NB:
# - if the eip address to deallocate is associated to a dns record/domain,
# - the eip address must first disassociated running elastic_IPs_reset_domain_name.sh
#
# Output:  in directorty $outputsDirThisRun
###################
source colours_functions.sh	 # to add colour to some messages

# instancesNamesFile=${1##*/}	 #; delete everything (*) up to last / and return the rest = (`basename $1`) but more efficient
instancesNamesFile=${1}		 #; actually need the full path ; echo instancesNameFile: $instancesNamesFile

# general inputs directory	 # return what is left after eliminating the last / and any character following it
inputsDir=${1%/*}		 # echo inputsdir: $inputsDir
				 
# general outputs directory	 # note that some data in the outpus directory (from creating instances) is needed as input
outputsDir=${1%/inputs*}/outputs # return what is left after eliminating the second to last / and "inputs" and any character
				 # following "inputs", then adds "/outputs"
				 # echo outputsdir: $outputsDir

# directory for the results of disassociating ip addresses  labelled with the date and time
outputsDirThisRun=${outputsDir}/ip-addresses-disassociate-output`date '+%Y%m%d.%H%M%S'`

echo -e "`colour cyan "Disassociating following elastic IP addresses:"`"

if [ ! -d $outputsDirThisRun ]; then
    echo -e "$(colour brown "Creating directory to hold the results of disassociating IP addresses:")"
    echo $outputsDirThisRun
    mkdir -p $outputsDirThisRun
fi

mapfile instancesIDs < $instancesNamesFile

for instance in ${instancesIDs[@]}
do
    # get the elastic ip out of the instance id.
    #echo -e "`colour brown "instance name:"` $instance"
    eipAssociationFile="$outputsDir/ip-addresses-association-output/${instance%-src*}-ip-associationID.txt"
    eipDisassociationFile="$outputsDirThisRun/eip-addr-disassoc-${instance%-src*}.txt"
    eipAssocID=`awk -F " " '$1 == "\"AssociationId\":" {print substr($2, 2, length($2) -2)}' $eipAssociationFile`
    #echo -e "`colour bl "instance:"` ${instance%-src*}; `colour brown eipAssociationId:` $eipAssocID"
    
    #aws ec2 reset-address-attribute  --allocation-id  $eipAllocID  --attribute domain-name > $eipDisassociationFile 2>&1
    aws ec2 disassociate-address  --association-id  $eipAssocID > $eipDisassociationFile 2>&1
    
    if [ $? -eq 0 ]; then
	echo -e "`colour gl Success` disassociating elasticIP, `colour bl "instance:"` ${instance%-src*}; `colour bl eipAssociationId:` $eipAssocID"
	echo -e "`colour gl Success` disassociating elasticIP, `colour bl "instance:"` ${instance%-src*}; `colour bl eipAssociationId:` $eipAssocID" >> $eipDisassociationFile
    else
	echo -e "`colour lightred Error` disassociating elasticIP, `colour bl "instance:"` ${instance%-src*}; `colour bl eipAssociationId:` $eipAssocID"
	echo -e "`colour lightred Error` disassociating elasticIP, `colour bl "instance:"` ${instance%-src*}; `colour bl eipAssociationId:` $eipAssocID" >> $eipDisassociationFile
    fi
done
