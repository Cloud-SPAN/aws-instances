#!/usr/bin/env bash
#  Title	: cptoInstances.sh
#  Date		: 20240231
#  Author	: "Jorge Buenabad-Chavez" <jorge.buenabad-chavez@york.ac.uk>
#  Version	: 1.0
#  Description	: copies a file or directory from the local machine to an account on multiple AWS instances.
#  Options	: [-l][-u][-v]  -- description below
#--------------------------------------------
source colour_utils_functions.sh	 # to add colour to some messages

function message_use() {
    printf "%b\n" "$(colour lb $(basename $0)) copies a local file/directory to the $(colour lb csuser) account of one or more AWS instances.

usage:

  $(colour lb "$(basename $0) [-l][-u][-v] instancesNamesFile  localFile/DirName  [remoteFile/DirName]")

- $(colour lb NB): copying individual files or links overwrites remote ones if they exist; remote directories are
  not overwritten if they exist but the copy is suffixed thus: remoteDirName$(colour lb -CopyYYYYMMDD.HHMMSS).
- use -l to copy links within directories as links (otherwise files pointed to by links are copied).
- use -u to copy to the 'ubuntu' account instead (of the 'csuser' account).
- use -v (verbose) to see what's going on and the copy command used.
- $(colour lb instancesNamesFile) is the full or relative path of the file containing the names of the instances 
  to which the specficied local file or directory will be copied. The login keys to access the
  instances are extracted from the $(colour lb "../outputs/") directory at the same level of the $(colour lb "../inputs/") 
  directory that contains the $(colour lb instancesNamesFile).
- if $(colour lb remoteFile/DirName) is not specified, the copy will be named as the localFile/DirName and copied
  at the home directory in each instance.
- $(colour lg Examples):
  $(colour lb $(basename $0)) genomics/inputs/instancesNames.txt  data/file1
  - copies data/file1 to /home/csuser/file1 on each instance specified in ../instancesNames.txt

  $(colour lb $(basename $0)) -u genomics/inputs/instancesNamesFile.txt  file2  file3
  - copies file2 to /home/$(colour lb ubuntu)/file3 on each instance specified in ../instancesNames.txt"
}

### Default values for options
linksCopyFlag=FALSE
user=csuser
verboseFlag=FALSE

### Get the options if any
# List of options the program will accept; those options that take arguments are followed by a colon
optionsToPass=""
optionsString=luv			### options to process -- 
while getopts $optionsString option
do
    case $option in			### $OPTARG contains the argument to the option in turn, but there are no argument
	l) linksCopyFlag=TRUE ;	
	   optionsToPass="$optionsToPass -l" ;;	
	u) user=ubuntu ;
	   optionsToPass="$optionsToPass -u" ;;
	v) verboseFlag=TRUE ;
	   optionsToPass="$optionsToPass -v" ;;	
	*) message_use; exit 1 ;;
    esac
done

### Remove options from the command line
### $OPTIND points to the next, unparsed argument
shift "$(( $OPTIND - 1 ))"

### start:
case $# in
    2|3) #message "linksCopyFlag $linksCopyFlag; user $user; verboseFlag $verboseFlag; $1 $2 $3 $4"; #exit 1;
	instancesNamesFile=${1}
	inputsDir=${1%/*}		# return what is left after eliminating the last / and any character following it
					# message "inputsdir: $inputsDir"
	loginKeysDir=${1%/inputs*}/outputs/login-keys  # return what is left after eliminating the second to last "/" and
					# "inputs" and any character following "inputs", then adds "/outputs/login-keys"
					# message "outputsdir: $loginKeysDir"
	localFileDir=$2			# file / dir to copy
	if [ $# -eq 3 ]; then
	    remoteFileDir=$3
	else
	    remoteFileDir=$(basename $localFileDir)  ### to copy at the home directory
	fi ;;
    *) message_use
       exit 2;;
esac
				 
instancesNames=( `cat $instancesNamesFile` )

for instance in ${instancesNames[@]}
do
    ### extract instance name  and add .pem at the end
    loginkey="login-key-${instance%-src*}.pem"	  ### gets rid of the suffix "-src" and anything * that follows, then adds .pem
   
    #cptoInstance.sh -u amis/ami02-myFirstAMIConfig/outputs/login-keys/login-key-instanceToBecomeAMI02-Jorge.pem .aws
    message "cptoInstance.sh $optionsToPass $loginKeysDir/$loginkey $localFileDir $remoteFileDir"
    cptoInstance.sh $optionsToPass $loginKeysDir/$loginkey $localFileDir $remoteFileDir
    
    if [ $? -ne 0 ]; then
	message "$(colour red ERROR): cptoInstance.sh $optionsToPass $loginKeysDir/$loginkey $localFileDir $remoteFileDir"
    fi
done
exit 0






