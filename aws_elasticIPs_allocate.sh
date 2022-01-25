#!/bin/bash
# allocates static, elastic IP addresses
#
#--------------------------------
source colours_functions.sh	 # to add colour to some messages

# instancesNamesFile=${1##*/}	 #; delete everything (*) up to last / and return the rest = (`basename $1`) but more efficient
instancesNamesFile=${1}		 #; actually need the full path ; echo instancesNameFile: $instancesNamesFile

# general inputs directory	 # return what is left after eliminating the last / and any character following it
inputsDir=${1%/*}		 # echo inputsdir: $inputsDir
				 
# general outputs directory	 # note that some data in the outpus directory (from creating instances) is needed as input
outputsDir=${1%/inputs*}/outputs # return what is left after eliminating the second to last / and "inputs" and any character
				 # following "inputs", then adds "/outputs" # echo outputsdir: $outputsDir

# directory for the results of creating instances, labelled with the date and time
outputsDirThisRun=${outputsDir}/ip-addresses-allocation-output   	# we may add the date later `date '+%Y%m%d.%H%M%S'`

echo -e "`colour cyan "Allocating IP addresses:"`"

if [ ! -d $outputsDirThisRun ]; then
    echo -e "$(colour brown "Creating directory to hold the results of allocation elastic IP adresses:")"
    echo $outputsDirThisRun
    mkdir -p $outputsDirThisRun
fi

tags=( `cat $inputsDir/yorkTags.txt` )   # mapfile tags < $inputsDir/yorkTags.txt is more difficult: two items per element
# we just need the tag values: 1, 3, 5, .. (not the tag key names: 0, 2, 6 ..) 
tag_name_value=${tags[1]}	  # redefined below but better to read them as the others
tag_group_value=${tags[3]}
tag_project_value=${tags[5]}
tag_status_value=${tags[7]}
tag_pushedby_value=${tags[9]}
tag_definedin_value=${tags[11]}

mapfile instancesNames < $instancesNamesFile

for instance in ${instancesNames[@]}
do
    #aws ec2 allocate-address  --dry-run --domain vpc --tag-specifications \\
    eipResultsFileName="elastic-IPaddress-for-${instance%-srcCSGC-AMI04}"
    #echo Allocating $eip
    #continue
    aws ec2 allocate-address --domain vpc --tag-specifications \
    "ResourceType=elastic-ip,Tags=[ {Key=Name,		Value=$eipResultsFileName}, \
    				    {Key=name,		Value=${eipResultsFileName,,}}, \
    				    {Key=group,		Value=$tag_group_value}, \
    				    {Key=project,	Value=$tag_project_value}, \
    				    {Key=status,	Value=$tag_status_value}, \
    				    {Key=pushed_by,	Value=$tag_pushedby_value}, \
				    {Key=defined_in,	Value=$tag_definedin_value},  \
				  ]" > $outputsDirThisRun/$eipResultsFileName.txt
    ## above in "Value=${eipResultsFileName,,}}", ${var,,} converts everything to lowercase as required by York tagging
    if [ $? -eq 0 ]; then
	echo -e "`colour gl Success` allocating `colour bl "elastic IP address for instance:"` ${instance%-srcCSGC-AMI04}"
	echo -e "`colour gl Success` allocating `colour bl "elastic IP address for instance:"` ${instance%-srcCSGC-AMI04}" >> $outputsDirThisRun/$eipResultsFileName.txt
    else
	echo -e "`colour red Error` ($?) creating `colour bl "elastic IP address for instance:"` ${instance%-srcCSGC-AMI04}"
	echo -e "`colour red Error` ($?) creating `colour bl "elastic IP address for instance:"` ${instance%-srcCSGC-AMI04}" >> $outputsDirThisRun/$eipResultsFileName.txt
    fi
done
