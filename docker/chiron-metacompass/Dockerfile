FROM umigs/chiron-core:1.0.0


#################
## MetaCompass ##
#################

# Pre-reqs
RUN apt-get install -y build-essential libbz2-dev liblzma-dev libncurses5-dev libtbb2 ncbi-blast+ python-software-properties software-properties-common zlib1g-dev python3-dev
RUN pip3 install snakemake psutil
RUN add-apt-repository ppa:webupd8team/java
RUN apt-get update && echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && apt-get -y install oracle-java8-installer

# We install bowtie2-legacy since normal bowtie2 doesn't want to play nicely.
RUN wget -O /opt/bowtie2-2.3.2-legacy-linux-x86_64.zip https://sourceforge.net/projects/bowtie-bio/files/bowtie2/2.3.2/bowtie2-2.3.2-legacy-linux-x86_64.zip/download
RUN unzip -d /opt/ /opt/bowtie2-2.3.2-legacy-linux-x86_64.zip
RUN rm /opt/bowtie2-2.3.2-legacy-linux-x86_64.zip
ENV PATH /opt/bowtie2-2.3.2-legacy:$PATH
ENV BT2_HOME=/opt/bowtie2-2.3.2-legacy

RUN svn checkout https://svn.code.sf.net/p/kmer/code/trunk /opt/kmer
RUN make -C /opt/kmer
ENV PATH $PATH:/opt/kmer/meryl

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

RUN git clone https://github.com/marbl/MetaCompass.git /opt/MetaCompass
RUN g++ -Wall -W -O2 -o /opt/MetaCompass/bin/extractSeq /opt/MetaCompass/src/utils/extractSeq.cpp
RUN g++ -Wall -W -O2 -o /opt/MetaCompass/bin/formatFASTA /opt/MetaCompass/src/utils/formatFASTA.cpp
RUN g++ -Wall -W -O2 -o /opt/MetaCompass/bin/buildcontig /opt/MetaCompass/src/buildcontig/buildcontig.cpp /opt/MetaCompass/src/buildcontig/cmdoptions.cpp /opt/MetaCompass/src/buildcontig/memory.cpp /opt/MetaCompass/src/buildcontig/procmaps.cpp /opt/MetaCompass/src/buildcontig/outputfiles.cpp
RUN wget --no-check-certificate https://gembox.cbcb.umd.edu/metacompass/markers.tar.gz -P /opt/MetaCompass/src/metaphyler
RUN tar -xzvf /opt/MetaCompass/src/metaphyler/markers.tar.gz -C /opt/MetaCompass/src/metaphyler/
RUN rm /opt/MetaCompass/src/metaphyler/markers.tar.gz
ENV PATH /opt/MetaCompass:/opt/MetaCompass/bin:$PATH

# This needs to happen separately within a startup/init script
RUN wget -O /opt/MetaCompass/refseq.tar.gz --no-check-certificate https://gembox.cbcb.umd.edu/metacompass/refseq.tar.gz
RUN tar -xvzf /opt/MetaCompass/refseq.tar.gz -C /opt/MetaCompass/
RUN rm /opt/MetaCompass/refseq.tar.gz
