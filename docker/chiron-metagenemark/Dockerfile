FROM ubuntu:18.04

##################
## MetaGeneMark ##
##################

MAINTAINER Joshua Orvis <jorvis@gmail.com>
LABEL Description="This image is used to run the metagenomic gene prediction tool MetaGeneMark, and includes biocode for format conversion" Version="1.0.0"

RUN apt-get -y update && apt-get install -y wget python3 python3-pip

RUN wget -O metagenemark.tar.gz https://www.dropbox.com/s/2ruuby8pgy631pk/MetaGeneMark_linux_64.tar.gz?dl=0
RUN tar -xzf metagenemark.tar.gz
RUN mv MetaGeneMark_linux_64/mgm/gmhmmp /usr/bin/
RUN mv MetaGeneMark_linux_64/mgm/MetaGeneMark_v1.mod .

RUN pip3 install biocode

# For reference databases needed by tools
RUN mkdir /dbs

# For demonstration datasets
RUN mkdir /tutorials
