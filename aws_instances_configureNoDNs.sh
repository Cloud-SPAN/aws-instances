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

#check_instancesNamesFile_format "$(basename $0)" "$instancesNamesFile" || exit 1
#check_created_resources_results_files "DO-EXIST" "$(basename $0)" "$outputsDir/instances-creation-output" "$instancesNamesFile" || exit 1
### tests exit 1

instancesNames=( `cat $instancesNamesFile` )

for instance in ${instancesNames[@]}
do
    instance=${instance%-src*}
    keyfile=${instance}
    message "$(colour lb "Configuring  $instance:")"

    instanceCreationFile="$outputsDir/instances-creation-output/$instance.txt"
    instanceID=`awk -F " " '$1 == "\"InstanceId\":" {print substr($2, 2, length($2) -3)}' $instanceCreationFile`
    message "instanceID $instanceID"
    
    message "Checking ${instance%-src*} is running: "
    while true 
    do
	echo -n "."
	instanceState=`aws ec2 describe-instance-status --instance-id $instanceID | awk -F " " '$1 == "\"Code\":" {print substr($2, 1, length($2) -1)}'`
	if [[ $instanceState == "16" ]]; then
	    #16 is running: https://awscli.amazonaws.com/v2/documentation/api/latest/reference/ec2/describe-instance-status.html
	    message " - instanceState $instanceState (running)"; break ;
	else
	    sleep 4
	fi
    done

    ### THIS ONE aws ec2 describe-instances --instance-ids  "i-0bab3619a50ac88f7" --query 'Reservations[*]. Instances[*]. PublicIpAddress' --output text
    ### OR THIS ONE aws ec2 describe-instances --instance-ids  "i-0bab3619a50ac88f7" --query 'Reservations[*]. Instances[*]. PublicDnsName' --output text  
    instanceHostName=`aws ec2 describe-instances --instance-ids  "$instanceID" --query 'Reservations[*]. Instances[*]. PublicDnsName' --output text`
    message "Getting the generic, public instanceHostName `colour bl "$instanceHostName"` assigned by AWS."
    
    message "Cleaning any previous keys associated with the instance $instance hostname: $instanceHostName"
    message "ssh-keygen -f $HOME/.ssh/known_hosts -R $instanceHostName"
    ### ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$instance.$hostZone"   ### doesn't work if instance names has capital letters
    ssh-keygen -f "$HOME/.ssh/known_hosts" -R "${instanceHostName,,}"   ### works w all lowercase: ${var,,}

    message "`colour bl "Please wait for SSH server (you may see a few 'Connection timed out/Connection refused' messages)"`";    
    message "ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -i $loginKeysDir/login-key-$keyfile.pem ubuntu@$instance.$hostZone \"echo \"Hi from Ubuntu user. Bye.\"; exit \""
    ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -i $loginKeysDir/login-key-$keyfile.pem ubuntu@$instanceHostName "echo \"Hi from Ubuntu user. Bye.\"; exit "
    sshON=$?
    
    while [[ sshON -ne 0 ]]
    do
	sleep 3
	ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -i $loginKeysDir/login-key-$keyfile.pem ubuntu@$instanceHostName "echo \"Hi from Ubuntu user. Bye.\"; exit "
	sshON=$?
	if [[ $sshON -eq 0 ]]; then
	    message "`colour greenlight "SSH server is ready"`";
	    break ;
	fi
    done
    #continue
    message "Setting up access keys."
    ssh -i $loginKeysDir/login-key-$keyfile.pem ubuntu@$instanceHostName /home/ubuntu/bin/usersAccessKeys-setup-MAIN.sh
    
    message "ssh return code: $?"
    message "\nUpdating the hostname to $instanceHostName"
    ssh -i $loginKeysDir/login-key-$keyfile.pem ubuntu@$instanceHostName "sudo hostnamectl set-hostname $instanceHostName"

    message "Logging as $(colour lg csuser)"
    ssh -o StrictHostKeyChecking=no -i $loginKeysDir/login-key-$keyfile.pem csuser@$instanceHostName "echo \"Hi from CSUSER at $instance\"; ls; echo \"Bye.\";  exit "
    message " "
    ###ssh -i $loginKeysDir/login-key-$keyfile.pem csuser@$instance.$hostZone "echo \"Hi from CSUSER at $instance\"; ls; echo \"Bye.\";  exit "
done
exit 0
