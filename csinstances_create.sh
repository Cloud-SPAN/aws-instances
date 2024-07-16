#!/usr/bin/env bash
#-----------------------------------------------------
# Name:		csinstances_create.sh
#
# Creates AWS Machine Image (AMI) instances, createing login key pair/s, intance/s, etc. see steps below
#
# Usage:	csinstances_create.sh  fullOrRelativePathToInstancesNamesFile
#
# Author:	Jorge Buenabad-Chavez
# Date:		20211130
# Version:	2nd - adding the automation of domain names creation through aws_domainNames_create.sh
#		      and tuning the handling of inputs and outputs in all the scripts invoked by this one.
# Assumptions:
# 1) AWS Resources Limits:
#    the AWS account running this script has the proper "limits" as to the number of instances, elastic ip addresses, etc.
# 2) AWS Machine Image specified exists
#-----------------------------------------------------
source colour_utils_functions.sh	 # to add colour to some messages

### messages variables 
error_msg="\n$(colour lg $(basename $0)) $(colour redTextWhiteBackground "aborting") creating instances and related resources!\n"
usage_msg="$(colour gl $(basename $0)) creates instances, login keys and domain names and associates them.
$(colour bl "Usage:                $(basename $0)  instancesNamesFile")

- provide the full or relative path to the file containing the names of the instances to create.
- example:  $(colour bl "$(basename $0)  courses/genomics01/")$(colour r inputs)$(colour bl /instancesNames.txt)
- the $(colour bl inputs) directory must be specified as such and inside one or more directories of your choice.
- an $(colour bl outputs) directory will be created at the same level of the inputs directory where the results 
  of the aws commands will be stored.
- $(colour r NB): the $(colour bl inputs) directory $(colour cyan "may have") the $(colour bl tags.txt) file but $(colour r "must have") the $(colour bl resourcesIDs.txt) file too.
$(colour bl tags.txt) contains \"key value\" pairs (one per line) to tag AWS resources; up to 10 tags are used."

##########  START

case $# in
    1)  message "$(colour gl $(basename $0)): creating instances with names in input file $(colour bl $1)" 
	;;        
    0|*) message "$usage_msg" ; valid_AWS_configurations_print;  exit 1 ;;	
esac

check_theScripts_csconfiguration        "$1" || { message "$error_msg"; exit 1; }

aws_loginKeyPair_create.sh 		"$1" || { message "$error_msg"; exit 1; }
aws_instances_launch.sh			"$1" || { message "$error_msg"; exit 1; }

if [ -f "${1%/*}/.csconfig_DOMAIN_NAMES.txt" ]; then  ### %/* gets the inputs directory path
    aws_domainNames_create.sh 		"$1" || { message "$error_msg"; exit 1; }
fi
aws_instances_configure.sh 		"$1" || { message "$error_msg"; exit 1; }
exit 0

