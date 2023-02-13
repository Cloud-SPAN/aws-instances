#!/bin/bash
# deletes login key pairs
#
# instance id suffix to use: srcCSGC-AMI04: CSGC-AMI-04-UsrKeyMng-NoAuthKeys
# Output:  in directorty $outputsDirThisRun
#------------------------------------------------
source colours_functions.sh	 # to add colour to some messages

# instancesNamesFile=${1##*/}	 #; delete everything (*) up to last / and return the rest = (`basename $1`) but more efficient
instancesNamesFile=${1}		 #; actually need the full path ; echo instancesNameFile: $instancesNamesFile

# general inputs directory	 # return what is left after eliminating the last / and any character following it
inputsDir=${1%/*}		 # echo inputsdir: $inputsDir
				 
# general outputs directory	 # note that some data in the outpus directory (from creating instances) is needed as input
outputsDir=${1%/inputs*}/outputs # return what is left after eliminating the second to last / and "inputs" and any character
				 # following "inputs", then adds "/outputs" # echo outputsdir: $outputsDir

# directory for the results of creating login keys (pairs) labelled with the date and time
outputsDirThisRun=${outputsDir}/login-keys-delete-output`date '+%Y%m%d.%H%M%S'`

echo -e "`colour cyan "Deleting login key pairs:"`"

if [ ! -d $outputsDirThisRun ]; then
    echo -e "$(colour brown "Creating directory to hold the results of deleting the login keys:")"
    echo $outputsDirThisRun
    mkdir -p $outputsDirThisRun
fi

instancesNames=( `cat $instancesNamesFile` )

for instance in ${instancesNames[@]}
do
    loginkey=${instance%-src*}
    loginkey="login-key-${loginkey%-gc}"
    #continue
    aws ec2 delete-key-pair --key-name $loginkey  >  $outputsDirThisRun/$loginkey.txt	     
    if [ $? -eq 0 ]; then
	echo -e "`colour gl Success` deleting `colour bl login-key:` $loginkey; `colour bl "instance:"` ${instance%-src*}"
	echo -e "`colour gl Success` deleting `colour bl login-key:` $loginkey; `colour bl "instance:"` ${instance%-src*}" >> $outputsDirThisRun/$loginkey.txt
    else
	echo -e "`colour red Error` ($?) deleting `colour bl login-key:` $loginkey; `colour bl "instance:"` ${instance%-src*}"
	echo -e "`colour red Error` ($?) deleting `colour bl login-key:` $loginkey; `colour bl "instance:"` ${instance%-src*}" >> $outputsDirThisRun/$loginkey.txt
    fi
done
exit 0

: <<COMMENTS
- ref
  https://docs.aws.amazon.com/cli/latest/reference/ec2/delete-key-pair.html

- example:
  aws ec2 delete-key-pair --key-name MyKeyPair

- Synopsis:
  delete-key-pair
--key-name <value>
[--dry-run | --no-dry-run]
[--key-type <value>]
[--tag-specifications <value>]
[--cli-input-json <value>]
[--generate-cli-skeleton <value>]

echo tag_name_key=${tags[0]}		# 
echo tag_name_value=${tags[1]}	# redefined below but better to read them as the others
echo tag_group_key=${tags[2]}
echo tag_group_value=${tags[3]}
echo tag_project_key=${tags[4]}
echo tag_project_value=${tags[5]}
echo tag_status_key=${tags[6]}
echo tag_status_value=${tags[7]}
echo tag_pushedby_key=${tags[8]}
echo tag_pushedby_value=${tags[9]}
echo tag_definedin_key=${tags[10]}
echo tag_definedin_value=${tags[11]}

COMMENTS
