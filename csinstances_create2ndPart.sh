#!/usr/bin/env bash
# Assumptions:
# 1) AWS Resources Limits:
#    the AWS account running this script has the proper "limits" as to the number of instances, elastic ip addresses, etc.
# 2) AWS Machine Image specified exists
#-----------------------------------------------------
source colour_utils_functions.sh	 # to add colour to some messages

case $# in
    1) message "$(colour gl $(basename $0)) is creating and launching instances specified in input file $(colour bl $1)";;
    0|*) ### display message on use
	message "
$(colour gl $(basename $0)) creates, associates and configures instances ${hyphen2} instances are associated to $(colour bl "IP addresses previously created") (with csinstances_create1stPart.sh).


$(colour bl "Usage:                $(basename $0)  instancesNamesFile")

 - provide the full or relative path to the file containing the names of the instances to create.
 - example:  $(colour bl "$(basename $0)  courses/genomics01/")$(colour r inputs)$(colour bl /instancesNames.txt)
 - the $(colour bl inputs) directory must be specified as such and inside one or more directories of your choice.
 - an $(colour bl outputs) directory will be created at the same level of the inputs directory where the results 
   of the aws commands will be stored.\n"
	exit 2;;	
esac

error_message="\n$(colour lg $(basename $0)): $(colour redTextWhiteBackground "aborting") creating instances and related resources!\n"

aws_instances_launch.sh		"$1" || { message "$error_message"; exit 1; }
aws_elasticIPs_associate2ins.sh	"$1" || { message "$error_message"; exit 1; }
aws_instances_configure.sh	"$1" || { message "$error_message"; exit 1; }
exit 0
