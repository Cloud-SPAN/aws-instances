#!/bin/bash
# create (run!?) AMI instances
# NB minimum parameters to specify are:
# --key-name		a must: the specified key is injected into the ubuntu user ~/.ssh/authorized_keys
# --image-id		a must: this is the virtual machine: CSGC-AMI-04-UsrKeyMng-NoAuthKeys (ami-id ami-05be6a5ff8a9091e0)
# --instance-type	a must: this is the hardware t2.small
# --security-group
# --subnet-ids
#
# and for cloud-span instances (like Data Carpentry's)
# --security-group-ids <value>			CSGC Security Group, id Security group ID sg-0771b67fde13b3899
#
# NB ResourceType=instance could instead be 
#    ResourceType=volume			# do the dry run
# vpc-01e55c4a61cab7cd1
#------------------------------------------------
source colours_functions.sh	 # to add colour to some messages

# instancesNamesFile=${1##*/}	 #; delete everything (*) up to last / and return the rest = (`basename $1`) but more efficient
instancesNamesFile=${1}		 #; actually need the full path ; echo instancesNameFile: $instancesNamesFile

# general inputs directory	 # return what is left after eliminating the last / and any character following it
inputsDir=${1%/*}		 # echo inputsdir: $inputsDir
				 
# general outputs directory	 # note that some data in the outpus directory (from creating instances) is needed as input
outputsDir=${1%/inputs*}/outputs # return what is left after eliminating the second to last / and "inputs" and any character
				 # following "inputs", then adds "/outputs" # echo outputsdir: $outputsDir

# directory for the results of creating instances, labelled with the date and time
outputsDirThisRun=${outputsDir}/instances-creation-output	# we may add the date later `date '+%Y%m%d.%H%M%S'`

echo -e "`colour cyan "Creating instances:"`"

if [ ! -d $outputsDirThisRun ]; then
    echo -e "$(colour brown "Creating directory to hold the results of creating instances:")"
    echo $outputsDirThisRun
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

mapfile instancesNames < $instancesNamesFile

for instance in ${instancesNames[@]}
do
    logkeyend=${instance%-src*}
    logkeyend=${logkeyend%-gc}
    #echo "$instance  login-key-$logkeyend"
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
	echo -e "`colour gl Success` creating `colour bl instance:` ${instance%-src*}"
	echo -e "`colour gl Success` creating `colour bl instance:` ${instance%-src*}" >> $outputsDirThisRun/$instance.txt
    else
	echo -e "`colour red Error` ($?) creating `colour bl instance:` ${instance%-src*}"
	echo -e "`colour red Error` ($?) creating `colour bl instance:` ${instance%-src*}" >> $outputsDirThisRun/$instance.txt
    fi
done

# the following is just comments:
: <<'END_OF_COMMENTS'
ec2-54-216-187-245.eu-west-1.compute.amazonaws.com

- ref
  https://awscli.amazonaws.com/v2/documentation/api/latest/reference/ec2/run-instances.html
  https://docs.aws.amazon.com/cli/latest/reference/ec2/run-instances.html
- parameters, all of them are after the examples
- examples:
1)  
aws ec2 run-instances --image-id ami-0abcdef1234567890  --instance-type t2.micro \
    --key-name MyKeyPair

Example 4: To launch an instance and add tags on creation
aws ec2 run-instances \
    --image-id ami-0abcdef1234567890 \
    --instance-type t2.micro \
    --count 1 \
    --subnet-id subnet-08fc749671b2d077c \
    --key-name MyKeyPair \
    --security-group-ids sg-0b0384b66d7d692f9 \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=webserver,Value=production}]' 'ResourceType=volume,Tags=[{Key=cost-center,Value=cc123}]'

- PARAMETERS:
run-instances
[--block-device-mappings <value>]
[--image-id <value>]
[--instance-type <value>]
[--ipv6-address-count <value>]
[--ipv6-addresses <value>]
[--kernel-id <value>]
[--key-name <value>]
[--monitoring <value>]
[--placement <value>]
[--ramdisk-id <value>]
[--security-group-ids <value>]
[--security-groups <value>]
[--subnet-id <value>]
[--user-data <value>]
[--additional-info <value>]
[--client-token <value>]
[--disable-api-termination | --enable-api-termination]
[--dry-run | --no-dry-run]
[--ebs-optimized | --no-ebs-optimized]
[--iam-instance-profile <value>]
[--instance-initiated-shutdown-behavior <value>]
[--network-interfaces <value>]
[--private-ip-address <value>]
[--elastic-gpu-specification <value>]
[--elastic-inference-accelerators <value>]
[--tag-specifications <value>]
[--launch-template <value>]
[--instance-market-options <value>]
[--credit-specification <value>]
[--cpu-options <value>]
[--capacity-reservation-specification <value>]
[--hibernation-options <value>]
[--license-specifications <value>]
[--metadata-options <value>]
[--enclave-options <value>]
[--count <value>]
[--secondary-private-ip-addresses <value>]
[--secondary-private-ip-address-count <value>]
[--associate-public-ip-address | --no-associate-public-ip-address]
[--cli-input-json <value>]
[--generate-cli-skeleton <value>]
END_OF_COMMENTS
