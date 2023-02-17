#!/usr/bin/env bash
# system-wide configuration and upgrade needed for csuser to install metagenomics software.
# must be run prior to creating the metagenomicsxs AWS AMI
source ~/bin/colours_functions.sh	 # to add colour to some messages

function message() {
    printf "%b\n" "$1"		### %b: print the argument while expanding backslash escape sequences.
    if [ -n "$2" ]; then	### if $2 is specified, it is log file where the call wants store the message in $1
	printf "%b\n" "$1" >> "$2"	
    fi
}

cd
if [ ! -d logs ]; then  
    message "Creating directory logs"
    mkdir logs
fi
logfile=logs/metagenomics_sftwre_install_ubuntuuser.sh`date '+%Y%m%d.%H%M%S'`.txt

message "System is about to be configured and upgraded for csuser to install metagenomics software."
message "This script and the software install by csuser is prior to creating the metagenomics AMI."
message "`colour red "*** NB"`: the `colour lb aws` cli must have been configured already - cancel installation if not."
read -n 1 -p "Do you want to continue (y/n)?: " option

if [ "$option" != "n" -a "$option" != "N" -a "$option" != "y" -a "$option" != "Y" ]; then
    message "\nWrong option $option. Script cancelled." $logfile
    exit 1;
elif [ "$option" == "n" -o "$option" == "N" ]; then
    message "\nScript cancelled ($option)." $logfile
    exit 1;
fi
message "\n($option): Configuring and upgrading system. Please wait:" $logfile

message "`colour lg "Increasing storage to 140 GB: aws_storageEBS_increase.sh 140"`" $logfile
aws_storageEBS_increase.sh 140				# manages its own log file
message "`colour lg "sudo apt-get update"`" $logfile	# lg is ligth green
sudo apt-get update  | tee -a $logfile
message "`colour lg "sudo apt-get upgrade"`" $logfile 
sudo apt-get upgrade -y | tee -a $logfile
message "`colour lg "sudo apt-get install libssl-dev"`" $logfile
sudo apt-get install -y libssl-dev | tee -a $logfile
message "`colour lg "sudo apt-get install libncurses5-dev"`" $logfile
sudo apt-get install -y libncurses5-dev | tee -a $logfile
message "`colour lg "sudo apt-get install libgsl0-dev"`" $logfile
sudo apt-get install -y libgsl0-dev | tee -a $logfile
message "`colour lg "sudo apt-get install python3-pip"`" $logfile
sudo apt install -y python3-pip | tee -a $logfile
message "`colour lg "sudo apt-get install porechop"`" $logfile
sudo apt-get install -y porechop | tee -a $logfile
message "`colour lg "sudo apt update -qq"`" $logfile
sudo apt update -qq | tee -a $logfile
message "`colour lg "sudo apt install --no-install-recommends software-properties-common dirmngr"`" $logfile
sudo apt install -y --no-install-recommends software-properties-common dirmngr  # to update software manager
message "`colour lg "wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | sudo tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc"`" $logfile
wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | sudo tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
message "`colour lg "sudo add-apt-repository \"deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/\""`" $logfile
sudo add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/" | tee -a $logfile
message "`colour lg "sudo apt install --no-install-recommends r-base"`" $logfile
sudo apt install -y --no-install-recommends r-base | tee -a $logfile
message "`colour lg "sudo add-apt-repository ppa:c2d4u.team/c2d4u4.0+"`" $logfile
sudo add-apt-repository -y ppa:c2d4u.team/c2d4u4.0+	# REGISTERING REPO
message "`colour lg "sudo apt-get install docker.io"`" $logfile
sudo apt install -y docker.io | tee -a $logfile
message "`colour lg "sudo groupadd docker"`" $logfile
sudo groupadd docker | tee -a $logfile			# docker group existed already
message "`colour lg "sudo usermod -aG docker csuser"`" $logfile
sudo usermod -aG docker csuser  | tee -a $logfile
message "`colour lg "sudo apt-get install hmmer"`" $logfile
sudo apt install hmmer | tee -a $logfile

message "`colour lg "sudo apt-get update"`" $logfile
sudo apt-get update -y  | tee -a $logfile
message "`colour lg "sudo apt-get upgrade"`" $logfile
sudo apt-get upgrade -y | tee -a $logfile		

#
message "`colour lg "----------------------"`."  $logfile
message "`colour lb "DONE system-wide setting and upgrade"` for csuser to install metagenomics software."  $logfile
message "CHECK the log file $logfile." $logfile
message "You may `colour red "need to reboot"` (sudo shutdown --reboot now) the system more than once" $logfile
message "and run the next command (CHECK login message for updates):" $logfile
message "`colour lightbrown "sudo apt-get --with-new-pkgs upgrade --yes"`" $logfile

