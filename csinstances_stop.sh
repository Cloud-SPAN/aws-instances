#!/usr/bin/env bash
# stops  AMI instances
#------------------------------------------------
source colour_utils_functions.sh	 # to add colour to some messages

case $# in
    1) message  "$(colour gl $(basename $0)) is stopping instances specified in input file $(colour bl $1)";;
    0|*)  ### display message on use
	message  "\n$(colour gl $(basename $0)) stops instances assumed to be running.

$(colour bl "Usage:                $(basename $0) instancesNamesFile")

 - provide the full or relative path to the file containing the names of the instances to stop.
 - example:  $(colour bl "$(basename $0)  courses/genomics01/")$(colour r inputs)$(colour bl /instancesNames.txt)
 - the $(colour bl inputs) directory must be specified as such and inside one or more directories of your choice.
 - an $(colour bl outputs) directory will be created at the same level of the inputs directory where the results 
   of the aws commands will be stored.\n"
	 exit 2;;
esac

# instancesNamesFile=${1##*/}	 #; delete everything (*) up to last / and return the rest = (`basename $1`) but more efficient
instancesNamesFile=${1}		 #; actually need the full path ; message "instancesNameFile: $instancesNamesFile"ss

# general inputs directory	 # return what is left after eliminating the last / and any character following it
inputsDir=${1%/*}		 # message "inputsdir: $inputsDir"
				 
# general outputs directory	 # note that some data in the outpus directory (from creating instances) is needed as input
outputsDir=${1%/inputs*}/outputs # return what is left after eliminating the second to last / and "inputs" and any character
				 # following "inputs", then adds "/outputs" # message "outputsdir: $outputsDir"

message "$(colour cyan "Stopping instances:")"
check_theScripts_csconfiguration "$instancesNamesFile" || exit 1
check_created_resources_results_files "DO-EXIST" "INSTANCE_FILES" "$instancesNamesFile" || { message "\n$(colour lb "$(basename $0) aborting")"; exit 1; }

if [ -f $inputsDir/.csconfig_DOMAIN_NAMES.txt ]; then
    ### check the domain names creation files exist 
    check_created_resources_results_files "DO-EXIST" "DOMAIN_NAME_FILES" "$instancesNamesFile" || { message "\n$(colour lb "$(basename $0) aborting")"; exit 1; }
fi

outputsDirThisRun=${outputsDir}/instances-stop-output`date '+%Y%m%d.%H%M%S'`
if [ ! -d $outputsDirThisRun ]; then
    message "$(colour brown "Creating directory to hold the results of stopping instances:")"
    message $outputsDirThisRun
    mkdir -p $outputsDirThisRun
fi

instancesNames=( `cat $instancesNamesFile` )


for instanceFullName in ${instancesNames[@]}
do
    instance=${instanceFullName%-src*}		### get rid of suffix "-srcAMInn.." if it exists
    resultsFile=$outputsDirThisRun/$instance.txt
    
    instanceID=`awk -F " " '$1 == "\"InstanceId\":" {print substr($2, 2, length($2) -3)}' $outputsDir/instances-creation-output/$instance.txt`

    aws  ec2  stop-instances  --instance-ids $instanceID  >> $resultsFile 2>&1

    awsResult=$?
    if [ $awsResult -eq 0 ]; then
 	message "`colour gl Success` stopping instance: $instance"  $resultsFile

	if [ -f $inputsDir/.csconfig_DOMAIN_NAMES.txt ]; then
	    ### now delete the domain name of the instance so that DNS servers invalidate it and restarting the instance is faster
	    ### we only need the last occurrence of Success, and therefore we are printing the last result found at the END block
	    eip=`awk -F " " '$1 == "Success" {ipaddress=$6} END {print ipaddress}' $outputsDir/domain-names-creation-output/domain-name-create-$instance.txt`

	    instanceDomainName=`awk -F " " '$1 == "Success" {domainName=$4} END {print domainName}' $outputsDir/domain-names-creation-output/domain-name-create-$instance.txt`

	    fileRequest="
{\n	    
\t   \"Comment\": \"Deleting subdomain\",\n
\t   \"Changes\": [\n
\t \t     {\n
\t \t \t      \"Action\": \"DELETE\",\n
\t \t \t      \"ResourceRecordSet\": {\n
\t \t \t \t         \"Name\": \"$instanceDomainName\",\n
\t \t \t \t         \"Type\": \"A\",\n
\t \t \t \t         \"TTL\": 3600,\n
\t \t \t \t         \"ResourceRecords\": [{ \"Value\": \"$eip\"}]\n
\t \t \t  }\n
\t \t  }\n
\t ]\n
}\n
"
	    echo -e $fileRequest > $outputsDirThisRun/${instance}Request.json
	    hostZoneId=`awk -F " " '$1 == "hostZoneId" {print $2}' $inputsDir/resourcesIDs.txt`

	    aws route53 change-resource-record-sets --hosted-zone-id $hostZoneId --change-batch file://$outputsDirThisRun/${instance}Request.json >> $resultsFile 2>&1

	    awsResult=$?
	    if [ $awsResult -eq 0 ]; then
		message "`colour gl Success` deleting `colour bl "domain:"` $instanceDomainName `colour bl ip:` $eip" $resultsFile
	    else
		message "`colour red Error` ($awsResult) deleting `colour bl "domain:"` $instanceDomainName `colour bl ip:` $eip" $resultsFile
		message "$(colour gl NB): if error is 254 the domain name to delete was not found (was likely deleted before) and eveything is OK. Otherwise check the results file:\n \"$resultsFile\"." $resultsFile
	    fi
	fi ### if [ -f $inputsDir/.csconfig_DOMAIN_NAMES.txt ]; then
    else
	message "`colour red Error` ($awsResult) stopping instance: $instance" $resultsFile
    fi
done
