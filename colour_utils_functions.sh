#!/usr/bin/env bash
# Author:	Jorge Buenabad-Chavez
# Date:		20210917
#		20240528 scripts v2: handling domain names optionally, added
#
# basic colors and styles (underlined, bold, etc)
NO_COLOR="\e[0m"		# is default/white --  \e replaced \033
BLACK="\e[1;30m"
RED="\e[1;31m"
GREEN="\e[1;32m"
BROWN="\e[1;33m"
BLUE="\e[1;34m"
PURPLE="\e[1;35m"
CYAN="\e[1;36m"
GRAY="\e[1;37m"			# this and above are bold (thicker) type and some a bit brighter
COL1="\e[1;38m"			# white, so it seems the above are all the colours available.
COL2="\e[1;39m"			# white
COL3="\e[1;40m"			# white
LIGHT_BLACK="\e[0;30m"
LIGHT_RED="\e[0;31m"
LIGHT_GREEN="\e[0;32m"
LIGHT_BROWN="\e[0;33m"
LIGHT_BLUE="\e[0;34m"
LIGHT_PURPLE="\e[0;35m"
LIGHT_CYAN="\e[0;36m"
LIGHT_GRAY="\e[0;37m"

# my functions
quotes() {
    echo \"$1\"
}

colour() {
    # $1 is the colour/s and $2 is the text to colour 
    case $1 in
	# CHANGING TO BOLD COLORS
	red|r)				echo "${RED}$2$NO_COLOR";;
	brown|b)			echo "${BROWN}$2$NO_COLOR";;
	cyan|c)				echo "${CYAN}$2$NO_COLOR";;
	green|g)			echo "${GREEN}$2$NO_COLOR";;
	white|w)			echo "`tput setaf 7``tput bold`$2`tput sgr0`";;
	# CHANGING TO LIGHT COLORS
	redlight|rl|lightred|lr)	echo "${LIGHT_RED}$2$NO_COLOR";;
	greenlight|gl|lightgreen|lg)	echo "${LIGHT_GREEN}$2$NO_COLOR";;
	brownlight|bl|lightbrown|lb)	echo "${LIGHT_BROWN}$2$NO_COLOR";;
	cyanlight|cl|lightcyan|lc)	echo "${LIGHT_CYAN}$2$NO_COLOR";;
	graylight|grl|lightgray|lgr)	echo "${LIGHT_GRAY}$2$NO_COLOR";;
	# CHANGING TEXT AND BACKGROUND COLOURS
	# tput setab [1-7]: Set a background color using ANSI escape
	# tput setaf [1-7] - Set a foreground color using ANSI escape
	# see documentation at the end of tput text colours and modes
	blackTextGreenBackground|btgb|textBlackBackgroundGreen|tbbg)
	    echo "`tput setaf 0``tput setab 2`$2`tput sgr0`";;
	redTextBoldBlackBackground|rtbbb|textRedBoldBackgroundBlack|trbbb)
	    echo "`tput setaf 1``tput setab 0``tput bold`$2`tput sgr0`";;
	redTextWhiteBackground)
	    echo "`tput setaf 1``tput setab 7`$2`tput sgr0`";;
	redTextBoldWhiteBackground)
	    echo "`tput setaf 1``tput setab 7``tput bold`$2`tput sgr0`";;
	greenTextBoldWhiteBackground|gtwb|textGreenBoldBackgroundWhite|tgbw)
	    echo "`tput setaf 2``tput setab 7``tput bold`$2`tput sgr0`";;
	blackTextBoldWhiteBackground|btwb|textBlackBoldBackgroundWhite|tbbw)
	    echo "`tput setaf 0``tput setab 7``tput bold`$2`tput sgr0`";;
	linkcolour|brownTextBlueBackground)
	    echo "`tput setaf 3``tput setab 4``tput bold`$2`tput sgr0`";;
	topiccolour)
	    echo "`tput setaf 3``tput setab 0``tput bold`$2`tput sgr0`";;
	*) echo "${RED}No right options to colour \"$1\" \"$2\"$NO_COLOR";;
    esac
}


