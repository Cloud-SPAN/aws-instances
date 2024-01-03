#!/usr/bin/env bash
#  Login To Instance x with SSH 
#
#------------------------------ 
source colour_utils_functions.sh	 # to add colour to some messages

function error_in_use() {
    #### message "from error-function messageing parameter 1 \"$(basename $1)\""
    message "----------------------------------------------
$(colour lb $(basename $0)) logs you in to an (AWS) instance using ssh.

usage: 

    $(colour lb $(basename $0))  login-key-instanceName.pem  csuser/ubuntu/yourusername

- login-key-instanceName.pem is the name (path) of the file containing the RSA login key
  to access the instance.
- the name of the instance to log you in is extracted from the name of the .pem file provided.
- the domain name is extracted from the inputs/resourcesIDs.txt file.
- Examples:
  $(colour lb $(basename $0)) courses/genomics01/outputs/login-keys/login-key-instance017.pem  csuser
  $(colour lb $(basename $0)) courses/genomics01/outputs/login-keys/login-key-instance017.pem  ubuntu\n";
}

### start:
case $# in
    2) # two parameters given as expected. Check the login key file specified exists.
	loginKeyFile=$1
	user=$2
	### get domain from inputs/resourcesID.txt file
	inputsDir=${1%/outputs*}/inputs
	domain=`awk -F " " '$1 == "hostZone" {print $2}' $inputsDir/resourcesIDs.txt`
	machine="to define below"
	if [ -f $loginKeyFile ]; then
	    # login key file exists.
	    # I used to check the user given was csuser or ubuntu but then i
	    # could not loging when testing changing csuser to other username: better open
	    #if [ $user == "csuser"  -o $user == "ubuntu" ]; then
	    #	# unpack machine name from the login key file name which has the form:
	    #	# gc_run02_data/outputs/login-keys/login-key-instance017.pem
	    #	# first get rid of .pem at the end
	    #	machine=${loginKeyFile%.pem}
	    #	# then, from the beginning/prefix (#), everything (*) up to loging-key-, replace it / with nothing.
	    #	machine=${machine/#*login-key-/}		
	    #	message "  $(basename $0): logging you thus:"
	    #	message "  ssh -i $loginKeyFile $user@$machine.$domain"
	    #	ssh -i $loginKeyFile $user@$machine.$domain
	    #	exit 0
	    #else
	    #	message "\nError: user must be \"csuser\"  or \"ubuntu\" (with no quotes)."
	    #	error_in_use
	    #	exit 2 
	    #fi
	    ###########
	    # unpack machine name from the login key file name which has the form:
	    # gc_run02_data/outputs/login-keys/login-key-instance017.pem
	    # first get rid of .pem at the end
	    machine=${loginKeyFile%.pem}
	    # then, from the beginning/prefix (#), everything (*) up to loging-key-, replace it / with nothing.
	    machine=${machine/#*login-key-/}		
	    message "  $(basename $0): logging you thus:"
	    message "  ssh -i $loginKeyFile $user@$machine.$domain"
	    ssh -i $loginKeyFile $user@$machine.$domain
	    if [ $? -eq 0 ]; then	### $?: result of last command
		exit 0
	    else
		message "\n$(colour r ERROR): could not login, check the username $(colour lb $user) is correct - try with  \"ubuntu\" (with no quotes)."
		error_in_use
		exit 2 
	    fi
	else
	    message "\nError: login key file $loginKeyFile DOES NOT EXIST."
	    error_in_use
	    exit 2
	fi
	;;
    *) error_in_use "$1"
       exit 2;;
esac

