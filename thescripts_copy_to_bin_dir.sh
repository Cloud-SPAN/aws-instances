#!/usr/bin/env bash
source colour_utils_functions.sh	 # to add colour to some messages

files=`ls *.sh`
case $# in
0) 	message "$(basename $0) copies all the scripts in the current dir, `pwd`, to \"bin\" directory (in the execution path).\n"
	message "usage:   $(basename $0)  \"bin_directory\"\n"   
	message "example:   $(basename $0) ~/bin/csaws    (Jorge's location but you can specify other)\n\n"
	message "These are the files to copy:"
	ls *.sh
	exit 2;;
*)	;;	# just continue below
esac

message "===================================="
message "Copying .sh files to $1"
cp *.sh $1

