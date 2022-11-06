#!/bin/bash
# updates aws cli, deleting previous download
echo Installing/Updating aws cli

if [ ! -d ~/software/others/ ]
then
    echo
    echo Creating directory ~/software/others/ to hold the download of aws cli
    mkdir -p ~/software/others/
fi

cd ~/software/others
aws --version > awscurrentversion	# to display below and compare with installed version

if [ -d aws/ ]
then
    echo
    echo Deleting previous installation
    rm -fr aws
fi

echo
echo Downloading from "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip"
echo
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip		# creates directory ~/software/others/aws/   which has some instructions
sudo ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update  #sudo ./aws/instal # first time only

echo Cleaning: deleting awscliv2.zip and aws tmp directory for download.
rm awscliv2.zip
rm -fr aws

echo Old version was:
cat awscurrentversion
rm  awscurrentversion		### is deleting the file where I put the output

echo 
echo Installed version is:
aws --version
cd				### back home directory
