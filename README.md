# Chiron*
Centralized access to Dockerized tools and pipelines for metagenomics developed by the Human Microbiome Project members.  Initially developed for the HMP Cloud Workshop.

This is under very active development and isn't likely to be stable until June 10th at the earliest.

\* Pronounced KY-rən

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

# Try a Cloud session on Amazon
The following instructions will help you launch the analysis on Amazon Cloud.

How to create account.
https://aws.amazon.com/console/

Switch to US East.

How to generate key-pair.

Set security settings.

Launch AMI. 
ami-21530437

Connecting to Amazon Instance using ssh.


https://aws.amazon.com/getting-started/tutorials/launch-a-virtual-machine/


# Related Links:

- [Discussion group site](https://groups.google.com/forum/#!forum/hmp-cloud-pilot) (Google groups, for collaborators)
- [GDC interface](http://portal.ihmpdcc.org) - Click 'data' to get the facet search
