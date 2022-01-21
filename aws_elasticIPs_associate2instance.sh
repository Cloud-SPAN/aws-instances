#!/bin/bash
# associates ip addresses to instances
#
#--------------------------
source colours_functions.sh	 # to add colour to some messages

# instancesNamesFile=${1##*/}	 #; delete everything (*) up to last / and return the rest = (`basename $1`) but more efficient
instancesNamesFile=${1}		 #; actually need the full path ; echo instancesNameFile: $instancesNamesFile

# general inputs directory	 # return what is left after eliminating the last / and any character following it
inputsDir=${1%/*}		 # echo inputsdir: $inputsDir
				 
# general outputs directory	 # note that some data in the outpus directory (from creating instances) is needed as input
outputsDir=${1%/inputs*}/outputs # return what is left after eliminating the second to last / and "inputs" and any character
				 # following "inputs", then adds "/outputs"
				 # echo outputsdir: $outputsDir

# directory for the results of associating ip addresses to instances
outputsDirThisRun=${outputsDir}/ip-addresses-association-output			# may be later `date '+%Y%m%d.%H%M%S'`

echo -e "`colour cyan "Associating elastic IPs to instances:"`"

if [ ! -d $outputsDirThisRun ]; then
    echo -e "$(colour brown "Creating directory to hold the results of associating IP addresses to instances:")"
    echo $outputsDirThisRun
    mkdir -p $outputsDirThisRun
fi

mapfile instancesIDs < $instancesNamesFile

for instance in ${instancesIDs[@]}
do
    # get the elastic ip out of the instance id.
    #echo -e "`colour brown "instance name:"` $instance"
    eipAllocationFile="$outputsDir/ip-addresses-allocation-output/elastic-IPaddress-for-${instance%-srcCSGC-AMI04}.txt"
    eipAllocID=`awk -F " " '$1 == "\"AllocationId\":" {print substr($2, 2, length($2) -3)}' $eipAllocationFile`
    # and we get the IP similarly
    eip=`awk -F " " '$1 == "\"PublicIp\":" {print substr($2, 2, length($2) -3)}' $eipAllocationFile`
    
    instanceCreationFile="$outputsDir/instances-creation-output/$instance.txt"
    instanceID=`awk -F " " '$1 == "\"InstanceId\":" {print substr($2, 2, length($2) -3)}' $instanceCreationFile`
     
    eipAssociationFile="$outputsDirThisRun/${instance%-srcCSGC-AMI04}-ip-associationID.txt"
    echo -e "`colour bl "eip:"` $eip ; `colour brown eipAllocationId:` $eipAllocID; `colour b iid:` $instanceID"

    echo -n "Checking ${instance%-srcCSGC-AMI04} is running: "
    tmpfile="/tmp/${instance%-srcCSGC-AMI04}.txt"
    while true 
    do
	echo -n "."
	aws ec2 describe-instance-status --instance-id $instanceID > $tmpfile
	instanceState=`awk -F " " '$1 == "\"Code\":" {print substr($2, 1, length($2) -1)}' $tmpfile`
	if [[ $instanceState == "16" ]]; then
	    #16 is running: https://awscli.amazonaws.com/v2/documentation/api/latest/reference/ec2/describe-instance-status.html
	    echo " - instanceState $instanceState (running)"; break ;
	else
	    sleep 2
	fi
    done

    aws ec2 associate-address  --instance-id $instanceID  --allocation-id $eipAllocID > $eipAssociationFile 2>&1
    
    if [ $? -eq 0 ]; then
	echo -e "`colour gl Success` associating `colour bl "eip:"` $eip; `colour bl "instance:"` $instance; `colour bl eipAllocationId:` $eipAllocID"
	echo -e "`colour gl Success` associating `colour bl "eip:"` $eip; `colour bl "instance:"` $instance; `colour bl eipAllocationId:` $eipAllocID" >> $eipAssociationFile
    else
	echo -e "`colour red Error` ($?) associating `colour bl "eip:"` $eip; `colour bl "instance:"` $instance; `colour bl eipAllocationId:` $eipAllocID"
	echo -e "`colour red Error` ($?) associating `colour bl "eip:"` $eip; `colour bl "instance:"` $instance; `colour bl eipAllocationId:` $eipAllocID" >> $eipAssociationFile
    fi
done
################################


#elasticIPs="eIP_instance12 eIP_instance13"
#aws ec2 associate-address --dry-run  --instance-id i-0cb53ea75a779bdd4  --allocation-id eipalloc-092f509ab223e522e
#aws ec2 associate-address  --instance-id i-0cb53ea75a779bdd4  --allocation-id eipalloc-092f509ab223e522e

