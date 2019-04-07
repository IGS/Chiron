FROM ubuntu:18.04

#############
## MEGAHIT ##
#############

MAINTAINER Joshua Orvis <jorvis@gmail.com>
LABEL Description="This image is used to run the metagenomic assembler MEGAHIT" Version="1.0.0"

RUN apt-get -y update && apt-get install -y wget python g++ zlib1g-dev bc xz-utils

RUN wget -O megahit.tar.gz https://github.com/voutcn/megahit/releases/download/v1.0.6/megahit_v1.0.6_LINUX_CPUONLY_x86_64-bin.tar.gz
RUN tar -xzf megahit.tar.gz
RUN mv megahit_v1.0.6_LINUX_CPUONLY_x86_64-bin/megahit* /usr/bin/

# For reference databases needed by tools
RUN mkdir /dbs

# For demonstration datasets
RUN mkdir /tutorials
