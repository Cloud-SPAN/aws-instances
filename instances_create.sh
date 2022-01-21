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
case $# in
    1) echo "${0##./} is creating and launching instances with input from $1";;
    0|*) echo "${0##./}  creates instances, IP addresses and domain names and associates them."
	 echo " "
	 echo "Usage:  ${0##./} instancesNamesFile"
	 echo ""
	 echo "  - provide the full or relative path to the file containing the names of the instances to create."
	 echo "  - for example:  ${0##./}  instances_data/inputs/instancesIDs.txt"
	 echo "  - an outputs directory will be created (if it doesn't exist) at same level of the inputs directory."
	 echo "    where the results of the aws commands will be stored."
	 exit 2;;
esac

# should check file with instance names to create exists

echo "Creating login key pairs:"
aws_loginKeyPair_create.sh $1		

echo "Creating instances:"
aws_instances_launch.sh	$1		

echo "Creating (allocating) elastic IPs:"  # use of parenthesis without ".." causes an error
aws_elasticIPs_allocate.sh $1		

echo "Creating domain names:"		
aws_domainNames_create.sh $1

echo "Associating IPs to instances:"	
aws_elasticIPs_associate2instance.sh $1 

echo "Configuring instances (login key and hostname):"
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
