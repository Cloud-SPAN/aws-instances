#!/bin/bash
#-----------------------------------------------------
# Name:		main_instances_delete.sh
#
# Deletes AWS Machine Image (AMI) instances, deleteing/deallocating login key pair/s, ip addresses, intances, etc. see steps below
#
# Usage:	main_instances_delete.sh  fullOrRelativePathToInstancesNamesFile
#
# Author:	Jorge Buenabad-Chavez
#		Cloud-SPAN Team
# Date:		20211207
# Version:	1
#-----------------------------------------------------
#
source colours_functions.sh

case $# in
    1) echo -e "`colour greenlight ${0##./}` is terminating instances specified in input file `colour brownlight $1`";;
    0|*) echo -e "`colour gl ${0##./}` terminates instances, IP addresses and domain names."
	 echo " "
	 echo -e "`colour bl "Usage:   ${0##./}   instancesNamesFile"`"
	 echo ""
	 echo "  - provide the full or relative path to the file containing the names of the instances to terminate."
	 echo -e "  - for example:  `colour bl "${0##./}  instances_data/inputs/instancesNames.txt"`"
	 echo "  - an outputs directory will be created (if it doesn't exist) at same level of the inputs directory."
	 echo "    where the results of invoked aws commands will be stored."
	 exit 2;;
esac

echo "Terminating instances:"
aws_instances_terminate.sh	$1	

echo "Deleting login key pairs:"
aws_loginKeyPair_delete.sh $1	

echo "Deleting domain names:"
aws_domainNames_delete.sh $1

echo "Disassociating IPs from instances:"
aws_elasticIPs_disassociate.sh $1	  

echo "Deallocating (deleting) elastic IPs:"
aws_elasticIPs_deallocate.sh $1

exit 0


