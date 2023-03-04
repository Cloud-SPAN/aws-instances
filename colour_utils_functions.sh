#!/usr/bin/env bash
# Welcome to the csguide
# Author:	Jorge Buenabad-Chavez
# Date:		20210917
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
	redTextWhitekBackground)
	    echo "`tput setaf 1``tput setab 7`$2`tput sgr0`";;
	redTextBoldWhitekBackground)
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
#`colour topiccolour "Overview of CSEnv: structure and software tools available"`
newline() {
    printf "\n"
}

function message() {
    printf "%b\n" "$1"		### %b: print the argument while expanding backslash escape sequences (for text colours to take effect).
    if [ -n "$2" ]; then	### if $2 is specified (is not null -n), it is the log file where the call wants store the message in $1
	printf "%b\n" "$1" >> "$2"	
    fi
}

function check_instancesNamesFile_format() {
    # $1 is the script checking the instancesNamesFile format, any of these: aws_domainNames_create.sh, aws_elasticIPs_allocate.sh,
    #	 aws_elasticIPs_associate2instance.sh, aws_instances_launch.sh, aws_loginKeyPair_create.sh
    # $2 instancesNamesFile actual name used to create instances and/or related resources

    [ ! -f $2 ] && message "\n$(colour red ERROR): file $(colour lb "$2") does not exit." && return 1
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

function message_error_awsResourceFiles_exist() {
    # $1 is the script checking the Scripts configuration files, any of these: aws_domainNames_create.sh, aws_elasticIPs_allocate.sh,
    #	 aws_elasticIPs_associate2instance.sh, aws_instances_launch.sh, aws_loginKeyPair_create.sh
    # $2 is the list of resource files to be created which SHOULD NOT EXIST
    # $3 instancesNamesFile.txt used to create instances and/or related resources

    message "$(colour red "Environment condition ERROR"):
$(colour lg ${1}) $(colour redTextWhitekBackground aborting): the following file/s already exist and $(colour lb "WILL NOT") be overwritten:"
    message "\n$2"			###     # did not work without double quotes: message "$(colour lb $2)"
    message "- You are trying to create instances and related resources using $(colour lb "previously used") instances names. 
- The file/s contain AWS resource ID/s that are needed to delete the related resource/s from your 
  AWS account. $(colour lb Delete) the resources (before creating them again) running this command:

  $(colour lb "csinstances_delete.sh") \"instancesNamesFile-you-used-to-create-the-resource/s\" 

- If you have already deleted the instances and related resource/s, then either: 
  - rename or delete the \"../$(colour lb outputs)/..\" parent directory of $(colour lb "the file/s") before creating the instances
  - or check for typing errors in the $(colour lb "names") of the instances your are trying to create."
    return 0
}


function message_error_awsResourceFiles_DONT_exist() {
    # $1 is the script checking the Scripts configuration files, any of these: aws_domainNames_create.sh, aws_elasticIPs_allocate.sh,
    #	 aws_elasticIPs_associate2instance.sh, aws_instances_launch.sh, aws_loginKeyPair_create.sh
    # $2 is the list of resource files to be created which SHOULD NOT EXIST
    # $3 instancesNamesFile.txt used to create instances and/or related resources

    message "Environment condition $(colour brown "WARNING"):
$(colour lg "${1}") $(colour redTextWhitekBackground aborting): the following file/s DO NOT exist:"
    message "\n$2"
    message "- Check you are using the same $(colour lb "instances names") you used to create the instances or resources.
- RECALL that instances and related resouces (IP, login keys, etc.) are created, configured, deleted, 
  etc., using the $(colour lb "instance-names") you specify in an \"instancesNamesFile\".
- Check for typing errors in the $(colour lb "instances-names") in the \"instancesNamesFile\" you are using."
    return 0
}

function check_created_resources_results_files() {
    # $1 either "DO-EXIST" or "DO-NOT-EXIST"
    # $2 the script checking: aws_*.sh (but not: aws_cli_install_update_linux.sh - aws_storageEBS_increase.sh - aws_instances_configure.sh)
    # $3 outputsResourceDir within outuputs dir
    # $4 instancesNamesFile.txt used to create instances and/or related resources
    local instances_names=( `cat $4` ); local files_list=""; local instance=""; local resource_filename=""
    
    for instance in ${instances_names[@]}		## $4 WAS instancesNames but  for instance in ${4}[@] or ${4[@]}   DOES NOT WORK
    do
	case "$2" in
	    "aws_instances_launch.sh" |"aws_instances_terminate.sh" | "aws_instances_configure.sh" | "csinstances_start.sh" |\
		"csinstances_stop.sh" )
		resource_filename="$3/${instance}.txt" ;;
	    
	    "aws_elasticIPs_allocate.sh" | "aws_elasticIPs_deallocate.sh" | "aws_domainNames_delete.sh" )
		# strange this case: domain names need to check for the existence of the file containing the relevant IP address
		resource_filename="$3/elastic-IPaddress-for-${instance%-src*}.txt" ;;

	    "aws_loginKeyPair_create.sh" | "aws_loginKeyPair_delete.sh" )
		resource_filename="$3/login-key-${instance%-src*}.json" ;;
	    
	    "aws_elasticIPs_associate2ins.sh" | "aws_elasticIPs_disassociate.sh" )
		resource_filename="$3/${instance%-src*}-ip-associationID.txt";;

	    "aws_domainNames_create.sh" )
		resource_filename="$3/domain-name-create-${instance%-src*}.txt" ;;
	    *) message "$(colour lg "check_cloud_created_resources_results_files $1 $2.."): invalid option: $2" ; return 1;;
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

