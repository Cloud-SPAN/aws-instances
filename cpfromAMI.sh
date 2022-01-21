#!/bin/bash
# cpfromAMI copies a file from an Amazon Machine Image (AMI) to the local machine.
#
# helper functions
function error_in_use() {
    #echo "from error-function echoing parameter 1 \"$(basename $1)\""
    echo "$(basename $0) copies a remote file, or folder, in an Amazon Machine Image (AMI) to the local machine."
    echo " ";
    echo "usage: "
    echo " ";
    echo "    $(basename $0) source_remote_file/dir_name  target_local_file/dir_name  [login_credentials_file]" ;
    echo " ";
    echo "- login-credentials is the name of the file containing (space-separated or in different lines):"
    echo "  username machine-domain-name loging-key-file-name";
    echo " ";	 
    echo "- if no login-credentials file is specified, the file \"cplogincredentials.txt\" must exist in the";
    echo "  current directory";    
}

### start:
case $# in
    2|3) if [ $# -eq 2 ]; then
	     # the login details file is in current directory
	     if [ -f ./cplogincredentials.txt ]; then
		 logindetails=( `cat ./cplogincredentials.txt` )
	     else
		 echo "Error: login credentials file \"cplogincredentials.txt\" DOES NOT EXIST in current directory."
		 error_in_use
		 exit 2
	     fi
	 elif [ -f $3 ]; then
	     # login details file specified by caller
	     logindetails=( `cat $3` )
	 else
	     echo "Error: login credentials file \"$3\" DOES NOT EXIST."
	     error_in_use
	     exit 2
	 fi
	 # unpack login details
	 username=${logindetails[0]}
	 machinedomainname=${logindetails[1]}
	 loginkeyfile=${logindetails[2]}
	 
	 if ssh -i "$loginkeyfile" "$username@$machinedomainname" "test -e $1" ; then # no [] is a must maybe because it is a cmd
	     # OK: file $1 exists ;  exit 0
	     if ssh -i "$loginkeyfile" "$username@$machinedomainname" "test -f $1" ; then # idem
		 # it is regular file to copy with scp
		 echo copying regular file $1 with scp
		 scp -r -i $loginkeyfile "$username@$machinedomainname":./$1 $2;
		 exit 0;
	     elif ssh -i "$loginkeyfile" "$username@$machinedomainname" "test -d $1" ; then # idem.
		 # it is a directory to copy with rsync (because scp cannot copy symbolic links)
		 echo copying directory $1 with rsync
		 # NO SO: rsync -av --delete -e "ssh -i $loginkeyfile" "$username@$machinedomainname":./$1/ $2; # IS TOO DANGEROUS ..
		 # as (--delete) will delete everything "extra" in current directory if $2 is . current dir.
		 if [ $2 == "."  ]; then
		     # SAFER: "./$1" (with no / at the end) copies the directory entry and its files and puts it in $2,
		     #	   creating $2 if it doesn't exist
		     rsync -av --delete -e "ssh -i $loginkeyfile" "$username@$machinedomainname":./$1 $2;
		 else
		     # while "/$1/" copies only the files and puts them in $2, creating $2 iff it doesn't exist
		     rsync -av --delete -e "ssh -i $loginkeyfile" "$username@$machinedomainname":./$1/ $2;
		 fi
		 exit 0;
	     else
		 echo "Error: file $username@$machinedomainname:/home/$username/$1 IS NOT A FILE NOR A DIRECTORY."
	     fi		     
	 else
	     echo "Error: file $username@$machinedomainname:/home/$username/$1 DOES NOT EXIST."
	 fi
	 exit 0;;
    0|1|*) error_in_use "$1"
	   exit 2;;
esac
