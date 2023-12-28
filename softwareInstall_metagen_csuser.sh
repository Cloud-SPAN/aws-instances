#!/usr/bin/env bash
# helper functions
#------------------
source colour_utils_functions.sh		# to add colour to some messages
shopt -s expand_aliases			### sets on expand_aliases otherwise docker aliases don't work
source ~/.bash_aliases

function remove_samtools() {
    message "`colour lg "Step 0"`: removing `colour lb samtools`; otherwise we cannot update python from version 3.9.5 to 3.10.4" $1
    message "conda remove --yes samtools" $1
    conda remove --yes samtools | tee -a $1 			
}

function update_python() {
    message "`colour lg "Step 1"`: updating `colour lb python`" $1
    message "python --version" $1
    python --version | tee -a $1
    message "conda update --yes python" $1
    conda update --yes python | tee -a $1
    message "python --version" $1
    python --version | tee -a $1
}

function update_conda() {
    message "`colour lg "Step 2"`: updating `colour lb conda`" $1
    message "conda --version" $1
    conda --version | tee -a $1
    message "conda update --yes conda" $1
    conda update --yes conda | tee -a $1
    message "conda --version" $1
    conda --version | tee -a $1
}

function install_seqkit() {
    # https://anaconda.org/bioconda/seqkit
    message "`colour lg "Step 3"`: installing `colour lb seqkit`" $1
    message "conda install --yes -c bioconda seqkit" $1
    conda install --yes -c bioconda seqkit | tee -a $1	### -c is channel: search in bioconda channel
    message "seqkit version" $1
    seqkit version | tee -a $1				### should be v2.2.0 
}

function install_kraken2() {
    # to add refs
    message "`colour lg "Step 4"`: installing `colour lb kraken2`" $1
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
    message "`colour lg "Step 5"`: installing `colour lb "kraken tools"`" $1
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
    message "`colour lg "Step 6"`: installing `colour lb canu`" $1
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
    message "`colour lg "Step 7"`: updating `colour lb bwa`" $1
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
    message "`colour lg "Step 8"`: installing `colour lb bwa`" $1
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
    message "`colour lg "Step 9"`: installing `colour lb flye`" $1
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
    message "`colour lg "Step 10"`: installing `colour lb htslib`" $1
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
    message "`colour lg "Step 11"`: installing `colour lb samtools`" $1
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
    message "`colour lg "Step 12"`: installing `colour lb bcftools`" $1
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
    message "`colour lg "Step 13"`: installing `colour lb fastqc`" $1
    message "conda update fastqc				    # did this which updated many packages but the fastqc version was the same" $1
    conda update --yes fastqc			    # did this which updated many packages but the fastqc version was the same
    message "fastqc --version" $1
    fastqc --version | tee -a $1		    # FastQC v0.11.9
}


function install_pycoqc() {
    #	https://github.com/a-slide/pycoQC		# 1) pycoQC v2.5.2
    #	https://a-slide.github.io/pycoQC/installation/ 	# 2) installation details
    #sudo apt install python3-pip			# done with ubuntu user - seems not needed if python is updated to 10.3.4
    message "`colour lg "Step 14"`: installing `colour lb pycoQC`" $1
    message "pip install git+https://github.com/a-slide/pycoQC.git   # option 3 in 2) above - NB: installs in ~/csuser/.local/bin/pycoQC" $1
    pip install git+https://github.com/a-slide/pycoQC.git   # option 3 in 2) above - NB: installs in ~/csuser/.local/bin/pycoQC
    message "pycoQC --version				# pycoQC v2.5.2" $1
    pycoQC --version | tee -a $1			# pycoQC v2.5.2
}

function update_cutadapt() {				##### (15) CUTADAPT
    #	https://cutadapt.readthedocs.io/en/stable/installation.html
    message "`colour lg "Step 15"`: updating `colour lb cutadapt`" $1
    message "cd" $1
    cd
    message "python3 -m pip install --user --upgrade cutadapt	# installed as before, actually upgraded" $1
    python3 -m pip install --user --upgrade cutadapt	# installed as before, actually upgraded
    message "cutadapt --version					# This is cutadapt 4.0 with Python 3.10.4" $1
    cutadapt --version | tee -a $1			# This is cutadapt 4.0 with Python 3.10.4
}

function check_porechop() {				##### (16) PORECHOP
    #	https://anaconda.org/bioconda/porechop/files    # conda installs version 0.2.3. or says that there are no channels.
    #	Did it with intructions from here // googled porechop installation
    #	https://ubuntu.pkgs.org/20.04/ubuntu-universe-arm64/porechop_0.2.4+dfsg-1build2_arm64.deb.html
    #sudo apt-get update					# done with ubuntu user
    #sudo apt-get install porechop				# idem
    message "`colour lg "Step 16"`: checking `colour lb porechop` (system-wide install by ubuntu user)" $1
    message "porechop --version					# csuser" $1
    porechop --version | tee -a $1					# csuser #0.2.4
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
    message "`colour lg "Step 17"`: checking `colour lb R` (system-wide install by ubuntu user)" $1
    message "R --version					# csuser" $1
    R --version | tee -a $1					# 4.2.0
}

