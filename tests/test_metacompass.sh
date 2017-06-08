cd /opt/MetaCompass

wget ftp://public-ftp.hmpdacc.org/Illumina/posterior_fornix/SRS044742.tar.bz2

tar -xjvf SRS044742.tar.bz2
 
cat SRS044742/*.fastq >SRS044742.fastq

./go_metacompass.py -U SRS044742.fastq -o SRS044742_unpaired_out

./go_metacompass.py -P SRS044742/SRS044742.denovo_duplicates_marked.trimmed.1.fastq,SRS044742/SRS044742.denovo_duplicates_marked.trimmed.2.fastq -o SRS044742_out

./go_metacompass.py -P SRS044742/SRS044742.denovo_duplicates_marked.trimmed.1.fastq,SRS044742/SRS044742.denovo_duplicates_marked.trimmed.2.fastq -U SRS044742/SRS044742.denovo_duplicates_marked.trimmed.singleton.fastq -o SRS044742_out2
