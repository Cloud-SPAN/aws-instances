#!/usr/bin/env bash
# create (run!?) AWS instances based on specified configuration and files and the following reference
# https://awscli.amazonaws.com/v2/documentation/api/latest/reference/ec2/run-instances.html
#------------------------------------------------
source colour_utils_functions.sh	 # to add colour to some messages and more

case $# in
    1) ;; ##message "$(colour gl $(basename $0)) is creating and launching instances specified in input file $(colour bl $1)";;
    0|*) ### display message on use
	message "\n$(colour gl $(basename $0)) creates the instances specified as below.

$(colour bl "Usage:                $(basename $0) instancesNamesFile")

 - provide the full or relative path to the file containing the names of the instances to create.
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
outputsDirThisRun=${outputsDir}/instances-creation-output	# we may add the date later `date '+%Y%m%d.%H%M%S'`

message "\n$(colour cyan "Creating instances:")"

check_theScripts_csconfiguration "$instancesNamesFile" || exit 1

if [ ! -d $outputsDirThisRun ]; then
    message "$(colour brown "Creating directory to hold the results of creating instances:")"
    message "$outputsDirThisRun"
    mkdir -p $outputsDirThisRun
fi

check_created_resources_results_files "DO-NOT-EXIST" "INSTANCE_FILES" "$instancesNamesFile" || { message "$(colour lb "$(basename $0) aborting")"; exit 2; }

# process the tags.txt file if it exists. If so, it has been checked before as to having 2 fields (keyName keyValue) per line
# only 10 tags (key-value pairs, 20 fields) are processed.

tagsAWS=""
if [ -f $inputsDir/tags.txt ]; then
    TAGS=( `cat $inputsDir/tags.txt` )

    tagsNumber=${#TAGS[@]}
    [[ $tagsNumber > 20 ]] && (( tagsNumber=20 ))

    for (( i = 0; i < $tagsNumber ; i=i+2  ))
    do
	tagsAWS="${tagsAWS}{ Key=${TAGS[$i]}, Value=${TAGS[$i+1]} }, "
    done
fi

# get the resourcesIDs.txt values for configuration - they have been checked and validated before
resource_image_id=`awk -F " "           'tolower($1) == "imageid"         {print $2}' $inputsDir/resourcesIDs.txt`
resource_instance_type=`awk -F " "      'tolower($1) == "instancetype"    {print $2}' $inputsDir/resourcesIDs.txt`
resource_security_group_ids=`awk -F " " 'tolower($1) == "securitygroupid" {print $2}' $inputsDir/resourcesIDs.txt`
resource_subnet_id=`awk -F " "          'tolower($1) == "subnetid"	  {print $2}' $inputsDir/resourcesIDs.txt`

instancesNames=( `cat $instancesNamesFile` )  ### mapfile instancesNamesMapfile < $instancesNamesFile ### does not work in macOS

for instanceFullName in ${instancesNames[@]}
do
    instance=${instanceFullName%-src*}		### get rid of suffix "-srcAMInn.." if it exists
    loginkey=login-key-$instance

    aws ec2 run-instances --image-id  $resource_image_id   --instance-type  $resource_instance_type \
	--key-name $loginkey  \
	--security-group-ids $resource_security_group_ids \
	--subnet-id $resource_subnet_id \
	--tag-specifications \
	"ResourceType=instance, Tags=[{Key=Name, Value=$instanceFullName}, $tagsAWS ]" >  $outputsDirThisRun/$instance.txt 2>&1
    
    if [ $? -eq 0 ]; then
	message "`colour gl Success` creating `colour bl instance:` $instance"  $outputsDirThisRun/$instance.txt
    else
	message "`colour red Error` ($?) creating `colour bl instance:` $instance"  $outputsDirThisRun/$instance.txt
	exit 2
    fi
done
exit 0
