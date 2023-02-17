#!/usr/bin/env bash
source colours_msg_functions.sh	  # to add colour to some messages
files=`ls *.sh`
case $# in
0|1) 	message "$(colour lb $(basename $0)) replaces a string with other string in all scripts (*.sh) in current directory."
	message "\nusage:   $(colour lb $(basename $0)) \"stringToReplace\" \"stringNew\""   
	message "\nexample:   $(colour lb $(basename $0)) \"-srcCSGC-AMI04\" \"-src*\""
	message "\n           replaces  -srcCSGC-AMI04  with  -src*"
	message "\nNB: you must quote ('str') or double quote (\"str\") the strings - single quotes avoid shell substitution."
	### message "example:   ${0##./} \"-srcCSGC-AMI04\" \"-src*\""	
	message "\n$(colour lb "These are the files to process:")"
	ls *.sh
	exit 2;;
*)	;;	# just continue below
esac


message "===================================="
message $files
for file in $files
do
    message "File: $file"
    message "------> GREP:"				# message doesn't like the ---- without double quotes.
    grep --colour -i -e  "$1" $file			# grep  "\-srcCSGC-AMI04" aws_instances_launch.sh
    message "------> SED:"
    sed --in-place=bak "s^$1^$2^" $file			# sed -n "s/-srcCSGC-AMI04/-src\*/p" aws_instances_launch.sh
done
