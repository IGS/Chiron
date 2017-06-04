FROM umigs/chiron-core:latest

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

RUN wget -O /opt/metaphlan2.zip https://bitbucket.org/biobakery/metaphlan2/get/default.zip
RUN unzip -d /opt/metaphlan2 /opt/metaphlan2.zip
RUN mv /opt/metaphlan2/biobakery-metaphlan2* /opt/metaphlan2/biobakery-metaphlan2

ENV PATH $PATH:/opt/metaphlan2/biobakery-metaphlan2
ENV MPA_DIR /opt/metaphlan2/biobakery-metaphlan2
