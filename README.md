# Dot Plot Operator

##### Description

Operator for creating a paneled dot plot, intended for the visualization of `Upstream Kinase Analysis` results.


##### Usage



Input projection|.
---|---
`y-axis` | values to map to the size of the dots, typicaly `Specificity Score`.
`color`| values to map to the color of the dots, typicaly `Kinase Change`.
`x-axis` | label for individual dots, typicaly `Kinase_Name`
`rows` | Each row is mapped to a panel, typicaly `Kinase_Family`
`columns`| optional, each column is mapped to a supergroup



Input parameters|.
---|---
ColorLowerLimit|Lower limit for color scale of the dots(default: -0.5)
ColorUpperLimit|Upper limit for color scale of the dots (default: 0.5)
ColorPalette|Diverging color palette, white at 0: `divergent_blue-red` (default) or `divergent_green-purple`
SizeLowerLimit|Lower limit for mapping to the size scale of the dots (default: 0)
SizeUpperLimit|Upper limit for mapping to the size scale of the dots(default: 2)
MinDotSize|Minimum dot size (SizeLowerLimit is mapped to this value, default: 0)
MaxDotSize|Maximum dot size (SizeUpperLimit is mapped to this value, default 6)
PlotSize|Size of longer plot size
LabelFontSize|Font size for the dot labels, e.g. kinase names, and the legend text (default: 10)
ComparisonFontsize|Font size for the comparison labels, i.e. the crosstab columns (default: 10)
GroupFontsize|Font size for the group labels, e.g. kinase families, i.e. the crosstab rows (default: 6)
LabelFontBold|Bold dot and comparison labels (default: true)
SizeLegendName|Title for the size legend
ColorLegendName|Title for teh color legend



Output relations|.
---|---
Output table | a dot plot (png file)

#### Example
https://bionavigator.pamgene.com/Rik/p/a775886f2d6fc251035df4c069050b27






 
 

#### Development

The operator runs in its own container (`ghcr.io/pamgene/dotplot_operator`), built from the `Dockerfile` on
`tercen/runtime-r44` (R 4.4.3). Dependencies are pinned in `renv.lock`; the Docker build copies the matching
packages from the base image instead of compiling them, so a full build takes about a minute.

- Push to `main`: CI builds the image and tags it with the branch name and commit SHA.
- Push a tag `x.y.z`: the release workflow builds `ghcr.io/pamgene/dotplot_operator:x.y.z`, pins it in
  `operator.json` and creates the GitHub release.
- When adding an R package: install it, run `renv::snapshot()` inside the `tercen/runtime-r44` image, and commit
  `renv.lock`.
