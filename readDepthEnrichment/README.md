# readdepthHyperGeomEnrichment.py

This is the script that was used to calculate relative enrichment of sequence reads per input contig in our assemblies. 

## Requirements

* Python v3.6+
	* Scipy
	* typing

## Input

Any tab delimited file containing normalized read depth estimates should be usable. The program is designed to also carry over any metadata (ie. explanatory columns or taxonomic information) to enable easy comparisons of datasets.

Here is an example input file to illustrate usage:

**test_file.tab**


|metadata_1	|metadata_2	|tax_group_col	|sample_col	|other_rd_1	|other_rd_2	|other_rd_3|
|:--- |:--- |:--- |:--- |:--- |:--- |:--- |
|contig1	|GC1	| R. albus	| 30	| 5	| 4	| 3 |
|contig2	|GC2	| R. albus	| 5	| 4 | 2 | 1|
|contig3	|GC3	| F. succinogenes | 1 | 10 | 40 | 20 |
|contig4	|GC4	| F. succinogenes | 0 | 40 | 20 | 23 |

In order to estimate the over- or under- enrichment of the read depth from the sample compared to other datasets (eg. other_rd_1), you would run the following command:

```bash
python3 readdepthHyperGeomEnrichment.py -f test_file.tab -c 4,5,6 -s 3 -m 0,1 -g 2 -o my_desired_output.tab
```

## Output

The default output file is tab-delimited text. Output from the program will depend on the number of optional metadata columns that you carry over. These are printed in the first *n* columns of the output file. The default output columns then begin from *n* + 1, and are as follows:

1. Group designation
2. Total number of observations per group
3. Number of times that the sample was the largest read depth in an observation
4. Number of times that the sample had the lowest read depth in an observation
5. Hypergeometric significance of the count of maximum read depth
6. Hypergeometric significance of the count of minimum read depth
7. Benjamini-Hockberg corrected significance for Maximum read depth observations
8. Benjamini-Hockberg corrected significance for Minimum read depth observations