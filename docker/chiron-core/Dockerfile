# Ubuntu 16.10 is the minimum for some native support, such as Python 3.6
FROM ubuntu:yakkety

MAINTAINER Joshua Orvis <jorvis@gmail.com>
LABEL Description="Common utilities / tools for Chiron-related docker images" Version="0.1"

################
## The basics ##
################

RUN apt-get -y update && apt-get install -y build-essential autoconf libtool pkg-config 
RUN apt-get install -y --no-install-recommends git nano python python-pip python-dev python-setuptools python3.6 python3-setuptools subversion unzip wget
RUN pip install --upgrade pip

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

RUN wget -O /opt/hmp_client.zip https://github.com/jmatsumura/hmp_client/archive/master.zip
RUN unzip -d /opt/hmp_client /opt/hmp_client.zip
ENV PATH /opt/hmp_client/hmp_client-master/bin:$PATH
