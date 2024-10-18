#!/usr/bin/env bash
# starts instances
#------------------------------------------------
source colour_utils_functions.sh	 # to add colour to some messages

case $# in
    1) message  "$(colour gl $(basename $0)) is starting instances specified in input file $(colour bl $1)";;
    0|*) ### display message on use
	message  "\n$(colour gl $(basename $0)) starts instances previously created and stopped.

$(colour bl "Usage:                $(basename $0) instancesNamesFile")

 - provide the full or relative path to the file containing the names of the instances to start.
 - example:  $(colour bl "$(basename $0)  courses/genomics01/")$(colour r inputs)$(colour bl /instancesNames.txt)
 - the $(colour bl inputs) directory must be specified as such and inside one or more directories of your choice.
 - an $(colour bl outputs) directory will be created at the same level of the inputs directory where the results 
   of the aws commands will be stored.\n"
	 exit 2;;
esac

# instancesNamesFile=${1##*/}	 #; delete everything (*) up to last / and return the rest = (`basename $1`) but more efficient
instancesNamesFile=${1}		 #; actually need the full path ; message "instancesNameFile: $instancesNamesFile"

# general inputs directory	 # return what is left after eliminating the last / and any character following it
inputsDir=${1%/*}		 # message "inputsdir: $inputsDir"
				 
# general outputs directory	 # note that some data in the outpus directory (from creating instances) is needed as input
outputsDir=${1%/inputs*}/outputs # return what is left after eliminating the second to last / and "inputs" and any character
				 # following "inputs", then adds "/outputs" # message "outputsdir: $outputsDir"

message "$(colour cyan "Starting instances:")"
check_theScripts_csconfiguration "$instancesNamesFile" || exit 1
check_created_resources_results_files "DO-EXIST" "INSTANCE_FILES" "$instancesNamesFile" || { message "\n$(colour lb "$(basename $0) aborting")"; exit 1; }

if [ -f $inputsDir/.csconfig_DOMAIN_NAMES.txt ]; then
    ### check the domain names creation files exist 
    check_created_resources_results_files "DO-EXIST" "DOMAIN_NAME_FILES" "$instancesNamesFile" || { message "\n$(colour lb "$(basename $0) aborting")"; exit 1; }
fi

outputsDirThisRun=${outputsDir}/instances-start-output`date '+%Y%m%d.%H%M%S'`
if [ ! -d $outputsDirThisRun ]; then
    message "$(colour brown "Creating directory to hold the results of starting instances:")"
    message $outputsDirThisRun
    mkdir -p $outputsDirThisRun
fi

instancesNames=( `cat $instancesNamesFile` )

##################### start the instances
for instanceFullName in ${instancesNames[@]}
do
    instance=${instanceFullName%-src*}		### get rid of suffix "-srcAMInn.." if it exists
    resultsFile=$outputsDirThisRun/$instance.txt

    ### we are using the whole instance name (including -srcAMI.. if present) because we accessing the instance creation results file
    instanceID=`awk -F " " '$1 == "\"InstanceId\":" {print substr($2, 2, length($2) -3)}' $outputsDir/instances-creation-output/$instance.txt`

    aws  ec2  start-instances  --instance-ids $instanceID >> $resultsFile 2>&1
    ### redirection was: 2>&1 | tee -a $outputsDirThisRun/$instance.txt but using tee overrides aws result ($?) for the if below   
    
    awsResult=$?
    if [ $awsResult -eq 0 ]; then
	message "`colour gl Success` starting instance: $instance"  $resultsFile
    else
	message "`colour red Error` ($awsResult) starting instance: $instance"  $resultsFile
	exit 2
    fi
done

######################
message "\n$(colour lb "Checking each instance is running to get its IP address"):"

for instanceFullName in ${instancesNames[@]}
do
    instance=${instanceFullName%-src*}		### get rid of suffix "-srcAMInn.." if it exists
    resultsFile=$outputsDirThisRun/$instance.txt
    
    instanceID=`awk -F " " '$1 == "\"InstanceId\":" {print substr($2, 2, length($2) -3)}' $outputsDir/instances-creation-output/$instance.txt`
    
    while true 
    do
	echo -n "."
	instanceState=`aws ec2 describe-instance-status --instance-id $instanceID | awk -F " " '$1 == "\"Code\":" {print substr($2, 1, length($2) -1)}'`
	if [[ $instanceState == "16" ]]; then
	    #16 running: https://awscli.amazonaws.com/v2/documentation/api/latest/reference/ec2/describe-instance-status.html
	    message "- instance $instance state $instanceState (running)"
	    eip=`aws ec2 describe-instances --instance-ids  "$instanceID" --query 'Reservations[*]. Instances[*]. PublicIpAddress' --output text`
	    ###dateTime=`date '+%Y%m%d.%H%M%S'`
	    ###echo "$eip" > $outputsDir/instances-creation-output/$instance-ip-address-$dateTime-$eip.txt
	    echo "$eip" > $outputsDir/instances-creation-output/$instance-ip-address.txt
	    
	    ### message "\n$(colour lb "Please note"): the IP address ($eip) of instance $instance was saved to file:\n$outputsDir/instances-creation-output/$instance-ip-address-$dateTime-$eip.txt" $resultsFile
	    message "\n$(colour lb "Please note"): the IP address ($eip) of instance $instance was saved to the file:\n$outputsDir/instances-creation-output/$instance-ip-address.txt" $resultsFile
	    break
	else
	    sleep 3
	fi
    done
done

### with dynamic IP addresses, we need to reassign the domain name to the new IP address as described here:
### https://awscli.amazonaws.com/v2/documentation/api/latest/reference/route53/change-resource-record-sets.html
### Action below can be CREATE, DELETE, UPSERT. Using UPSERT instead of CREATE for flexibility
### as with UPSERT, if a resource set doesn’t exist, Route 53 creates it. If a resource set exists Route 53 updates
### it with the values in the request.

if [ -f $inputsDir/.csconfig_DOMAIN_NAMES.txt ]; then
    message "\n$(colour lb "Mapping each instance domain name to its IP address"):"

    for instanceFullName in ${instancesNames[@]}
    do
	instance=${instanceFullName%-src*}		### get rid of suffix "-srcAMInn.." if it exists
	resultsFile=$outputsDirThisRun/$instance.txt
	
	instanceID=`awk -F " " '$1 == "\"InstanceId\":" {print substr($2, 2, length($2) -3)}' $outputsDir/instances-creation-output/$instance.txt`
	
	eip=`aws ec2 describe-instances --instance-ids  "$instanceID" --query 'Reservations[*]. Instances[*]. PublicIpAddress' --output text`
	### we only need the last occurrence of Success, and therefore we are printing the last result found at the END block
	instanceDomainName=`awk -F " " '$1 == "Success" {domainName=$4} END {print domainName}' $outputsDir/domain-names-creation-output/domain-name-create-$instance.txt`
	
	fileRequest="
{\n		
\t   \"Comment\": \"Creating subdomain\",\n
\t   \"Changes\": [\n
\t \t     {\n
\t \t \t      \"Action\": \"UPSERT\",\n
\t \t \t      \"ResourceRecordSet\": {\n
\t \t \t \t         \"Name\": \"$instanceDomainName\",\n
\t \t \t \t         \"Type\": \"A\",\n
\t \t \t \t         \"TTL\": 3600,\n
\t \t \t \t         \"ResourceRecords\": [{ \"Value\": \"$eip\"}]\n
\t \t \t  }\n
\t \t  }\n
\t ]\n
}\n
"
	echo -e $fileRequest > $outputsDirThisRun/${instance}Request.json
	hostZoneID=`awk -F " " '$1 == "hostZoneId" {print $2}' $inputsDir/resourcesIDs.txt`
	
	aws route53 change-resource-record-sets --hosted-zone-id $hostZoneID --change-batch file://$outputsDirThisRun/${instance}Request.json  >> $resultsFile 2>&1
	
	awsResult=$?
	if [ $awsResult -eq 0 ]; then
	    message "`colour gl Success` mapping `colour b "domain:"` $instanceDomainName, `colour b ip:` $eip"
	    message2file "Success mapping domain: $instanceDomainName ip: $eip" $resultsFile
	    ### write domain name and last mapping ip address to the domain name resource creation file as it is therein that
	    ### the scripts csinstances_stop.sh  and aws_domainNames_delete.sh will recover them when needed.
	    message2file "Success mapping domain: $instanceDomainName ip: $eip" $outputsDir/domain-names-creation-output/domain-name-create-$instance.txt
	    message "ssh-keygen -f $HOME/.ssh/known_hosts -R ${instanceDomainName,,}" $resultsFile
	    ssh-keygen -f "$HOME/.ssh/known_hosts" -R "${instanceDomainName,,}"   ### works w all lowercase: ${var,,}
	else
	    message "`colour red Error` ($awsResult) mapping `colour b "domain:"` $instanceDomainName, `colour b ip:` $eip"
	    message "Error ($awsResult) mapping domain: $instanceDomainName  ip: $eip" $resultsFile
	fi
    done
    
    ### Now check each instance domain name is reachable
    message "$(colour lb "Checking each domain is reachable"):"
    
    for instanceFullName in ${instancesNames[@]}
    do
	instance=${instanceFullName%-src*}		### get rid of suffix "-srcAMInn.." if it exists
	resultsFile=$outputsDirThisRun/$instance.txt
	
	### we only need the last occurrence of Success, and therefore we are printing the last result found at the END block
	instanceDomainName=`awk -F " " '$1 == "Success" {domainName=$4} END {print domainName}' $outputsDir/domain-names-creation-output/domain-name-create-$instance.txt`

	domainNameChangeID=`awk -F " " '$1 == "\"Id\":" {print substr($2, 2, length($2) -3)}' $outputsDirThisRun/$instance.txt`
	
	while true 
	do
	    echo -n "."
	    domainStatus=`aws route53  get-change --id $domainNameChangeID | awk -F " " '$1 == "\"Status\":" {print substr($2, 2, length($2) -3)}'`
	    if [[ "$domainStatus" == "INSYNC" ]]; then
		# INSYNC is reachable:
		# https://aws.amazon.com/premiumsupport/knowledge-center/simple-resource-record-route53-cli/
		message " : $instanceDomainName status $domainStatus (reachable)" $resultsFile
		break 
	    else
		sleep 2
	    fi
	done
    done
    message "\n$(colour lb "Please note"): you may need to wait up to one hour to be able to access re-started 
instances with \"ssh\". This is because Domain Name servers ask every hour for changes
to the configuration of instance domain names and IP addresses have just changed.\n"
fi
exit 0
