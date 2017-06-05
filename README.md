# Chiron
Centralized access to Dockerized tools and pipelines for metagenomics developed by the Human Microbiome Project members.  Initially developed HMP Cloud Pilot workshop.

This is under very active development and isn't likely to be stable until June 10th at the earliest.

# Why Chiron?

This was initially organized for training workshop held by the [Human Microbiome Project](http://hmpdacc.org/).  We want this organization of utilities to be useful for others, so an independent project was created.  The name 'Chiron' was used to reflect its initial use in training.  In Greek mythology [Chiron](https://en.wikipedia.org/wiki/Chiron) was the centaur who trained greats such as Aeneas, Heracles, Jason and Achilles.

# How to run 

There are two primary ways we intend for this to be run.  First, we will supply [CWL pipelines](http://www.commonwl.org/) for many tools which will allow you to run entire analysis paths at once in both a local and distributed manner.  This is under development, and not yet available.

Second, you can launch an interactive session for any of the tools within a Docker image.

# Get on a cloud machine (optional)

If you want to run things on a cloud machine, you can [launch an Amazon Virtual Machine](https://aws.amazon.com/getting-started/tutorials/launch-a-virtual-machine/).  To just run on your local machine instead, skip to the next step.

# Try an interactive session

If you want to use a specific tool's docker image, you'll need to first make sure you have
Docker [installed](https://docs.docker.com/engine/installation/), reboot, then [download](https://github.com/IGS/Chiron/archive/master.zip) or clone Chiron like this:

```
git clone https://github.com/IGS/Chiron.git
```

Under the Chiron/bin/ directory this creates, you'll find scripts to run each tool such as:

```
./Chiron/bin/humann2_interactive
```

This will download the Docker image if you don't already have it, then drop you to a terminal within it.

# Existing tools/Docker images available (and status)

- humann2 - Installed and tested with 'humann2_test'
- metacompass - Installed, currently without RefSeq
- metaphlan2 - Installed and tested with MetaPhlAn2 tutorial on bitbucket
- metaviz - Installed
- strainphlan - Installed and tested with [tutorial steps](https://bitbucket.org/biobakery/biobakery/wiki/strainphlan#rst-header-how-to-run)
- qiime2 - Installed (2017.5) and tested with the [Moving Pictures](https://docs.qiime2.org/2017.5/tutorials/moving-pictures/) tutorial

# Try a Cloud session on Amazon
The following instructions will help you launch the analysis on Amazon Cloud.
How to create account.
How to generate key-pair.
Launch AMI.
Connecting to Amazon Instance using ssh.
Switch to US East.

https://aws.amazon.com/getting-started/tutorials/launch-a-virtual-machine/


# Related Links:

- [Discussion group site](https://groups.google.com/forum/#!forum/hmp-cloud-pilot) (Google groups, for collaborators)
- [GDC interface](http://portal.ihmpdcc.org) - Click 'data' to get the facet search
