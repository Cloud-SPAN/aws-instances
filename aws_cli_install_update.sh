#!/bin/bash
#  Title	: aws_cli_install_update.sh
#  Date		: 20221109
#  Author	: "Jorge Buenabad-Chavez" <jorge.buenabad-chavez@york.ac.uk>
#  Version	: 1.0
#  Description	: installs or updates the AWS CLI and AWS completer locally (no need for sudo use)
#  Options	: [-l][-u][-v]  -- description below
#-------------------------------------
# helper functions
source colours_functions.sh	 # to add colour to some messages

function message() {
    printf "%b\n" "$1"		### %b: print the argument while expanding backslash escape sequences.
    if [ -n "$2" ]; then	### if $2 is specified, it is log file where the call wants store the message in $1
	printf "%b\n" "$1" >> "$2"	
    fi
}

function message_use() {
    printf "%b\n" \
	   "`colour lb $(basename $0)` installs or updates the AWS CLI and the AWS completer locally."\
	   " "
}

message_use
read -N 1 -p "Do you want to continue (y/n)?: " option
if [ "$option" != "n" -a "$option" != "N" -a "$option" != "y" -a "$option" != "Y" ]; then
    message "\nWrong option $option. Script cancelled." $logfile
    exit 1;
elif [ "$option" == "n" -o "$option" == "N" ]; then
    message "\nScript cancelled ($option)." $logfile
    exit 1;
fi

message "\nInstalling/updating `colour lb aws` (CLI)"

mkdir ___tmpaws
cd  ___tmpaws
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip		# creates directory aws in current directory
./aws/install --bin-dir $HOME/.local/binaws --install-dir $HOME/.local/aws-cli --update

message "Cleaning: deleting awscliv2.zip and aws tmp directory for download."
rm awscliv2.zip
rm -fr aws

message "Installed version of aws:"
aws --version
cd				### back home directory
