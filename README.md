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
SizeLowerLimit|Lower limit for size scale of the dots (default: 0)
SizeUpperLimit|Upper limit for size scale of the dots(default: 2)
PlotSize|Size of longer plot size
LabelFontSize|Font size for axis labels
SizeLegendName|Title for the size legend
ColorLegendName|Title for teh color legend


Output relations|.
---|---
Output table | a dot plot (png file)








 
 
