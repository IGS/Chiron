# Ubuntu 16.10 is the minimum for some native support, such as Python 3.6
FROM ubuntu:yakkety

MAINTAINER Joshua Orvis <jorvis@gmail.com>
LABEL Description="Holds all software for the HMP Cloud Pilot workshop" Version="0.5"

RUN apt-get -y update && apt-get install -y --no-install-recommends git python python-pip python3.6 subversion unzip wget
RUN pip install --upgrade pip
RUN mkdir /dbs

# General location to drop datasets needed by tutorials
RUN mkdir /tutorials/


################
## HMP client ##
################

RUN apt-get install -y python3-pip

ENV LC_ALL C.UTF-8
ENV LANG C.UTF-8

RUN pip3 install boto

RUN wget -O /opt/hmp_client.zip https://github.com/jmatsumura/hmp_client/archive/master.zip
RUN unzip -d /opt/hmp_client /opt/hmp_client.zip
ENV PATH /opt/hmp_client/hmp_client-master/bin:$PATH

#############
## HUMAnN2 ##
#############

RUN pip install humann2

# Setting up tutorial data 
RUN mkdir -p /tutorials/humann2/input
RUN wget -P /tutorials/humann2/input https://bitbucket.org/biobakery/biobakery/raw/tip/demos/biobakery_demos/data/humann2/input/demo.fastq
RUN wget -P /tutorials/humann2/input https://bitbucket.org/biobakery/biobakery/raw/tip/demos/biobakery_demos/data/humann2/input/demo.sam
RUN wget -P /tutorials/humann2/input https://bitbucket.org/biobakery/biobakery/raw/tip/demos/biobakery_demos/data/humann2/input/demo.m8

# Do any databases need to be installed?
RUN mkdir /dbs/humann2

# ChocoPhlAn is 5.6 GB
RUN humann2_databases --download chocophlan full /dbs/humann2/
 
# You'll only want one of these:
#    Full UniRef90 (11.0 GB)
# RUN humann2_databases --download uniref uniref90_diamond /dbs/humann2/
#    EC-filtered UniRef90 (0.8 GB)
RUN humann2_databases --download uniref uniref90_ec_filtered_diamond /dbs/humann2/
#    Full UniRef50 (4.6 GB)
# RUN humann2_databases --download uniref uniref50_diamond /dbs/humann2/
#    EC-filtered UniRef50 (0.2 GB)
# RUN humann2_databases --download uniref uniref50_ec_filtered_diamond /dbs/humann2/

#################
## MetaCompass ##
#################

# Pre-reqs
RUN pip3 install snakemake
RUN apt-get install -y libbz2-dev liblzma-dev libncurses5-dev zlib1g-dev

RUN apt-get install -y software-properties-common python-software-properties
RUN add-apt-repository ppa:webupd8team/java
RUN apt-get update && echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && apt-get -y install oracle-java8-installer

RUN svn checkout https://svn.code.sf.net/p/kmer/code/trunk /opt/kmer
RUN make -C /opt/kmer
ENV PATH $PATH:/opt/kmer/meryl

# Careful here, as this version conflicts with the required (much older) version required by
#  StrainPhlAn.  We'll make this first in PATH since it's current.
RUN wget -O /tmp/samtools-1.4.1.tar.bz2 https://github.com/samtools/samtools/releases/download/1.4.1/samtools-1.4.1.tar.bz2
RUN tar -xjf /tmp/samtools-1.4.1.tar.bz2 -C /tmp/
RUN /tmp/samtools-1.4.1/configure --prefix=/opt/samtools-1.4.1 --enable-plugins --enable-libcurl
RUN mv config.h config.mk config.status /tmp/samtools-1.4.1
RUN make -C /tmp/samtools-1.4.1 all all-htslib
RUN make -C /tmp/samtools-1.4.1 install
ENV PATH $PATH:/opt/samtools-1.4.1/bin

RUN git clone https://github.com/voutcn/megahit.git /opt/megahit
RUN make -C /opt/megahit
ENV PATH $PATH:/opt/megahit

