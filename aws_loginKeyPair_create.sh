#!/usr/bin/env bash
# creates login key pairs to use when creating instances
# NB minimum parameters to specify are:
# --key-name		a must: the specified key is injected into the ubuntu user ~/.ssh/authorized_keys
# --image-id		a must: this is the virtual machine: CSGC-AMI-04-UsrKeyMng-NoAuthKeys (ami-id ami-05be6a5ff8a9091e0)
# --instance-type	a must: this is the hardware t2.small
#
# instance id suffix to use: srcCSGC-AMI04: CSGC-AMI-04-UsrKeyMng-NoAuthKeys
# Output:  in directorty $outputsDirThisRun
#------------------------------------------------
source colours_msg_functions.sh	 # to add colour to some messages

case $# in
    1) ;; ### message "$(colour gl $(basename $0)) is login keys for instances specified in input file $(colour bl $1)";;
    0|*) ### display message on use
	message "\n$(colour gl $(basename $0)) creates the login keys for the instances specified as below.

$(colour bl "Usage:                $(basename $0) instancesNamesFile")

 - provide the full or relative path to the file containing the names of the instances to which 
   to create login keys.
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

# directory for the results of creating login keys (pairs) labelled with the date and time
outputsDirThisRun=${outputsDir}/login-keys-creation-output		# to add later perhaps `date '+%Y%m%d.%H%M%S'`

message "`colour cyan "Creating login keys:"`"

if [ ! -d $outputsDirThisRun ]; then
    message "$(colour brown "Creating directory to hold the results of creating the login keys:")"
    message $outputsDirThisRun
    mkdir -p $outputsDirThisRun
fi


if [ ! -d $outputsDir/login-keys ]; then
    message "$(colour brown "Creating directory to hold the login keys:")"
    message $outputsDir/login-keys
    mkdir -p $outputsDir/login-keys
fi

tags=( `cat $inputsDir/tags.txt` )   # mapfile tags < $workdir/inputs/tags.txt more difficult: two items per element
# we just need values: 1, 3, 5, .. (not the key names: 0, 2, 6 ..) 
tag_name_value=${tags[1]}	# redefined below but better to read them as the others
tag_group_value=${tags[3]}
tag_project_value=${tags[5]}
tag_status_value=${tags[7]}
tag_pushedby_value=${tags[9]}
tag_definedin_value=${tags[11]}

instancesNames=( `cat $instancesNamesFile` )

for instance in ${instancesNames[@]}
do
    loginkey=${instance%-src*}
    loginkey="login-key-${loginkey%-gc}"
    message "Creating $loginkey"
    #continue
    #aws ec2 create-key-pair --dry-run --key-name $loginkey --key-type rsa  --tag-specifications
    aws ec2 create-key-pair --key-name $loginkey --key-type rsa  --tag-specifications \
	"ResourceType=key-pair, Tags=[{Key=Name, Value=$loginkey}, {Key=name, Value=${loginkey,,}}, \
    				    {Key=group, Value=$tag_group_value}, \
    				    {Key=project, Value=$tag_project_value}, \
    				    {Key=status, Value=$tag_status_value}, \
    				    {Key=pushed_by, Value=$tag_pushedby_value}, \
				    {Key=defined_in, Value=$tag_definedin_value},  \
				  ]" > $outputsDirThisRun/$loginkey.json
    ## above in "Value=${loginkey,,}}", ${var,,} converts everything to lowercase as required by York tagging
    if [ $? -eq 0 ]; then
	message "`colour gl Success` creating `colour bl login-key:` $loginkey; `colour bl "instance:"` ${instance%-src*}" $outputsDirThisRun/$loginkey.json
	# format the key as expected by macOS machines
	# was this way: awk -f loginKey_extract.awk $outputsDirThisRun/$loginkey.json > $outputsDir/login-keys/$loginkey.pem
	# but better her:
	awk '
	BEGIN {
	    # three \\\ just to escape \n
	    FS="\\\\n" ;
	    print "-----BEGIN RSA PRIVATE KEY-----"
	}					
	/BEGIN RSA PRIVATE KEY/ {
    		 # we are skipping the first (i=1) and the last (NF) fields because
		 # there we have "..BEGIN R.." and ".. END R.." along with sth else. 
    		 for (i = 2; i < NF; i++) {
	    	     print $i
    	 	 }
	}
	END{
		print "-----END RSA PRIVATE KEY-----"
	}
	' $outputsDirThisRun/$loginkey.json > $outputsDir/login-keys/$loginkey.pem
	
	# and change permissions
	chmod 700 $outputsDir/login-keys/$loginkey.pem

    else
	message "`colour red Error` ($?) creating `colour bl login-key:` $loginkey; `colour bl "for instance:"` ${instance%-src*}" $outputsDirThisRun/$loginkey.json
    fi
done
exit 0
