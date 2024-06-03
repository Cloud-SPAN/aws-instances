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

### Defaults and string messages 
domainNames=FALSE

error_msg="\n$(colour lg $(basename $0)) $(colour redTextWhiteBackground "aborting") creating instances and related resources!\n"
usage_msg="\n$(colour gl $(basename $0)) creates instances, IP addresses and domain names and associates them.

$(colour bl "Usage:                $(basename $0) [-d] instancesNamesFile")

 - use $(colour lb "-d") to create $(colour lb "custom domain names") to access instances if you have setup a based domain name.
   Otherwise, generic domain names and IP addresses provided by AWS will be used to access instances.
 - provide the full or relative path to the file containing the names of the instances to create.
 - example:  $(colour bl "$(basename $0)  courses/genomics01/")$(colour r inputs)$(colour bl /instancesNames.txt)
 - the $(colour bl inputs) directory must be specified as such and inside one or more directories of your choice.
 - an $(colour bl outputs) directory will be created at the same level of the inputs directory where the results 
   of the aws commands will be stored.\n"

### run starts here 

case $# in
    1) ### run without domain names
	message "$(colour gl $(basename $0)) is creating and launching instances specified in input file $(colour bl $1)" 
	#check_theScripts_configuration_files $1 "NO_DOMAIN_NAMES"
	exit 2;;

    2) ### run with domain names
	if [ ! $1 == "-d" ]; then
	    message "$(colour red "ERROR:") option $1 is not valid, aborting."
	    message "$usage_msg" 
	    exit 2
	fi
	;;
	#check_theScripts_configuration_files $2 "DOMAIN_NAMES"
	#exit 2
	
        #domainNames=$(is_base_domain_stuff_specified $2)
	#if [ $domainNames == TRUE ]; then
	#    message "option $1 is valid, but not yet."
	#    exit 0
	#fi ;;
    0|*) message "$usage_msg" ; exit 2;;	
esac

#exit 0  ### delete me once the above is ready!
message "$(colour gl $(basename $0)) is creating and launching instances specified in input file $(colour bl $1)" 
domainNames=TRUE

aws_loginKeyPair_create.sh		"$2" || { message "$error_msg"; exit 1; }
aws_instances_launch.sh			"$2" || { message "$error_msg"; exit 1; }
if [ $domainNames == TRUE ]; then
    #aws_elasticIPs_allocate.sh		"$2" || { message "$error_msg"; exit 1; }
    aws_domainNames_create.sh		"$2" || { message "$error_msg"; exit 1; }
    #aws_elasticIPs_associate2ins.sh	"$2" || { message "$error_msg"; exit 1; }
    aws_instances_configure.sh		"$2" || { message "$error_msg"; exit 1; }
else
    aws_instances_configureNoDNs.sh	"$2" || { message "$error_msg"; exit 1; }
fi
exit 0
