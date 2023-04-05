#!/usr/bin/env bash
#-----------------------------------------------------
# Name:		csinstances_delete.sh
#
# Deletes AWS Machine Image (AMI) instances, deleteing/deallocating login key pair/s, ip addresses, intances, etc. see steps below
#
# Usage:	csinstances_delete.sh  fullOrRelativePathToInstancesNamesFile
#
# Author:	Jorge Buenabad-Chavez
#		Cloud-SPAN Team
# Date:		20211207
# Version:	1
#-----------------------------------------------------
source colour_utils_functions.sh	 # to add colour to some messages

case $# in
    1) message "$(colour gl $(basename $0)) is terminating instances specified in input file $(colour bl $1)";;
    0|*) ### display message on use
	message "\n`colour gl $(basename $0)` deletes instances and related login keys, IP addresses and domain names.

$(colour bl "Usage:                $(basename $0) instancesNamesFile")

 - provide the full or relative path to the file containing the names of the instances to delete.
 - example:  $(colour bl "$(basename $0)  courses/genomics01/")$(colour r inputs)$(colour bl /instancesNames.txt)
 - the $(colour bl inputs) directory must be specified as such and inside one or more directories of your choice.
 - an $(colour bl outputs) directory will be created at the same level of the inputs directory where the results 
   of the aws commands will be stored.\n"
	exit 2;;
esac

error_message="\n$(colour lg $(basename $0)): $(colour redTextWhitekBackground "aborting") deleting instances and related resources!\n"

aws_instances_terminate.sh	"$1" || { message "$error_message"; exit 1; }
aws_loginKeyPair_delete.sh	"$1" || { message "$error_message"; exit 1; }
aws_domainNames_delete.sh	"$1" || { message "$error_message"; exit 1; }
aws_elasticIPs_disassociate.sh	"$1" || { message "$error_message"; exit 1; }
aws_elasticIPs_deallocate.sh	"$1" || { message "$error_message"; exit 1; }
exit 0
