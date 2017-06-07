FROM umigs/chiron-core:latest

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

RUN apt-get install -y muscle ncbi-blast+ raxml libz-dev libncurses5-dev libncursesw5-dev
RUN pip install biopython pysam msgpack-python dendropy

# StrainPhlAn requires a specifically old version of samtools (0.1.19), where
#  apt-get currently installs 1.3.1
RUN wget -O /tmp/samtools.zip https://github.com/samtools/samtools/archive/0.1.19.zip
RUN unzip -d /opt/ /tmp/samtools.zip
RUN make -C /opt/samtools-0.1.19
RUN rm /tmp/samtools.zip
ENV PATH /opt/samtools-0.1.19:/opt/samtools-0.1.19/misc:/opt/samtools-0.1.19/bcftools:$PATH

# The rest is all handled by the MetaPhlAn2 installation

##############
## GraPhlAn ##
##############

RUN apt-get install -y mercurial
RUN hg clone https://hg@bitbucket.org/nsegata/graphlan /opt/graphlan
ENV PATH $PATH:/opt/graphlan/

##############
## PanPhlAn ##
##############

RUN hg clone https://bitbucket.org/CibioCM/panphlan /opt/panphlan

RUN wget -O /opt/bowtie2-2.3.2-linux-x86_64.zip https://sourceforge.net/projects/bowtie-bio/files/bowtie2/2.3.2/bowtie2-2.3.2-linux-x86_64.zip/download
RUN unzip -d /opt/bowtie2 /opt/bowtie2-2.3.2-linux-x86_64.zip
RUN rm /opt/bowtie2-2.3.2-linux-x86_64.zip
ENV PATH /opt/bowtie2:$PATH
ENV BT2_HOME=/opt/bowtie2/

RUN mkdir /opt/panphlan/indexes
ENV BOWTIE2_INDEXES=/opt/panphlan/indexes/



