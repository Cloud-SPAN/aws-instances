#!/bin/bash
# cptoAMI copies a file from the local machine to an Amazon Machine Image (AMI)
#
case $# in
    1)	scp $1 csuser@instanceJorge.cloud-span.aws.york.ac.uk:./$1; exit 0 ;;
    2)	scp $1 csuser@instanceJorge.cloud-span.aws.york.ac.uk:./$2; exit 0 ;;
    0|*)  #echo "usage: `basename $0`  sourceLocalFile  [targetRemoteFile]";
	  # or
	  echo "usage: $0 sourceLocalFile  [targetRemoteFile]";	  
	  echo " ";
	  echo "- if targetRemoteFile is not specied, it'll be named as sourceLocalFile and copied at remote home directory"; 
	  echo " ";
	  exit 2;;
esac