cli="${LIGHT_BROWN}CLI${NO_COLOR}"
shell="${LIGHT_BROWN}shell${NO_COLOR}"
terminal="${LIGHT_BROWN}terminal${NO_COLOR}"
console="${LIGHT_BROWN}console${NO_COLOR}"
csenv="${LIGHT_BROWN}CSEnv${NO_COLOR}"
#guide="${LIGHT_CYAN}`tput smul`guide`tput rmul`${NO_COLOR}"
guide="${CYAN}guide${NO_COLOR}"
less="${LIGHT_GREEN}less${NO_COLOR}"
hyphenBlue="$BLUE——$NO_COLOR"		# ${hyphenBlue}
bullet="•"
hyphen2="——"				# ${hyphen2}
hyphen="—"				# ${hyphen}
newln="\n"				# ${newln}
enter="$GREEN↵$NO_COLOR"		# ${enter}
prompthome="`colour lightgray csuser``colour lb @``colour lightgreen instance01cloud-span`:`colour lc \~` $"
promptinshell_data="`colour lightgray csuser``colour lb @``colour lightgreen instance01cloud-span`:`colour lc \~/shell_data` $"
promptinsoftware="`colour lightgray csuser``colour lb @``colour lightgreen instance01cloud-span`:`colour lc \~/software` $"

#__________
newline() {
    printf "\n"
}

#___________________
function message() {
    printf "%b\n" "$1"	      ### %b: print the argument while expanding backslash escape sequences for text colours to take effect.
    if [ -n "$2" ]; then      ### if $2 is specified (is not null -n), it is the log file where the message in $1 is to be added.
	printf "%b\n" "$1" >> "$2"	
    fi
}

#___________________
function message2file() {
    ### $1 message to print
    ### $2 file to print to
    printf "%b\n" "$1" >> "$2"	
}

#________________________________________________
function message_error_awsResourceFiles_exist() {
    # $1 is the script checking the Scripts configuration files, any of these: aws_domainNames_create.sh, aws_elasticIPs_allocate.sh,
    #	 aws_elasticIPs_associate2instance.sh, aws_instances_launch.sh, aws_loginKeyPair_create.sh
    # $2 is the list of resource files to be created which SHOULD NOT EXIST
    # $3 instancesNamesFile.txt used to create instances and/or related resources

    message "$(colour red "Environment condition ERROR"):
$(colour lg ${1}) $(colour redTextWhiteBackground aborting): the following file/s already exist and $(colour lb "WILL NOT") be overwritten:"
    message "\n$2"			###     # did not work without double quotes: message "$(colour lb $2)"
    message "- You are trying to create instances and related resources using $(colour lb "previously used") instances names. 
- The file/s contain AWS resource ID/s that are needed to delete the related resource/s from your 
  AWS account. $(colour lb Delete) the resources (before creating them again) running this command:

  $(colour lb "csinstances_delete.sh") \"instancesNamesFile-you-used-to-create-the-resource/s\" 

- If you have already deleted the instances and related resource/s, try the following: 
  - rename or delete the \"../$(colour lb outputs)/..\" parent directory of $(colour lb "the file/s") before creating the instances
  - or check for typing errors in the $(colour lb "names") of the instances your are trying to create."
    return 0
}

#_____________________________________________________
function message_error_awsResourceFiles_DONT_exist() {
    # $1 is the script checking the Scripts configuration files, any of these: aws_domainNames_create.sh, aws_elasticIPs_allocate.sh,
    #	 aws_elasticIPs_associate2instance.sh, aws_instances_launch.sh, aws_loginKeyPair_create.sh
    # $2 is the list of resource files to be created which SHOULD NOT EXIST
    # $3 instancesNamesFile.txt used to create instances and/or related resources

    message "Environment condition $(colour brown "WARNING"):
$(colour lg "${1}") $(colour redTextWhiteBackground aborting): the following file/s DO NOT exist:"
    message "\n$2"
    message "- Check you are using the same $(colour lb "instances names") you used to create the instances or resources.
- RECALL that instances and related resouces (IP, login keys, etc.) are created, configured, deleted, 
  etc., using the $(colour lb "instance-names") you specify in an \"instancesNamesFile\".
- Check for typing errors in the $(colour lb "instances-names") in the \"instancesNamesFile\" you are using."
    return 0
}