function install_qiime2() {				##### (18) QIIME2
    #	conda installation requires the use of an environment - hence not used, better version
    #	https://qiime2.org
    #   better 	https://docs.qiime2.org/2022.2/install/virtual/docker/	 # DOCKER installation
    #	getent group docker
    #sudo apt install docker.io				# did with ubuntu
    #sudo groupadd docker				# idem
    #sudo usermod -aG docker csuser			# idem
    ### csuser from now
    #newgrp docker					# activates change to the group - asks for password .todo probably not needed
    message "`colour lg "Step 18"`: installing `colour lb qiime2` (DOCKER install)" $1
    message "cd" $1
    cd
    message "docker pull quay.io/qiime2/core:2022.2			# takes a while" $1
    docker pull quay.io/qiime2/core:2022.2			# takes a while
     #...											// HELP https://qiime2.org
    message "docker run -t -i -v $(pwd):/data quay.io/qiime2/core:2022.2 qiime --version" $1
    docker run -t -i -v $(pwd):/data quay.io/qiime2/core:2022.2 qiime --version
    #q2cli version 2022.2.0					#.todo aliases for qiime2
    message 'adding qiime aliases for docker invocation: cat >> ~/.bash_aliases <<EOF' $1
    cat >> ~/.bash_aliases <<EOF
alias qiime2='docker run -t -i -v $(pwd):/data quay.io/qiime2/core:2022.2 qiime'
alias qiime='docker run -t -i -v $(pwd):/data quay.io/qiime2/core:2022.2 qiime'
EOF
}

function install_metabat2() {				##### (19) METABAT2
    #	https://anaconda.org/bioconda/metabat2		
    #	conda install -c bioconda metabat2		# NO installs metabat2-2.12.1 and we want last one 2:2.15
    #	googled 	"ubuntu install metabat2 2.15" and got this links:
    #       https://bioconda.github.io/recipes/metabat2/README.html
    #       - it shows two options to install metabat2. I tried both as the first one did not work: it also installs version 2.12.1
    #       - The first option required to install some channels and then run conda update which sounded promising
    #         but it did not work. So better with docker:
    message "`colour lg "Step 19"`: installing `colour lb metabat2` (DOCKER install)" $1
    message "cd" $1
    cd
    message "docker pull quay.io/biocontainers/metabat2:2.15--h986a166_1" $1
    docker pull quay.io/biocontainers/metabat2:2.15--h986a166_1
    message "docker run quay.io/biocontainers/metabat2:2.15--h986a166_1  metabat2 -h" $1
    docker run quay.io/biocontainers/metabat2:2.15--h986a166_1  metabat2 --help | tee -a $1
    docker run quay.io/biocontainers/metabat2:2.15--h986a166_1  metabat2 --version | tee -a $1
    #MetaBAT: Metagenome Binning based on Abundance and Tetranucleotide frequency (version 2:2.15 (Bioconda); 2020-07-03T13:02:15)
    message 'adding metabat2 alias for docker invocation: cat >> ~/.bash_aliases <<EOF' $1
    cat >> ~/.bash_aliases <<EOF
alias metabat2='docker run quay.io/biocontainers/metabat2:2.15--h986a166_1  metabat2'
EOF
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
    
    message "`colour lg "Step 20"`: checking `colour lb hmmer` (phmmer-nhmmer-jackhmmer for checkm -system-wide install, ubuntu user)" $1
    message "phmmer -h" $1
    phmmer -h | tee -a $1		# phmmer :: search a protein sequence against a protein databaseaak
    message "nhmmer -h" $1
    nhmmer -h | tee -a $1		# nhmmer :: search a DNA model, alignment, or sequence against a DNA database
    message "jackhmmer -h" $1
    jackhmmer -h | tee -a $1		# jackhmmer :: iteratively search a protein sequence against a protein database
}

function install_prodigal() {				##### (21) PRODIGAL for checkm
    # see hmmer (previous one (20) for some info 
    message "`colour lg "Step 21"`: installing  `colour lb prodigal` for checkm" $1
    message "cd ~/software" $1
    cd ~/software
    message "git clone https://github.com/hyattpd/Prodigal.git" $1
    git clone https://github.com/hyattpd/Prodigal.git
    message "cd Prodigal/" $1
    cd Prodigal/
    message "make" $1
    make
    message "cd ~/bin/" $1
    cd ~/bin/
    message "ln -s ~/software/Prodigal/prodigal" $1
    ln -s ~/software/Prodigal/prodigal
    message "cd" $1
    cd
    message "prodigal -v" $1
    prodigal -v | tee -a $1		#Prodigal V2.6.3: February, 2016
}

