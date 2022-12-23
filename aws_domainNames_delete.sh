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
outputsDirThisRun=${outputsDir}/domain-names-delete-output`date '+%Y%m%d.%H%M%S'`
#hostZone=cloud-span.aws.york.ac.uk	# from the AWS Console - Route 53 - Host Zone
#hostZoneID=Z012538133YPRCJ0WP3UZ	# idem
hostZone=`awk -F " " '$1 == "hostZone" {print $2}' $inputsDir/resourcesIDs.txt`
hostZoneID=`awk -F " " '$1 == "hostZoneId" {print $2}' $inputsDir/resourcesIDs.txt`

echo -e "`colour cyan "Deleting domain names:"`"

if [ ! -d $outputsDirThisRun ]; then
    echo -e "$(colour brown "Creating directory to hold the results of deleting domain names:")"
    echo $outputsDirThisRun
    mkdir -p $outputsDirThisRun
fi

mapfile instancesIDs < $instancesNamesFile

for instance in ${instancesIDs[@]}
do
    # get the elastic ip out of the instance id.
    subDomainName=${instance%-src*}		# get rid of suffix
    eipAllocationFile="$outputsDir/ip-addresses-allocation-output/elastic-IPaddress-for-${instance%-src*}.txt"
    dnDeleteFile="$outputsDirThisRun/domain-name-delete-${instance%-src*}.txt"
    
    # get the IP within the file eipAllocationFile with awk, where:
    # - -F is the field separator (single space " ") within each line
    # - /"PublicIp"/ is the field we are looking for, which precedes the actual eipAllocID.
    # - $2 is (the 2nd field and) the eipAllocId itself which is dirty (e.g.: "eipalloc-060adb8fb72b1aa94",) and with
    # - substr we are unpacking into: eipalloc-060adb8fb72b1aa94
    eip=`awk -F " " '$1 == "\"PublicIp\":" {print substr($2, 2, length($2) -3)}' $eipAllocationFile`
    #echo -e "`colour brown "subDomainName:"` $subDomainName ; `colour b "eip:"` $eip ;`colour b "related instance name:"` $instance"

    # create the file batch request required by aws cli command to update the domain records
    fileRequest="
{\n
\t   \"Comment\": \"Deleting subdomain\",\n
\t   \"Changes\": [\n
\t \t     {\n
\t \t \t      \"Action\": \"DELETE\",\n
\t \t \t      \"ResourceRecordSet\": {\n
\t \t \t \t         \"Name\": \"$subDomainName.$hostZone\",\n
\t \t \t \t        \"Type\": \"A\",\n
\t \t \t \t         \"TTL\": 3600,\n
\t \t \t \t         \"ResourceRecords\": [{ \"Value\": \"$eip\"}]\n
\t \t \t  }\n
\t \t  }\n
\t ]\n
}\n
"
    echo -e $fileRequest > ${dnDeleteFile%.txt}Request.json
    #echo -e "fileRequest: $fileRequest"
    aws route53 change-resource-record-sets --hosted-zone-id $hostZoneID --change-batch file://${dnDeleteFile%.txt}Request.json > $dnDeleteFile 2>&1

    if [ $? -eq 0 ]; then
	echo -e "`colour gl Success` deleting `colour bl "domain:"` $subDomainName.$hostZone; `colour bl ip:` $eip"
	echo -e "`colour gl Success` deleting `colour bl "domain:"` $subDomainName.$hostZone; `colour bl ip:` $eip" >> $dnDeleteFile
    else
	echo -e "`colour red Error` deleting `colour bl "domain:"` $subDomainName.$hostZone; `colour bl ip:` $eip"
	echo -e "`colour red Error` deleting `colour bl "domain:"` $subDomainName.$hostZone; `colour bl ip:` $eip" >> $dnDeleteFile
    fi
done
