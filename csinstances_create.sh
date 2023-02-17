#!/usr/bin/env bash
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
source colours_msg_functions.sh	 # to add colour to some messages

case $# in
    1) message "$(colour gl $(basename $0)) is creating and launching instances specified in input file $(colour bl $1)";;
    0|*) ### display message on use
	message "\n$(colour gl $(basename $0)) creates instances, IP addresses and domain names and associates them.

$(colour bl "Usage:                $(basename $0) instancesNamesFile")

 - provide the full or relative path to the file containing the names of the instances to create.
 - example:  $(colour bl "$(basename $0)  courses/genomics01/")$(colour r inputs)$(colour bl /instancesNames.txt)
 - the $(colour bl inputs) directory must be specified as such and inside one or more directories of your choice.
 - an $(colour bl outputs) directory will be created at the same level of the inputs directory where the results 
   of the aws commands will be stored.\n"
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
COMMENTS