function install_pplacer() {				##### (22) PPLACER for checkm
    # see hmmer (above (20) for some info 
    #	https://github.com/matsen/pplacer		# github site has following links
    #	- https://github.com/matsen/pplacer.git		# github repo to compile from source but is complicated
    #	- http://matsen.github.io/pplacer/compiling.html  # compilation instructions NO
    #	- http://matsen.github.io/pplacer/		# DOCUMENTATION
    #	- http://fhcrc.github.io/microbiome-demo/	# Tutorial
    #	- https://matsen.fhcrc.org/pplacer/		# project webpage with link binaries latest release ///// THIS ONE
    #	  - https://github.com/matsen/pplacer/releases/tag/v1.1.alpha19   ///// THIS ONE has the link used below with curl
    message "`colour lg "Step 22"`: installing  `colour lb pplacer` for checkm" $1
    message "cd ~/software" $1
    cd ~/software
    message "curl -L https://github.com/matsen/pplacer/releases/download/v1.1.alpha19/pplacer-linux-v1.1.alpha19.zip -o pplacer-linux-v1.1.alpha19.zip" $1
    curl -L https://github.com/matsen/pplacer/releases/download/v1.1.alpha19/pplacer-linux-v1.1.alpha19.zip -o pplacer-linux-v1.1.alpha19.zip
    message "unzip pplacer-linux-v1.1.alpha19.zip		# creates directory ~/software/pplacer-Linux-v1.1.alpha19" $1
    unzip pplacer-linux-v1.1.alpha19.zip			# creates directory ~/software/pplacer-Linux-v1.1.alpha19
    message "cd ~/bin" $1
    cd ~/bin
    message "ln -s ~/software/pplacer-Linux-v1.1.alpha19/pplacer" $1
    ln -s ~/software/pplacer-Linux-v1.1.alpha19/pplacer
    message "cd" $1
    cd
    message "pplacer --version		#v1.1.alpha19-0-g807f6f3" $1
    pplacer --version | tee -a $1	#v1.1.alpha19-0-g807f6f3
}

function install_checkm() {				##### (23) CHECKM
    #	https://github.com/Ecogenomics/CheckM/wiki/Installation#how-to-install-checkm
    message "`colour lg "Step 23"`: installing `colour lb checm`" $1
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
    message "`colour lg "Step 24"`: installing `colour lb prokka`" $1
    message "docker pull staphb/prokka:latest" $1
    docker pull staphb/prokka:latest			
    message "docker run staphb/prokka:latest prokka -help" $1
    docker run staphb/prokka:latest prokka -help
    message "docker run staphb/prokka:latest prokka --version" $1
    docker run staphb/prokka:latest prokka --version
    #prokka 1.14.5
    message 'adding prokka alias for docker invocation: cat >> ~/.bash_aliases <<EOF' $1
    cat >> ~/.bash_aliases <<EOF
alias prokka='docker run staphb/prokka:latest prokka'
EOF
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

#################################### installations above
function print_all_versions() {
    python --version
    conda --version
    seqkit version
    kraken2 -v
    canu -version 
    bwa 2>&1 | head -n 3
    message "minimap2 --vesion"
    minimap2 --version
    message "flye --version"
    flye --version
    samtools version | head -n 2
    bcftools --version | head -n 2
    fastqc --version
    pycoQC --version
    message "cutadapt --version"
    cutadapt --version
    message "porechop --version"
    porechop --version
    R --version | head -n 1
    message "qiime --version"
    qiime --version
    metabat2  2>&1 | head -n 3
    message "\n> > > > > > for CHECKM"    
    phmmer -h | head -n 2
    nhmmer -h | head -n 2
    jackhmmer -h | head -n 2
    prodigal -v
    message "pplacer --version"
    pplacer --version
    message "< < < < < < < END for CHECKM"    
    checkm | head -n 2 | tail -n 1
    prokka --version
    kraken-biom --version
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
message "All metagenomics software (25 applications) is about to be installed."
message "This script should only be run once before creating the metagenomics AMI."
message "Deletes all software previously installed in ~/software and installs the new versions as at 20220930."
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

remove_samtools $logfile
update_python $logfile
update_conda $logfile
install_seqkit $logfile
install_kraken2 $logfile
install_krakenTools $logfile
install_canu $logfile
update_bwa $logfile
install_minimap2 $logfile
install_flye $logfile
install_htslib $logfile
install_samtools $logfile
install_bcftools $logfile
install_fastqc $logfile
install_pycoqc $logfile
update_cutadapt $logfile
check_porechop $logfile
check_r $logfile
install_qiime2 $logfile
install_metabat2 $logfile
check_hmmer $logfile
install_prodigal $logfile
install_pplacer $logfile
install_checkm $logfile
install_prokka $logfile
install_kraken_biom $logfile

message "`colour lg DONE ` installing metagenomics software." $logfile
message " Logout and login again for any environment changes to take effect." $logfile
