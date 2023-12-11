#!/usr/bin/env bash
# helper functions
#------------------
source colour_utils_functions.sh		# to add colour to some messages and more
shopt -s expand_aliases				### sets on expand_aliases otherwise docker aliases don't work
#source ~/.bash_aliases

############# this script starts at the end, after the functions, at ####################______ script starts  here:

function remove_samtools() {
    message "`colour lg "removing conda samtools if it exists"` otherwise we cannot update python" $1
    message "conda remove --yes samtools" $1
    conda remove --yes samtools | tee -a $1 			
}

function update_conda() {
    message "updating `colour lb conda`" $1
    message "conda --version" $1
    conda --version | tee -a $1
    message "conda update --yes conda" $1
    conda update --yes conda | tee -a $1
    message "conda --version" $1
    conda --version | tee -a $1
}

function install_conda() {
    ### https://docs.conda.io/projects/miniconda/en/latest/    - Linux version,
    ### but we install in ~/.miniconda3 instead of ~/miniconda3
    message "removing (current) conda `colour lb conda`" $1
    message "cd" $1
    cd
    message "rm -rf ~/.miniconda3" $1
    rm -rf ~/.miniconda3
    message "rm -rf ~/.conda ~/.continuum" $1
    rm -rf ~/.conda ~/.continuum
    message "installing conda `colour lb conda`" $1
    message "cd ~/software" $1
    cd ~/software
    message "wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda3-latest-install.sh" $1
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda3-latest-install.sh
    message "bash miniconda3-latest-install.sh -b -u -p ~/.miniconda3" $1
    bash miniconda3-latest-install.sh -b -u -p ~/.miniconda3  | tee -a $1
    message "rm -rf miniconda3-latest-install.sh" $1
    rm -rf miniconda3-latest-install.sh
    message "~/.miniconda3/bin/conda init bash" $1
    ~/.miniconda3/bin/conda init bash | tee -a $1
    message "conda --version   (installed)" $1
    conda --version | tee -a $1
}

function update_python() {
    message "installing `colour lb "python"`:" $1
    message "python --version   (current version)" $1
    python --version | tee -a $1
    message "conda install python" $1
    conda install --yes python | tee -a $1
    message "python --version" $1
    python --version | tee -a $1
}

function install_fastqc() {
    #	https://www.bioinformatics.babraham.ac.uk/projects/fastqc/		# main website has next link to installation
    #	https://raw.githubusercontent.com/s-andrews/FastQC/master/INSTALL.txt	# instructions here are not clear at all
    #	So i'm going to stick to the conda installation:
    # conda install -c bioconda fastqc
    message "installing `colour lb fastqc`" $1
    message "conda update fastqc		    # did this which updated many packages but the fastqc version was the same" $1
    conda update --yes fastqc | tee -a $1	    # did this which updated many packages but the fastqc version was the same
    message "fastqc --version" $1
    fastqc --version | tee -a $1		    # FastQC v0.11.9
}

function install_cutadapt() {
    # conda install -c bioconda cutadapt	    # Didn't work 
    # but from anaconda link https://anaconda.org/bioconda/cutadapt  i got this other link	// OK - very easy.
    # https://cutadapt.readthedocs.io/en/stable/
    # from which i clicked on Installation on the menu on the left
    # https://cutadapt.readthedocs.io/en/stable/installation.html

    message "installing `colour lb cutadapt`" $1
    message "cd" $1
    cd
    message "cutadapt old version:"
    cutadapt --version | tee -a $1
    python3 -m pip install --user --upgrade cutadapt  | tee -a $1
    message "cutadapt installed version:"
    cutadapt --version | tee -a $1
}

function update_bwa() {
    # https://anaconda.org/bioconda/bwa
    # conda install -c bioconda bwa
    # conda update bwa
    message "updating `colour lb bwa`" $1
    message "cd" $1
    cd
    message "conda update --yes bwa" $1
    conda update --yes bwa  | tee -a $1
    message "bwa" $1
    bwa  | tee -a $1		# Version: 0.7.17-r1188 - last version already installed as at 20220526
}

function install_htslib() {
    # conda does not install last version
    # https://github.com/samtools/htslib/blob/develop/INSTALL	# details here
    message "installing `colour lb htslib`" $1
    message "cd ~/software" $1
    cd ~/software
    message "git clone https://github.com/samtools/htslib.git	# downloading - creates hstlib directory within ~/software" $1
    git clone https://github.com/samtools/htslib.git	# downloading - creates hstlib directory within ~/software
    message "cd htslib" $1
    cd htslib
    message "autoreconf -i				# no output but created script configure and perhaps other files" $1
    autoreconf -i  | tee -a $1				# no output but created script configure and perhaps other files 
    message "git submodule update --init --recursive	# otherwise script configure asks for this in the output" $1
    git submodule update --init --recursive		# otherwise script configure asks for this in the output
    #sudo apt-get install libssl-dev			# done before by ubuntu user to avoid following warning:
    # configure: WARNING: S3 support not enabled: requires SSL development files
    message "configure" $1
    configure | tee -a $1
    message "make					# loads of output but everything fine." $1
    make      | tee -a $1				# loads of output but everything fine.
    # make install					# NO requirese sudo credentials
}

