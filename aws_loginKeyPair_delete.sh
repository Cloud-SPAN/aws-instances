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
