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

instancesNamesFile=${1}		 #; actually need the full path ; message "instancesNameFile: $instancesNamesFile"

# general inputs directory	 # return what is left after eliminating the last / and any character following it
inputsDir=${1%/*}		 
				 
# general outputs directory	 # note that some data in the outpus directory (from creating instances) is needed as input
outputsDir=${1%/inputs*}/outputs # return what is left after eliminating the second to last / and "inputs" and any character
				 # following "inputs", then adds "/outputs"

message "\n$(colour cyan "Configuring instances (login keys and hostnames):")"

check_theScripts_csconfiguration "$instancesNamesFile" || exit 1

check_created_resources_results_files "DO-EXIST" "INSTANCE_FILES" "$instancesNamesFile" || { message "\n$(colour lb "$(basename $0) aborting")"; exit 1; }

hostZone=`awk -F " " '$1 == "hostZone" {print $2}' $inputsDir/resourcesIDs.txt`
loginKeysDir=$outputsDir/login-keys

outputsDirThisRun=${outputsDir}/instances-configuration-output`date '+%Y%m%d.%H%M%S'`

if [ ! -d $outputsDirThisRun ]; then
    message "$(colour brown "Creating directory to hold the results of configuring instances:")"
    message $outputsDirThisRun
    mkdir -p $outputsDirThisRun
fi

instancesNames=( `cat $instancesNamesFile` )

for instanceFullName in ${instancesNames[@]}
do
    instance=${instanceFullName%-src*}		### get rid of suffix "-srcAMInn.." if it exists
    resultsFile=$outputsDirThisRun/configuration-$instance.txt

    #########################################################
    ################   DOMAIN_NAMES option   ################
    if [ -f $inputsDir/.csconfig_DOMAIN_NAMES.txt ]; then
	message "$(colour lb "Configuring instance $instance with DOMAIN NAME")" $resultsFile
	
	domainNameChangeID=`awk -F " " '$1 == "\"Id\":" {print substr($2, 2, length($2) -3)}' $outputsDir/domain-names-creation-output/domain-name-create-$instance.txt`
	
	message "Checking $instance.$hostZone is reachable: " $resultsFile
	
	while true 
	do
	    echo -n "."
	    domainStatus=`aws route53  get-change --id $domainNameChangeID | awk -F " " '$1 == "\"Status\":" {print substr($2, 2, length($2) -3)}'`
	    if [[ $domainStatus == "INSYNC" ]]; then
		#INSYNC is reachable: https://aws.amazon.com/premiumsupport/knowledge-center/simple-resource-record-route53-cli/
		message " : domain name status $domainStatus (reachable)";
		break ;
	    else
		sleep 2
	    fi
	done
	
	message "Cleaning any previous keys associated with $instance.$hostZone"  $resultsFile
	message "ssh-keygen -f \"$HOME/.ssh/known_hosts\" -R \"${instance,,}.${hostZone,,}\"" $resultsFile
	### ssh-keygen below works well only with all lowercase for instance and hostZone: ${var,,}
	ssh-keygen -f "$HOME/.ssh/known_hosts" -R "${instance,,}.${hostZone,,}"  >> $resultsFile 2>&1
	
	message "`colour bl "Please wait for SSH server (you may see a few 'Connection timed out/Connection refused' messages)"`";
	message "ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -i $loginKeysDir/login-key-$instance.pem ubuntu@$instance.$hostZone \"echo \"Hi from Ubuntu user. Bye.\"; exit \"" $resultsFile
	
	ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -i $loginKeysDir/login-key-$instance.pem ubuntu@$instance.$hostZone "echo \"Hi from Ubuntu user. Bye.\"; exit "
	
	sshON=$?
	while [[ sshON -ne 0 ]]
	do
	    sleep 3
	    ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -i $loginKeysDir/login-key-$instance.pem ubuntu@$instance.$hostZone "echo \"Hi from Ubuntu user. Bye.\"; exit "
	    sshON=$?
	    if [[ $sshON -eq 0 ]]; then
		message "`colour greenlight "SSH server is ready"`";
		break ;
	    fi
	done

	message "Setting up access keys." $resultsFile
	message "ssh -i $loginKeysDir/login-key-$instance.pem ubuntu@$instance.$hostZone /home/ubuntu/bin/usersAccessKeys-setup-MAIN.sh" $resultsFile
	
	ssh -i $loginKeysDir/login-key-$instance.pem ubuntu@$instance.$hostZone /home/ubuntu/bin/usersAccessKeys-setup-MAIN.sh
	
	message "\nUpdating the hostname to $instance.$hostZone" $resultsFile
	
	ssh -i $loginKeysDir/login-key-$instance.pem ubuntu@$instance.$hostZone "sudo hostnamectl set-hostname $instance.$hostZone"
	
	message "Logging as $(colour lg csuser)" $resultsFile
	message "ssh -o StrictHostKeyChecking=no -i $loginKeysDir/login-key-$instance.pem csuser@$instance.$hostZone \"echo \"Hi from CSUSER at $instance\"; ls; echo \"Bye.\";  exit \""
	
	ssh -o StrictHostKeyChecking=no -i $loginKeysDir/login-key-$instance.pem csuser@$instance.$hostZone "echo \"Hi from CSUSER at $instance\"; ls; echo \"Bye.\";  exit "
	
	message " "

	############################################################
	################   NO_DOMAIN_NAMES option   ################
    elif [ -f $inputsDir/.csconfig_NO_DOMAIN_NAMES.txt ]; then
	message "$(colour lb "Configuring instance $instance with (NO DOMAIN NAME but) its dynamic IP address:")" $resultsFile
	
	instanceID=`awk -F " " '$1 == "\"InstanceId\":" {print substr($2, 2, length($2) -3)}' $outputsDir/instances-creation-output/$instance.txt`
	
	message "Checking $instance is running: " $resultsFile
	while true 
	do
	    echo -n "."
	    instanceState=`aws ec2 describe-instance-status --instance-id $instanceID | awk -F " " '$1 == "\"Code\":" {print substr($2, 1, length($2) -1)}'`
	    if [[ $instanceState == "16" ]]; then
		#16 is running: https://awscli.amazonaws.com/v2/documentation/api/latest/reference/ec2/describe-instance-status.html
		message " - instanceState $instanceState (running)"; break ;
	    else
		sleep 2
	    fi
	done
	
	instanceHostName=`aws ec2 describe-instances --instance-ids  "$instanceID" --query 'Reservations[*]. Instances[*]. PublicDnsName' --output text`
	instanceIPaddress=`aws ec2 describe-instances --instance-ids  "$instanceID" --query 'Reservations[*]. Instances[*]. PublicIpAddress' --output text`
	
	message "Cleaning any previous keys associated with $instanceHostName ip: $instanceIPaddress" $resultsFile
	message "ssh-keygen -f $HOME/.ssh/known_hosts -R $instanceIPaddress"
	
	ssh-keygen -f "$HOME/.ssh/known_hosts" -R "${instanceIPaddress,,}"  >> $resultsFile 2>&1
	
	message "`colour bl "Please wait for SSH server (you may see a few 'Connection timed out/Connection refused' messages)"`";    
	message "ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -i $loginKeysDir/login-key-$instance.pem ubuntu@$instance.$hostZone \"echo \"Hi from Ubuntu user. Bye.\"; exit \"" $resultsFile
	
	ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -i $loginKeysDir/login-key-$instance.pem ubuntu@$instanceIPaddress "echo \"Hi from Ubuntu user. Bye.\"; exit "
	
	sshON=$?
	while [[ sshON -ne 0 ]]
	do
	    sleep 3
	    ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -i $loginKeysDir/login-key-$instance.pem ubuntu@$instanceIPaddress "echo \"Hi from Ubuntu user. Bye.\"; exit "
	    sshON=$?
	    if [[ $sshON -eq 0 ]]; then
		message "`colour greenlight "SSH server is ready"`";
		break ;
	    fi
	done

	message "Setting up access keys." $resultsFile
	message "ssh -i $loginKeysDir/login-key-$instance.pem ubuntu@$instanceIPaddress /home/ubuntu/bin/usersAccessKeys-setup-MAIN.sh" $resultsFile
	
	ssh -i $loginKeysDir/login-key-$instance.pem ubuntu@$instanceIPaddress /home/ubuntu/bin/usersAccessKeys-setup-MAIN.sh
	
	message "\nUpdating the hostname to $instance.$instanceIPaddress" $resultsFile
	ssh -i $loginKeysDir/login-key-$instance.pem ubuntu@$instanceIPaddress "sudo hostnamectl set-hostname $instance.$instanceIPaddress"
	
	message "Logging as $(colour lg csuser)" $resultsFile
	message	"ssh -o StrictHostKeyChecking=no -i $loginKeysDir/login-key-$instance.pem csuser@$instanceIPaddress \"echo \"Hi from CSUSER at $instance\"; ls; echo \"Bye.\";  exit \"" $resultsFile
	
	ssh -o StrictHostKeyChecking=no -i $loginKeysDir/login-key-$instance.pem csuser@$instanceIPaddress "echo \"Hi from CSUSER at $instance\"; ls; echo \"Bye.\";  exit "

	dateTime=`date '+%Y%m%d.%H%M%S'`
	echo "$instanceIPaddress" > $outputsDir/instances-creation-output/$instance-ip-address-$dateTime-$instanceIPaddress.txt
	
	message "\n$(colour lb "Please note"): the IP address ($instanceIPaddress) of instance $instance was saved to file:\n$outputsDir/instances-creation-output/$instance-ip-address-$dateTime-$instanceIPaddress.txt\n" $resultsFile

    else
	################   WRONG option, abort   ############
	message "DID NOT find configuration file .csconfig_DOMAIN_NAMES.txt or .csconfig_NO_DOMAIN_NAMES.txt, $(colour red aborting)."
	exit 2
    fi
done
exit 0