#_________________________________________________
function check_created_resources_results_files() {
    # $1 is either "DO-EXIST" or "DO-NOT-EXIST"
    # $2 is the type of created resource files whose existence is to be checked, namely:
    #    "INSTANCE_FILES", "IP_ADDRESS_FILES", "LOGIN_KEY_FILES", and "DOMAIN_NAME_FILES" 
    # $3 outputsResourceDir within the outuputs dir
    # $4 instancesNamesFile.txt used to create instances and/or related resources
    local files_list=""
    local instance=""
    local resource_filename=""
    local outputs_dir=${3%/inputs*}/outputs	### general outputs directory where results files are.
    local instances_names=( `cat $3` )
    
    for instance in ${instances_names[@]}	### instancesNames WAS $3 but for instance in ${4}[@] or ${4[@]} DOES NOT WORK
    do
	instance=${instance%-src*}		### get rid of suffix "-srcAMInn.." if it exists
	case "$2" in
	    "DOMAIN_NAME_FILES" ) 
		resource_filename="$outputs_dir/domain-names-creation-output/domain-name-create-$instance.txt" ;;
	    
	    "INSTANCE_FILES" )
		resource_filename="$outputs_dir/instances-creation-output/$instance.txt" ;;
	    
	    "IP_ADDRESS_FILES" )
		resource_filename="$outputs_dir/domain-names-creation-output/ip-addresses-$instance.txt" ;;
	    
	    "LOGIN_KEY_FILES" )
		resource_filename="$outputs_dir/login-keys-creation-output/login-key-$instance.txt" ;;
	    
	    *) message "$(colour lg "check_created_resources_results_files $1 $2.."): invalid option: $2" ; return 1;;
	esac
	case "$1" in
	    "DO-NOT-EXIST")
		### first case developed for creating instances or related resources.
		[ -f "$resource_filename" ] && files_list="${files_list}$(colour brown "--->") $resource_filename   $hyphen2 related $(colour lb "instance name"):     ${instance%-src*}\n" ;;
	    
	    "DO-EXIST")
		### second case developed for DELETING instances or related resources or to STOP/START instances.
		[ ! -f "$resource_filename" ] && files_list="${files_list}$(colour brown "--->") $resource_filename   $hyphen2 related $(colour lb "instance name"):     ${instance%-src*}\n" ;;
	esac
    done
    case "$1" in
	"DO-NOT-EXIST")
	    [ -n "$files_list" ] && message_error_awsResourceFiles_exist "$2" "$files_list" "$4" && return 2 ;;
	
 	"DO-EXIST")
	    ### as files SHOULD exist, the error message is about the files NOT existing
	    [ -n "$files_list" ] && message_error_awsResourceFiles_DONT_exist "$2" "$files_list" "$4" && return 2 ;;
    esac
    return 0
}

#___________________________________________
function check_instancesNames_file() {
    # $1 is instancesNames.txt file full path

    [ ! -f $1 ] && message "\n$(colour red ERROR): file $(colour lb "$1") does not exist." && return 1

    ### check the "instancesNamesFile" has only one field in each line and valid characteres, empty lines are ignored.
    awk '
        BEGIN { number_of_fields = 1
	      	bad_instance_name = "FALSE"
	      }  
	      {	if ( NF == 0 ) {
	      	   ;	 ### ignore empty lines
		} else { 
	          if ( NF > 1 ) {
	      	    number_of_fields = NF
	      	    print "--> more than one instance name in line:", $0
	      	  }
		  if ( $0 !~ /^[a-zA-Z][a-zA-Z0-9_-]*$/ ) {
		    bad_instance_name = "TRUE"
	      	    print "--> invalid characters in instance name:", $0
		  }
	        }
	      }
	END   { if ( number_of_fields != 1 || bad_instance_name == "TRUE")
		  exit 3
		else 
		  exit 0
	      }' $1
    [ $? == 0 ] && return 0  # 0: OK, every single line has only one or 0 strings
    message "\n$(colour red "Formatting ERROR") (see lines \"--> ..\" above) in file: $(colour lb "$1") 
The file must contain $(colour lb "ONLY ONE") instance name per line; $(colour lb "instance names") must $(colour r start) with an alphabetic
character and then include only alpha-numeric characters or hyphens (-) or underscores (_). 
$(colour cyan Examples): 
genomics-instance01
MetaGenomics_course_instance-01"
    
    return 1
}

