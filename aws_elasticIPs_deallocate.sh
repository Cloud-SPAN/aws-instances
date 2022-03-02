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

# directory for the results of deallocating addresses labelled with the date and time
outputsDirThisRun=${outputsDir}/ip-addresses-deallocate-output`date '+%Y%m%d.%H%M%S'`

echo -e "`colour cyan "Deallocating elastic IP addresses:"`"

if [ ! -d $outputsDirThisRun ]; then
    echo -e "$(colour brown "Creating directory to hold the results of deallocating IP addresses:")"
    echo $outputsDirThisRun
    mkdir -p $outputsDirThisRun
fi

mapfile instancesIDs < $instancesNamesFile

for instance in ${instancesIDs[@]}
do
    # get the elastic ip out of the instance id.
    #echo -e "`colour brown "instance name:"` $instance"
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
    #echo -e "`colour brown "eip:"` $eip ; `colour brown eipAllocationId:` $eipAllocID"

    aws ec2 release-address --allocation-id $eipAllocID > $eipDeallocationFile  2>&1
    if [ $? -eq 0 ]; then
	echo -e "`colour gl Success` deallocating `colour bl "eip:"` $eip; `colour bl "instance:"` $instance; `colour bl eipAllocationId:` $eipAllocID"
	echo -e "`colour gl Success` deallocating `colour bl "eip:"` $eip; `colour bl "instance:"` $instance; `colour bl eipAllocationId:` $eipAllocID" >> $eipDeallocationFile
    else
	echo -e "`colour red Error` ($?) deallocating `colour bl "eip:"` $eip; `colour bl "instance:"` $instance; `colour bl eipAllocationId:` $eipAllocID"
	echo -e "`colour red Error` ($?) deallocating `colour bl "eip:"` $eip; `colour bl "instance:"` $instance; `colour bl eipAllocationId:` $eipAllocID" >> $eipDeallocationFile
    fi
done
