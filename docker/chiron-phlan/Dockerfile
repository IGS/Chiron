FROM umigs/chiron-core:1.0.0

#################
## MetaPhlAn 2 ##
#################

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

ENV PATH $PATH:/opt/metaphlan2/biobakery-metaphlan2:/opt/metaphlan2/biobakery-metaphlan2/utils
ENV MPA_DIR /opt/metaphlan2/biobakery-metaphlan2

# Drop the tutorial data in a location where attendees can get to it
RUN mkdir -p /tutorials/metaphlan2/input
RUN wget -P /tutorials/metaphlan2/input https://bitbucket.org/biobakery/biobakery/raw/tip/demos/biobakery_demos/data/metaphlan2/input/SRS014459-Stool.fasta.gz
RUN wget -P /tutorials/metaphlan2/input https://bitbucket.org/biobakery/biobakery/raw/tip/demos/biobakery_demos/data/metaphlan2/input/SRS014464-Anterior_nares.fasta.gz
RUN wget -P /tutorials/metaphlan2/input https://bitbucket.org/biobakery/biobakery/raw/tip/demos/biobakery_demos/data/metaphlan2/input/SRS014470-Tongue_dorsum.fasta.gz
RUN wget -P /tutorials/metaphlan2/input https://bitbucket.org/biobakery/biobakery/raw/tip/demos/biobakery_demos/data/metaphlan2/input/SRS014472-Buccal_mucosa.fasta.gz
RUN wget -P /tutorials/metaphlan2/input https://bitbucket.org/biobakery/biobakery/raw/tip/demos/biobakery_demos/data/metaphlan2/input/SRS014476-Supragingival_plaque.fasta.gz
RUN wget -P /tutorials/metaphlan2/input https://bitbucket.org/biobakery/biobakery/raw/tip/demos/biobakery_demos/data/metaphlan2/input/SRS014494-Posterior_fornix.fasta.gz

#################
## StrainPhlAn ##
#################

# Grab data needed for tutorials
RUN mkdir -p /tutorials/strainphlan
RUN wget -P /tutorials/strainphlan https://bitbucket.org/biobakery/biobakery/raw/tip/demos/biobakery_demos/data/strainphlan/output/13530241_SF05.markers
RUN wget -P /tutorials/strainphlan https://bitbucket.org/biobakery/biobakery/raw/tip/demos/biobakery_demos/data/strainphlan/output/13530241_SF06.markers
RUN wget -P /tutorials/strainphlan https://bitbucket.org/biobakery/biobakery/raw/tip/demos/biobakery_demos/data/strainphlan/output/19272639_SF05.markers
RUN wget -P /tutorials/strainphlan https://bitbucket.org/biobakery/biobakery/raw/tip/demos/biobakery_demos/data/strainphlan/output/19272639_SF06.markers
RUN wget -P /tutorials/strainphlan https://bitbucket.org/biobakery/biobakery/raw/tip/demos/biobakery_demos/data/strainphlan/output/40476924_SF05.markers
RUN wget -P /tutorials/strainphlan https://bitbucket.org/biobakery/biobakery/raw/tip/demos/biobakery_demos/data/strainphlan/output/40476924_SF06.markers

# Reference genome
RUN wget -P /tutorials/strainphlan https://bitbucket.org/biobakery/biobakery/raw/tip/demos/biobakery_demos/data/strainphlan/input/GCF_000154325.fna.bz2

# Metadata 
RUN wget -P /tutorials/strainphlan https://bitbucket.org/biobakery/biobakery/raw/tip/demos/biobakery_demos/data/strainphlan/output/metadata.txt

RUN apt-get -q update \
  && apt-get -q install -y --no-install-recommends muscle ncbi-blast+ raxml libtbb2 libz-dev libncurses5-dev libncursesw5-dev \
  && apt-get -q clean autoclean \
  && apt-get -q autoremove -y \
  && rm -rf /var/lib/apt/lists/*
RUN pip install biopython pysam msgpack-python dendropy

# StrainPhlAn requires a specifically old version of samtools (0.1.19), where
#  apt-get currently installs 1.3.1
RUN wget -O /tmp/samtools.zip https://github.com/samtools/samtools/archive/0.1.19.zip
RUN unzip -d /opt/ /tmp/samtools.zip
RUN make -C /opt/samtools-0.1.19
RUN rm /tmp/samtools.zip
ENV PATH /opt/samtools-0.1.19:/opt/samtools-0.1.19/misc:/opt/samtools-0.1.19/bcftools:$PATH

ENV PATH /opt/metaphlan2/biobakery-metaphlan2/strainphlan_src:$PATH

# The rest is all handled by the MetaPhlAn2 installation

##############
## GraPhlAn ##
##############

RUN mkdir -p /tutorials/graphlan 

RUN apt-get -q update \
  && apt-get -q install --no-install-recommends -y mercurial \
  && apt-get -q clean autoclean \
  && apt-get -q autoremove -y \
  && rm -rf /var/lib/apt/lists/*

RUN pip install dendropy==3.12.0
RUN pip install ipdb

RUN hg clone https://hg@bitbucket.org/nsegata/graphlan /opt/graphlan
ENV PATH $PATH:/opt/graphlan/
ENV PATH /opt/graphlan/export2graphlan:$PATH

##############
## PanPhlAn ##
##############

RUN hg clone https://bitbucket.org/CibioCM/panphlan /opt/panphlan

# Data we need for the tutorial
RUN mkdir -p /tutorials/panphlan/pangenomes
RUN wget -P /tutorials/panphlan/pangenomes http://www.matthias-scholz.de/panphlan_erectale15.zip
RUN unzip -d /tutorials/panphlan/pangenomes /tutorials/panphlan/pangenomes/panphlan_erectale15.zip
RUN rm /tutorials/panphlan/pangenomes/panphlan_erectale15.zip

RUN mkdir -p /tutorials/panphlan/map_results
RUN wget -P /tutorials/panphlan/map_results https://bitbucket.org/CibioCM/panphlan/wiki/map_results/SRS013951_erectale15.csv.bz2
RUN wget -P /tutorials/panphlan/map_results https://bitbucket.org/CibioCM/panphlan/wiki/map_results/SRS014459_erectale15.csv.bz2
RUN wget -P /tutorials/panphlan/map_results https://bitbucket.org/CibioCM/panphlan/wiki/map_results/SRS015065_erectale15.csv.bz2
RUN wget -P /tutorials/panphlan/map_results https://bitbucket.org/CibioCM/panphlan/wiki/map_results/SRS019161_erectale15.csv.bz2

# Couple dependencies we can grab down from apt and pypi
RUN apt-get -q update \
  && apt-get -q install --no-install-recommends -y libtbb2 python-tk bc

# We install bowtie2-legacy since normal bowtie2 doesn't want to play nicely.
RUN wget -O /opt/bowtie2-2.3.2-legacy-linux-x86_64.zip https://sourceforge.net/projects/bowtie-bio/files/bowtie2/2.3.2/bowtie2-2.3.2-legacy-linux-x86_64.zip/download
RUN unzip -d /opt/ /opt/bowtie2-2.3.2-legacy-linux-x86_64.zip
RUN rm /opt/bowtie2-2.3.2-legacy-linux-x86_64.zip
ENV PATH /opt/bowtie2-2.3.2-legacy:$PATH
ENV BT2_HOME=/opt/bowtie2-2.3.2-legacy

RUN mkdir /opt/panphlan/indexes
ENV BOWTIE2_INDEXES=/opt/panphlan/indexes/

ENV PATH /opt/panphlan/:$PATH
