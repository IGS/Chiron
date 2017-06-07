FROM umigs/chiron-core:latest

###########
## VALET ##
###########

RUN apt-get install -y bedtools r-base r-base-dev libfile-copy-link-perl

RUN wget -O /opt/bowtie2-2.3.2-linux-x86_64.zip https://sourceforge.net/projects/bowtie-bio/files/bowtie2/2.3.2/bowtie2-2.3.2-linux-x86_64.zip/download
RUN unzip -d /opt/bowtie2 /opt/bowtie2-2.3.2-linux-x86_64.zip
RUN rm /opt/bowtie2-2.3.2-linux-x86_64.zip
ENV PATH /opt/bowtie2:$PATH
ENV BT2_HOME=/opt/bowtie2/

RUN wget -O /tmp/samtools-1.4.1.tar.bz2 https://github.com/samtools/samtools/releases/download/1.4.1/samtools-1.4.1.tar.bz2
RUN tar -xjf /tmp/samtools-1.4.1.tar.bz2 -C /tmp/
RUN /tmp/samtools-1.4.1/configure --prefix=/opt/samtools-1.4.1 --enable-plugins --enable-libcurl
RUN mv config.h config.mk config.status /tmp/samtools-1.4.1
RUN make -C /tmp/samtools-1.4.1 all all-htslib
RUN make -C /tmp/samtools-1.4.1 install
ENV PATH $PATH:/opt/samtools-1.4.1/bin

RUN pip install numpy
RUN pip install scipy

#RUN wget -O /tmp/Reapr_1.0.18.tar.gz ftp://ftp.sanger.ac.uk/pub/resources/software/reapr/Reapr_1.0.18.tar.gz
#RUN tar -xzf /tmp/Reapr_1.0.18.tar.gz -C /tmp/
#RUN cd /tmp/Reapr_1.0.18/ && ./install.sh

RUN git clone https://github.com/cmhill/VALET.git /opt/VALET
ENV VALET /opt/VALET/src/py/

