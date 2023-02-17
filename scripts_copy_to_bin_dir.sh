#!/usr/bin/env bash
files=`ls *.sh`
case $# in
0) 	echo "$(basename $0) copies all the scripts in the current dir, `pwd`, to \"bin\" directory (in the execution path)."
	echo "usage:   $(basename $0)  \"bin_directory\""   
	echo
	echo "example:   $(basename $0) \"~/bin/\""
	echo 
	echo 
	echo These are the files to copy:
	ls *.sh
	exit 2;;
*)	;;	# just continue below
esac

echo "===================================="
echo Copying .sh files to $1
cp *.sh $1

