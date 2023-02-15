#!/bin/bash
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
    printf "%b\n" "$1"		### %b: print the argument while expanding backslash escape sequences.
    if [ -n "$2" ]; then	### if $2 is specified, it is the log file where the call wants store the message in $1
	printf "%b\n" "$1" >> "$2"	
    fi
}
