#!/usr/bin/env bash
# starts instances
#------------------------------------------------
source colour_utils_functions.sh	 # to add colour to some messages

case $# in
    1) message  "$(colour gl $(basename $0)) is starting instances specified in input file $(colour bl $1)";;
    0|*) ### display message on use
	message  "\n$(colour gl $(basename $0)) starts instances previously created and stopped.

$(colour bl "Usage:                $(basename $0) instancesNamesFile")

 - provide the full or relative path to the file containing the names of the instances to start.
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
				 # following "inputs", then adds "/outputs" # message "outputsdir: $outputsDir"

# directory for the results of creating instances, labelled with the date and time
outputsDirThisRun=${outputsDir}/instances-start-output`date '+%Y%m%d.%H%M%S'`

message "$(colour cyan "Starting instances:")"
check_instancesNamesFile_format "$(basename $0)" "$instancesNamesFile" || exit 1
check_created_resources_results_files "DO-EXIST" "$(basename $0)" "$outputsDir/instances-creation-output" "$instancesNamesFile" || exit 1

if [ ! -d $outputsDirThisRun ]; then
    message "$(colour brown "Creating directory to hold the results of starting instances:")"
    message $outputsDirThisRun
    mkdir -p $outputsDirThisRun
fi

instancesNames=( `cat $instancesNamesFile` )

for instance in ${instancesNames[@]}
do
    instanceID=`awk -F " " '$1 == "\"InstanceId\":" {print substr($2, 2, length($2) -3)}' $outputsDir/instances-creation-output/$instance.txt`
    
    aws  ec2  start-instances  --instance-ids $instanceID  > $outputsDirThisRun/$instance.txt 2>&1

    if [ $? -eq 0 ]; then
	message "`colour gl Success` starting instance: ${instance%-src*}"  $outputsDirThisRun/$instance.txt
    else
	message "`colour red Error` ($?) starting instance: ${instance%-src*}"  $outputsDirThisRun/$instance.txt
    fi
    ### with dynamic IP addresses, we need to reassign the domain name to the new IP address as described here:
    ### https://awscli.amazonaws.com/v2/documentation/api/latest/reference/route53/change-resource-record-sets.html 
    eip=`aws ec2 describe-instances --instance-ids  "$instanceID" --query 'Reservations[*]. Instances[*]. PublicIpAddress' --output text`
    fileRequest="
{\n
\t   \"Comment\": \"Updating subdomain\",\n
\t   \"Changes\": [\n
\t \t     {\n
\t \t \t      \"Action\": \"UPSERT\",\n
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
