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

#___________________________________________
function check_instancesNamesFile_format() {
    # $1 is the script checking the instancesNamesFile format, any of these: aws_domainNames_create.sh, aws_elasticIPs_allocate.sh,
    #	 aws_elasticIPs_associate2instance.sh, aws_instances_launch.sh, aws_loginKeyPair_create.sh
    # $2 instancesNamesFile actual name used to create instances and/or related resources

    [ ! -f $2 ] && message "\n$(colour red ERROR): file $(colour lb "$2") does not exist." && return 1
    ### check the "instancesNamesFile" has only one field in each line - it does not matter if there are empty lines
    fields_in_instances_names_file=`awk '
        BEGIN { number_of_fields = 1 }  
	      {	if ( NF > 1 )
	     	   number_of_fields = NF
	      }
	END   { print number_of_fields }' $2`

    [ $fields_in_instances_names_file -eq 1 ] && return 0  # 0: OK, every single line has only one or 0 strings
    message "\n$(colour red "File configuration ERROR"): 
$(colour lg ${1}): the file $(colour lb ../$(basename "$2")) must contain $(colour lb "only one") instance name per line. 
Some lines have up to $fields_in_instances_names_file fields! $(colour lb "Check it is the right file").

An $(colour lb "instance name") must consist of alpha-numeric characters and hyphens/minus signs (-) only. $(colour lb Examples): 
genomics-instance01
MetaGenomics-course-instance-01
"
    return 1
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
    # $1 either "DO-EXIST" or "DO-NOT-EXIST"
    # $2 the script checking: aws_*.sh (but not: aws_cli_install_update_linux.sh - aws_storageEBS_increase.sh - aws_instances_configure.sh)
    # $3 outputsResourceDir within outuputs dir
    # $4 instancesNamesFile.txt used to create instances and/or related resources
    local instances_names=( `cat $4` )
    local files_list=""
    local instance=""
    local resource_filename=""
    
    for instance in ${instances_names[@]}	  ### $4 WAS instancesNames but for instance in ${4}[@] or ${4[@]} DOES NOT WORK
    do  ### determine which script is making the call to determine the outputs/aws_resources_dir/instance_resource_file.txt/.json
	case "$2" in
	    "csinstances_start.sh" | "csinstances_stop.sh" | "aws_instances_launch.sh" | "aws_instances_terminate.sh" | \
		"aws_instances_configure.sh" | "aws_instances_configureNoDNs.sh"  )
		resource_filename="$3/${instance}.txt" ;;
	    
	    "aws_elasticIPs_allocate.sh" | "aws_elasticIPs_deallocate.sh" ) ### | "aws_domainNames_delete.sh" ) ### in v1:
		# deleting domain names needed to check for the existence of the file containing the relevant IP address
		# because deleting a domain name had to specify the mapping IP address as specified here:
		# https://awscli.amazonaws.com/v2/documentation/api/latest/reference/route53/change-resource-record-sets.html
		# resource_filename="$3/elastic-IPaddress-for-${instance%-src*}.txt" ;;
		resource_filename="$3/elastic-IPaddress-for-${instance%-src*}.txt" ;;

	    "aws_loginKeyPair_create.sh" | "aws_loginKeyPair_delete.sh" )
		resource_filename="$3/login-key-${instance%-src*}.json" ;;
	    
	    "aws_elasticIPs_associate2ins.sh" | "aws_elasticIPs_disassociate.sh" )
		resource_filename="$3/${instance%-src*}-ip-associationID.txt";;

	    "aws_domainNames_create.sh" | "aws_domainNames_delete.sh" ) ### for v2, "aws_domainNames_delete.sh" was moved here
		resource_filename="$3/domain-name-create-${instance%-src*}.txt" ;;
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

#_________________________________________________
function wrong_key_words_msg() {
    
    message "Valid key words in a ../inputs/resourcesIDs.txt file include and must be followed by value:"
    message "imageId"
    message "instanceType"
    message "securityGroupId"
    message "subnetId             (optional, depending on AWS acc. configuration)"
    message "hostZone             (optional)"
    message "hostZoneId           (optional)"
    return 0
}