# Doing the install without downloading RefSeq since it's so large.  We'll do this step
#  as needed within the running instance.
RUN git clone https://github.com/marbl/MetaCompass.git /opt/MetaCompass
RUN g++ -Wall -W -O2 -o /opt/MetaCompass/bin/extractSeq /opt/MetaCompass/src/utils/extractSeq.cpp
RUN g++ -Wall -W -O2 -o /opt/MetaCompass/bin/formatFASTA /opt/MetaCompass/src/utils/formatFASTA.cpp
RUN g++ -Wall -W -O2 -o /opt/MetaCompass/bin/buildcontig /opt/MetaCompass/src/buildcontig/buildcontig.cpp /opt/MetaCompass/src/buildcontig/cmdoptions.cpp /opt/MetaCompass/src/buildcontig/memory.cpp /opt/MetaCompass/src/buildcontig/procmaps.cpp /opt/MetaCompass/src/buildcontig/outputfiles.cpp
RUN wget --no-check-certificate https://gembox.cbcb.umd.edu/metacompass/markers.tar.gz -P /opt/MetaCompass/src/metaphyler
RUN tar -xzvf /opt/MetaCompass/src/metaphyler/markers.tar.gz -C /opt/MetaCompass/src/metaphyler/
RUN rm /opt/MetaCompass/src/metaphyler/markers.tar.gz

# This needs to happen separately within a startup/init script
#RUN wget --no-check-certificate https://gembox.cbcb.umd.edu/metacompass/refseq.tar.gz


#################
## MetaPhlAn 2 ##
#################

# Drop the tutorial data in a location where attendees can get to it
RUN mkdir -p /tutorials/metaphlan2/input
RUN wget -P /tutorials/metaphlan2/input https://bitbucket.org/biobakery/biobakery/raw/tip/demos/biobakery_demos/data/metaphlan2/input/SRS014459-Stool.fasta.gz
RUN wget -P /tutorials/metaphlan2/input https://bitbucket.org/biobakery/biobakery/raw/tip/demos/biobakery_demos/data/metaphlan2/input/SRS014464-Anterior_nares.fasta.gz
RUN wget -P /tutorials/metaphlan2/input https://bitbucket.org/biobakery/biobakery/raw/tip/demos/biobakery_demos/data/metaphlan2/input/SRS014470-Tongue_dorsum.fasta.gz
RUN wget -P /tutorials/metaphlan2/input https://bitbucket.org/biobakery/biobakery/raw/tip/demos/biobakery_demos/data/metaphlan2/input/SRS014472-Buccal_mucosa.fasta.gz
RUN wget -P /tutorials/metaphlan2/input https://bitbucket.org/biobakery/biobakery/raw/tip/demos/biobakery_demos/data/metaphlan2/input/SRS014476-Supragingival_plaque.fasta.gz
RUN wget -P /tutorials/metaphlan2/input https://bitbucket.org/biobakery/biobakery/raw/tip/demos/biobakery_demos/data/metaphlan2/input/SRS014494-Posterior_fornix.fasta.gz    

