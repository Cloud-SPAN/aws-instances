#!/usr/bin/env bash
#  Title	: cptoAWSinstance.sh
#  Date		: 20220310
#  Author	: "Jorge Buenabad-Chavez" <jorge.buenabad-chavez@york.ac.uk>
#  Version	: 1.0
#  Description	: copies a file or directory from the local machine to the csuser account in a Cloud-SPAN AWS instance.
#  Options	: [-l][-u][-v]  -- description below
#--------------------------------------------
source colour_utils_functions.sh	 # to add colour to some messages

function message_use() {
    printf "%b\n" "\n$(colour lb $(basename $0)) copies a local file/directory to the $(colour lb csuser) account of an AWS instance.

usage:

  $(colour lb "$(basename $0) [-l][-u][-v] login-key-instanceName.pem  localFile/DirName  [remoteFile/DirName]")

- $(colour lb NB): copying an individual file or link overwrites remote ones if they exist; remote directories are
  not overwritten if they exist but the copy is suffixed thus: remoteDirName$(colour lb -CopyYYYYMMDD.HHMMSS).
- use -l to copy links within directories as links (otherwise files pointed to by links are copied).
- use -u to copy to the 'ubuntu' account instead (of the 'csuser' account).
- use -v (verbose) to see what's going on and the copy command used.
- $(colour lb login-key-instanceName.pem) is the name (path) of the file containing the RSA login key to access
  the instance. The $(colour lb "name of the instance") to copy to is extracted from this name.
- if $(colour lb remoteFile/DirName) is not specified, the copy will be named as the localFile/DirName and copied
  at the home directory in the instance.
- $(colour lg Examples):
  $(colour lb $(basename $0)) gc_data/outputs/login-keys/login-key-instance017.pem  data/shell_data
  - copies (file/dir) data/shell_data to instance017$(colour lb .cloud-span.aws.york.ac.uk):/home/csuser/shell_data

  $(colour lb $(basename $0)) -u gc_data/outputs/login-keys/login-key-instance017.pem  shell_data  shell_data2
  - copies  data/shell_data to instance017.cloud-span.aws.york.ac.uk:/home/$(colour lb ubuntu)/shell_data2\n"
}

### Default values for options
linksCopyFlag=FALSE
user=csuser
verboseFlag=FALSE

### Get the options if any
# List of options the program will accept; those options that take arguments are followed by a colon
optionsString=luv

