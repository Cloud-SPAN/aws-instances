#!/usr/bin/env bash
# deletes domain names
###################
source colour_utils_functions.sh	 # to add colour to some messages

case $# in
    1) ;; ### continue below
    0|*) ### display message on use
	message "\n`colour gl $(basename $0)` deletes the domain names of the instances specified as below.

$(colour bl "Usage:                $(basename $0)  instancesNamesFile")

 - provide the full or relative path to the file containing the names of the instances whose 
   domain names will be deleted.
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
outputsDirThisRun=${outputsDir}/domain-names-delete-output`date '+%Y%m%d.%H%M%S'`
#hostZone=cloud-span.aws.york.ac.uk	# from the AWS Console - Route 53 - Host Zone
#hostZoneID=Z012538133YPRCJ0WP3UZ	# idem
hostZone=`awk -F " " '$1 == "hostZone" {print $2}' $inputsDir/resourcesIDs.txt`
hostZoneID=`awk -F " " '$1 == "hostZoneId" {print $2}' $inputsDir/resourcesIDs.txt`

message "$(colour cyan "Deleting domain names:")"

check_instancesNamesFile_format "$(basename $0)" "$instancesNamesFile" || exit 1
check_created_resources_results_files "DO-EXIST" "$(basename $0)" "$outputsDir/domain-names-creation-output" "$instancesNamesFile" || exit 1

if [ ! -d $outputsDirThisRun ]; then
    message "$(colour brown "Creating directory to hold the results of deleting domain names:")"
    message $outputsDirThisRun
    mkdir -p $outputsDirThisRun
fi

instancesNames=( `cat $instancesNamesFile` )

for instance in ${instancesNames[@]}
do
    # get the elastic ip out of the instance id.
    subDomainName=${instance%-src*}		# get rid of suffix
    #nodns don't use: eipAllocationFile="$outputsDir/ip-addresses-allocation-output/elastic-IPaddress-for-${instance%-src*}.txt"
    dnDeleteFile="$outputsDirThisRun/domain-name-delete-${instance%-src*}.txt"
    domainNameCreationFile="$outputsDir/domain-names-creation-output/domain-name-create-${subDomainName}.txt"
    # get the IP address from the  within the file domainNameCreationFile where:
    # - -F is the field separator (single space " ") within each line
    # - "Success" is the field we are looking for, the containing record also contains the ip address as the $6 field
    eip=`awk -F " " '$1 == "Success" {print $6}' $domainNameCreationFile`

    # create the file batch request required by aws cli command to update the domain records
    fileRequest="
{\n
\t   \"Comment\": \"Deleting subdomain\",\n
\t   \"Changes\": [\n
\t \t     {\n
\t \t \t      \"Action\": \"DELETE\",\n
\t \t \t      \"ResourceRecordSet\": {\n
\t \t \t \t         \"Name\": \"$subDomainName.$hostZone\",\n
\t \t \t \t         \"Type\": \"A\",\n
\t \t \t \t         \"TTL\": 3600,\n
\t \t \t \t         \"ResourceRecords\": [{ \"Value\": \"$eip\"}]\n
\t \t \t  }\n
\t \t  }\n
\t ]\n
}\n
"
    echo -e $fileRequest > ${dnDeleteFile%.txt}Request.json
    #message "fileRequest: $fileRequest"
    aws route53 change-resource-record-sets --hosted-zone-id $hostZoneID --change-batch file://${dnDeleteFile%.txt}Request.json > $dnDeleteFile 2>&1

    if [ $? -eq 0 ]; then
	message "`colour gl Success` deleting `colour bl "domain:"` $subDomainName.$hostZone; `colour bl ip:` $eip"  $dnDeleteFile
    else
	message "`colour red Error` deleting `colour bl "domain:"` $subDomainName.$hostZone; `colour bl ip:` $eip"  $dnDeleteFile
    fi
done
