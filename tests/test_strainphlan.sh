#!/bin/bash

# Source
#  https://bitbucket.org/biobakery/biobakery/wiki/strainphlan#rst-header-installation

mkdir strainphlan_analysis
cd strainphlan_analysis/

wget https://bitbucket.org/biobakery/biobakery/raw/tip/demos/biobakery_demos/data/strainphlan/input/13530241_SF05.fasta.gz
wget https://bitbucket.org/biobakery/biobakery/raw/tip/demos/biobakery_demos/data/strainphlan/input/13530241_SF06.fasta.gz
wget https://bitbucket.org/biobakery/biobakery/raw/tip/demos/biobakery_demos/data/strainphlan/input/19272639_SF05.fasta.gz
wget https://bitbucket.org/biobakery/biobakery/raw/tip/demos/biobakery_demos/data/strainphlan/input/19272639_SF06.fasta.gz
wget https://bitbucket.org/biobakery/biobakery/raw/tip/demos/biobakery_demos/data/strainphlan/input/40476924_SF05.fasta.gz
wget https://bitbucket.org/biobakery/biobakery/raw/tip/demos/biobakery_demos/data/strainphlan/input/40476924_SF06.fasta.gz

metaphlan2.py 13530241_SF05.fasta.gz 13530241_SF05_profile.txt --bowtie2out 13530241_SF05_bowtie2.txt --samout 13530241_SF05.sam.bz2 --input_type multifasta
metaphlan2.py 13530241_SF06.fasta.gz 13530241_SF06_profile.txt --bowtie2out 13530241_SF06_bowtie2.txt --samout 13530241_SF06.sam.bz2 --input_type multifasta
metaphlan2.py 19272639_SF05.fasta.gz 19272639_SF05_profile.txt --bowtie2out 19272639_SF05_bowtie2.txt --samout 19272639_SF05.sam.bz2 --input_type multifasta
metaphlan2.py 19272639_SF06.fasta.gz 19272639_SF06_profile.txt --bowtie2out 19272639_SF06_bowtie2.txt --samout 19272639_SF06.sam.bz2 --input_type multifasta
metaphlan2.py 40476924_SF05.fasta.gz 40476924_SF05_profile.txt --bowtie2out 40476924_SF05_bowtie2.txt --samout 40476924_SF05.sam.bz2 --input_type multifasta
metaphlan2.py 40476924_SF06.fasta.gz 40476924_SF06_profile.txt --bowtie2out 40476924_SF06_bowtie2.txt --samout 40476924_SF06.sam.bz2 --input_type multifasta

sample2markers.py --ifn_samples 13530241_SF05.sam.bz2 --input_type sam --output_dir .
sample2markers.py --ifn_samples 13530241_SF06.sam.bz2 --input_type sam --output_dir .
sample2markers.py --ifn_samples 19272639_SF05.sam.bz2 --input_type sam --output_dir .
sample2markers.py --ifn_samples 19272639_SF06.sam.bz2 --input_type sam --output_dir .
sample2markers.py --ifn_samples 40476924_SF05.sam.bz2 --input_type sam --output_dir .
sample2markers.py --ifn_samples 40476924_SF06.sam.bz2 --input_type sam --output_dir .

strainphlan.py --ifn_samples *.markers --output_dir . --print_clades_only > clades.txt

# This step fails because mpa_v20_m200.pkl doesn't exist yet
extract_markers.py --mpa_pkl mpa_v20_m200.pkl --ifn_markers all_markers.fasta --clade s__Eubacterium_siraeum --ofn_markers s__Eubacterium_siraeum.markers.fasta

# This is an alternative to command above
wget https://bitbucket.org/biobakery/biobakery/raw/tip/demos/biobakery_demos/data/strainphlan/input/s__Eubacterium_siraeum.markers.fasta

wget https://bitbucket.org/biobakery/biobakery/raw/tip/demos/biobakery_demos/data/strainphlan/input/GCF_000154325.fna.bz2

strainphlan.py --ifn_samples *.markers --ifn_markers s__Eubacterium_siraeum.markers.fasta --ifn_ref_genomes GCF_000154325.fna.bz2 --output_dir . --clades s__Eubacterium_siraeum --marker_in_clade 0.2

