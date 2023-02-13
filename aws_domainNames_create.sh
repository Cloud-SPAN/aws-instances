#!/bin/bash
# creates the domain names for instances
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

echo -e "`colour cyan "Creating domain names:"`"

# directory for the results of creating domain names
outputsDirThisRun=${outputsDir}/domain-names-creation-output		# may be later add `date '+%Y%m%d.%H%M%S'`
if [ ! -d $outputsDirThisRun ]; then
    echo -e "$(colour brown "Creating directory to hold the results of creating domain names and associating them to instances:")"
    echo $outputsDirThisRun
    mkdir -p $outputsDirThisRun
fi

hostZone=`awk -F " " '$1 == "hostZone" {print $2}' $inputsDir/resourcesIDs.txt`
hostZoneID=`awk -F " " '$1 == "hostZoneId" {print $2}' $inputsDir/resourcesIDs.txt`
echo -e "`colour cyanlight "Using hostZone"`: $hostZone (hostZoneID: $hostZoneID)"

instancesNames=( `cat $instancesNamesFile` )

for instance in ${instancesNames[@]}
do
    subDomainName=${instance%-src*}
    eipAllocationFile="$outputsDir/ip-addresses-allocation-output/elastic-IPaddress-for-${instance%-src*}.txt"
    dnCreateFile="$outputsDirThisRun/domain-name-create-${instance%-src*}.txt"
    
    # get the IP within the file eipAllocationFile with awk, where:
    # - -F is the field separator (single space " ") within each line
    # - /"PublicIp"/ is the field we are looking for, which precedes the actual eipAllocID.
    # - $2 is (the 2nd field and) the eipAllocId itself which is dirty (e.g.: "eipalloc-060adb8fb72b1aa94",) and with
    # - substr we are unpacking into: eipalloc-060adb8fb72b1aa94
    eip=`awk -F " " '$1 == "\"PublicIp\":" {print substr($2, 2, length($2) -3)}' $eipAllocationFile`
    #echo -e "`colour brown "subDomainName:"` $subDomainName ; `colour b "eip:"` $eip ;`colour b "related instance:"` $instance"
    # create the file batch request required by aws cli command to update the domain records
    fileRequest="
{\n
\t   \"Comment\": \"Creating subdomain\",\n
\t   \"Changes\": [\n
\t \t     {\n
\t \t \t      \"Action\": \"CREATE\",\n
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
    echo -e $fileRequest > ${dnCreateFile%.txt}Request.json
    #continue
    #echo -e "fileRequest: $fileRequest"
    aws route53 change-resource-record-sets --hosted-zone-id $hostZoneID --change-batch file://${dnCreateFile%.txt}Request.json > $dnCreateFile 2>&1

    if [ $? -eq 0 ]; then
	echo -e "`colour gl Success` creating `colour b "domain:"` $subDomainName.$hostZone; `colour b ip:` $eip"
	echo -e "`colour gl Success` creating `colour b "domain:"` $subDomainName.$hostZone; `colour b ip:` $eip" >> $dnCreateFile
    else
	echo -e "`colour red Error` creating `colour b "domain:"` $subDomainName.$hostZone; `colour b ip:` $eip"
	echo -e "`colour red Error` creating `colour b "domain:"` $subDomainName.$hostZone; `colour b ip:` $eip" >> $dnCreateFile
    fi
done
