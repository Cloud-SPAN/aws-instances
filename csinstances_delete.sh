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

### message variables
error_msg="\n$(colour lg $(basename $0)): $(colour redTextWhiteBackground "aborting") deleting instances and related resources!\n"
usage_msg="\n$(colour gl $(basename $0)) deletes instances and related login keys and domain names.

$(colour bl "Usage:          $(basename $0) instancesNamesFile")

 - provide the full or relative path to the file containing the names of the instances to delete.
 - example:  $(colour bl "$(basename $0) courses/genomics01/")$(colour r inputs)$(colour bl /instancesNames.txt)
 - the $(colour bl inputs) directory must be specified as such and inside one or more directories of your choice.
 - an $(colour bl outputs) directory will be created at the same level of the inputs directory where the results 
   of the aws commands will be stored.\n"

#############  START 

case $# in
    1) message "$(colour gl $(basename $0)) is terminating instances specified in input file $(colour bl $1)";;
    0|*) message "$usage_msg" ;	exit 1 ;;
esac

check_theScripts_csconfiguration        "$1" || { message "$error_msg"; exit 1; }

aws_instances_terminate.sh		"$1" || { message "$error_msg"; exit 1; }
aws_loginKeyPair_delete.sh		"$1" || { message "$error_msg"; exit 1; }

if [ -f "${1%/*}/.csconfig_DOMAIN_NAMES.txt" ]; then ### %/* gets inputs dir. path
    aws_domainNames_delete.sh "$1" || { message "$error_msg"; exit 1; }
fi
exit 0
