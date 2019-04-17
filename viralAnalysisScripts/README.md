# Scripts used in Viral association analysis

These scripts can be used to segregate and analyze the association signal between proximity ligation data and long-read alignment data into evidence for viral-host analysis, though it is possible to use them for other nefarious purposes (ie. identification of host-specificity of other types of mobile DNA in a metagenomics community). Each script is designed to produce output that can be used in sequence with other scripts in the pipeline, as well as to print statistics for use in downstream analysis.

Extensive details on the use of each script can be found in the supplementary methods of our manuscript, though we will print a quick-use guide and some comments to assist with their use in other datasets.

## Requirements

* Perl 5
* [minimap2](https://github.com/lh3/minimap2)
* [samtools](http://www.htslib.org/)

## Recommended

* [Blobtools](https://blobtools.readme.io/docs)
* [Cytoscape](https://cytoscape.org/)

## Quick start guide

Starting with your assembly, viral contigs (a subset of your assembly!), [error-corrected long reads](#reads), and [contig taxonomy](#taxonomy) files, run the following commands in order:

```bash
# Generate alignment file of long-reads to viral contigs
minimap2 -x map-pb viral_contig_fasta_file.fa error_corrected_long_reads.fa > ec_virus_long_read_alignments.paf

# Identify portions of ec_reads that overhang the viral contigs
perl selectLikelyViralOverhangs.pl ec_virus_long_read_alignments.paf ec_virus_long_read_overhangs

# Extract the portion of viral overhang sequence from the ec_long_reads
perl filterViralOverhangsAndGenerateSeq.pl ec_virus_long_read_overhangs.bed error_corrected_long_reads.fa 150 ec_virus_long_read_overhangs.fa

# Align viral contig overhangs to full assembly
minimap2 -x map-pb full_assembly_fasta_file.fa ec_virus_long_read_overhangs.fa > ec_virus_long_read_overhangs.paf

# Generate an association table
perl filterOverhangAlignments.pl ec_virus_long_read_overhangs.paf ec_virus_long_read_alignments.paf ec_virus_filtered_association_table.tab

# Format the data for input into cytoscape (or some other network-visualization tool)
perl generateViralAssociationGraph.pl contig_taxonomy_file.tab ec_virus_filtered_association_table.tab ec_virus_filtered_association_table.cyto.tab
```

At this point, you should be ready to load the output of the last script (ec_virus_filtered_association_table.cyto.tab) into Cytoscape or some similar visualization tool. However, if you haven't had enough punishment yet, let's try to incorporate [Hi-C links](#hic) into the final dataset.

```bash
# Generate a cytoscape table of Hi-C links
perl generateViralAssociationGraph.hiclinks.pl contig_taxonomy_file.tab hic_link_graph.tab hic_virus_association_table.cyto.tab

# Combine this link table with the long-read overhang table
perl combineViralSignal.pl hic_virus_association_table.cyto.tab ec_virus_filtered_association_table.cyto.tab > combined_virus_association_table.cyto.tab
```

The final step is to load the final, combined association table output into Cytoscape for plotting. I am not an expert in Cytoscape artistry, but the key feature that I've realized about the platform is that you can select groupings of nodes and adjust their positioning automatically using different layout options. This makes for a much cleaner network than some of the default options.

## File formats

We try to use previously defined file formats whenever possible, but there are some slight exceptions that are listed below.

<a name="hic"></a>
### Hi-C link table

This file consists of three tab-delimited columns that can be generated easily from an alignment of Hi-C links to an assembly. The columns consist of the following information (listed in order):

1. Viral contig name
2. Other contig name
3. Count of Hi-C links between the two

If you start with a [SAM file](https://samtools.github.io/hts-specs/SAMv1.pdf) of Hi-C links aligned to your reference, and a new-line delimited list of your contigs of interest (ie. the viral contigs), then you can run this script to generate this file:

```bash
perl createHiCLinktabFile.pl list_of_viral_contigs.txt hic_alignments_to_assembly.sam output_hic_link_graph.tab
```

<a name="reads"></a>
### Error-corrected long reads

This file simply consists of all of the error-corrected long-reads from your dataset in [FASTA](https://en.wikipedia.org/wiki/FASTA_format) file format. There are no other special requirements, apart from the condition that all of the reads from your dataset are present in a single file.

<a name="taxonomy"></a>
### Taxonomic information file

After assembling contigs from your metagenomic sample, we strongly recommend running your assembly through [Blobtools](https://blobtools.readme.io/docs) to generate summary information on your contigs. For this pipeline, we are particularly interested in the putative taxonomic affiliation of each contig as assessed via the Blobtools [taxify](https://blobtools.readme.io/docs/taxify) workflow. If you have a strong aversion to Blobtools, or if it just doesn't fit in your workflow, you can simulate this file by generating a tab-delimited text file with the following information:

```
## Ignored comments are prefaced with double "hashes"
# Contig\tsuperkingdom.t\tgenus.t (single hash denotes the header. Must contain these three fields. Only the position of the "Contig" column must be in the first column of the file)
contig1\tBacteria\tPrevotella
contig2\tBacteria\tPseudomonas
```

