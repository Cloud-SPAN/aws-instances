#!/usr/bin/env bash
# system-wide configuration and upgrade needed for csuser to install genomics software.
# must be run prior to creating the genomics AWS AMI
source colour_utils_functions.sh	 # to add colour to some messages and more

#------------ script START 
message "\n$(colour lb $(basename $0)) upgrades and configures the Ubuntu system. 
This script must be run before running the script that installs the $(colour lb genomics) software analysis
tools (softwareInstall_genomics_csuser.sh) in the csuser account." 

read -n 1 -p "Do you want to continue (y/n)?: " option

if [ "$option" != "n" -a "$option" != "N" -a "$option" != "y" -a "$option" != "Y" ]; then
    message "\nWrong option $option. Script cancelled." 
    exit 1;
elif [ "$option" == "n" -o "$option" == "N" ]; then
    message "\nScript cancelled ($option)." 
    exit 1;
fi

cd				### work in home directory
if [ ! -d logs ]; then  
    message "\nCreating directory logs"
    mkdir logs
fi
logfile=logs/genomics_sftwre_install_ubuntuuser.sh`date '+%Y%m%d.%H%M%S'`.txt
message "\n($option): Configuring and upgrading system. Please wait:" $logfile
message "Saving installation logs to file:" $logfile
message "$(colour lb "$logfile")" $logfile

sudo apt-get update -y | tee -a $logfile

message "$(colour lg "sudo apt-get upgrade")" $logfile 
sudo apt-get upgrade -y | tee -a $logfile

message "$(colour lg "sudo apt-get install libssl-dev")" $logfile
sudo apt-get install -y libssl-dev | tee -a $logfile

message "$(colour lg "sudo apt-get install libncurses5-dev")" $logfile
sudo apt-get install -y libncurses5-dev | tee -a $logfile

### required by htslib, samtools, bcftools 
#message "$(colour lg "sudo apt-get install libgsl0-dev")" $logfile   ### was this but in moving to ubuntu 22.04 autoheader and 
#sudo apt-get install -y libgsl0-dev | tee -a $logfile		      ### autoconf were no longer available in /usr/bin
message "$(colour lg "sudo apt-get install -y autoconf automake make gcc perl zlib1g-dev libbz2-dev liblzma-dev libcurl4-gnutls-dev libssl-dev libperl-dev libgsl0-dev")" $logfile
sudo apt-get install -y autoconf automake make gcc perl zlib1g-dev libbz2-dev liblzma-dev libcurl4-gnutls-dev libssl-dev libperl-dev libgsl0-dev | tee -a $logfile

message "$(colour lg "sudo apt-get install python3-pip")" $logfile
sudo apt install -y python3-pip | tee -a $logfile

message "$(colour lg "sudo apt-get install docker.io")" $logfile
sudo apt install -y docker.io | tee -a $logfile

message "$(colour lg "sudo groupadd docker")" $logfile
sudo groupadd docker | tee -a $logfile			# docker group existed already

message "$(colour lg "sudo usermod -aG docker csuser")" $logfile
sudo usermod -aG docker csuser  | tee -a $logfile

message "$(colour lg "sudo apt-get update")" $logfile
sudo apt-get update -y  | tee -a $logfile

message "$(colour lg "sudo apt-get upgrade")" $logfile
sudo apt-get upgrade -y | tee -a $logfile		

#------------------------ DONE
message "$(colour lg "---------------------")
$(colour lg "DONE system-wide setting and upgrade") for csuser to install genomics software.
CHECK the log file $(colour lb "$logfile").

You $(colour red "need to reboot") the system (sudo shutdown --reboot now), login again, and 
check the Ubuntu system message above the Cloud-SPAN message. If the system message says that
some \"updates can be applied immediately\", run this command:

sudo apt-get --with-new-pkgs upgrade --yes

You may need to reboot, login again  and run the above command a few times until the system
message reads \"0 updates can be applied immediately\" - you may want to make a not the command\n"  $logfile
