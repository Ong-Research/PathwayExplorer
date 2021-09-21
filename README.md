# PathwayExplorer

This is an app to provide a tool to explore the results of a differential expression analysis and the downstream pathway analysis.

It requires:

1. Results of using DESeq2 to test for differential expression
2. A `gmt` symbol file obtained from [MSigDB](https://www.gsea-msigdb.org/gsea/msigdb/)

Then the app will show:

1. A volcano plot to explore the DE results. Clicking here will show whether the gene is one of the leading genes in a pathway

<center>
<img src="man/figures/demo_volcano.png" alt = "volcano" width = "450"/>
</center>

2. A dot plot to explore the pathway analysis results. Clicking here will show in the volcano plot which genes are in the pathway and which among them are determined as leading edges by gsea.

<center>
<img src="man/figures/demo_pathway.png" alt = "path" width = "450" />
</center>


