#!/bin/bash
files=`ls aws*.sh instances*.sh`
case $# in
0|1) 	echo "${0##./} replaces a string for another string in all scripts that manage multiple aws instances."
	echo "usage:   ${0##./} \"stringToReplace\" \"stringNew\""   
	echo
	echo "example:   ${0##./} \"-srcCSGC-AMI04\" \"-src*\""
	echo 
	echo "           replaces  -srcCSGC-AMI04  with  -src\*    NB: you must double quote the strings"
	echo
	echo THIS SCRIPT NEEDS FIXING - DO NOT USE.
	echo These are the files to process:
	for file in $files
	do
	    echo  $file
	done
	exit 2;;
*)	;;	# just continue below
esac


echo "===================================="
echo $files
for file in $files
do
    echo File: $file
    echo "------> GREP:"				# echo doesn't like the ---- without double quotes.
    grep --colour -i -e  "$1" $file			# grep  "\-srcCSGC-AMI04" aws_instances_launch.sh
    echo "------> SED:"
    sed --in-place=bak "s/$1/$2/" $file			# sed -n "s/-srcCSGC-AMI04/-src\*/p" aws_instances_launch.sh
done
