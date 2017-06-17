[TOC]

# StrainPhlAn analysis steps

Here we describe the general steps needed to perform a strain-level analysis with StrainPhlAn based on the single nucleotide variations (SNV) of the MetaPhlAn2 markers.

A StrainPhlAn analysis starts from the raw metagenome reads that can be stored in one of the following formats: `.fasta`, `.fastq`, `.fasta.gz`, and `.fastq.gz`.


## 1. Save the .sam file from MetaPhlAn2

The first step is to run MetaPhlAn2 in order to save a necessary file for StrainPhlAn that is the intermediate `.sam` file.
To save the `.sam` intermediate file you just have to specify the `--samout` param when running MetaPhlAn2.

~~~{Bash}
for i in $(ls *.fasta.gz); do
    metaphlan2.py ${i} ${i%.fasta.gz}_profile.txt --bowtie2out ${i%.fasta.gz}_bowtie2.txt \
                                  --samout ${i%.fasta.gz}.sam.bz2 --input_type multifasta
done
~~~

Each `.sam` file contains the reads mapped against the MetaPhlAn2 markers.


## 2. Generation of .markers files

From the `.sam` intermediate files we can generate a `.markers` file for each sample using the `sample2markers.py` script.

~~~{Bash}
for i in $(ls *.sam.bz2); do
    sample2markers.py --ifn_samples ${i} --input_type sam --output_dir .
done
~~~

Each `.markers` file contains the consensus of unique marker genes for each species found in the sample, which will be used for SNV profiling.


## 3. Specie selection & Identification of detected clades

To select which species we can further analyze at strain-level with StrainPhlAn, we should first look at the profiles computed with MetaPhlAn2.
From the MetaPhlAn2 profiles, we should look for the shared species, i.e., such species that are present in many different samples.
For these specie, with StrainPhlAn we can then verify which samples carry the same strain.
You can refer to the MetaPhlAn2 tutorial about how to visualize the species profiles with a heatmap.

To be sure to use the correct keyword for the selected species from the MetaPhlAn2 profiles, we can ask StrainPhlAn to produce a list of detected clades.
From the `.markers` files, StrainPhlAn can identify the clades detected in the samples. From the list of identify clades we can take the keyword for the species that we are interested in, which can be further investigate for the SNV-profiling.

~~~{Bash}
strainphlan.py --ifn_samples *.markers --output_dir . --print_clades_only > clades.txt
~~~

This will write the `clades.txt` file that contains the name of the clades detected in the samples.


## 4. Build a reference database

The following command will extract all the markers from the MetaPhlAn2 database.

~~~{Bash}
bowtie2-inspect ${mpa_dir}/db_v20/mpa_v20_m200 > all_markers.fasta
~~~

**Note**: the file `all_markers.fasta` does not need to be generated each time you execute StrainPhlAn, but instead it can be saved and re-used for all future StrainPhlAn executions.


## 5. Extract markers of a selected clade

Once selected a clade for SNV-profiling, we can use the `extract_markers.py` script to extract the markers sequences for the specific clade.

~~~{Bash}
extract_markers.py --mpa_pkl ${mpa_dir}/db_v20/mpa_v20_m200.pkl --ifn_markers all_markers.fasta --clade ${clade} \
                                                                            --ofn_markers ${clade}.markers.fasta
~~~

where `${clade}` is the name of the species to consider. The correct key to assigned to the `clade` variable can be found in the `clades.txt` file.

**Note**: this step will only extract the markers of the specified `${clade}` from the MetaPhlAn2 database, hence it only need to be run the first time you consider that particular clade. If you should have already run this step for the same clade, but for another analysis, you can retrieve and reuse the `${clade}.markers.fasta` file from your previous analysis.


## 6. Align markers and infer phylogeny

This step, using the `.markers` files and the `${clade}.markers.fasta` file generated in the previous steps, will produce a multiple sequence alignment (MSA) and store it in the file `${clade}.fasta`.
Then, it will execute RAxML to build the phylogenetic tree based on the SNV contained in the MSA.
At this point, you can also provide a reference genome sequence for the specific clade, to be added to the final phylogeny for comparative purposes.

~~~{Bash}
strainphlan.py --ifn_samples *.markers --ifn_markers ${clade}.markers.fasta --ifn_ref_genomes ${reference_genome} \
                                                                                 --output_dir . --clades ${clade}
~~~

where `${reference_genome}` can be a list space-separated that contains the reference genomes to include.

**Note**: if you do not specify any reference genomes (by `--ifn_ref_genomes`) and any specific clade (by `--clades`), StrainPhlAn will build the phylogenetic trees for all species that it can detect.

You can have a look at the [StrainPhlAn tutorial](https://bitbucket.org/biobakery/metaphlan2#markdown-header-some-useful-options) if you want to learn more about the several parameters that can be used to relax thresholds to include more samples in the final result.