#_________________________________________________
function create_csconfiguration_file() {   ### if possible
    # $1 either "DOMAIN_NAMES" or "NO_DOMAIN_NAMES" as requested by the user running csinstances_create.sh
    # $2 resourcesIDs.txt file path
    message "create_csconfiguration_file: \$1 $1"
    message "create_csconfiguration_file: \$2 $2"
    
    local domainNames=$1
    local resourcesIDsFile=$2
    # DONE read the $resourcesIDsFile into an array
    # DONE loop through the options checking the key values exist use case within for loop
    # DONE once identified the key value store in a variable named accordingly.
    # message and read option as to what is going to happen based
    # NO : write  "DOMAIN_NAMES" or "NO_DOMAIN_NAMES" at the top .csconfiguration.txt
    # instead write to file  .csconfigurationDNs.txt or .csconfigurationNODNs.txt
    # writhe the variable names, keys, and their values in a specific order.
    local imageId_key instanceType_key securityGroupId_key subnetId_key hostZone_key hostZoneId_key
    local imageId_val instanceType_val securityGroupId_val subnetId_val hostZone_val hostZoneId_val
    local WORDS word wordsNumber i wrongKeys=FALSE

    WORDS=( `cat $resourcesIDsFile` )
    #for word in ${words[@]}
    wordsNumber=${#WORDS[@]}
    for (( i = 0; i < $wordsNumber ; i=i+2  ))
    do  # convert each word to lowercase
	local word=${WORDS[$i],,}	### ,, converts everything to lowercase
	message "word being processed $word"
	case ${word} in
	    "imageid" )
		imageId_key=${WORDS[$i]} ; imageId_val=${WORDS[$i+1]}
		message "imageId_key $imageId_key imageId_val $imageId_val" ;;
	    "instancetype" )
		instanceType_key=${WORDS[$i]} ;	instanceType_val=${WORDS[$i+1]}
		message "instanceType_key $instanceType_key instanceType_val $instanceType_val" ;;
	    "securitygroupid" )
		securityGroupId_key=${WORDS[$i]} ; securityGroupId_val=${WORDS[$i+1]} 
		message "securityGroupId_key $securityGroupId_key securityGroupId_val $securityGroupId_val" ;;
	    "subnetid")
 		subnetId_key=${WORDS[$i]} ; subnetId_val=${WORDS[$i+1]}
		message "subnetId_key $subnetId_key subnetId_val $subnetId_val" ;;
	    "hostzone" )
		hostZone_key=${WORDS[$i]} ; hostZone_val=${WORDS[$i+1]}
		message "hostZone_key $hostZone_key hostZone_val $hostZone_val" ;;
	    "hostzoneid" )
		hostZoneID_key=${WORDS[$i]} ; hostZoneID_val=${WORDS[$i+1]}
		message "hostZoneID_key $hostZoneID_key hostZoneID_val $hostZoneID_val" ;;
	    *) message "$(colour lr "invalid key word"): ${WORDS[$i]}" ;
	       wrongKeys=TRUE ;;
	       #exit 2; return 1;;
	esac
    done
    ### check each of the resource configurations given.
    [ $wrongKeys == TRUE ] && wrong_key_words_msg && return 2

    ### perhaps I don't need to do much checking as aws calls will reject the call if wrong
    [ -z $imageId_key ] && message "variable \$hostZone_key THE TRUE was not specified:" && return 2 
    [ -z $instanceType_key ] && message "variable \$hostZone_key THE TRUE was not specified:" && return 2 
    [ -z $securityGroupId_key ] && message "variable \$hostZone_key THE TRUE was not specified:" && return 2 
    [ -z $subnetId_key ] &&   message "variable \$hostZone_key was not specified:" && return 2
    if [ $domainNames == DOMAIN_NAMES ]; then
	[ -z $hostZone_key ] &&	message "variable \$hostZone_key was not specified:" && return 2 
	[ -z $hostZoneId_key ] && message "variable \$hostZone_key was not specified:" && return 2
    fi
    ### everything was fine, now create the .csconfiguration file 

    
    exit 0
}

#_________________________________________________
function check_theScripts_configuration_files() {
    # $1 the instancesNamesFile.txt full path
    # $2 either "DOMAIN_NAMES" or "NO_DOMAIN_NAMES" as requested by the user in running csinstances_create.sh
    message "check_theScripts_configuration_files: \$1 $1"
    message "check_theScripts_configuration_files: \$2 $2"
    
    local instancesNamesFile=${1}
    local domainNames="FALSE"
    # return what is left after eliminating the last / and any character following it
    local inputsDir=${1%/*}
    # return what is left after eliminating the second to last / and "inputs" and any character following "inputs",
    # then adds "/outputs"
    # local outputsDir=${1%/inputs*}/outputs      
    resourcesIDsFile=$inputsDir/resourcesIDs.txt
    tagsFile=$inputsDir/tags.txt
    configFile=$inputsDir/.csconfiguration.txt

    create_csconfiguration_file "$2" "$resourcesIDsFile"
    message "finishing"
    exit 2

    if [ -f $configFile ]; then
	# read the first line, domainNamesConf="DOMAIN_NAMES" or "NO_DOMAIN_NAMES"
	# if [ -z $2 ];
	#     ### no domainNames option specified
	#    return 0 (OK) for the calling script to continue with the current configuration, no question asked
	#
	# elif [  domainNames ($2) == domainNamesConf ]; then
	#    return 0 (OK) for the calling script to continue with the current configuration, no question asked
	#
	# elif [  domainNames ($2) != domainNamesConf ]; then
	#    message about discrepancy, it is not possible to handle manage instances with and w/o DNs.
	#	they should not specify DNs or not DNs but continue to use the first configuration used
	#	if it is the first time they run the scripts against this inputs dir, they may delef the file .csconfiguration.txt
	#	and start again with the option intended.
	#	or perhaps offer option to delete .csconfiguration.txt file. NO TOO DIFFICULT. Better to delete the file.
	#    return 2 
	# else
	#    message wrong option
	#    return 2
	# fi
	return 0
    else
	# create .csconfiguration.txt based on the options given and the resourcesIDs.txt file
	{ create_csconfiguration_file $2 $resourcesIDsFile && retun 0; } || return 2
    fi
       
#    if [ -n $2 ]; then 
#	if [ $2 == "DOMAIN_NAMES" ];
#	then
#	    domainNames="TRUE"
#	fi
 #   else
  #  fi  
    # NO let it as it is
    # should probably call the above function check_created_resources_results_files() here on behalf of csinstances_create/delete.
    # but let the call in the aws_*.sh scripts in case they are called individually.
    # just for rsync test
}
