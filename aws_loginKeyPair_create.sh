#!/usr/bin/env bash
# creates login key pairs to use when creating instances
#------------------------------------------------
source colour_utils_functions.sh	 # to add colour to some messages

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

message "\n$(colour cyan "Creating login keys:")"

check_theScripts_csconfiguration "$instancesNamesFile" || exit 1

if [ ! -d $outputsDirThisRun ]; then
    message "$(colour brown "Creating directory to hold the results of creating the login keys:")"
    message "$outputsDirThisRun"
    mkdir -p $outputsDirThisRun
fi
if [ ! -d $outputsDir/login-keys ]; then
    message "$(colour brown "Creating directory to hold the login keys:")"
    message "$outputsDir/login-keys"
    mkdir -p $outputsDir/login-keys
fi

check_created_resources_results_files "DO-NOT-EXIST" "LOGIN_KEY_FILES" "$instancesNamesFile" || { message "$(colour lb "$(basename $0) aborting")"; exit 1; }

# process the tags.txt file if it exists. If so, it has been checked before as to having 2 fields (keyName keyValue) per line
# only 10 tags (key-value pairs, 20 fields) are processed.

tagsAWS=""
if [ -f $inputsDir/tags.txt ]; then
    TAGS=( `cat $inputsDir/tags.txt` )	
    tagsNumber=${#TAGS[@]}
    [[ $tagsNumber > 20 ]] && (( tagsNumber=20 ))
    
    tagsAWS=""
    
    for (( i = 0; i < $tagsNumber ; i=i+2  ))
    do
	tagsAWS="${tagsAWS}{ Key=${TAGS[$i]}, Value=${TAGS[$i+1]} }, "
    done
fi

instancesNames=( `cat $instancesNamesFile` )

for instanceFullName in ${instancesNames[@]}
do
    instance=${instanceFullName%-src*}		### get rid of suffix "-srcAMInn.." if it exists
    loginkey="login-key-$instance"
    
    ### aws ec2 create-key-pair --dry-run --key-name ..
    aws ec2 create-key-pair --key-name $loginkey --key-type rsa  --tag-specifications \
    	"ResourceType=key-pair, Tags=[ {Key=Name, Value=$loginkey}, $tagsAWS ]" > $outputsDirThisRun/$loginkey.txt 2>&1

    if [ $? -eq 0 ]; then
	message "`colour gl Success` creating `colour bl login-key:` $loginkey; `colour bl "instance:"` $instance" $outputsDirThisRun/$loginkey.txt
	
	# format the key as expected by macOS machines
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
	END {
		print "-----END RSA PRIVATE KEY-----"
	}
	' $outputsDirThisRun/$loginkey.txt > $outputsDir/login-keys/$loginkey.pem
	
	# and change permissions
	chmod 700 $outputsDir/login-keys/$loginkey.pem

    else
	message "`colour red Error` ($?) creating `colour bl login-key:` $loginkey; `colour bl "for instance:"` ${instance%-src*}" $outputsDirThisRun/$loginkey.txt
	exit 2
    fi
done
exit 0
