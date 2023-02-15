#!/bin/bash
# create (run!?) AWS instances based on specified configuration and files and the following reference
# https://awscli.amazonaws.com/v2/documentation/api/latest/reference/ec2/run-instances.html
#------------------------------------------------
source colours_msg_functions.sh	 # to add colour to some messages

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
instancesNamesFile=${1}		 #; actually need the full path ; echo instancesNameFile: $instancesNamesFile

# general inputs directory	 # return what is left after eliminating the last / and any character following it
inputsDir=${1%/*}		 # echo inputsdir: $inputsDir
				 
# general outputs directory	 # note that some data in the outpus directory (from creating instances) is needed as input
outputsDir=${1%/inputs*}/outputs # return what is left after eliminating the second to last / and "inputs" and any character
				 # following "inputs", then adds "/outputs" # echo outputsdir: $outputsDir

# directory for the results of creating instances, labelled with the date and time
outputsDirThisRun=${outputsDir}/instances-creation-output	# we may add the date later `date '+%Y%m%d.%H%M%S'`

message "$(colour cyan "Creating instances:")"

if [ ! -d $outputsDirThisRun ]; then
    message "$(colour brown "Creating directory to hold the results of creating instances:")"
    message $outputsDirThisRun
    mkdir -p $outputsDirThisRun
fi

tags=( `cat $inputsDir/tags.txt` )   # mapfile tags < $inputsDir/tags.txt is more difficult: two items per element
# we just need the tag values: 1, 3, 5, .. (not the tag key names: 0, 2, 6 ..) 
tag_name_value=${tags[1]}	  # redefined below but better to read them as the others
tag_group_value=${tags[3]}
tag_project_value=${tags[5]}
tag_status_value=${tags[7]}
tag_pushedby_value=${tags[9]}
tag_definedin_value=${tags[11]}

resources=( `cat $inputsDir/resourcesIDs.txt` )
# we just need the tag values: 1, 3, 5, .. (not the tag key names: 0, 2, 6 ..)
resource_image_id=${resources[1]}
resource_instance_type=${resources[3]}
resource_security_group_ids=${resources[5]}
resource_subnet_id=${resources[7]}

#mapfile instancesNamesMapfile < $instancesNamesFile   ### does not work in macOS
instancesNames=( `cat $instancesNamesFile` )

for instance in ${instancesNames[@]}
do
    logkeyend=${instance%-src*}
    logkeyend=${logkeyend%-gc}
    #message "$instance  login-key-$logkeyend"
    #continue
    aws ec2 run-instances --image-id  $resource_image_id   --instance-type  $resource_instance_type \
	--key-name "login-key-${logkeyend}"  \
	--security-group-ids $resource_security_group_ids \
	--subnet-id $resource_subnet_id --tag-specifications \
	"ResourceType=instance, Tags=[{Key=Name,	Value=$instance}, \
    				    {Key=name,		Value=${instance,,}}, \
    				    {Key=group, Value=$tag_group_value}, \
    				    {Key=project, Value=$tag_project_value}, \
    				    {Key=status, Value=$tag_status_value}, \
    				    {Key=pushed_by, Value=$tag_pushedby_value}, \
				    {Key=defined_in, Value=$tag_definedin_value},  \
				  ]" >  $outputsDirThisRun/$instance.txt 2>&1
    ## above in "Value=${instance,,}}", ${var,,} converts everything to lowercase as required by York tagging
    if [ $? -eq 0 ]; then
	message "`colour gl Success` creating `colour bl instance:` ${instance%-src*}"  $outputsDirThisRun/$instance.txt
    else
	message "`colour red Error` ($?) creating `colour bl instance:` ${instance%-src*}"  $outputsDirThisRun/$instance.txt
    fi
done
