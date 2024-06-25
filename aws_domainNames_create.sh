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

check_theScripts_csconfiguration "$instancesNamesFile" || exit 1

check_created_resources_results_files "DO-NOT-EXIST" "DOMAIN_NAME_FILES" "$instancesNamesFile" || { message "\n$(colour lb "$(basename $0) aborting")"; exit 1; }

# directory for the results of creating domain names
outputsDirThisRun=${outputsDir}/domain-names-creation-output		# may be later add `date '+%Y%m%d.%H%M%S'`
if [ ! -d $outputsDirThisRun ]; then
    message "$(colour brown "Creating directory to hold the results of creating domain names and IP addresses:")"
    message $outputsDirThisRun
    mkdir -p $outputsDirThisRun
fi

hostZone=`awk -F " "   'tolower($1) == "hostzone"   {print $2}' $inputsDir/resourcesIDs.txt`
hostZoneID=`awk -F " " 'tolower($1) == "hostzoneid" {print $2}' $inputsDir/resourcesIDs.txt`

message "`colour cyanlight "Using hostZone"`: $hostZone (hostZoneID: $hostZoneID)"

instancesNames=( `cat $instancesNamesFile` )

for instanceFullName in ${instancesNames[@]}
do
    instance=${instanceFullName%-src*}		### get rid of suffix "-srcAMInn.." if it exists
    resultsFile="$outputsDirThisRun/domain-name-create-$instance.txt"
    instanceID=`awk -F " " '$1 == "\"InstanceId\":" {print substr($2, 2, length($2) -3)}' $outputsDir/instances-creation-output/$instance.txt`
    eip=`aws ec2 describe-instances --instance-ids  "$instanceID" --query 'Reservations[*]. Instances[*]. PublicIpAddress' --output text`
    # create the file batch request required by aws cli command to update the domain records
    fileRequest="
{\n
\t   \"Comment\": \"Creating subdomain\",\n
\t   \"Changes\": [\n
\t \t     {\n
\t \t \t      \"Action\": \"CREATE\",\n
\t \t \t      \"ResourceRecordSet\": {\n
\t \t \t \t         \"Name\": \"$instance.$hostZone\",\n
\t \t \t \t        \"Type\": \"A\",\n
\t \t \t \t         \"TTL\": 3600,\n
\t \t \t \t         \"ResourceRecords\": [{ \"Value\": \"$eip\"}]\n
\t \t \t  }\n
\t \t  }\n
\t ]\n
}\n
"
    echo -e $fileRequest > ${resultsFile%.txt}Request.json

    aws route53 change-resource-record-sets --hosted-zone-id $hostZoneID --change-batch file://${resultsFile%.txt}Request.json > $resultsFile 2>&1

    if [ $? -eq 0 ]; then
	message "`colour gl Success` creating `colour b "domain:"` $instance.$hostZone, `colour b ip:` ${eip}"
	### write results without colour because colour characters make it difficult to recover the IP address
	### to delete the domain name which requires to specify the mapping IP address
	message2file "Success creating domain: $instance.$hostZone ip: ${eip}"  $resultsFile
    else
	message "`colour red Error` creating `colour b "domain:"` $instance.$hostZone, `colour b ip:` ${eip}"  $resultsFile
	exit 2
    fi
done
exit 0

