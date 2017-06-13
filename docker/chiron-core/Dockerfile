# Ubuntu 16.10 is the minimum for some native support, such as Python 3.6
FROM ubuntu:yakkety

MAINTAINER Joshua Orvis <jorvis@gmail.com>
LABEL Description="Common utilities / tools for Chiron-related docker images"

################
## The basics ##
################

RUN apt-get -y update && apt-get install -y build-essential autoconf libtool pkg-config 
RUN apt-get install -y --no-install-recommends git nano python python-pip python-dev python-setuptools python3.6 python3-setuptools subversion unzip wget less
RUN pip install --upgrade pip

# R things
COPY setup.R setup.R
RUN apt-get install -y apt-transport-https
RUN echo "deb http://cran.revolutionanalytics.com/bin/linux/ubuntu yakkety/" >> /etc/apt/sources.list
RUN apt-get update
RUN apt-get install -y r-base r-base-dev --allow-unauthenticated
RUN Rscript setup.R

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
ADD https://github.com/IGS/Chiron/raw/master/examples/hmp_data_exercise/16s_metadata.tsv /tutorials/hmp_client/
ADD https://github.com/IGS/Chiron/raw/master/examples/hmp_data_exercise/extract_qiime_subset.R /tutorials/hmp_client/
ADD https://github.com/IGS/Chiron/raw/master/examples/hmp_data_exercise/extract_subset.R /tutorials/hmp_client/
ADD https://github.com/IGS/Chiron/raw/master/examples/hmp_data_exercise/generate_matched_two_site_samples.R /tutorials/hmp_client/
ADD https://github.com/IGS/Chiron/raw/master/examples/hmp_data_exercise/generate_matched_visit_samples.R /tutorials/hmp_client/
ADD https://github.com/IGS/Chiron/raw/master/examples/hmp_data_exercise/identify_visit_samples.R /tutorials/hmp_client/
ADD https://github.com/IGS/Chiron/raw/master/examples/hmp_data_exercise/wgs_metadata.tsv /tutorials/hmp_client/