function install_samtools() {
    # https://github.com/samtools/samtools/
    # https://github.com/samtools/samtools/blob/develop/INSTALL  # installation details
    message "installing `colour lb samtools`" $1
    message "cd ~/software" $1
    cd ~/software
    message "git clone https://github.com/samtools/samtools.git" $1
    git clone https://github.com/samtools/samtools.git
    message "cd samtools" $1
    cd samtools
    message "autoheader					# output:" $1
    autoheader  | tee -a $1				# output:
    message "autoconf -Wno-syntax			# created configure script" $1
    autoconf -Wno-syntax | tee -a $1			# created configure script
    #configure						# FAILED, need to run the following with ubuntu before
    # .. 
    #as libncurses5-dev (on Debian or Ubuntu Linux) or ncurses-devel (on RPM-based
    #Linux distributions) is installed.
    #FAILED.  Either configure --without-curses or resolve this error to build
    #samtools successfully.
    #sudo apt-get update				# done before by ubuntu user
    #sudo apt-get install libncurses5-dev		# done before by ubuntu user
    message "configure					# PERFECT" $1
    configure | tee -a $1				# PERFECT
    message "make" $1
    make | tee -a $1
    #make install					# no - installs system-wide in /usr/local/bin/
    message "cd ~/bin" $1
    cd ~/bin
    if [ -h samtools ]; then				# if the link in ~/bin exists, we need to delete it
	message "rm samtools  (link in ~/bin)" $1
	rm samtools
    fi
    message "ln -s ~/software/samtools/samtools		# local install ONLY" $1
    ln -s ~/software/samtools/samtools			# local install ONLY
    message "cd" $1
    cd
    message "samtools version" $1
    samtools version | tee -a $1
}

function install_bcftools() {
    # bcfctools						###### (12) BCFTOOLS
    # 1 https://github.com/samtools/bcftools
    # 2 https://github.com/samtools/bcftools.git		# or git://github.com/samtools/bcftools.git
    # 3 http://samtools.github.io/bcftools/howtos/install.html  # THIS ONE, i used it first and now.
    # 4 https://raw.githubusercontent.com/samtools/bcftools/develop/INSTALL   # Details about options
    # Install based on 3:
    # git clone --recurse-submodules git://github.com/samtools/htslib.git
    # git clone git://github.com/samtools/bcftools.git
    # cd bcftools
    ## The following is optional:				# explained in 4 above
    #   autoheader && autoconf && ./configure --enable-libgsl --enable-perl-filters
    # make
    # NB: not using the first clone (ove htslib) because I did it above with version
    # git submodule update --init --recursive		# while in the htslib directory	
    # this link https://stackoverflow.com/questions/3796927/how-to-git-clone-including-submodules says both versions
    # "git clone --recurse-submodules .."  AND "git submodule update --init --recursive" ARE EQUIVALENT. So:
    message "installing `colour lb bcftools`" $1
    message "cd ~/software" $1
    cd ~/software
    message "git clone https://github.com/samtools/bcftools.git" $1
    git clone https://github.com/samtools/bcftools.git    
    message "cd bcftools/" $1
    cd bcftools/
    #sudo apt-get update					# done before by ubuntu user
    #sudo apt-get install libgsl0-dev				# idem
    #sudo apt-get install libperl-dev				# did not do as it doesn't solve the problem with perl filters
    message "( autoheader && autoconf && ./configure --enable-libgsl ) # no --enable-perl-filters, let Annabel and Sarah F. know" $1
    ( autoheader && autoconf && ./configure --enable-libgsl ) | tee -a $1 #  no --enable-perl-filters, let Annabel and Sarah F. know
    message "make" $1
    make  | tee -a $1

    # make local install
    message "cd ~/bin" $1
    cd ~/bin
    if [ -h bcftools ]; then				# if the link in ~/bin exists, we need to delete it
	message "rm bcftools  (link in ~/bin)" $1
	rm bcftools
    fi
    message "ln -s ~/software/bcftools/bcftools		# local install ONLY" $1
    ln -s ~/software/bcftools/bcftools 			# local install ONLY

    if [ -h vcfutils.pl ]; then				# if the link in ~/bin exists, we need to delete it
	message "rm vcfutils.pl  (link in ~/bin)" $1
	rm vcfutils.pl 
    fi
    message "ln -s ~/software/bcftools/misc/vcfutils.pl # local install ONLY" $1
    ln -s ~/software/bcftools/misc/vcfutils.pl		# local install ONLY

    
    message "cd" $1
    cd
    message "vcfutils.pl    (likely not to print a version)" $1
    vcfutils.pl | tee -a $1
}

