#!/usr/bin/env bash
#-----------------------------------------------------
# Name:		main_instances_create.sh
#
# Creates AWS Machine Image (AMI) instances, createing login key pair/s, intance/s, etc. see steps below
#
# Usage:	main_instances_create.sh  fullOrRelativePathToInstancesNamesFile
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

case $# in
    1) message "$(colour gl $(basename $0)) is creating login keys, IP addresses and domain names for instances specified in input file $(colour bl $1)";;
    0|*) ### display message on use
	message "
$(colour gl $(basename $0)) creates login keys, IP addresses and domain names for $(colour bl instances) that 
$(colour bl "will be created later") (with csinstances_2ndPart_create.sh).

$(colour bl "Usage:                $(basename $0)  instancesNamesFile")

 - provide the full or relative path to the file containing the names of the instances to create.
 - example:  $(colour bl "$(basename $0)  courses/genomics01/")$(colour r inputs)$(colour bl /instancesNames.txt)
 - the $(colour bl inputs) directory must be specified as such and inside one or more directories of your choice.
 - an $(colour bl outputs) directory will be created at the same level of the inputs directory where the results 
   of the aws commands will be stored.\n"
	exit 2;;	
esac

error_message="\n$(colour lg $(basename $0)): $(colour redTextWhitekBackground "aborting") creating instances and related resources!\n"

aws_loginKeyPair_create.sh	"$1" || { message "$error_message"; exit 1; }
aws_elasticIPs_allocate.sh	"$1" || { message "$error_message"; exit 1; }
aws_domainNames_create.sh	"$1" || { message "$error_message"; exit 1; }
exit 0
