#!/bin/bash
#  Title	: aws_cli_install_update-macOS.sh
#  Date		: 20221109
#  Author	: "Jorge Buenabad-Chavez" <jorge.buenabad-chavez@york.ac.uk>
#  Version	: 1.0
#  Description	: installs or updates the AWS CLI and AWS completer locally (no need for sudo use)
#  Options	: [-l][-u][-v]  -- description below
#-------------------------------------
# helper functions
source colours_msg_functions.sh	 # to add colour to some messages

message "\n$(colour lb $(basename $0))  installs or updates the AWS CLI and the AWS completer locally.\n"

read -n 1 -p "Do you want to continue (y/n)?: " option

if [ "$option" != "n" -a "$option" != "N" -a "$option" != "y" -a "$option" != "Y" ]; then
    message "\nWrong option $option. Script cancelled." 
    exit 1;
elif [ "$option" == "n" -o "$option" == "N" ]; then
    message "\nScript cancelled ($option)." 
    exit 1;
fi

message "\nInstalling/updating $(colour lb aws) (CLI):\n"

cd			### do it in home directory
mkdir ___tmpaws
cd  ___tmpaws

curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"

# macOS ORIGINAL instructions
#installer -pkg AWSCLIV2.pkg \
#	  -target CurrentUserHomeDirectory \
#	  -applyChoiceChangesXML choices.xml
#sudo ln -s /folder/installed/aws-cli/aws /usr/local/bin/aws
#sudo ln -s /folder/installed/aws-cli/aws_completer /usr/local/bin/aws_completer


# need to create the file "choices.xml" but with the name macosConfOptions.xml.

#  ${HOME/#*\//}  is the user name
# sed "s/myusername/${HOME/#*\//}/" $HOME/.local/bincsaws/the-Scripts/aws_cli_install_update_macOS.sh.xml > macosConfOptions.xml
#  but better to use the following to ensure the actual $HOME dir is used --- NOTE the different sed separator : instead of /
sed "s:/Users/myusername:${HOME}\/.local/bincsaws:" $HOME/.local/bincsaws/aws_cli_install_update_macOS.sh.xml > macosConfOptions.xml

message "macosConfOptions.xml  content:"
cat macosConfOptions.xml

message "running macOS installer:"
installer -pkg AWSCLIV2.pkg \
	  -target CurrentUserHomeDirectory \
	  -applyChoiceChangesXML macosConfOptions.xml

# these sudo may fail.
sudo ln -s $HOME/.local/bincsaws/aws-cli/aws $HOME/.local/bincsaws/aws
sudo ln -s $HOME/.local/bincsaws/aws-cli/aws_completer $HOME/.local/bincsaws/aws_completer

# --- same as in linux
echo "complete -C $HOME/.local/bincsaws/aws_completer aws" >> ~/.bash_profile
echo "complete -C $HOME/.local/bincsaws/aws_completer aws" >> ~/.bashrc

message "\nInstalled version of aws:\n"
which aws
aws --version

message "\nCleaning: deleting temporary download directory."
read -n 1 -p "Do you want to continue (y/n)?: " option

if [ "$option" != "n" -a "$option" != "N" -a "$option" != "y" -a "$option" != "Y" ]; then
    message "\nWrong option $option. Script cancelled."
    exit 1;
elif [ "$option" == "n" -o "$option" == "N" ]; then
    message "\nScript cancelled ($option)." 
    exit 1;
fi

cd  			### back to home directory to delete download directory
rm -fr  ___tmpaws

