#!/bin/bash
#-----------------------------------------------------
# Name:		main_instances_create.sh
#
# Creates AWS Machine Image (AMI) instances, createing login key pair/s, intance/s, etc. see steps below
#
# Usage:	main_instances_create.sh  fullOrRelativePathToInstancesNamesFile
#		# not yet: -s stop instances after creating and launching them
#
# Author:	Jorge Buenabad-Chavez
# Date:		20211130
# Version:	2nd - adding the automation of domain names creation through aws_domainNames_create.sh
#		      and tuning the handling of inputs and outputs in all the scripts invoked by this one.
#-----------------------------------------------------
#
source colours_functions.sh

function message() {
    printf "%b\n" "$1"		### %b: print the argument while expanding backslash escape sequences.
    if [ -n "$2" ]; then	### if $2 is specified, it is log file where the call wants store the message in $1
	printf "%b\n" "$1" >> "$2"	
    fi
}

function message_use() {
    printf "%b\n" \
	   "`colour gl $(basename $0)` creates instances, IP addresses and domain names and associates them."\
	   " " \
	   "`colour bl "Usage:  $(basename $0) instancesNamesFile"`"\
	   " " \
	   "  - provide the full or relative path to the file containing the names of the instances to create."\
	   "  - for example:  `colour bl "$(basename $0)  instances_data/inputs/instancesNames.txt"`"\
	   "  - an outputs directory will be created (if it doesn't exist) at same level of the inputs directory."\
	   "    where the results of the aws commands will be stored."\
	   " "
}

case $# in
    1) message "`colour greenlight $(basename $0)` is creating and launching instances specified in input file `colour brownlight $1`";;
    0|*) message "`colour gl $(basename $0)` creates instances, IP addresses and domain names and associates them.\
\n
`colour bl "Usage:  $(basename $0) instancesNamesFile"`\
\n
  - provide the full or relative path to the file containing the names of the instances to create.\n\
  - for example:  `colour bl "$(basename $0)  instances_data/inputs/instancesNames.txt"`\n\
  - an outputs directory will be created (if it doesn't exist) at same level of the inputs directory.\n\
    where the results of the aws commands will be stored.\n"
     	 exit 2;;
esac

# should check file with instance names to create exists

message "Creating login key pairs:"
aws_loginKeyPair_create.sh $1		

message "Creating instances:"
aws_instances_launch.sh    $1		

message "Creating (allocating) elastic IPs:"  # use of parenthesis without ".." causes an error
aws_elasticIPs_allocate.sh $1		

message "Creating domain names:"		
aws_domainNames_create.sh $1

message "Associating IPs to instances:"	
aws_elasticIPs_associate2instance.sh $1 

message "Configuring instances (login key and hostname):"
aws_instances_configure.sh $1		 # configures up login keys and hostname based on domain name, and logs in to csuser

exit 0

: <<COMMENTS
Assumptions:

1) AWS Resources Limits. 
   
   The AWS account running this script has the proper "limits" as to the number of instances, elastic ip addresses,
   etc.
2) AWS Machine Image specified exists
3) Inputs to the scripts called above by this script is 
4)  

5) Only delete functions outputs directories have the date at the end.

COMMENTS
