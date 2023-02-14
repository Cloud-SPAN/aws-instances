#!/bin/bash
# helper functions
#------------------
source ~/bin/colours_functions.sh	 # to add colour to some messages
shopt -s expand_aliases			### sets on expand_aliases otherwise docker aliases don't work
source ~/.bash_aliases

function message() {
    printf "%b\n" "$1"		### %b: print the argument expanding backslash escape sequences.
    if [ -n "$2" ]; then	### if $2 is specified, it's a log file to also store message $1
	printf "%b\n" "$1" >> "$2"	
    fi
}


function remove_samtools() {
    message "`colour lg "removing conda samtools"` otherwise we cannot update python" $1
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

function update_python() {
    message "installing `colour lb "python 3.9.7"`:" $1
    message "python --version   (current version)" $1
    python --version | tee -a $1
    message "conda install python=3.9.7" $1
    conda install --yes python=3.9.7
    message "python --version" $1
    python --version | tee -a $1
}

function install_seqkit() {
    # https://anaconda.org/bioconda/seqkit
    message "installing `colour lb seqkit`" $1
    message "conda install --yes -c bioconda seqkit" $1
    conda install --yes -c bioconda seqkit | tee -a $1	### -c is channel: search in bioconda channel
    message "seqkit version" $1
    seqkit version | tee -a $1				### should be v2.2.0 
}

function install_kraken2() {
    # to add refs
    message "installing `colour lb kraken2`" $1
    message "cd ~/software" $1
    cd ~/software 
    message "git clone https://github.com/DerrickWood/kraken2.git  # downloading" $1  
    git clone https://github.com/DerrickWood/kraken2.git    # downloading
    message "cd kraken2" $1
    cd kraken2
    message "install_kraken2.sh install			# installing in directory install - creates directory install" $1
    install_kraken2.sh install				# installing in directory install - creates directory install
    message "cd ~/bin					# creating links in ~/bin" $1
    cd ~/bin
    message "ln -s ~/software/kraken2/install/kraken2" $1
    ln -s ~/software/kraken2/install/kraken2
    message "ln -s ~/software/kraken2/install/kraken2-build" $1
    ln -s ~/software/kraken2/install/kraken2-build 
    message "ln -s ~/software/kraken2/install/kraken2-inspect" $1
    ln -s ~/software/kraken2/install/kraken2-inspect 
    message "cd						# trying links" $1
    cd
    message "kraken2 -v" $1
    kraken2 -v | tee -a $1				# should be version 2.1.2
}

function install_krakenTools() {
    # to add refs
    message "installing `colour lb "kraken tools"`" $1
    message "cd ~/software" $1
    cd ~/software 
    message "git clone https://github.com/jenniferlu717/KrakenTools.git  # downloading" $1  
    git clone https://github.com/jenniferlu717/KrakenTools.git
    message "cd KrakenTools" $1
    cd KrakenTools
    message "mv *.py DiversityTools/*.py ~/bin		# installing: simple mv to ~/bin" $1
    mv *.py DiversityTools/*.py ~/bin			# installing: simple mv to ~/bin
}

function install_canu() {
    # Canu version v2.2		
    #    https://github.com/marbl/canu
    #    They recommend installing from binary, the binaries are here with instructions 
    #    https://github.com/marbl/canu/releases
    message "installing `colour lb canu`" $1
    message "cd ~/software" $1
    cd ~/software    
    message "mkdir canu" $1
    mkdir canu    
    message "cd canu" $1
    cd canu    
    message "curl -L https://github.com/marbl/canu/releases/download/v2.2/canu-2.2.Linux-amd64.tar.xz --output canu-2.2.Linux.tar.xz" $1
    curl -L https://github.com/marbl/canu/releases/download/v2.2/canu-2.2.Linux-amd64.tar.xz --output canu-2.2.Linux.tar.xz    
    message "tar -xJf canu-2.2.*.tar.xz				#  unpacking" $1
    tar -xJf canu-2.2.*.tar.xz				#  unpacking    
    message "cd ~/bin" $1
    cd ~/bin    
    message "ln -s ~/software/canu/canu-2.2/bin/canu canu" $1
    ln -s ~/software/canu/canu-2.2/bin/canu canu    
    message "cd" $1
    cd
    message "canu -version" $1
    canu -version | tee -a $1				#canu 2.2
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

function install_minimap2() {
    # Minimap2  version 2-2.24 (r1122)			##### (8) MINIMAP2 install
    #   https://github.com/lh3/minimap2#install manual page and the precompiled binaries are here: 
    #   https://github.com/lh3/minimap2/releases
    message "installing `colour lb bwa`" $1
    message "cd ~/software" $1
    cd ~/software
    message "mkdir minimap2" $1
    mkdir minimap2
    message "cd minimap2" $1
    cd minimap2
    message "curl -L https://github.com/lh3/minimap2/releases/download/v2.24/minimap2-2.24_x64-linux.tar.bz2 | tar -jxvf -" $1
    curl -L https://github.com/lh3/minimap2/releases/download/v2.24/minimap2-2.24_x64-linux.tar.bz2 | tar -jxvf -
    message "cd ~/bin" $1
    cd ~/bin    
    message "ln -s ~/software/minimap2/minimap2-2.24_x64-linux/minimap2" $1
    ln -s ~/software/minimap2/minimap2-2.24_x64-linux/minimap2
    message "cd"
    cd
    message "minimap2 --version			# 2.24-r1122" $1
    minimap2 --version | tee -a $1		# 2.24-r1122
}

function install_flye() {
    # Flye version 2.9					##### (9) FLYE 2.9 install
    #    https://github.com/fenderglass/Flye
    #    https://github.com/fenderglass/Flye/blob/flye/docs/INSTALL.md
    #    FAILED with conda and bioconda
    # conda install flye							// FAILED
    # conda install -c bioconda flye						// FAILED TOO
    # so from sources
    message "installing `colour lb flye`" $1
    message "cd ~/software" $1
    cd ~/software
    message "git clone https://github.com/fenderglass/Flye" $1
    git clone https://github.com/fenderglass/Flye		# download
    message "cd Flye/"
    cd Flye/
    message "make" $1
    make
    message "cd ~/bin" $1
    cd ~/bin
    message "ln -s ~/software/Flye/bin/flye" $1
    ln -s ~/software/Flye/bin/flye
    message "flye --version" $1
    flye --version | tee -a $1			    #2.9-b1778
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
    autoreconf -i					# no output but created script configure and perhaps other files 
    message "git submodule update --init --recursive	# otherwise script configure asks for this in the output" $1
    git submodule update --init --recursive		# otherwise script configure asks for this in the output
    #sudo apt-get install libssl-dev			# done before by ubuntu user to avoid following warning:
    # configure: WARNING: S3 support not enabled: requires SSL development files
    message "configure" $1
    configure
    message "make					# loads of output but everything fine." $1
    make						# loads of output but everything fine.
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
    autoheader						# output:
    message "autoconf -Wno-syntax			# created configure script" $1
    autoconf -Wno-syntax				# created configure script
    #configure						# FAILED, need to run the following with ubuntu before
    # .. 
    #as libncurses5-dev (on Debian or Ubuntu Linux) or ncurses-devel (on RPM-based
    #Linux distributions) is installed.
    #FAILED.  Either configure --without-curses or resolve this error to build
    #samtools successfully.
    #sudo apt-get update				# done before by ubuntu user
    #sudo apt-get install libncurses5-dev		# done before by ubuntu user
    message "configure					# PERFECT" $1
    configure						# PERFECT
    message "make" $1
    make
    #make install					# no - installs system-wide in /usr/local/bin/
    message "cd ~/bin" $1
    cd ~/bin
    message "ln -s ~/software/samtools/samtools		# local install ONLY" $1
    ln -s ~/software/samtools/samtools			# local install ONLY
    message "samtools version" $1
    samtools version | tee -a $1
}

function install_bcftools() {
    # bcfctools						###### (12) BCFTOOLS
    # 1 https://github.com/samtools/bcftools
    # 2 https://github.com/samtools/bcftools.git		# or git://github.com/samtools/bcftools.git
    # 3 http://samtools.github.io/bcftools/howtos/install.html  # the one i used first and now.
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
    message "autoheader && autoconf && ./configure --enable-libgsl	# NB: no --enable-perl-filters, let Annabel and Sarah F. know" $1
    autoheader && autoconf && ./configure --enable-libgsl	# NB: no --enable-perl-filters, let Annabel and Sarah F. know
    message "make" $1
    make
    message "cd" $1
    cd
    message "bcftools" $1
    bcftools | tee -a $1
}

function install_fastqc() {
    #	https://www.bioinformatics.babraham.ac.uk/projects/fastqc/		# main website has next link to installation
    #	https://raw.githubusercontent.com/s-andrews/FastQC/master/INSTALL.txt	# instructions here are not clear at all
    #	So i'm going to stick to the conda installation:
    # conda install -c bioconda fastqc
    message "installing `colour lb fastqc`" $1
    message "conda update fastqc				    # did this which updated many packages but the fastqc version was the same" $1
    conda update --yes fastqc			    # did this which updated many packages but the fastqc version was the same
    message "fastqc --version" $1
    fastqc --version | tee -a $1		    # FastQC v0.11.9
}


function install_kraken_biom() {				##### (25) KRAKEN-BIOM
    #	https://github.com/smdabdoub/kraken-biom
    cd
    message "`colour lg "Step 25"`: installing `colour lb kraken-biom`" $1
    message "pip install kraken-biom" $1
    pip install kraken-biom
    message "kraken-biom --version" $1
    kraken-biom --version | tee -a $1
}

function check_r() {					#####  (17) R
    #	https://cran.r-project.org/			#
    #	followed the instructions below from link above: clicked on Ubuntu and took me to page with these instructions:
    #sudo apt update -qq				# did with ubuntu user and .todo likewise before creating the AMI
    #sudo apt install --no-install-recommends software-properties-common dirmngr  # to update software manager
    #wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | sudo tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
    #sudo add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"
    #sudo apt install --no-install-recommends r-base
    #sudo add-apt-repository ppa:c2d4u.team/c2d4u4.0+	# REGISTERING REPO
    #csuser@metagenomics:~/software $ R
    message "checking `colour lb R` (system-wide install by ubuntu user)" $1
    message "R --version					# csuser" $1
    R --version | tee -a $1					# 4.2.0
}

function install_metabat2() {				##### (19) METABAT2
    #	https://anaconda.org/bioconda/metabat2		
    #	conda install -c bioconda metabat2		# NO installs metabat2-2.12.1 and we want last one 2:2.15
    #	googled 	"ubuntu install metabat2 2.15" and got this links:
    #       https://bioconda.github.io/recipes/metabat2/README.html
    #       - it shows two options to install metabat2. I tried both as the first one did not work: it also installs version 2.12.1
    #       - The first option required to install some channels and then run conda update which sounded promising
    #         but it did not work. So better with docker:
    message "installing `colour lb metabat2` (new conda install)" $1
    ### as instructued here  https://anaconda.org/bioconda/metabat2
    message "cd" $1
    cd
    message "conda install -c bioconda metabat2" $1
    conda install -c bioconda metabat2 | tee -a $1
}

function check_hmmer() {				##### (20) HMMER for checkm
    #	https://github.com/Ecogenomics/CheckM  - has this
    #       Please see the project home page for usage details and installation instructions:
    #      	https://github.com/Ecogenomics/CheckM/wiki  and this has links to:
    #	- System Requirements - designed to run on Linux, the full reference genome tree required approximately 40 GB of memory.
    #	- Installation - Dependencies
    #	    - HMMER (>=3.1b1)
    #	      http://hmmer.org/#
    #	    - prodigal (2.60 or >=2.6.1)	    executable must be named prodigal and not prodigal.linux
    #	      https://github.com/hyattpd/Prodigal
    #	    - pplacer (>=1.1)
    #	      http://matsen.fhcrc.org/pplacer/
    #	      http://matsen.github.io/pplacer/compiling.html  see more instructions below
    #	- Installation - How can I install CheckM?	### THIS ONE:
    #	  https://github.com/Ecogenomics/CheckM/wiki/Installation#how-to-install-checkm
    #	  with pip as shown below after installing the dependencies
    #	- Upgrade
    #	  https://github.com/Ecogenomics/CheckM/wiki/Installation#how-to-upgrade-checkm  -- just this
    #	  > pip3 install checkm-genome --upgrade --no-deps
    #	 
    #sudo apt install hmmer				##### did with ubuntu user, .todo likewise before creating AMI
    #
    # NB: hmmer is actually phmmer, nhmmer, jackhmmer
    
    message "checking `colour lb hmmer` (phmmer-nhmmer-jackhmmer for checkm -system-wide install, ubuntu user)" $1
    message "phmmer -h" $1
    phmmer -h | tee -a $1		# phmmer :: search a protein sequence against a protein databaseaak
    message "nhmmer -h" $1
    nhmmer -h | tee -a $1		# nhmmer :: search a DNA model, alignment, or sequence against a DNA database
    message "jackhmmer -h" $1
    jackhmmer -h | tee -a $1		# jackhmmer :: iteratively search a protein sequence against a protein database
}


function install_checkm() {				##### (23) CHECKM
    #	https://github.com/Ecogenomics/CheckM/wiki/Installation#how-to-install-checkm
    message "`colour lg "installingxs checkm"`" $1
    message "pip3 install numpy" $1
    pip3 install numpy
    message "pip3 install matplotlib" $1
    pip3 install matplotlib
    message "pip3 install pysam" $1
    pip3 install pysam
    message "pip3 install checkm-genome" $1
    pip3 install checkm-genome
    message "checkm" $1
    checkm | tee -a $1
    #               ...::: CheckM v1.2.0 :::...
}

function install_prokka() {				##### (24) PROKKA - docker version - typical version impossible to intall
    #	https://github.com/tseemann/prokka		# many install options: docker, conda, github, etc
    #	- docker version has the following two lines
    #
    message "`colour lg "Prokka was installed by ubuntu use - checkin version"`" $1
    message "Version is" $1
    ### does not work: conda install --yes -c conda-forge -c bioconda -c defaults prokka
    prokka --version
}

function install_nanoplot() {				##### (24) PROKKA - docker version - typical version impossible to intall
    #	https://github.com/tseemann/prokka		# many install options: docker, conda, github, etc
    #	- docker version has the following two lines
    #
    message "`colour lg "installing NanoPlot"`" $1
    message "pip install NanoPlot" $1
    pip install NanoPlot
    which NanoPlot
    NanoPlot --version
}

function install_medaka() {		
    #
    #
    message "`colour lg "installing medaka"`" $1
    message "pip install medaka" $1
    cd
    pip install medaka
    which medaka
    medaka --version
}

function install_pilon() {		
    #
    #
    message "`colour lg "installing pilon"`" $1
    message "conda install -c bioconda pilon" $1
    cd
    conda install --yes -c bioconda pilon
    which pilon
    pilon --version
}

function install_metaquast() {		
    #
    #
    message "`colour lg "installing metaquast"`" $1
    message "conda install -c bioconda pilon" $1
    cd
    pip install quast
    cd .miniconda3/bin/
    ln -s metaquast.py metaquast
    which metaquast
    metaquast --version
}

#################################### installations above
function print_all_versions() {
    conda --version
    python --version
    seqkit version
    kraken2 -v
###    canu -version 
    bwa 2>&1 | head -n 3
###    message "minimap2 --vesion"
###    minimap2 --version
       message "flye --version"
    flye --version
    samtools version | head -n 2
###    bcftools --version | head -n 2
    fastqc --version
    kraken-biom --version
###    pycoQC --version
###    message "cutadapt --version"
###    cutadapt --version
###    message "porechop --version"
###    porechop --version
###    R --version | head -n 1
###    message "qiime --version"
###    qiime --version
       message "metabat2 --version"
    metabat2  2>&1 | head -n 3
       message "\n> > > > > > support for CHECKM"    
    phmmer -h | head -n 2
    nhmmer -h | head -n 2
    jackhmmer -h | head -n 2
###    prodigal -v
###    message "pplacer --version"
###    pplacer --version
    message "< < < < < < < END support for CHECKM"
    message "checkm version is:"
    checkm | head -n 2 | tail -n 1
    message "prokka --version:"
    prokka --version
    message "NanoPlot --version:"
    NanoPlot  --version
    message "medaka --version:"
    medaka --version
    message "pilon --version:"
    pilon --version
    message "metaquast --version is:"
    metaquast --version 
}

function message_use() {
    printf "%b\n" \
	   "`colour lb $(basename $0)` installs all metagenomics software (24 applications): seqkit, .., prokka."\
	   " " \
	   "usage: " \
	   " " \
	   "  `colour lb "$(basename $0)"` [versions][go]" \
	   " " \
	   " " \
	   "- use option `colour lb go` to install all applications."\
	   "- use option `colour lb versions` to see the versions installed."\
	   " "
}

############# script start

if [ $# -eq 0 -o $# -gt 1 ]; then	### $# number of parameters - must be one (versions or go)
    message_use
    exit 2
fi


if [ "$1" == "versions" ]; then
    message "Versions of metagenomics applications installed:"
    print_all_versions
    exit 0
elif [ "$1" != "go" ]; then
    message_use
    exit 2
fi

############# installation start
message "All metagenomics software (14 applications) is about to be installed."
message "This script should only be run once before creating the metagenomics AMI."
message "Deletes all software previously installed in ~/software and installs the new versions as at `date`."
read -n 1 -p "Do you want to continue (y/n)?: " option

if [ "$option" != "n" -a "$option" != "N" -a "$option" != "y" -a "$option" != "Y" ]; then
    message "\nWrong option $option. Script cancelled."
    exit 1;
elif [ "$option" == "n" -o "$option" == "N" ]; then
    message "\nScript cancelled ($option)."
    exit 1;
fi

if [ ! -d .metagenomics_sftw_logs ]; then  
    message "\nCreating directory .metagenomics_sftw_logs"
    mkdir .metagenomics_sftw_logs
fi

logfile=~/.metagenomics_sftw_logs/metagenomics_sftwre_install.sh`date '+%Y%m%d.%H%M%S'`.txt   ### don't "" as ~ is not replaced w/ /home/csuser
message "\nInstalling all metagenomics applications" $logfile

message "\nCleaning directory ~/software (rm -fr /home/csuser/software/*)" $logfile
rm -fr ~/software/*
cd
### new list of metagenomics programs to install - only the calls here will be updated and the calls in function print_versions
remove_samtools $logfile		### ok 0
update_conda $logfile			### ok 0
update_python $logfile			### ok 0
install_seqkit $logfile			### ok 1 (03) installed into main conda (with this script)
install_kraken2 $logfile		### ok 2 (11) is installed and database is too (not in conda but installed)
# install_krakenTools $logfile		### NO -
# install_canu $logfile			### NO -
update_bwa $logfile			### ok 3 (06) installed into the main conda (with this script)
install_minimap2 $logfile		### ok - required by medaka
install_flye $logfile			### ok 4 (04) installed into main conda (NOT TRUE: with this script - not in conda)
install_htslib $logfile			### ok 5 (07) needed by samtools
install_samtools $logfile		### ok 5 (07) installed into the main conda (NOT TRUE: with this script - not in conda)
install_bcftools $logfile		### ok - required by medaka
install_fastqc $logfile			### ok 6 (01) installed in main conda (with this script in conda main)
install_kraken_biom $logfile		### ok 7 (12) installed on the instance (as it is).
#---------------------------------------DONE
# install_pycoqc $logfile 		### NO -
# update_cutadapt $logfile		### NO -
# check_porechop $logfile		### NO -
# check_r $logfile			### NO -
# install_qiime2 $logfile		### NO -
install_metabat2 $logfile		### ok 8 (13) DONE-MANUAL ** managed to install into the main conda (this script intalled it with docker - to reinstall, installed version 2:2.15 -- I could install  version 2:2.15 too with conda install -c bioconda metabat2 -- https://anaconda.org/bioconda/metabat2
check_hmmer $logfile			### ok 9 - checkm assumes these to be installed, installed by metagenomics sript ubuntu2v.sh
install_prodigal $logfile		### ok 9 - checkm assumes these to be installed
install_pplacer $logfile		### NO 9 - 
install_checkm $logfile			### ok 9 (14) DONE-MANUAL ** installed incorrectly - installed in conda but needs reinstall into conda main (version is CheckM v1.2.1 in conda,  version i installed with pin CheckM v1.2.1 )
install_prokka $logfile			### ok 10 (15) DONE-MANUAL with "sudo apt install prokka" in ubuntu script ** docker install wrong - currently in conda but needs reinstall into conda main (I installed it with docker - need to reinstall in conda in the main or from compilation but NOT with DOCKER - it can be with apt install prokka.)
#================= NEW PROGRAMS ==========================
install_nanoplot $logfile		### ok 11 (02) DONE-MANUAL with "pip install NanoPlot"  ** Currently (NanoPlot 1.40.0) in its own conda environment called nanoplot - couldn't install into the main conda
install_medaka	$logfile		### ok 12 (05) DONE-MANUal as Annabel did ** currently in its conda environment called medaka
install_pilon $logfile			### ok 13 (08) DONE-MANUAL as Annabel did  ** installed into the main conda but needs path to pilon.jar
install_metaquast $logfile		### ok 14 (10) DONE MANUAL with "pip install quast" ** Annabel couldn't get a working conda env for this - porting viking env
#-------------------------------------- ### ok 15 (09) nano - done

message "`colour lg DONE ` installing metagenomics software." $logfile
message " Log out and login again for docker aliases to take effect." $logfile