# 
while getopts $optionsString option
do
    case $option in
	l) linksCopyFlag=TRUE ;; ## $OPTARG contains the argument to the option
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
	localFileDir=$2
	if [ $# -eq 3 ]; then
	    remoteFileDir=$3
	else
	    remoteFileDir=$(basename $localFileDir)  ### to copy at the home directory
	fi
	### get domain from inputs/resourcesID.txt file
	inputsDir=${1%/outputs*}/inputs
	domain=`awk -F " " '$1 == "hostZone" {print $2}' $inputsDir/resourcesIDs.txt`
	### was this domain="cloud-span.aws.york.ac.uk" but is unusable outside Cloud-SPAN
	machine="to define below"
	# Check the login key file specified exists. WE ARE ASSUMING IS a .pem file below. It will fail if not.
	if [ -f $loginKeyFile ]; then
	    # file exists. Check file to copy exists
	    if [ -e $localFileDir ]; then
		# unpack machine name from the login key file name which has a form like this:
		#	 gc_run02_data/outputs/login-keys/login-key-instance017.pem
		# get rid of .pem at the end
		machine=${loginKeyFile%.pem}    
		# then from the beginning/prefix (#), get rid of anything  (*) up to login-key- (replace it with nothing /})
		# to get instantance017
		machine=${machine/#*login-key-/}
		# What kind of copy is it gonna be: file or directory
		if [ -d $localFileDir ]; then   ### DIRECTORY
		    # check whether remote directory exists
		    if ssh -i "$loginKeyFile" "$user@$machine.$domain" "test -e $remoteFileDir" ; then # no [] because it is a cmd
			# check whether there is a trailing / in the remote file name to copy within instead of renaming
			(( remoteFileDirLength = ${#remoteFileDir} - 1 ))
			if [ ${remoteFileDir:$remoteFileDirLength:1} == "/" ]; then
			    # message "Yes, $remoteFileDir has trailing /"
			    remoteFileDir="${remoteFileDir}$(basename $localFileDir)"
			    if ssh -i "$loginKeyFile" "$user@$machine.$domain" "test -e $remoteFileDir" ; then
				if [ $verboseFlag == TRUE ]; then
				    message "`colour lb WARNING`: file $user@$machine.$domain:./$remoteFileDir `colour lb EXISTs`,"
				fi
				remoteFileDir="$remoteFileDir-Copy`date '+%Y%m%d.%H%M%S'`"
				if [ $verboseFlag == TRUE ]; then
				    message "hence the `colour lb "remote copy will be named"` $remoteFileDir."
				fi
			    fi
			else
			    if [ $verboseFlag == TRUE ]; then
				message "`colour lb WARNING`: file $user@$machine.$domain:./$remoteFileDir `colour lb EXISTs`,"
			    fi
			    remoteFileDir="$remoteFileDir-Copy`date '+%Y%m%d.%H%M%S'`"
			    if [ $verboseFlag == TRUE ]; then
				message "hence the `colour lb "remote copy will be named"` $remoteFileDir."
			    fi
			fi
		    else
			if [ $verboseFlag == TRUE ]; then
			    message "`colour lg OK`: remote dir $user@$machine.$domain:./$remoteFileDir DOES NOT EXIST."
			fi
		    fi
		    echo -n -e 
		    # check whether to use rsync or scp
		    if [ $linksCopyFlag == TRUE ]; then
			# NB rsync has two options:
			# 1) rsync -av --delete -e "ssh -i $loginKeyFile" $localFileDir "$user@$machine.$domain":./$remoteFileDir;
			# 2) rsync -av --delete -e "ssh -i $loginKeyFile" $localFileDir/ "$user@$machine.$domain":./$remoteFileDir;
			# ---
			# 1) using "$localFileDir" (no / at the end) copies the directory entry with its files and puts it within
			#    $remoteFileDir, creating $remoteFileDir if it doesn't exist.
			# 2) using "$localFileDir/" (with / at the end) copies only the files within $localFileDir and puts them in
			#    $remoteFileDir$2, creating $remoteFileDir iff it doesn't exist.
			# You can think of a trailing / on a source as meaning "copy the  contents  of this directory" as opposed
			# to "copy the directory by name"
			################ We are using option 2)
			if [ $verboseFlag == TRUE ]; then
			    message "`colour lg "Copying directory"` with rsync:"
			    message "rsync -av --delete -e \"ssh -i $loginKeyFile\" $localFileDir/ \"$user@$machine.$domain\":./$remoteFileDir;"
			fi
			rsync -av --delete -e "ssh -i $loginKeyFile" $localFileDir/ "$user@$machine.$domain":./$remoteFileDir;
		    else
			if [ $verboseFlag == TRUE ]; then
			    message "`colour lg "Copying directory"` with scp:"
			    message "scp -r -i  $loginKeyFile $localFileDir \"$user@$machine.$domain\":./$remoteFileDir;"
			fi
			scp -r -i  $loginKeyFile $localFileDir/ "$user@$machine.$domain":./$remoteFileDir;
		    fi   
		    exit 0
		elif [ -h $localFileDir ]; then   ### LINK
		    # symbolic links are tested with -h or -L but the test must be before the regular file test below as
		    # a soft link also tests true as a regular file
		    if [ $verboseFlag == TRUE ]; then
			message "`colour lg Copying` link $localFileDir to remote ./$remoteFileDir"
			message "rsync -av --delete -e \"ssh -i $loginKeyFile\" $localFileDir \"$user@$machine.$domain\":./$remoteFileDir;"
		    fi
		    rsync -av --delete -e "ssh -i $loginKeyFile" $localFileDir "$user@$machine.$domain":./$remoteFileDir;
		    exit 1	### why 1 and not 0
		elif [ -f $localFileDir ]; then   ### REGULAR FILE
		    if [ $verboseFlag == TRUE ]; then
			message "`colour lg Copying` file $localFileDir to remote ./$remoteFileDir"
			message "scp -i  $loginKeyFile $localFileDir \"$user@$machine.$domain\":./$remoteFileDir;"
		    fi
		    scp -i  $loginKeyFile $localFileDir "$user@$machine.$domain":./$remoteFileDir;
		    exit 0
		else
		    message "`colour lr "Unknown file type"`. It must be a regular file, a directory or a valid link. "
		    exit 0
		fi
	    else
		message "`colour lr Error`: local file/dir  $localFileDir  DOES NOT EXIST."
		message_use
		exit 2
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
