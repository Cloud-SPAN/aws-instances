#!/usr/bin/env bash
source colour_utils_functions.sh	 # to add colour to some messages

files=`ls *.sh`
case $# in
0) 	message "$(colour lb $(basename $0)) creates soft links to each of the scripts (.sh file) in the 
current directory in the specified \"bin\" directory. The current directory is:
	$(colour cyan `pwd`)

  $(colour lb usage):    $(basename $0)  \"bin_directory\"
  $(colour lb example):  $(basename $0)  ~/.local/bincsaws   (Jorge's location - specify yours)

  This script $(colour lr "must be run") in the directory where the scripts source files to link reside. 
Creating such links makes it possible (1) to run the scripts from any location in the system (typical) 
but also (2) to git-manage the scripts separately from other scripts in the target bin directory.
  The target $(colour cyan bin) directory $(colour lr "must exist") and be specified in the execution PATH. 

  $(colour lb "Files to link (NB: files or links with same names in target bin directory will be deleted)"):"
	ls *.sh
	exit 2;;
*)	;;	# just continue below
esac

message "===================================="
target_bin_directory=$1
if [ ! -d $target_bin_directory ]; then
    message "..Target bin directory $(colour cyan $target_bin_directory) $(colour lr "does not exist"). Create it before running this script."
    exit 2
fi

source_directory=`pwd`
message "Creating soft links in bin directory $(colour cyan $target_bin_directory) to each .sh file in $(colour cyan $source_directory)"

cd $target_bin_directory
message "\nworking in directory $(colour cyan `pwd`):"

for file in $files
do
    message "creating link: ln -sf $source_directory/$file $file"  
    ln -sf $source_directory/$file $file	### -sf create link deleting first if it exists
done
message "FINISHED creating links"
