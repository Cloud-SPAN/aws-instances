#!/usr/bin/env bash
#  Title	: aws_storageEBS_increase.sh
#  Date		: 20220504
#  Author	: "Jorge Buenabad-Chavez" <jorge.buenabad-chavez@york.ac.uk>
#  Version	: 1.0
#  Description	: increases the size of EBS storage to the given number of GigaBytes for the instance running this script
#  Options	: [-l][-u][-v]  -- description below
# 
# Main steps:
# Original main steps:
# 1. Stop instance
# 2. Take snapshot
# 3. Increase EBS either in AWS Console or AWS cli - asks for which one
# 4. Runs instance - to login
# 5. Login to instance
# 6. Increase file system (FS) to the new size of EBS storage - see aws ec2 guide for Linux commands
# 7. Check FS size has been increased
# This script can be run on its own or through/by the script instances_create.sh. 
#-------------------------------------
# helper functions
source colours_msg_functions.sh	 # to add colour to some messages

function message_use() {
    printf "%b\n" "\n$(colour lg $(basename $0)) increases the size of the instance disk (EBS storage) and the file system
$(colour lb "up to") the given number of GigaBytes (GB) if such number is larger than the current size of the disk.

usage:     $(colour lb "$(basename $0)")  newSizeOfDiskInGBs

  $(colour lb Example):       $(basename $0) 120

 - increases the size of the disk and file system to be of 120 GB.
 - the current disk size must be smaller than 120 GB.
 - note that the file system size may be shown as slightly smaller than disk space:
   try command: \"df -h .\""
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
    1)  ### set -x   # too much of a log
	diskSizeToBe=$1
	### check disk size specified is bigger than the current disk size
	### change to home directory and check the ~/logs directory exists, otherwise create it.
	cd
	if [ ! -d logs ]; then  
	    message "Creating directory logs"
	    mkdir logs
	fi
	logfile=logs/aws_storage_increase.sh`date '+%Y%m%d.%H%M%S'`.txt

	### get the volume's size and volume-id into logfile		   --- "curl -s" is silent 
	aws ec2 describe-volumes --filters Name=attachment.instance-id,Values=$(curl -s http://169.254.169.254/latest/meta-data/instance-id) >> $logfile								      ### .todo document IP address 169..

	### get the following from the logfile:
	### - substr gets rid off quotation marks ("") and commas in strings
	### - !visited.. gets rid of duplicate fields as otherwise they are concatenated and cause error when passed to aws below.
	instanceID=`awk -F " " '
	!visited[$1]++ {
	  if ( $1 == "\"InstanceId\":" ) {
       	    print substr($2, 2, length($2) -3)
	  }
	}' $logfile`
	volumeSize=`awk -F " " '
	!visited[$1]++ {
	  if ( $1 == "\"Size\":") {
	    print substr($2, 1, length($2) -1)
	  }
        }' $logfile`
	volumeID=`awk -F " " '  
	!visited[$1]++ {
	  if ( $1 == "\"VolumeId\":" ) {
	    print substr($2, 2, length($2) -3)
	  }	    
	}' $logfile`

	### check the new size is OK
	if [ $volumeSize -ge $diskSizeToBe ]; then
	    message "`colour lr "Disk and file system not increased"`"
	    message "Disk current size is $volumeSize; must be smaller than $diskSizeToBe to increase it up to that size.\n"
	    message_use
	    exit 1;
	fi
	### New size is OK, confirming whether to continue
	message "Disk current size is $volumeSize and is going to be increased to $diskSizeToBe."
	read -n 1 -p "Do you want to continue (y/n)?: " option
	if [ "$option" != "n" -a "$option" != "N" -a "$option" != "y" -a "$option" != "Y" ]; then
	    message "\nWrong option $option. Script cancelled." $logfile
	    exit 1;
	elif [ "$option" == "n" -o "$option" == "N" ]; then
	    message "\nScript cancelled ($option)." $logfile
	    exit 1;
	fi
	message "\nIncreasing disk size from $volumeSize to $diskSizeToBe GBs. Please wait:" $logfile
	# aws ec2 modify-volume --size $diskSizeToBe --volume-id $volumeID | tee -a "$logfile" ### if aws fails, tee may succeed
	# - and the test below $? will be misleading
	# aws ec2 modify-volume --size $diskSizeToBe --volume-id $volumeID >> $logfile 2>&1 ## doesn't work without quoting variables
	# aws ec2 modify-volume --dry-run --size "$diskSizeToBe" --volume-id "$volumeID" >> $logfile 2>&1  THIS one without dry-run
	message "aws ec2 modify-volume --size $diskSizeToBe --volume-id $volumeID >> $logfile 2>&1" $logfile

	aws ec2 modify-volume --size $diskSizeToBe --volume-id $volumeID >> $logfile 2>&1
	if [ $? -eq 0 ]; then
	    message "`colour gl Success` extending disk size but must wait for optimisation phase:" $logfile
	else
	    message "`colour red Error` extending disk size, please check the log file $logfile for details." $logfile
	    exit 1
	fi
	
	while true 
	do
	    #aws ec2 describe-volumes-modifications --volume-ids $volumeID  >> $logfile 2>&1
	    #status=`awk -F " " '$1 == "\"ModificationState\":" {print substr($2, 2, length($2) -3)}' $logfile`
	    # NB we cannot read the status from the $logfile as before with "!visited" within awk because the value "optimising" we
	    # are waiting for will be the last one in that file and hence will be ignored (deleted by "!visited"). Better with a
	    # pipe so that only the last state is processed. .todo Perhaps i should use above  a pipe too.

	    status=`aws ec2 describe-volumes-modifications --volume-ids $volumeID | awk -F " " '$1 == "\"ModificationState\":" {print substr($2, 2, length($2) -3)}'`
	    if [[ "$status" == "optimizing" ]]; then		### "optimizing" is enough see below, "completed" is DONE
		message "Status: $status is enough, proceeding .." $logfile
		break ;
	    else
		message "not yet, status: $status" $logfile
		sleep 1
	    fi
	done

	### After you increase the size of an EBS volume (ec2 user guide p. 1553), you must use ﬁle system–speciﬁc commands to
	### extend the ﬁle system to the larger size. You can resize the ﬁle system as soon as the volume enters the
	### optimizing state. NB YOU CANNOT increase the size of a volume while it is in optimising state, which may take a while.
        # very powerful bash
	#message "Checking new size with `lsblk /dev/xvda | awk -F " " '$1 == "xvda" {print substr($4, 1, length($4) -1)}'`" $logfile
	### Check disk volume has been increased and if so increase partition:
	#------------- OLD Version for t2. instances disk partition and file system named xdva and xvda1 -------------------
#	message "Checking new size with \"lsblk /dev/xvda\":"
#	lsblk /dev/xvda  >> $logfile 2>&1
#	newDiskSize=`awk -F " " '$1 == "xvda" {print substr($4, 1, length($4) -1)}' $logfile`
#	message "newDiskSize $newDiskSize" $logfile
#	if [ $newDiskSize -le $volumeSize ]; then
#	    message "Sorry, the disk size could not be increased. " $logfile
#	    exit 1 ;
#	fi
#	   
#	# increase partition
#	message "Increasing partition and file system:"
#	sudo growpart /dev/xvda 1  | tee -a $logfile		### perhaps checking again the new size (ec2 user guide p. 1563-4)
#	sudo resize2fs /dev/xvda1  | tee -a $logfile		### perhaps checking the new file system and printing to the user. 
#	df -h .	 | tee -a $logfile				### to show the new size of the file system
#	#------------- OLD Version END -------------------
	# NEW VERSION for t3. instances disk partition and file system named nvme0n1 and nvme0n1p1
	message "Checking new size with command \"/dev/nvme0n1\":"
	lsblk /dev/nvme0n1  >> $logfile 2>&1
	newDiskSize=`awk -F " " '$1 == "nvme0n1" {print substr($4, 1, length($4) -1)}' $logfile`
	message "newDiskSize $newDiskSize" $logfile
	if [ $newDiskSize -le $volumeSize ]; then
	    message "Sorry, the disk size could not be increased. " $logfile
	    exit 1 ;
	fi
	   
	# increase partition
	message "Increasing partition and file system:"
	sudo growpart /dev/nvme0n1 1  | tee -a $logfile		### perhaps checking again the new size (ec2 user guide p. 1563-4)
	sudo resize2fs /dev/nvme0n1p1  | tee -a $logfile	### perhaps checking the new file system and printing to the user. 
	df -h .	 | tee -a $logfile				### to show the new size of the file system
	exit 0
	;;
    *) message_use
       exit 2;;
esac

: <<'COMMENTS'
- https://stackoverflow.com/questions/625644/how-to-get-the-instance-id-from-within-an-ec2-instance
  - $ ec2-metadata -i
  instance-id: i-1234567890abcdef0
  - Or, on Ubuntu and some other linux flavours, ec2metadata --instance-id (This command may not be installed by default on ubuntu, but you can add it with sudo apt-get install cloud-utils)

- https://serverfault.com/questions/427018/what-is-this-ip-address-169-254-169-254
Of particular note, 169.254.169.254 is used in Amazon EC2 and other cloud computing platforms to distribute metadata to cloud instances.

- This works fine in ubuntu user of any instance 
aws ec2 describe-volumes --filters Name=attachment.instance-id,Values=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

COMMENTS
