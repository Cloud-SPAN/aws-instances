#!/usr/bin/env bash
#  Login To Instance x with SSH 
#
# helper functions
function error_in_use() {
    #echo "from error-function echoing parameter 1 \"$(basename $1)\""
    echo "----------------------------------------------"
    echo "$(basename $0) logs you in to an (AWS) instance using ssh."
    echo " ";
    echo "usage: "
    echo " ";
    echo "    $(basename $0)  login-key-instanceName.pem  csuser/ubuntu" ;
    echo " ";
    echo "- login-key-instanceName.pem is the name (path) of the file containing the RSA login key"
    echo "  to access the instance."
    echo " ";    
    echo "- the name of the instance to log you in is extracted from the name of the .pem file provided.";
    echo " ";    
    echo "- the domain name is extracted from the inputs/resourcesIDs.txt file.";
    echo " ";    
    echo "- Examples:";
    echo "  $(basename $0) courses/genomics01/outputs/login-keys/login-key-instance017.pem  csuser";
    echo "  $(basename $0) courses/genomics01/outputs/login-keys/login-key-instance017.pem  ubuntu";
    echo " ";
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
	    # file exists. Check the user given is csuser or ubuntu
	    if [ $user == "csuser"  -o $user == "ubuntu" ]; then
		# unpack machine name from the login key file name which has the form:
		# gc_run02_data/outputs/login-keys/login-key-instance017.pem
		# first get rid of .pem at the end
		machine=${loginKeyFile%.pem}
		# then, from the beginning/prefix (#), everything (*) up to loging-key-, replace it / with nothing.
		machine=${machine/#*login-key-/}		
		echo "  $(basename $0): logging you thus:"
		echo "  ssh -i $loginKeyFile $user@$machine.$domain"
		ssh -i $loginKeyFile $user@$machine.$domain
		exit 0
	    else
		echo 
		echo "Error: user must be \"csuser\"  or \"ubuntu\" (with no quotes)."
		error_in_use
		exit 2 
	    fi
	else
	    echo 
	    echo "Error: login key file $loginKeyFile DOES NOT EXIST."
	    error_in_use
	    exit 2
	fi
	;;
    *) error_in_use "$1"
       exit 2;;
esac
