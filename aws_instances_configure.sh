#!/usr/bin/env bash
# configures each instance so that users other than sudo user can login using the private key of sudo user 
#-------------------------------------
source colour_utils_functions.sh	 # to add colour to some messages

case $# in
    1) ;; # message "$(colour gl $(basename $0)) is configuring the instances specified in input file $(colour bl $1)";;
    0|*) ### display message on use
	message "\n$(colour gl $(basename $0)) configures instances to be accessible by the $(colour lb csuser) with ssh.

$(colour bl "Usage:                $(basename $0) instancesNamesFile")

 - provide the full or relative path to the file containing the names of the instances to configure.
 - example:  $(colour bl "$(basename $0)  courses/genomics01/")$(colour r inputs)$(colour bl /instancesNames.txt)
 - the $(colour bl inputs) directory must be specified as such and inside one or more directories of your choice.
 - this is the last step in creating instances --- $(colour bl check) all the the previous steps were successful 
   for each instance before running $(colour lb $(basename $0)) on its own.\n"
	exit 2;; 
esac

# instancesNamesFile=${1##*/}	 #; delete everything (*) up to last / and return the rest = (`basename $1`) but more efficient
instancesNamesFile=${1}		 #; actually need the full path ; message "instancesNameFile: $instancesNamesFile"

# general inputs directory	 # return what is left after eliminating the last / and any character following it
inputsDir=${1%/*}		 
				 
# general outputs directory	 # note that some data in the outpus directory (from creating instances) is needed as input
outputsDir=${1%/inputs*}/outputs # return what is left after eliminating the second to last / and "inputs" and any character
				 # following "inputs", then adds "/outputs"
# get the domain name suffix (hostZone): cloud-span.aws.york.ac.uk
hostZone=`awk -F " " '$1 == "hostZone" {print $2}' $inputsDir/resourcesIDs.txt`
loginKeysDir=$outputsDir/login-keys

message "\n$(colour cyan "Configuring instances (login keys and hostnames):")"

check_instancesNamesFile_format "$(basename $0)" "$instancesNamesFile" || exit 1
check_created_resources_results_files "DO-EXIST" "$(basename $0)" "$outputsDir/instances-creation-output" "$instancesNamesFile" || exit 1
### tests exit 1

instancesNames=( `cat $instancesNamesFile` )

for instance in ${instancesNames[@]}
do
    instance=${instance%-src*}
    keyfile=${instance}
    message "$(colour lb "Configuring  $instance:")"

    # we need to ensure the domain is available before issuing any ssh; otherwise will get Connection refused port 22 or similar
    domainNameCreationFile="$outputsDir/domain-names-creation-output/domain-name-create-${instance}.txt"
    domainNameChangeID=`awk -F " " '$1 == "\"Id\":" {print substr($2, 2, length($2) -3)}' $domainNameCreationFile`
    
    message "Checking $instance.$hostZone is reachable: "

    ### tmpfile="/tmp/domainName${instance}-status.txt"
    while true 
    do
	echo -n "."
	### worked fine but better withoug /tmpfile because in windows users it will not work.
	### aws route53  get-change --id $domainNameChangeID > $tmpfile	# domainNameChangeID = /change/C3QYC83OA0KX5K
	### domainStatus=`awk -F " " '$1 == "\"Status\":" {print substr($2, 2, length($2) -3)}' $tmpfile`
	domainStatus=`aws route53  get-change --id $domainNameChangeID | awk -F " " '$1 == "\"Status\":" {print substr($2, 2, length($2) -3)}'`
	if [[ $domainStatus == "INSYNC" ]]; then
	    #INSYNC is reachable: https://aws.amazon.com/premiumsupport/knowledge-center/simple-resource-record-route53-cli/
	    message " : status $domainStatus (reachable)";
	    break ;
	else
	    sleep 1
	fi
    done

    message "Cleaning any previous keys associated with the instance $instance.$hostZone"
    message "ssh-keygen -f $HOME/.ssh/known_hosts -R $instance.$hostZone"
    ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$instance.$hostZone"

    message "`colour bl "Please wait for SSH server (you may see a few 'Connection timed out/Connection refused' messages)"`";
    ### ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no -i $loginKeysDir/login-key-$keyfile.pem ubuntu@$instance.$hostZone "echo \"Hi from Ubuntu user. Bye.\"; exit "
    message "ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -i $loginKeysDir/login-key-$keyfile.pem ubuntu@$instance.$hostZone \"echo \"Hi from Ubuntu user. Bye.\"; exit \""
    ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -i $loginKeysDir/login-key-$keyfile.pem ubuntu@$instance.$hostZone "echo \"Hi from Ubuntu user. Bye.\"; exit "
    sshON=$?
    
    while [[ sshON -ne 0 ]]
    do
	sleep 3
	###ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no -i $loginKeysDir/login-key-$keyfile.pem ubuntu@$instance.$hostZone "echo \"Hi from Ubuntu user. Bye.\"; exit "
	ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -i $loginKeysDir/login-key-$keyfile.pem ubuntu@$instance.$hostZone "echo \"Hi from Ubuntu user. Bye.\"; exit "
	sshON=$?
	if [[ $sshON -eq 0 ]]; then
	    message "`colour greenlight "SSH server is ready"`";
	    break ;
	fi
    done
    #continue
    message "Setting up access keys."
    ssh -i $loginKeysDir/login-key-$keyfile.pem ubuntu@$instance.$hostZone /home/ubuntu/bin/usersAccessKeys-setup-MAIN.sh
    
    message "ssh return code: $?"
    message "\nUpdating the hostname to $instance.$hostZone"
    ssh -i $loginKeysDir/login-key-$keyfile.pem ubuntu@$instance.$hostZone "sudo hostnamectl set-hostname $instance.$hostZone"

    message "Logging as $(colour lg csuser)"
    ssh -o StrictHostKeyChecking=no -i $loginKeysDir/login-key-$keyfile.pem csuser@$instance.$hostZone "echo \"Hi from CSUSER at $instance\"; ls; echo \"Bye.\";  exit "
    message " "
    ###ssh -i $loginKeysDir/login-key-$keyfile.pem csuser@$instance.$hostZone "echo \"Hi from CSUSER at $instance\"; ls; echo \"Bye.\";  exit "
done
exit 0
