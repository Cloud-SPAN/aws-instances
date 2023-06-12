---
title: 'Automated Management of AWS Instances for Training'
tags:
  - Bash scripts
  - AWS instances
  - automated management
  - teaching assistance
authors:
  - name: Jorge Buenabad-Chavez
    orcid: 0009-0003-1751-653X
    affiliation: 1             # "1, 2" # (Multiple affiliations must be quoted)
  - name: Emma Rand
    affiliation: 1
  - name: James Chong
    affiliation: 1
affiliations:
 - name: Biology Department, University of York
   index: 1
date: 5 June 2023
bibliography: paper.bib
# Optional fields if submitting to a AAS journal too, see this blog post:
# https://blog.joss.theoj.org/2018/12/a-new-collaboration-with-aas-publishing
# aas-doi: 10.3847/xxxxx <- update this with the DOI from AAS once you know it.
# aas-journal: Astrophysical Journal <- The name of the AAS journal.
---

# Summary

We present a set of Bash scripts that automatically manage Amazon Web Services ([AWS](https://aws.amazon.com/)) instances which are Linux virtual machines. We use the scripts to manage multiple instances for training. Instances are created before a workshop with ‘omics data and software analysis tools required for the workshop. Each student is granted exclusive access to an instance through the use of an encrypted login key with the ``ssh`` program:

```  
   ssh -i login-key-instance01.pem  csuser@instance01.cloud-span.aws.york.ac.uk
```

Running the scripts requires only the path of the file that contains the names of the instances to create, stop, start or delete — login keys, IP addresses and domain names used by the instances are created or deleted automatically, see the screenshot below. Creating over 30 instances takes 10-15 minutes. 

![Output of running the script **csinstances_create.sh** — first part. The input file (path) "**courses/instances-management/inputs/instancesNames.txt**" contains three instances names: **instance01**, **instance02**, **instance03**. Login keys are created first as their AWS resource-id’s must be passed as parameters to create the corresponding instances, which are created second. IP addresses are then allocated. The last part of the output (not shown) corresponds to: creating the instance domain names as mapped to the relevant IP addresses, associating IP addresses to instances, accessing each instance with **ssh** as shown above but with the **ubuntu** user (AWS default) to configure the csuser to being accessed with the same login key, and accessing each instance with the csuser (as above) to validate such configuration was successful. Running the script **csinstances_delete.sh** with the same input file will delete those instances and related login keys, IP addresses, and domain names from the AWS account.](fig01-csinstances_create-output-first-part.png)

# Statement of need
Using cloud resources for training is rather efficient and most convenient as there is no need to buy nor manage hardware resources.  Typically, a Linux instance is configured with the required data and software tools and then replicated so that each student can be provided with an individual, real training environment — and instances can be scaled according to the storage and compute requirements of a workshop material. Once a workshop is finished the replicated instances are deleted to stop incurring any further cost.

On the other hand, starting using cloud resources is not trivial for the many technologies involved, and **managing multiple** instances through a graphical user interface (GUI), such as the AWS Console, **is cumbersome** and **error-prone**. 

One of the goals of the [Cloud-SPAN](https://cloud-span.york.ac.uk/) project was to facilitate the use of cloud resources for training as outlined above. The scripts [@buenabad22] and the accompanying online course [Automated Management of AWS Instances](https://cloud-span.github.io/cloud-admin-guide-0-overview/) [@buenabad23] (introduced below) are the outcome of this goal.

# The scripts 
The scripts are shown below. The scripts "`csinstances_*.sh`" are to be run by the user of the scripts, the person in charge of managing instances for workshops. 

```
aws_domainNames_create.sh        aws_instances_configure.sh  csinstances_create.sh
aws_domainNames_delete.sh        aws_instances_launch.sh     csinstances_delete.sh
aws_elasticIPs_allocate.sh       aws_instances_terminate.sh  csinstances_start.sh
aws_elasticIPs_associate2ins.sh  aws_loginKeyPair_create.sh  csinstances_stop.sh
aws_elasticIPs_deallocate.sh     aws_loginKeyPair_delete.sh
aws_elasticIPs_disassociate.sh   colour_utils_functions.sh
```

The scripts "`aws_*.sh`" are invoked by the scripts `csinstances_create.sh` or `csinstances_delete.sh` to either create or delete instances and *related resources* (login keys, IP addresses and domain names used by instances). However, the scripts "`aws_*.sh`" can also be run directly by the user in the same way (passing as parameter the path of a file "*instancesNames.txt*"). This may be useful to improve the scripts or to fix a failed step in creating instances.  The file `colours_utils_functions.sh` provides (is “sourced” by) the other scripts with text colouring functions and other utility functions.

## The scripts design — overview
AWS services can be managed using the AWS Console, the AWS CLI (command line interface), SDKs (libraries) with programming languages, or infrastructure as code (IaC) blueprints — the level of automation increases from the former to the latter [@wittig23]. 

The scripts make use of the AWS CLI to manage instances and *related resources*, invoking the AWS CLI repeatedly for each instance name specified in the input file provided to a script. The scripts communicate through shared files.

When **creating** instances and related resources, the results returned by each AWS CLI invocation include the **resource-id** assigned by AWS to each instance or resource. As a resource-id is needed to further manage the corresponding resource, for example, to delete it, the scripts store the results of each AWS invocation to a file. The name of each file has, as a sub-string, the name of the relevant instance, so that the scripts can later recover the resource-id of the resources to  delete, stop, etc.

The names of login key files and domain names are managed similarly: including the relevant instance name as a substring, as exemplified in the `ssh` example above: the instance name ``instance01`` was made part of both the login key file name and the domain name.

# Configuring the scripts 
How to configure and use the scripts is described in detail in the online course [Automated Management of AWS Instances](https://cloud-span.github.io/cloud-admin-guide-0-overview/)  [@buenabad23] which covers the following main topics: 

- how to open an AWS account and how to configure it both with programmatic access with the AWS CLI (as required by the scritps) and with a base domain name (cloud-span.aws.york.ac.uk in the example above) from which to create each instance domain name.

- how to configure a *terminal* environment with the scripts and the AWS CLI — in Linux, Mac, Windows (Git Bash), or the AWS CloudShell.

- how to configure and run the scripts, manage late registrations and cancellations, and some troubleshooting.

- how to create and manage Amazon Machine Images (AMIs) which serve as templates to create AWS instances.

- the organisation and workings of the scripts.

## Managing instances for workshops
Once an AWS account and a terminal environment have been configured, configuring the scripts to create and manage instances for a workshop involves creating three files:

- **tags.txt** contains a set of key-value pairs to tag instances and related resources on creating them.

- **resourcesIDs.txt** contains the AWS resources to use in creating intances and related resources, namely: the id of the AMI from which instances will be created, the AWS instance type (number of processors and memory) to use for each instance, security group id, subnet id, the base domain name, and the host zone id.

- *instancesNames.txt* — contains the name of the instances to be created. Only this file can be named differently to your choice.

The three files must be placed inside a directory called **inputs**, and the inputs directory must be placed within at least other directory whose name you can choose. We use this directory structure:

```
courses                       ### you can omit this directory or use other name
   genomics01                 ### course/workshop name; you can use other name
      inputs                  ### you **cannot** use other name
         instancesNames.txt   ### you can use other name 
         resourcesIDs.txt     ### you **cannot** use other name
         tags.txt             ### you **cannot** use other name
      outputs                 ### created automatically - do not modify it at all
   genomics02                 ### another course: inputs and outputs dirs. inside
   metagenomics01             ### another course: inputs and outputs dirs. inside
```

# Conclusions
Using the scripts is rather easy and most convenient once the scripts environment has been configured. We have saved a lot of time in managing the instances for our workshops for over a year. Most of the time we only need to configure the file "*instancesNames.txt*" with the names of the instances to manage for a workshop. The file **tags.txt** has to be configured only once and we copy it to manage instances for other workshops. Similary, the file **resourcesIDs.txt** needs to be configured only once for workshops that use a different instance type (t3.small, t3.medium, etc.) or a different AMI template. We handle only two `resourcesIDs.txt` files, one for our genomics workshops and the other for our metagenomics workshops. They differ on both the instance type and the AMI template id, but are the same in all other entries: subnet-id, base domatin name, etc.  

While configuring the scripts environment is somewhat involved, it has to be made only once and the online course covers all the details. It should take 2 to 4 hours depending on experience to cover the course along with configuring the scripts environment. 

# Acknowledgements

We acknowledge contributions from ...

# References
