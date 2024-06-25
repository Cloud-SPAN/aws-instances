#!/usr/bin/env bash
#  Login To Instance x with SSH 
#
#------------------------------ 
source colour_utils_functions.sh	 # to add colour to some messages

usage_msg="----------------------------------------------
$(colour lb $(basename $0)) logs you in to an (AWS) instance using ssh.

usage: 

    $(colour lb $(basename $0))  login-key-instanceName.pem  csuser/ubuntu/yourusername

- login-key-instanceName.pem is the name (path) of the file containing the RSA login key
  to access the instance.
- the name of the instance to log you in is extracted from the name of the .pem file provided.
- to access the instance, $(colour cyan if) domain names were configured, the domain name is extracted from 
  the inputs/resourcesIDs.txt file, $(colour cyan otherwise) the instance IP address is queried from AWS 
  using the instanceId stored in the instance creation results file.
- Examples:
  $(colour lb $(basename $0)) courses/genomics01/outputs/login-keys/login-key-instance017.pem  csuser
  $(colour lb $(basename $0)) courses/genomics01/outputs/login-keys/login-key-instance017.pem  ubuntu\n"


############ start:
case $# in
    2) # two parameters given as expected. Check the login key file specified exists.
	loginKeyFile=$1
	user=$2
	if [ -f $loginKeyFile ]; then
	    ### get domain mainfrom inputs/resourcesID.txt file
	    inputsDir=${loginKeyFile%/outputs*}/inputs
	    # first get rid of .pem at the end
	    instance=${loginKeyFile%.pem}
	    # then, from the beginning/prefix (#), everything (*) up to loging-key-, replace it / with nothing.
	    instance=${instance/#*login-key-/}
	    message "   $(colour lb "logging you thus"):"

	    if [ -f $inputsDir/.csconfig_DOMAIN_NAMES.txt ]; then
		domain=`awk -F " " '$1 == "hostZone" {print $2}' $inputsDir/resourcesIDs.txt`
		message "  ssh -i $loginKeyFile $user@$instance.$domain"
		ssh -i $loginKeyFile $user@$instance.$domain
		
	    elif [ -f $inputsDir/.csconfig_NO_DOMAIN_NAMES.txt ]; then
		outputsDir=${loginKeyFile%/outputs*}/outputs
		instanceID=`awk -F " " '$1 == "\"InstanceId\":" {print substr($2, 2, length($2) -3)}' $outputsDir/instances-creation-output/$instance.txt`

		instanceIPaddress=`aws ec2 describe-instances --instance-ids  "$instanceID" --query 'Reservations[*]. Instances[*]. PublicIpAddress' --output text`
		message "  ssh -i $loginKeyFile $user@$instanceIPaddress"
		ssh -i $loginKeyFile $user@$instanceIPaddress

	    else
		################   WRONG option, abort   ############
		message "DID NOT find config. file .csconfig_DOMAIN_NAMES.txt or .csconfig_NO_DOMAIN_NAMES.txt, $(colour r aborting)."
		exit 2
	    fi

	    if [ $? -eq 0 ]; then	### $?: result of last (ssh) command
		exit 0
	    else
		message "\n$(colour r ERROR): could not login, check the username $(colour lb $user) is correct - try with  \"ubuntu\" (with no quotes)."
		message "$usage_msg"
		exit 2 
	    fi
	else
	    message "\nError: login key file $loginKeyFile DOES NOT EXIST."
	    message "$usage_msg"
	    exit 2
	fi
	;;
    *) message "$usage_msg"
       exit 2;;
esac

