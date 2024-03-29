#!/usr/bin/env bash
#  Title	: aws_cli_install_update-linux.sh
#  Date		: 20221109
#  Author	: "Jorge Buenabad-Chavez" <jorge.buenabad-chavez@york.ac.uk>
#  Version	: 1.0
#  Description	: installs or updates the AWS CLI and AWS completer locally (no need for sudo use)
#  Options	: [-l][-u][-v]  -- description below
#-------------------------------------
# helper functions
source colour_utils_functions.sh	 # to add colour to some messages

message "\n$(colour lb $(basename $0))  installs or updates the AWS CLI and the AWS completer locally.\n"

read -n 1 -p "Do you want to continue (y/n)?: " option

if [ "$option" != "n" -a "$option" != "N" -a "$option" != "y" -a "$option" != "Y" ]; then
    message "\nWrong option $option. Script cancelled." $logfile
    exit 1;
elif [ "$option" == "n" -o "$option" == "N" ]; then
    message "\nScript cancelled ($option)." $logfile
    exit 1;
fi

message "\nInstalling/updating `colour lb aws` (CLI):\n"

cd			### do it in home directory
mkdir ___tmpaws
cd  ___tmpaws

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip	### creates directory aws in current directory

./aws/install --bin-dir $HOME/.local/bincsaws --install-dir $HOME/.local/bincsaws/aws-cli2 --update
echo "complete -C $HOME/.local/bincsaws/aws_completer aws" >> ~/.bashrc

message "\nCleaning: deleting temporary download directory."
cd  			### back to home directory to delete download directory
rm -fr  ___tmpaws

message "\nInstalled version of aws:\n"
aws --version