# Install some pre-reqs needed
RUN wget -O /opt/hclust2.zip https://bitbucket.org/nsegata/hclust2/get/tip.zip
RUN unzip -d /opt/hclust2 /opt/hclust2.zip
RUN mv /opt/hclust2/nsegata-hclust2-*/* /opt/hclust2/
RUN rm -rf /opt/hclust2/nsegata-hclust2-*

ENV PATH $PATH:/opt/hclust2

# These have to be done sequentially, as there's a current problem with the dependency order resolution
RUN pip install numpy
RUN pip install matplotlib scipy biom-format h5py

RUN wget -O /opt/metaphlan2.zip https://bitbucket.org/biobakery/metaphlan2/get/default.zip
RUN unzip -d /opt/metaphlan2 /opt/metaphlan2.zip
RUN mv /opt/metaphlan2/biobakery-metaphlan2* /opt/metaphlan2/biobakery-metaphlan2

ENV PATH $PATH:/opt/metaphlan2/biobakery-metaphlan2
ENV MPA_DIR /opt/metaphlan2/biobakery-metaphlan2

## Add the utility scripts included with metaphlan2 to the PATH
ENV PATH $PATH:/opt/metaphlan2/biobakery-metaphlan2/utils/

#############
## METAVIZ ##
#############

RUN apt-get install -y --no-install-recommends php

# neo4j instance
## METAVIZ Instance
COPY metaviz_start.sh /bin/metaviz_start.sh

# neo4j instance
RUN wget -O neo4j.tar.gz "https://neo4j.com/artifact.php?name=neo4j-community-3.2.0-unix.tar.gz"
RUN mkdir /graph-db && tar -xvzf neo4j.tar.gz -C /graph-db
RUN /graph-db/neo4j-community-3.2.0/bin/neo4j-admin set-initial-password "osdf1"
RUN echo "dbms.connectors.default_listen_address=0.0.0.0" >> /graph-db/neo4j-community-3.2.0/conf/neo4j.conf
RUN echo "dbms.allow_format_migration=true" >> /graph-db/neo4j-community-3.2.0/conf/neo4j.conf
RUN wget -O graph.db.tar.gz "http://metaviz-dev.cbcb.umd.edu/hmp_workshop/graph.db.tar.gz"
RUN tar -xvzf graph.db.tar.gz -C /graph-db/neo4j-community-3.2.0/data/databases/
RUN ./graph-db/neo4j-community-3.2.0/bin/neo4j start

EXPOSE 7474 7687

# metaviz data provider
RUN wget -O metaviz-dp.zip "https://github.com/epiviz/metaviz-data-provider/archive/hmp_workshop.zip"
RUN pip install --upgrade pip
RUN unzip -d /graph-api metaviz-dp.zip && pip install -r /graph-api/metaviz-data-provider-hmp_workshop/requirements.txt 
RUN touch /graph-api/metaviz-data-provider-hmp_workshop/credential.py && echo "neo4j_username=\"neo4j\"" >> /graph-api/metaviz-data-provider-hmp_workshop/credential.py && echo "neo4j_password=\"osdf1\"" >> /graph-api/metaviz-data-provider-hmp_workshop/credential.py 

EXPOSE 5000

# metaviz ui
RUN wget -O metaviz-ui.zip "https://github.com/epiviz/epiviz/archive/metaviz-4.1.zip"
RUN unzip -d /graph-ui metaviz-ui.zip
RUN echo 'epiviz.Config.SETTINGS.dataServerLocation="http://metaviz.cbcb.umd.edu/data/",epiviz.Config.SETTINGS.dataProviders=[["epiviz.data.EpivizApiDataProvider","mouseTest","http://localhost:5000/api",[],3,{4:epiviz.ui.charts.tree.NodeSelectionType.NODE}]];' > /graph-ui/epiviz-metaviz-4.1/site-settings.js
RUN rm metaviz-ui.zip

EXPOSE 8888
CMD bash /bin/metaviz_start.sh


#################
## StrainPhlAn ##
#################

RUN apt-get install -y muscle ncbi-blast+ raxml libz-dev libncurses5-dev libncursesw5-dev
RUN pip install biopython pysam msgpack-python dendropy

# StrainPhlAn requires a specifically old version of samtools (0.1.19), where
#  apt-get currently installs 1.3.1
RUN wget -O /tmp/samtools.zip https://github.com/samtools/samtools/archive/0.1.19.zip
RUN unzip -d /opt/ /tmp/samtools.zip
RUN make -C /opt/samtools-0.1.19
RUN rm /tmp/samtools.zip

# Some PATH supplement.  The path to the older samtools will need to be added by students
#  manually since it breaks MetaCompass, which expects a current version.
# ENV PATH /opt/samtools-0.1.19:/opt/samtools-0.1.19/misc:/opt/samtools-0.1.19/bcftools:$PATH
ENV PATH $PATH:/opt/metaphlan2/biobakery-metaphlan2/strainphlan_src

# The rest of the install was included already with MetaPhlAn2

###########
## Qiime ##
###########

# Configure matplotlib for a headless environment
#   https://forum.qiime2.org/t/matplotlib-configuration-issues/185/2?u=thermokarst
RUN mkdir -p ~/.config/matplotlib
RUN echo "backend: Agg" > ~/.config/matplotlib/matplotlibrc

# Attempt to resolve python Click library errors
ENV LC_ALL C.UTF-8
ENV LANG C.UTF-8

# Dependency: miniconda
RUN wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
RUN bash Miniconda3-latest-Linux-x86_64.sh -b -p /opt/miniconda
ENV PATH $PATH:/opt/miniconda/bin
RUN rm Miniconda3-latest-Linux-x86_64.sh

# Primary: Qiime2-2017.2
RUN conda create -n qiime2-2017.4 --file https://data.qiime2.org/distro/core/qiime2-2017.4-conda-linux-64.txt

# Users will need to run this when they start the Qiime tutorial
# source activate qiime2-2017.4



