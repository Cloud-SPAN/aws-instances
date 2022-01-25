#!/bin/bash
# configures each instance so that users other than sudo user can login using the private key of sudo user 
#
#-------------------------------------
source colours_functions.sh	 # to add colour to some messages

# instancesNamesFile=${1##*/}	 #; delete everything (*) up to last / and return the rest = (`basename $1`) but more efficient
instancesNamesFile=${1}		 #; actually need the full path ; echo instancesNameFile: $instancesNamesFile

# general inputs directory	 # return what is left after eliminating the last / and any character following it
inputsDir=${1%/*}		 
				 
# general outputs directory	 # note that some data in the outpus directory (from creating instances) is needed as input
outputsDir=${1%/inputs*}/outputs # return what is left after eliminating the second to last / and "inputs" and any character
				 # following "inputs", then adds "/outputs"
# get the domain name suffix (hostZone): cloud-span.aws.york.ac.uk
hostZone=`awk -F " " '$1 == "hostZone" {print $2}' $inputsDir/resourcesIDs.txt`
loginKeysDir=$outputsDir/login-keys

mapfile instancesNames < $instancesNamesFile

for instance in ${instancesNames[@]}
do
    # replace echo with ssh
    instance=${instance%-srcCSGC-AMI04}
    keyfile=${instance%-gc}
    echo ""
    echo -e "$(colour cyan "Configuring $instance: ")"

    # we need to ensure the domain is available before any issuing any ssh; otherwise will get Connection refused port 22 or similar
    domainNameCreationFile="$outputsDir/domain-names-creation-output/domain-name-create-${instance%-srcCSGC-AMI04}.txt"
    domainNameChangeID=`awk -F " " '$1 == "\"Id\":" {print substr($2, 2, length($2) -3)}' $domainNameCreationFile`
    
    echo -n "Checking $instance.$hostZone is reachable: "
    tmpfile="/tmp/domainName${instance%-srcCSGC-AMI04}-status.txt"
    while true 
    do
	echo -n "."
	aws route53  get-change --id $domainNameChangeID > $tmpfile	# domainNameChangeID = /change/C3QYC83OA0KX5K
	domainStatus=`awk -F " " '$1 == "\"Status\":" {print substr($2, 2, length($2) -3)}' $tmpfile`
	if [[ $domainStatus == "INSYNC" ]]; then
	    #INSYNC is reachable: https://aws.amazon.com/premiumsupport/knowledge-center/simple-resource-record-route53-cli/
	    echo " : status $domainStatus (reachable)";
	    break ;
	else
	    sleep 1
	fi
    done

    echo "Cleaning any previous keys associated with the instance $instance.$hostZone"
    ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$instance.$hostZone"

    echo -e "`colour bl "Waiting for SSH server, please wait (you may see some 'Connection timed out/Connection refused' messages)"`";
    ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no -i $loginKeysDir/login-key-$keyfile.pem ubuntu@$instance.$hostZone "echo \"Hola. Bye.\"; exit "
    sshON=$?
    
    while [[ sshON -ne 0 ]]
    do
	echo -n "."
	sleep 3
	ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no -i $loginKeysDir/login-key-$keyfile.pem ubuntu@$instance.$hostZone "echo \"Hola. Bye.\"; exit "
	sshON=$?
	if [[ $sshON -eq 0 ]]; then
	    echo -e "`colour greenlight "SSH server is ready"`";
	    break ;
	fi
    done
    #continue
    
    echo "Trimming off all previous public keys but the last one generated by AWS for the instance
    ssh -o StrictHostKeyChecking=no -i $loginKeysDir/login-key-$keyfile.pem ubuntu@$instance.$hostZone /home/ubuntu/bin/sudoAuthorizedKeys-lastKeyOnly.sh" 

    ssh -i $loginKeysDir/login-key-$keyfile.pem ubuntu@$instance.$hostZone /home/ubuntu/bin/sudoAuthorizedKeys-lastKeyOnly.sh

    echo 
    echo Copying trimmed keys file to all other accounts
    ssh -i $loginKeysDir/login-key-$keyfile.pem ubuntu@$instance.$hostZone /home/ubuntu/bin/usersAuthorizedKeys-activate.sh

    echo "ssh return code: $?"
    
    echo 
    echo Updating the hostname to $instance.$hostZone
    ssh -i $loginKeysDir/login-key-$keyfile.pem ubuntu@$instance.$hostZone "sudo hostnamectl set-hostname $instance.$hostZone"

    echo Logging as csuser
    ssh -i $loginKeysDir/login-key-$keyfile.pem csuser@$instance.$hostZone "echo \"Hi. Bye from $instance\"; ls; exit "
done

