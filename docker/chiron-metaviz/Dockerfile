FROM umigs/chiron-core:1.1.0

#############
## METAVIZ ##
#############
RUN apt-get install -y --no-install-recommends php

# neo4j instance
## METAVIZ Instance
COPY metaviz_start.sh /bin/metaviz_start.sh
RUN chmod +x /bin/metaviz_start.sh
COPY setup.R setup.R

RUN apt-get install -y software-properties-common python-software-properties
RUN add-apt-repository ppa:webupd8team/java
RUN apt-get update && echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && apt-get -y install oracle-java8-installer

RUN apt-get install -y apt-transport-https
RUN echo "deb http://cran.revolutionanalytics.com/bin/linux/ubuntu yakkety/" >> /etc/apt/sources.list
RUN apt-get update
RUN apt-get install -y r-base r-base-dev --allow-unauthenticated
RUN apt-get install -y libcurl4-openssl-dev libxml2-dev libssl-dev git
RUN Rscript setup.R

RUN apt-get install -y -q gdebi-core libapparmor1 supervisor wget vim
RUN wget https://download2.rstudio.org/rstudio-server-1.0.143-amd64.deb
#This is from https://github.com/mgymrek/docker-rstudio-server/blob/master/Dockerfile
RUN gdebi -n rstudio-server-1.0.143-amd64.deb
RUN adduser metaviz --disabled-login 
RUN echo "metaviz:metaviz" | chpasswd
RUN usermod -a -G root metaviz
RUN chmod -R 777 /usr/local/lib/R/
RUN mkdir -p /var/log/supervisor
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN git config --global user.name "metaviz"
RUN git config --global user.email "metaviz@metaviz.org"
RUN wget -O ~/workshopData "https://github.com/jmwagner/Chiron/blob/master/docker/chiron-metaviz/workshopData?raw=true"
RUN chown metaviz ~/workshopData && chgrp metaviz ~/workshopData

# neo4j instance
RUN wget -O neo4j.tar.gz "https://neo4j.com/artifact.php?name=neo4j-community-3.2.0-unix.tar.gz"
RUN mkdir /graph-db && tar -xvzf neo4j.tar.gz -C /graph-db
RUN /graph-db/neo4j-community-3.2.0/bin/neo4j-admin set-initial-password "osdf1"
RUN echo "dbms.connectors.default_listen_address=0.0.0.0" >> /graph-db/neo4j-community-3.2.0/conf/neo4j.conf
RUN echo "dbms.allow_format_migration=true" >> /graph-db/neo4j-community-3.2.0/conf/neo4j.conf
RUN wget -O graph.db.tar.gz "http://metaviz-dev.cbcb.umd.edu/hmp_workshop/graph.db.tar.gz"
RUN tar -xvzf graph.db.tar.gz -C /graph-db/neo4j-community-3.2.0/data/databases/
RUN ./graph-db/neo4j-community-3.2.0/bin/neo4j start

# metaviz data provider
RUN wget -O metaviz-dp.zip "https://github.com/epiviz/metaviz-data-provider/archive/hmp_workshop.zip"
RUN pip install --upgrade pip
RUN unzip -d /graph-api metaviz-dp.zip && pip install -r /graph-api/metaviz-data-provider-hmp_workshop/requirements.txt 
RUN touch /graph-api/metaviz-data-provider-hmp_workshop/credential.py && echo "neo4j_username=\"neo4j\"" >> /graph-api/metaviz-data-provider-hmp_workshop/credential.py && echo "neo4j_password=\"osdf1\"" >> /graph-api/metaviz-data-provider-hmp_workshop/credential.py 

# metaviz ui
RUN wget -O metaviz-ui.zip "https://github.com/epiviz/epiviz/archive/metaviz-4.1.zip"
RUN unzip -d /graph-ui metaviz-ui.zip
RUN echo 'epiviz.Config.SETTINGS.dataServerLocation="http://metaviz.cbcb.umd.edu/data/",epiviz.Config.SETTINGS.dataProviders=[["epiviz.data.EpivizApiDataProvider","ihmp_data","http://localhost:5000/api",[],3,{4:epiviz.ui.charts.tree.NodeSelectionType.NODE}]];' > /graph-ui/epiviz-metaviz-4.1/site-settings.js
RUN rm metaviz-ui.zip

EXPOSE 8888 5000 8787 7123

#This is from https://github.com/mgymrek/docker-rstudio-server/blob/master/Dockerfile
CMD ["/usr/bin/supervisord"]

