[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.6564314.svg)](https://doi.org/10.5281/zenodo.6564314)
AMAIS: Automatic Management of AWS AMI Instances Using Bash Scripts

Overview
Running the scripts
Scripts design
Before running the scripts - environment configuration
Further work - improving the scripts

*** Overview:

The bash scripts below invoke AWS services through the aws command line interface (CLI) to create, start, stop, and delete one or multiple instances with a single run of a script. Each instance is created to be accessed through a domain name that is mapped to an "elastic" (permanent) IP address, and once created it is run and left running.
    Domain names, elastic IP addresses, and login keys are created on demand on creating the corresponding instances, and are deleted when the corresponding instances are deleted. When resources are created, they are automatically tagged with the tags required by the IT Team of York University. This will help reduce costs and admin time, and keep the relevant AWS account tidy - yet logs of the scripts runs are held in the machine wherein the scripts were run.
    Between creating and deleting a group of instances, all or some of the instances in the group can be stopped and started as required.

aws_domainNames_create.sh
aws_domainNames_delete.sh
aws_elasticIPs_allocate.sh
aws_elasticIPs_associate2instance.sh
aws_elasticIPs_deallocate.sh
aws_elasticIPs_disassociate.sh
aws_instances_configure.sh
aws_instances_launch.sh
aws_instances_terminate.sh
aws_loginKeyPair_create.sh
aws_loginKeyPair_delete.sh
colours_functions.sh
instances_create.sh
instances_delete.sh
instances_start.sh
instances_stop.sh

The last four scripts, instances_create.sh, instances_delete.sh instances_start.sh and instances_stop.sh are meant to be invoked by the user as described below. The scripts named "aws_...sh" are meant to be invoked by the script instances_create.sh or instances_delete.sh, but can be invoked individually for debugging or improving purposes. The script colour_functions.sh provides (is "sourced" by) the other scripts with text colouring functions for the logging output of "the other scripts" to be easier to read.

***Running the scripts 

The scripts are to be invoked thus:

$ instances_create.sh  instancesNamesFile
$ instances_stop.sh    instancesNamesFile
$ instances_start.sh   instancesNamesFile
$ instances_delete.sh  instancesNamesFile

The scripts named "aws...sh" are invoked the same way, for example:

$ aws_domainNames_create.sh   instancesNamesFile

The input file instancesNamesFile can be named differently but must contain each of the names of the instances to create (delete, start, etc.) in one line, like this:

instance01
instance02
...

*** Scripts design

The scripts were designed and organised around the names of the instances to create, delete, etc. This is why all scripts are invoked the same way: receiving as input the file with the names of target instances.  Specifically,  when creating an instance or a resource for an instance, the result (output) of invoking the relevant AWS service (through the aws cli) is written to a file whose name has, as a substring, the name of the instance as specified in the input file in order to enable us to track related resources.  

For example, after running:

$ instances_create.sh instancesNamesFile

the following files will be created for each instance specified in the input file:

domain-name-create-instance01.txt
elastic-IPaddress-for-instance01.txt
login-key-instance01.txt		# the login key must extracted from this file (.txt) and 
login-key-instance01.pem		# placed in this file
...
similarly named files for instance02 and for other instances specified in the input file.

Those files contain (among other pieces of information) the resourceID of the resource (requested by the script and) allocated by the AWS service. The resourceID (e.g. key-00b392c7ddf3fd3ac) is given by the relevant AWS service and is needed to invoke further operations on the resource. Thus, when an instance and its resources are to be deleted, we can look into those files for their AWS resourceID. 
*** Before running the scripts - environment configuration

Observe the following before running the scripts. The examples below asumme a Linux machine and how I have run the scripts assuming the genomics course context. I indicate which parts can be changed for another context.

Create a directory to run the scripts and move to the created directory so that it becomes your "current" directory. For example:

jorge@wine:~/software/york/cloud-SPAN/genomics-course/aws-stuff $  

I will only show the end of prompt "aws-stuff $" from now on.

The scripts can be stored in your current directory (aws-stuff) or in your local bin directory (/home/jorge/bin). I'm running the scripts in the current directory as they are only relevant to the genomics course. My PATH is:

aws-stuff $ echo $PATH
.:/home/jorge/bin:/home/jorge/.local/bin:.... other bin directories

The dot . at the beginning represents the current directory, which means that, when running a script in the current directory (../aws-stuff), I can run it thus "instances_create.sh .." instead of  "./instances_create.sh ..".

*Inputs

Create the following directories to hold the data related to creating, deleting, etc., a group of instances:

aws-stuff$ mkdir -p gc_run02_data/inputs

This will create (within aws-stuff) the directory gc_run02_data and the directory inputs within gc_run02_data.

You can use another name for gc_run02_data but not for inputs. For example, for the 3rd run of the genomics course I will create:

aws-stuff$ mkdir -p gc_run03_data/inputs

Create the following configuration files in gc_run02_data/inputs:

instancesNames.txt  resourcesIDs.txt  yorkTags.txt

You can use another name for the file instancesNames.txt, but you must use resourcesIDs.txt and yorkTags.txt as these names are "hardwired" in the scripts code. The contents of "instancesNames.txt" should be as described above: only an instance name in each line.

instance01
instance02
...

You can use whatever names you want but it is convenient to use some numeric or alphabetical pattern that will let you identify them quickly. 

The contents of the file resourcesIDs.txt should be like this:

imageId			ami-05be6a5ff8a9091e0
instanceType		t2.small
securityGroupId		sg-0771b67fde13b3899
subnetId		subnet-00ff8cd3b7407dc83
hostZone		cloud-span.aws.york.ac.uk  
hostZoneId		Z012538133YPRCJ0WP3UZ

You can change the values on the right column (but not on the left column). Use the characters space or tab to separate the values in each line. Based on the hostZone value (cloud-span.aws.york.ac.uk), the domain names of each instance created will be similar to (assuming the instances names used above):

instance01.cloud-span.aws.york.ac.uk
instance02.cloud-span.aws.york.ac.uk
..

Obviously, the source/blueprint Amazon Machine Image (AMI) must exist in, or be accessible by, your AWS account; you must have configured the securityGroupId, the subnetId and the hostZoneId.


The contents of yorkTags.txt should be like this:

name		instance
group		BIOL
project		cloud-span
status		prod
pushed_by 	manual
defined_in	manual

You can change the values on the right column (but not on the left column). The value of the key "name" (instance) is overwritten with the actual name of each instance. Use the characters space or tab to separate the values in each line. 

*Outputs

Recall that the results of creating instances, or resources for instances, are written to files such as:

domain-name-create-instance01.txt
elastic-IPaddress-for-instance01.txt
login-key-instance01.txt
..
domain-name-create-instance02.txt
elastic-IPaddress-for-instance02.txt
login-key-instance02.txt
..

For easy access of all these (results) files, all the files about "domain-name-create-instance...txt" are placed in the same directory (defined below), all the files about "elastic-IPaddress-for-instance...txt" are placed in the same directory, and so on. 

These "same directory"/ies are handled automatically as follows. 

When you run a script, the outputs directory will be automatically created (if it doesn't exist) at the same level of the inputs directory (in our example: "..aws-stuff/gc_run02_data/outputs"). And within the outputs directory, the following directories will be created by the script in parenthesis when the script is invoked either by the script instances_create.sh or by the user manually:

aws-stuff $ ls gc_run02_data/outputs/
domain-names-creation-output	  (created by aws_domainNames_create.sh)
instances-creation-output	  (created by aws_instances_launch.sh)
ip-addresses-allocation-output	  (created by aws_elasticIPs_allocate.sh)
ip-addresses-association-output	  (created by aws_elasticIPs_associate2instance.sh)
login-keys			  (created by aws_loginKeyPair_create.sh)
login-keys-creation-output	  (created by aws_loginKeyPair_create.sh)

Thus, the directory "../outputs/domain-names-creation-output/" contains all the files: domain-name-create-instance01.txt, domain-name-create-instance02.txt, etc. Similarly for the other  "..-output" directories in the list above, each contain all the results file of each instance regading elastic IP addresses, or login-keys, etc.

The scripts, output directories, and results files just described are related to *creating* instances or resources for instances. When *deleting* instances or resources of (allocated to) instances, the relevant scripts also create output directories to store the files with the results of deleting an instance or a resource of an instance. The output directories are also created within the outputs directory (gc_run02_data/outputs/).  These are examples of output directories and the scripts that creates them when the script is invoked either by the script instances_delete.sh or by the user manually:

domain-names-delete-output20211214.134348	(aws_domainNames_delete.sh)
domain-names-delete-output20211215.092841	(aws_domainNames_delete.sh)
instances-delete-output20211214.134328		(aws_instances_terminate.sh)
instances-delete-output20211215.092841		(aws_instances_terminate.sh)
ip-addresses-deallocate-output20211214.134408	(aws_elasticIPs_deallocate.sh)
ip-addresses-deallocate-output20211215.092841	(aws_elasticIPs_deallocate.sh)
ip-addresses-disassociate-output20211214.134358	(aws_elasticIPs_disassociate.sh)
ip-addresses-disassociate-output20211215.092841	(aws_elasticIPs_disassociate.sh)
login-keys-delete-output20211214.134338		(aws_loginKeyPair_delete.sh)
login-keys-delete-output20211215.092841		(aws_loginKeyPair_delete.sh)

The only difference to the creation of output directories above (for results of creating instances or other resources) is that, output directories for results of deleting instances or other resources are named with the date of creation as a suffix.

Handling such a suffix allows us to better keep track of what was deleted and when. For example, we may want to delete only a number of instances and their resources in the middle of the course because of cancellations. To do so, we only need to create another instancesNames.txt file, say instancesNamesFile-Deletes20220321.txt, and use it thus:

aws-stuff $ instances_delete.sh  gc_run02_data/inputs/instancesNamesFile-Deletes20220321.txt

And only the instances specified in that file will be deleted. And we will keep record in our local machine of what happened when.

Technical note 1:

All scripts display in the screen and log onto the relevant file the results of creating or deleting the relevant result. All results should be "Success in creating/deleting ...", except the results of disassociating elastic IP addresses - which are nothing to worry about. The results of disassociatingIP addresses are issued by the script  aws_elasticIPs_disassociate.sh and may sometimes be:

"Error disassociating elasticIP, instance: instance11-gc; ...".

This is because instances are deleted first and, by the time that script is run, the association of IP addresses to instances is no longer valid/existant. This is more likely to happen if instance is stopped. If it is running, then stopping it before deleting it will take longer and disassociating the IP address will most like be successful. 

Technical note 2:
The user invoking the scripts must have installed:
- the aws cli
- saml2aws
- Bash shell.

Technical note 3:
The AWS account must have been configured with adequate limits in number of instances, elastic IP addresses, that are to be created.


*** Improvements

The scripts just described provide enough functionality to handle AMI instances efficiently in the context of the Genomics course, and similar contexts where each instance is to be used by a particular individual for a period of time.

Other contexts will most likely need modifying the scripts and, of course, the scripts can be improved somehow. This is a list of improvements that could be undertaken:

- Code naming conventions and comments in scripts can be improved.

- When creating or deleting an instance or resource, it is not validated whether that resource already exists or has been deleted. Doing so will help manage not running the scripts accidentally.

- Checking the limits (quotas) of the AWS account.

- Some scripts write temporary results to the /tmp/ directory while checking the status of a resource. For instance, an ip address cannot be associated to an instance until the instance is finally created, but creating an instance take much longer than creating an IP address. Similary with creating the domain names; we have to wait for them to be visible before trying to access each instance to log in to configure it. The point is: the scripts will not work if they cannot write to /tmp directory. This may be relevant to Windows and Mac users.  

- Managing dynamic addresses should perhaps be considered in order to make management more efficient. 

- Adding the --dry-run option to each script

- Handling more tags

- Handling othe instance-internal configuration


