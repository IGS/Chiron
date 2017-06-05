# Chiron
Centralized access to Dockerized tools and pipelines for metagenomics developed by the Human Microbiome Project members.  Initially developed HMP Cloud Pilot workshop.

This is under very active development and isn't likely to be stable until June 10th at the earliest.

# Why Chiron?

This was initially organized for training workshop held by the [Human Microbiome Project](http://hmpdacc.org/).  We want this organization of utilities to be useful for others, so an independent project was created.  The name 'Chiron' was used to reflect its initial use in training.  In Greek mythology [Chiron](https://en.wikipedia.org/wiki/Chiron) was the centaur who trained greats such as Aeneas, Heracles, Jason and Achilles.

# How to run 

There are two primary ways we intend for this to be run.  First, we will supply [CWL pipelines](http://www.commonwl.org/) for many tools which will allow you to run entire analysis paths at once in both a local and distributed manner.  This is under development, and not yet available.

Second, you can reference a specific tool directly and enter that tool's Docker image, allowing interactive use.

# Try an interactive session

If you want to try a specific tool's docker image, you'll need to first make sure you have
Docker [installed](https://docs.docker.com/engine/installation/), reboot, then execute a command like this (depending on the tool you want to run):

```
docker run -i -t jorvis/chiron-humann2 /bin/bash
```

This will download the Docker image if you don't already have it, then drop you to a terminal within it.

# Existing Docker images available (and status)

- jorvis/chiron-core - Installed (version as of 2017-05-08) (Contains HMP Client and common libraries)
- jorvis/chiron-humann2 - Installed and tested with 'humann2_test'
- jorvis/chiron-metacompass - Installed, currently without RefSeq
- jorvis/chiron-metaphlan2 - Installed and tested with MetaPhlAn2 tutorial on bitbucket
- jorvis/chiron-metaviz - Installed
- jorvis/chiron-strainphlan - Installed and tested with [tutorial steps](https://bitbucket.org/biobakery/biobakery/wiki/strainphlan#rst-header-how-to-run)
- jorvis/chiron-qiime2 - Installed (2017.4) and tested with the [Moving Pictures](https://docs.qiime2.org/2017.4/tutorials/moving-pictures/) tutorial

# Related Links:

- [Discussion group site](https://groups.google.com/forum/#!forum/hmp-cloud-pilot) (Google groups, for collaborators)
- [GDC interface](http://portal.ihmpdcc.org) - Click 'data' to get the facet search
