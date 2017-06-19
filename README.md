# Chiron*
Centralized access to Dockerized tools and pipelines for metagenomics developed by the Human Microbiome Project members.  Initially developed for the HMP Cloud Workshop, you can run common metagenomics tools on the command line interactively within Docker or run entire pipelines at once.

\* Pronounced KY-rən

# Why Chiron?

This was initially organized for a training workshop held by the [Human Microbiome Project](http://hmpdacc.org/).  We want this organization of utilities to be useful for others, so an independent project was created.  The name 'Chiron' was used to reflect its initial use in training.  In Greek mythology [Chiron](https://en.wikipedia.org/wiki/Chiron) was the centaur who trained greats such as Aeneas, Heracles, Jason and Achilles.

# Installation

### Install [Docker](https://docs.docker.com/engine/installation/)

The Docker site has detailed [instructions](https://docs.docker.com/engine/installation/) for many architectures, but for some this may be as simple as:

```
$ sudo apt-get install docker.io
[restart]
```

If this is the first time you've installed Docker Engine, reboot your machine (even if the docs leave this step out.)

### Install dependencies

After Docker installation, the only other dependences are python things.  They can all be installed like this on Ubuntu machines.  Make any changes necessary for your platform.

```
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 40976EAF437D05B5
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F76221572C52609D
    sudo apt-get update
    sudo apt install -y python3 python3-pip python-pip
    sudo pip3 install pyyaml requests
    sudo pip install pyyaml cwlref-runner
```

### Get Chiron

This command will create a Chiron directory:

```
$ git clone https://github.com/IGS/Chiron.git
```

# How to run 

There are two primary ways we intend for this to be run.  

First, you can launch an interactive session for any of the tools within a Docker image.  Second, we supply [CWL pipelines](http://www.commonwl.org/) for many tools which will allow you to run entire analysis paths at once in both a local and distributed manner.  Both are described below.

# Get on a cloud machine (optional)

If you want to run things on a cloud machine, you can [launch an Amazon Virtual Machine](https://aws.amazon.com/getting-started/tutorials/launch-a-virtual-machine/).  To just run on your local machine instead, skip to the next step.

# Try an interactive session

If you want to use a specific tool's docker image, you'll find scripts to run each tool such as:

```
$ ./Chiron/bin/humann2_interactive
```

This will download the Docker image if you don't already have it, then drop you to a terminal within it.

# Run a pre-built analysis pipeline

Docker-enabled pipelines have been written for several analysis tools using [Common Workflow Language](https://github.com/common-workflow-language/common-workflow-language) (CWL).  These are available for viewing [here](https://github.com/IGS/Chiron/tree/master/pipelines), and you can view help for any of the pipeline launchers named like this:

```
# ./Chiron/bin/strainphlan_pipeline -h
```

# Existing tools/Docker images:

- umigs/chiron-core - Includes the HMP Client and common utilities
- umigs/chiron-humann2
- umigs/chiron-metacompass
- umigs/chiron-metaviz
- umigs/chiron-phlan - Suite of -PhlAn tools, includes:
  - MetaPhlAn2
  - GraPhlAn
  - PanPhlAn
  - StrainPhlAn
- umigs/chiron-qiime2
- umigs/chiron-valet

# Try a Cloud session on Amazon
To create and configure your Amazon AWS cloud environment to execute the tools and Docker containers presented in the workshop, please use the following guide:

[Cloud Workshop AWS Setup Guide](/docs/amazon_aws_setup.md)

For general instructions about launching virtual machines on AWS, Amazon has provided useful instructions here:

[Launch a VM on Amazon AWS](https://aws.amazon.com/getting-started/tutorials/launch-a-virtual-machine/)

# Getting help

If you run into issues using Chiron or just need help, please either [file an issue](https://github.com/IGS/Chiron/issues) here on GitHub or use the [mailing list](https://groups.google.com/forum/#!forum/igs-chiron).

# Related Links:

- [HMP data portal](http://portal.ihmpdcc.org) - click 'Data' to get to facet search
- [HMP client](https://github.com/IGS/hmp_client) - client for downloading HMP data via manifest files generated at the HMP data portal