function check_tags_file() {
    # $1 is the tags.txt file full path

    [ ! -f $1 ] && message "\n$(colour cyan Optional) tags file $(colour lb "$1") does not exist, continuing .." && return 0

    message "\nChecking formatting of file ../tags.txt:"

    ### check the "tags" file has two fields in each line (keywork and value) - it does not matter if there are empty lines
    awk '
        BEGIN {  number_of_fields = 2 }  
	      {	 if ( NF != 0 && NF != 2 ) {
	     	   number_of_fields = NF
	      	   print "--> only 2 values per line allowed ( found", NF, "):", $0
		 }
	      }
	END   {  if ( number_of_fields != 2 )
	      	   exit 3
		 else
		   exit 0
	      }' $1

    [ $? == 0 ] && return 0  # 0: OK, every single line has only one or 0 strings
    message "\n$(colour red "Formatting ERROR") (see lines \"--> ..\" above) in file: $(colour lb "$1") 
The file must contain a $(colour lb "key value") pair per line: 2 values /fields /strings! 
You can use up to 10 $(colour lb "key value") pairs and each $(colour lb key) must be unique. 
$(colour cyan Examples):
name		instance
group		BIOL
project		cloud-span
status		prod"
    return 1
}

#_________________________________________________
function valid_AWS_configurations_print () {
    message "A $(colour lb "resourcesIDs.txt") file contains some or all of the keywords below and valid corresponding values:
 
KEYWORD           VALUE examples (Cloud-SPAN's for Genomics course using instance domain names)
                                              ## $(colour cyan NB): \"key value\" pairs can be specified in any order
imageId           ami-07172f26233528178       ## NOT optional: instance template (AMI) id
instanceType      t3.small                    ## NOT optional: processor count, memory size, bandwidth
securityGroupId   sg-0771b67fde13b3899        ## NOT optional: should allow ssh (port 22) communication
subnetId          subnet-00ff8cd3b7407dc83    ## optional: search vpc in AWS console then click subnets
hostZone          cloud-span.aws.york.ac.uk   ## optional: specify to use instance domain names
hostZoneId        Z012538133YPRCJ0WP3UZ       ## optional: specify to use instance domain names

$(colour r NB): keywords are NON-case sensitive; values are validated, last four values against your AWS account
configuration. If $(colour lb hostZone) and $(colour lb hostZoneId) and their values are specified, an instance domain name will
look like this: $(colour cyan instance01.cloud-span.aws.york.ac.uk), where instance01 is a specified instance name.
  Otherwise, access to each instance will be using the $(colour lb "IP address") or the $(colour lb "generic domain name") provided
by AWS which look like this: $(colour cyan 52.215.49.10) or $(colour cyan ec2-54-171-158-66.eu-west-1.compute.amazonaws.com)."
}

#_________________________________________________
function validate_imageId () {
    ### $1 = imageID_value

    aws ec2 describe-images --image-ids $1 > /dev/null 2> /dev/null
    [[ $? -eq 0 ]] && return 0
    message "--> $(colour lb imageId) $1 is $(colour r "invalid")"
    return 3
}

#_________________________________________________
function validate_instanceType () {
    ### $1 = instanceType_value

    aws ec2 describe-instance-types --instance-types $1  > /dev/null 2> /dev/null
    [[ $? -eq 0 ]] && return 0
    message "--> $(colour lb instanceType) $1 is $(colour r "invalid")"
    return 3
}

#_________________________________________________
function validate_securityGroupId () {
    ### $1 = $securityGroupId_value

    aws ec2  describe-security-groups --group-ids $1  > /dev/null 2> /dev/null
    [[ $? -eq 0 ]] && return 0
    message "--> $(colour lb securityGroupId) $1 is $(colour r "invalid")"
    return 3
}

#_________________________________________________
function validate_subnetId () {
    ### $1 is resourcesIDs.txt file full path
    ### $2 is $subnetId_value if specified

    if [ ! -z $2 ]; then
	### if subnetId_value was specified (! -z: not zero byte or not empty string) check it is valid
	aws ec2  describe-subnets --subnet-ids  $2	 > /dev/null 2> /dev/null
	[[ $? -eq 0 ]] && return 0
	message "--> $(colour lb subnetId) $1 is $(colour r "invalid")"
	return 3

    else
	### try to get an available subnet's id
	#	domainStatus=`aws route53  get-change --id $domainNameChangeID | awk -F " " '$1 == "\"Status\":" {print substr($2, 2, length($2) -3)}'`
	aws ec2  describe-subnets | awk '
        BEGIN {  found = "FALSE"; state = "NOT_AVAILABLE"; subnetID = "NULL"  } 
	      ### we are looking for two lines with these two strings:
	      ### "State": "available",                    in one line and
	      ### "SubnetId": "subnet-00ff8cd3b7407dc83",  in a subsequent line, 2nd field is only an example

	      {	 if ( $1 == "\"State\":" && $2 == "\"available\"," ) {
	      	    state = "AVAILABLE"
	      	 }
		 if ( state == "AVAILABLE" && $1 == "\"SubnetId\":" ) {
		   subnetID = substr($2, 2, length($2) -3)
		   found = "TRUE"
		 }
	      }
	END   {  if ( found == "TRUE" ) {
	      	   print "subnetId          ", subnetID, "    ## found and added here by the Scripts"
	      	   exit 0
		 } else {
		   exit 3
		 }
	      }' >> $1

	[[ $? == 0 ]] && message "--> subnetId $(colour cyan found) and appended to ../resourcesIDs.txt file" && return 0
	message "--> subnetId $(colour r "NOT FOUND"). In the AWS Console, search for $(colour lb vpc), then click $(colour lb subnets) on the left menu."
	return 3
    fi
}

#_________________________________________________
function validate_hostZone () {
    ### $1 = $hostZone_value

    found=`aws route53 list-hosted-zones-by-name --dns-name "$1" | awk -F " " 'BEGIN {found="FALSE"} $1 == "\"Name\":" && substr($2, 2, length($2) -4) == "'"$1"'" { found=substr($2, 2, length($2) -4) } END {print found}'`
    
    [[ $found == $1 ]] && return 0
    message "--> $(colour lb hostZone) $1 is $(colour r "invalid")"
    return 3
}

#_________________________________________________
function validate_hostZoneId () {
    ### $1 = $hostZoneId_value
    
    aws route53  list-hosted-zones-by-name --hosted-zone-id  $1	 > /dev/null 2> /dev/null
    [[ $? -eq 0 ]] && return 0
    message "--> $(colour lb hostZoneId) $1 is $(colour r "invalid")"
    return 3
}

csconfig_domainNames_management=FALSE   ### global as needed by a few functions below
#_________________________________________________
function check_resourcesIDs_file () { 
    # $1 is resourcesIDs.txt file full path
    [ ! -f "$1" ] && message "\n$(colour red ERROR): file (with AWS configuration) $1 does not exist" && return 2
    
    local resourcesIDsFile=$1
    
    local imageId_value=`awk -F " "         'tolower($1) == "imageid" {print $2}' $resourcesIDsFile`
    local instanceType_value=`awk -F " "    'tolower($1) == "instancetype" {print $2}' $resourcesIDsFile`
    local securityGroupId_value=`awk -F " " 'tolower($1) == "securitygroupid" {print $2}' $resourcesIDsFile`
    local subnetId_value=`awk -F " "        'tolower($1) == "subnetid" {print $2}' $resourcesIDsFile`
    local hostZone_value=`awk -F " "	    'tolower($1) == "hostzone" {print $2}' $resourcesIDsFile`
    local hostZoneId_value=`awk -F " "	    'tolower($1) == "hostzoneid" {print $2}' $resourcesIDsFile`

    local configError=FALSE
    csconfig_domainNames_management=FALSE

    message "\nChecking configuration specification in file ../resourcesIDs.txt:"
    ### -z  means zero bytes or empty string
    [ -z $imageId_value ] && \
	message "--> $(colour lb imageId) (AMI id) value $(colour r "not specified")" && configError=TRUE
    [ -z $instanceType_value ] && \
	message "--> $(colour lb instanceType) value $(colour r "not specified")" && configError=TRUE
    [ -z $securityGroupId_value ] && \
	message "--> $(colour lb securityGroupId) value $(colour r "not specified")" && configError=TRUE
    # subnetId and subnetId_value are optional - Toby Hodges' suggestion, but still is validate below on trying to get one
    #[ -z $subnetId_value ] && \
    #	message "--> $(colour lb subnetId) value is $(colour r "not specified")" && configError=TRUE

    { [ ! -z $hostZone_value ] && [ -z $hostZoneId_value ]; } || { [ -z $hostZone_value ] && [ ! -z $hostZoneId_value ]; } && configError=TRUE
    
    # -n DOES NOT WORK so used "! -z" instead, as awk seems to return empty string
    #[ -n $hostZone_value ] && [ -n $hostZoneId_value ] && csconfig_domainNames_management=TRUE
    [ ! -z $hostZone_value ] && [ ! -z $hostZoneId_value ] && csconfig_domainNames_management=TRUE

    [ $configError == TRUE ] && \
	{ message "\n$(colour r "Configuration specification error") in file:\n$resourcesIDsFile\n" ; valid_AWS_configurations_print ; return 2; }
    
    message "\nValidating configuration values in file ../resourcesIDs.txt:"
    validate_imageId $imageId_value			 || configError=TRUE 
    validate_instanceType $instanceType_value		 || configError=TRUE 
    validate_securityGroupId $securityGroupId_value	 || configError=TRUE 
    validate_subnetId $resourcesIDsFile $subnetId_value  || configError=TRUE 
    
    if [ $csconfig_domainNames_management == TRUE ]; then
	validate_hostZone $hostZone_value		 || configError=TRUE 
	validate_hostZoneId $hostZoneId_value		 || configError=TRUE
    fi

    [ $configError == TRUE ] && \
	{ message "\n$(colour r "Configuration validation error") in file:\n$resourcesIDsFile\n" ; valid_AWS_configurations_print ; return 3; }

    if [ $csconfig_domainNames_management == TRUE ]; then
	message "--> $(colour lb "base domain name") to create instance domain names was $(colour lb FOUND) and validated.
Each instance to be created will be accessed with a domain name that looks like this:
$(colour cyan instance01.$hostZone_value) (where instance01 is just an example of an instance name).\n"
    else
	message "--> NO $(colour lb "base domain name") was FOUND. 
Each instance to be created will be accessed with the $(colour lb "IP address") or the $(colour lb "generic domain name") provided
by AWS, which look like this: $(colour cyan 52.215.49.10) or $(colour cyan ec2-54-171-158-66.eu-west-1.compute.amazonaws.com).\n"
    fi
    return 0
}

#_______________________________________
function create_csconfiguration_file() {   ### if user configuration files are fine.
    # $1 is the full path of instancesNamesFile.txt
    local inputsDir=${1%/*}
    local configError=FALSE

    ### check_instancesNames_file $1 is invoked from other scripts -- but we only want the next message to appear when called here
    message "\nChecking formatting of file ../$(basename $1):"
    check_instancesNames_file $1                          || configError=TRUE
    check_tags_file	      $inputsDir/tags.txt         || configError=TRUE
    check_resourcesIDs_file   $inputsDir/resourcesIDs.txt || configError=TRUE

    [ $configError == TRUE ] && return 3

    ### Everything fine, give option as to whether to create the csconfiguration file
    read -p "Would you like to continue (y/n)?: " option

    if [ "$option" != "n" -a "$option" != "N" -a "$option" != "y" -a "$option" != "Y" ]; then
	message "\nWrong option $option, cancelling."
	return 1;
    elif [ "$option" == "n" -o "$option" == "N" ]; then
	message "\nRun cancelled ($option)."
	return 1;
    fi
    
    if [ $csconfig_domainNames_management == TRUE ]; then    
	touch $inputsDir/.csconfig_DOMAIN_NAMES.txt
    else
	touch $inputsDir/.csconfig_NO_DOMAIN_NAMES.txt
    fi
    return 0
}

#________________________________________________
function check_theScripts_csconfiguration() {
    # $1 is the full path of instancesNamesFile.txt 
    local inputsDir=${1%/*}	  # %/* returns what is left after eliminating the last / and any character following it

    if [ -f "$inputsDir/.csconfig_DOMAIN_NAMES.txt" ]; then
	### if configuration file exists, only check the formatting of the "instancesNamesFile" in case it is a new such file
	{ check_instancesNames_file $1 && return 0; } || return 2

    elif  [ -f "$inputsDir/.csconfig_NO_DOMAIN_NAMES.txt" ]; then
	### if configuration file exists, only check the formatting of the "instancesNamesFile" in case it is a new such file
	{ check_instancesNames_file $1 && return 0; } || return 2

    else
	### if no configuration file exists, create it if files "instancesNamesFile", resourcesIDs.txt and tags.txt are
	### well configured
	{ create_csconfiguration_file "$1" && return 0; } || return 2
    fi
}
