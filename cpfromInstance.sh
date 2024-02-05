#!/usr/bin/env bash
#  Title	: cpfromAWSinstance.sh
#  Date		: 20220310
#  Author	: "Jorge Buenabad-Chavez" <jorge.buenabad-chavez@york.ac.uk>
#  Version	: 1.0
#  Description	: copies a file or directory from a Cloud-SPAN AWS instance to the local machine.
#  Options	: [-l][-u][-v]  -- description below
#--------------------------------------------
source colour_utils_functions.sh	 # to add colour to some messages


function message_use() {
    printf "%b\n" "$(colour lb $(basename $0)) copies a file/directory from/in an AWS instance $(colour lb csuser) account to the local machine.

usage: 
 
  $(colour lb "$(basename $0) [-u][-v] login-key-instanceName.pem  remoteFileOrDirName  [localFileOrDirName]")
 
- if $(colour lb localFileDirName) is not specified, the copy will be named as the remoteFileDirName and copied 
  to the local current directory.
- $(colour lb NB): copying an individual file or directory overwrites the local ones if they exist. 
- $(colour lb rsync) is used to copy directories so that links are copied as links.
- use -u to copy from the 'ubuntu' account instead (of the 'csuser' account).
- use -v (verbose) to see what's going on and the copy command used.
- $(colour lb login-key-instanceName.pem) is the name (path) of the file containing the RSA login key to access
  the instance. The $(colour lb "name of the instance") to copy to is extracted from this file name.
- $(colour lg Examples):
  $(colour lb $(basename $0)) gc_data/outputs/login-keys/login-key-instance017.pem  shell_data
  - copies (file/dir) instance017$(colour lb .cloud-span.aws.york.ac.uk):/home/csuser/shell_data to ./shell_data
 
  $(colour lb $(basename $0)) -u gc_data/outputs/login-keys/login-key-instance017.pem  shell_data  shell_data2
  - copies instance017.cloud-span.aws.york.ac.uk:/home/$(colour lb ubuntu)/shell_data  to  ./shell_data2\n"
}

### Default values for options
user=csuser
verboseFlag=FALSE

### Get the options if any
# List of options the program will accept; those options that take arguments are followed by a colon
optionsString=uv

# 
while getopts $optionsString option
do
    case $option in
	u) user=ubuntu ;;
	v) verboseFlag=TRUE ;;
	*) message_use; exit 1 ;;
    esac
done

### Remove options from the command line
# $OPTIND points to the next, unparsed argument
shift "$(( $OPTIND - 1 ))"

### start:
case $# in
    2|3) #message "linksCopyFlag $linksCopyFlag; user $user; verboseFlag $verboseFlag; $1 $2 $3 $4"; #exit 1;
	loginKeyFile=$1
	remoteFileDir=$2
	if [ $# -eq 3 ]; then
	    localFileDir=$3
	else
	    localFileDir=$(basename $remoteFileDir)  ### to copy at the current directory
	fi
	### get domain from inputs/resourcesID.txt file
	inputsDir=${1%/outputs*}/inputs
	domain=`awk -F " " '$1 == "hostZone" {print $2}' $inputsDir/resourcesIDs.txt`
	### was this domain="cloud-span.aws.york.ac.uk" but is unusable outside Cloud-SPAN
	machine="to define below"
	# Check the login key file specified exists. WE ARE ASSUMING IS a .pem file below. It will fail if not.
	if [ -f $loginKeyFile ]; then
	    ### login key file is an existing regular file (-f); now get the machine name from that file name delete:
	    # get rid of .pem at the end
	    machine=${loginKeyFile%.pem}    
	    # then from the beginning/prefix (#), get rid of anything  (*) up to login-key- (replace it with nothing /})
	    # to get instantance017    
	    machine=${machine/#*login-key-/}
	    if ssh -i "$loginKeyFile" "$user@$machine.$domain" "test -e $remoteFileDir" ; then # no [] because it is a cmd
		# remote file or directory exists
		if ssh -i "$loginKeyFile" "$user@$machine.$domain" "test -f $remoteFileDir" ; then # idem
		    # it is regular a file to copy with scp
		    if [ $verboseFlag == TRUE ]; then
			message "`colour lg Copying` remote file ./$remoteFileDir to local file $localFileDir"
			message "scp -i  $loginKeyFile $user@$machine.$domain:./$remoteFileDir  $localFileDir;"
		    fi
		    scp -i  $loginKeyFile "$user@$machine.$domain":./$remoteFileDir  $localFileDir;
		    exit 0
		elif ssh -i "$loginKeyFile" "$user@$machine.$domain" "test -d $remoteFileDir" ; then # idem.
		    # it is a directory to copy with rsync (because scp cannot copy symbolic links)
		    # NB rsync has two options:
		    # 1) rsync -av --delete -e "ssh -i $loginKeyFile" "$user@$machine.$domain":./$remoteFileDir $localFileDir ;
		    # 2) rsync -av --delete -e "ssh -i $loginKeyFile" "$user@$machine.$domain":./$remoteFileDir/ $localFileDir ;
		    # ---
		    # 1) using "../$remoteFileDir" (no / at the end) copies the directory entry with its files and puts it in
		    #    $localFileDir, creating $remoteFileDir ???? if it doesn't exist.
		    # 2) using "..$remoteFileDir/" (with / at the end) copies only the files within $localFileDir and puts them in
		    #    $localFileDir, creating $localFileDir iff it doesn't exist. TYPICAL rsync behaviour.
		    # You can think of a trailing / on a source as meaning "copy the  contents  of this directory" as opposed
		    # to "copy the directory by name"
		    ################ We are using both options depending on the name of the target directory
		    ## BUT as rsync is rather powerful, we are going to allow copyin only within the current directory, nowhere else
		    #  as we may specify a directory outside the current one d and crash it.
		    case $localFileDir in
			.*|..*|~/*) # copy the remote directory entry / not only the files within
			    if [ $verboseFlag == TRUE ]; then
				message "`colour lg "Copying directory"` with rsync:"
				message "local dir was . or .. or ~/*: $localFileDir"
				message "rsync -av --delete -e \"ssh -i $loginKeyFile\" \"$user@$machine.$domain\":./$remoteFileDir  $localFileDir/ ;" 
			    fi
			    rsync -av --delete -e "ssh -i $loginKeyFile" "$user@$machine.$domain":./$remoteFileDir  $localFileDir/ ;
			    ;;
			*) ### copy only the files within remote directory, creating a local directory only if it doesn't exist.
			    if [ $verboseFlag == TRUE ]; then
				message "`colour lg "Copying directory"` with rsync:"
				message "local dir was NOT . or .. or ~/\*: $localFileDir"
				message "rsync -av --delete -e \"ssh -i $loginKeyFile\" \"$user@$machine.$domain\":./$remoteFileDir/  $localFileDir/ ;"
			    fi
			    rsync -av --delete -e "ssh -i $loginKeyFile" "$user@$machine.$domain":./$remoteFileDir/  $localFileDir/ ;
			    ;;
		    esac
		    exit 0
		else
		    message "`colour lr Error`: file $user@$machine.$domain:/home/$user/$remoteFileDir IS NOT A FILE NOR A DIRECTORY."
		fi		     
	    else
		message "`colour lr Error`: file $user@$machine.$domain:/home/$user/$remoteFileDir DOES NOT EXIST."
		exit 0
	    fi
	else
	    message "`colour lr Error`: login key file  $loginKeyFile DOES NOT EXIST."
	    message_use
	    exit 2
	fi
	;;
    *) message_use
       exit 2;;
esac