function install_trimmomatic() {
    message "installing `colour lb trimmomatic`" $1
    conda install --yes -c bioconda trimmomatic  | tee -a $1
    message "trimmomatic -version" $1
    trimmomatic -version  | tee -a $1
}

#################################### print installations above
function print_all_versions() {
    conda --version
    python --version
    
    fastqc --version
    message "cutadapt version:"
    cutadapt --version
    bwa 2>&1 | head -n 3
    samtools version | head -n 2	
    bcftools --version | head -n 2
    # vcfutils.pl	### does not print version but is a misc app with bcftools
    message "trimmomatic -version:"
    trimmomatic -version
}

function message_use() {
    message "\n$(colour lb $(basename $0)) updates or installs all genomics software analysis tools.

This script should be run before creating a genomics AMI, and after running the script that 
updates the Ubuntu system, softwrInstall_genomics_ubuntusr.sh, in the ubuntu account.

    usage:
	     $(colour lb $(basename $0)) [go][versions]

	     - use option $(colour lb go) to install all applications - you will have the option to cancel.
	     - use option $(colour lb versions) to see the versions installed.
"  ### end of string to function message
}

####################______ script starts  here:

if [ $# -eq 0 -o $# -gt 1 ]; then	### $# number of parameters - must be one (versions or go)
    message_use
    exit 1
fi

if [ "$1" == "versions" ]; then
    message "Versions of genomics applications installed:"
    print_all_versions
    exit 0
elif [ "$1" != "go" ]; then
    message_use
    exit 2
fi

### installation start
local_user=$USER
grep csuser ~/.conda/environments.txt	
if [ $? -eq 0 ]; then			### if grep finds csuser (default) the scripts need updating only.
    message "\n$(colour lb $(basename $0)) is about to UPDATE $(colour lb genomics) software analysis tools ($local_user account)\n"
else					### else it's a new user so we need to remove and re-install conda
    message "\n$(colour lb $(basename $0)) is about to INSTALL $(colour lb genomics) software analysis tools ($local_user account)\n"
fi

read -n 1 -p "Do you want to continue (y/n)?: " option

if [ "$option" != "n" -a "$option" != "N" -a "$option" != "y" -a "$option" != "Y" ]; then
    message "\nWrong option $option. Script cancelled."
    exit 1;
elif [ "$option" == "n" -o "$option" == "N" ]; then
    message "\nScript cancelled ($option)."
    exit 1;
fi

if [ ! -d .genomics_sftw_logs ]; then  
    message "\nCreating directory .genomics_sftw_logs"
    mkdir .genomics_sftw_logs
fi

logfile=~/.genomics_sftw_logs/genomics_sftwre_install.sh`date '+%Y%m%d.%H%M%S'`.txt  ### don't "" as ~ is not replaced w/ /home/csuser
message "\nInstalling all genomics applications" $logfile

message "\nCleaning directory ~/software (rm -fr ~/software/*)" $logfile
rm -fr ~/software/*
cd

### genomics programs to install or update - only the calls here will be updated and the calls in function print_versions
### check wheter the username has been changed in which case the software must be installed, as opposed to be only updated.
### grep csuser ~/.conda/environments.txt	
### if [ $? -eq 0 ]; then		### if grep finds csuser, default, the scripts need updating only.
if [ "$local_user" != "csuser"]; then	### if $local_user is csuser (default), the scripts need updating only.
    remove_samtools $logfile		### need to remove samtools if it exists in order to update python
    update_conda $logfile		### 
else					### it is a new user so we need to remove and re-install conda
    install_conda $logfile		### 
fi
update_python $logfile			### the miniconda version is usually more recent than the ubuntu system one

install_fastqc $logfile			### installed in main conda (with this script in conda main)
install_cutadapt $logfile		### 
update_bwa $logfile			### installed in main conda (with this script)

install_htslib $logfile			### kind of library needed by samtools and other programs
install_samtools $logfile		### 
install_bcftools $logfile		### 
# vcfutils.pl is installed by bcftools
install_trimmomatic $logfile		### .to add with conda

#-------------------------------------- ### ok 15 (09) nano - done
message "`colour lg DONE ` installing genomics software." $logfile
message " Log out and login again for docker aliases to take effect." $logfile
