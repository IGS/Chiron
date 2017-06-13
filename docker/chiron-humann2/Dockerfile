FROM umigs/chiron-core:1.0.0

#############
## HUMAnN2 ##
#############

RUN pip install humann2

RUN mkdir -p /tutorials/humann2/input
RUN wget -P /tutorials/humann2/input https://bitbucket.org/biobakery/biobakery/raw/tip/demos/biobakery_demos/data/humann2/input/demo.fastq
RUN wget -P /tutorials/humann2/input https://bitbucket.org/biobakery/biobakery/raw/tip/demos/biobakery_demos/data/humann2/input/demo.sam
RUN wget -P /tutorials/humann2/input https://bitbucket.org/biobakery/biobakery/raw/tip/demos/biobakery_demos/data/humann2/input/demo.m8
RUN wget -P /tutorials/humann2/input https://bitbucket.org/biobakery/biobakery/raw/tip/demos/biobakery_demos/data/humann2/input/hmp_pathabund.pcl

RUN wget -P /tutorials/humann2/input https://bitbucket.org/biobakery/biobakery/raw/tip/demos/biobakery_demos/data/metaphlan2/input/SRS014459-Stool.fasta.gz
RUN wget -P /tutorials/humann2/input https://bitbucket.org/biobakery/biobakery/raw/tip/demos/biobakery_demos/data/metaphlan2/input/SRS014464-Anterior_nares.fasta.gz
RUN wget -P /tutorials/humann2/input https://bitbucket.org/biobakery/biobakery/raw/tip/demos/biobakery_demos/data/metaphlan2/input/SRS014470-Tongue_dorsum.fasta.gz
RUN wget -P /tutorials/humann2/input https://bitbucket.org/biobakery/biobakery/raw/tip/demos/biobakery_demos/data/metaphlan2/input/SRS014472-Buccal_mucosa.fasta.gz
RUN wget -P /tutorials/humann2/input https://bitbucket.org/biobakery/biobakery/raw/tip/demos/biobakery_demos/data/metaphlan2/input/SRS014476-Supragingival_plaque.fasta.gz
RUN wget -P /tutorials/humann2/input https://bitbucket.org/biobakery/biobakery/raw/tip/demos/biobakery_demos/data/metaphlan2/input/SRS014494-Posterior_fornix.fasta.gz

# Do any databases need to be installed?
RUN mkdir /dbs/humann2

RUN humann2_databases --download utility_mapping full /dbs/humann2/
RUN humann2_databases --download chocophlan DEMO /dbs/humann2/
RUN humann2_databases --download uniref DEMO_diamond /dbs/humann2/

# ChocoPhlAn is 5.6 GB
# RUN humann2_databases --download chocophlan full /dbs/humann2/
 
# You'll only want one of these:
#    Full UniRef90 (11.0 GB)
# RUN humann2_databases --download uniref uniref90_diamond /dbs/humann2/
#    EC-filtered UniRef90 (0.8 GB)
# RUN humann2_databases --download uniref uniref90_ec_filtered_diamond /dbs/humann2/
#    Full UniRef50 (4.6 GB)
# RUN humann2_databases --download uniref uniref50_diamond /dbs/humann2/
#    EC-filtered UniRef50 (0.2 GB)
# RUN humann2_databases --download uniref uniref50_ec_filtered_diamond /dbs/humann2/

# MetaPhlAn2 is required
RUN wget -O /opt/hclust2.zip https://bitbucket.org/nsegata/hclust2/get/tip.zip
RUN unzip -d /opt/hclust2 /opt/hclust2.zip
RUN mv /opt/hclust2/nsegata-hclust2-*/* /opt/hclust2/
RUN rm -rf /opt/hclust2/nsegata-hclust2-*

ENV PATH $PATH:/opt/hclust2

# These have to be done sequentially, as there's a current problem with the dependency order resolution
RUN pip install numpy
RUN pip install matplotlib scipy==0.18.0 biom-format h5py
RUN wget -O /opt/metaphlan2.zip https://bitbucket.org/biobakery/metaphlan2/get/default.zip
RUN unzip -d /opt/metaphlan2 /opt/metaphlan2.zip
RUN mv /opt/metaphlan2/biobakery-metaphlan2* /opt/metaphlan2/biobakery-metaphlan2

ENV PATH $PATH:/opt/metaphlan2/biobakery-metaphlan2:/opt/metaphlan2/biobakery-metaphlan2/utils
ENV MPA_DIR /opt/metaphlan2/biobakery-metaphlan2
