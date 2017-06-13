# Ubuntu 16.10 is the minimum for some native support, such as Python 3.6
FROM ubuntu:yakkety

MAINTAINER Joshua Orvis <jorvis@gmail.com>
LABEL Description="Common utilities / tools for Chiron-related docker images" Version="0.1"

################
## The basics ##
################

RUN apt-get -y update && apt-get install -y build-essential autoconf libtool pkg-config 
RUN apt-get install -y --no-install-recommends git nano python python-pip python-dev python-setuptools python3.6 python3-setuptools subversion unzip wget less
RUN pip install --upgrade pip

# R things
RUN apt-get install -y r-base r-base-dev r-cran-getopt r-cran-reshape2

# For reference databases needed by tools
RUN mkdir /dbs

# For demonstration datasets
RUN mkdir /tutorials

################
## HMP client ##
################

RUN apt-get install -y --no-install-recommends python3-pip

ENV LC_ALL C.UTF-8
ENV LANG C.UTF-8

RUN pip3 install boto

RUN wget -O /opt/hmp_client.zip https://github.com/IGS/hmp_client/archive/v1.1.zip
RUN unzip -d /opt/hmp_client /opt/hmp_client.zip
RUN ln -s /opt/hmp_client/hmp_client-1.1/bin/client.py /usr/local/bin/hmp_client

# Place the examples
RUN mkdir /tutorials/hmp_client
COPY ../../examples/hmp_data_exercise/*.* /tutorials/hmp_client/
