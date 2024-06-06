#!/usr/bin/env bash
# creates the domain names for instances
#
# Output:  in directorty $outputsDirThisRun
###################
source colour_utils_functions.sh	 # to add colour to some messages

case $# in
    1) ;; ### message "$(colour gl $(basename $0)) is login keys for instances specified in input file $(colour bl $1)";;
    0|*) ### display message on use
	message "\n$(colour gl $(basename $0)) creates the domain names for the instances specified as below.

$(colour bl "Usage:                $(basename $0)   instancesNamesFile")

 - provide the full or relative path to the file containing the names of the instances to which 
   to create domain names.
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

message "\n$(colour cyan "Creating domain names:")"

check_instancesNamesFile_format "$(basename $0)" "$instancesNamesFile" || exit 1

# directory for the results of creating domain names
outputsDirThisRun=${outputsDir}/domain-names-creation-output		# may be later add `date '+%Y%m%d.%H%M%S'`
if [ ! -d $outputsDirThisRun ]; then
    message "$(colour brown "Creating directory to hold the results of creating domain names and associating them to instances:")"
    message $outputsDirThisRun
    mkdir -p $outputsDirThisRun
fi

check_created_resources_results_files "DO-NOT-EXIST" "$(basename $0)" "$outputsDirThisRun" "$instancesNamesFile" || exit 1
### tests exit 1

hostZone=`awk -F " " '$1 == "hostZone" {print $2}' $inputsDir/resourcesIDs.txt`
hostZoneID=`awk -F " " '$1 == "hostZoneId" {print $2}' $inputsDir/resourcesIDs.txt`
message "`colour cyanlight "Using hostZone"`: $hostZone (hostZoneID: $hostZoneID)"

instancesNames=( `cat $instancesNamesFile` )

for instance in ${instancesNames[@]}
do
    subDomainName=${instance%-src*}
    #nodns don't use: eipAllocationFile="$outputsDir/ip-addresses-allocation-output/elastic-IPaddress-for-${instance%-src*}.txt"
    dnCreateFile="$outputsDirThisRun/domain-name-create-${instance%-src*}.txt"
    
    # get the IP within the file eipAllocationFile with awk, where:
    # - -F is the field separator (single space " ") within each line
    # - /"PublicIp"/ is the field we are looking for, which precedes the actual eipAllocID.
    # - $2 is (the 2nd field and) the eipAllocId itself which is dirty (e.g.: "eipalloc-060adb8fb72b1aa94",) and with
    # - substr we are unpacking into: eipalloc-060adb8fb72b1aa94
    #nodns don't use: eip=`awk -F " " '$1 == "\"PublicIp\":" {print substr($2, 2, length($2) -3)}' $eipAllocationFile`
    #nodns use next 3 sentences instead:
    instanceCreationFile="$outputsDir/instances-creation-output/$instance.txt"
    instanceID=`awk -F " " '$1 == "\"InstanceId\":" {print substr($2, 2, length($2) -3)}' $instanceCreationFile`
    eip=`aws ec2 describe-instances --instance-ids  "$instanceID" --query 'Reservations[*]. Instances[*]. PublicIpAddress' --output text`
    #message "`colour brown "subDomainName:"` $subDomainName ; `colour b "eip:"` $eip ;`colour b "related instance:"` $instance"
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
    # message "fileRequest: $fileRequest"
    aws route53 change-resource-record-sets --hosted-zone-id $hostZoneID --change-batch file://${dnCreateFile%.txt}Request.json > $dnCreateFile 2>&1

    if [ $? -eq 0 ]; then
	message "`colour gl Success` creating `colour b "domain:"` $subDomainName.$hostZone, `colour b ip:` ${eip}"
	### write results to log file without colour because colour characters make it difficult to recover the IP address
	### to delete the domain name which requires to specify the mapping IP address
	message "Success creating domain: $subDomainName.$hostZone; ip: ${eip}"  $dnCreateFile
    else
	message "`colour red Error` creating `colour b "domain:"` $subDomainName.$hostZone, `colour b ip:` ${eip}"  $dnCreateFile
    fi
done
exit 0

