library(tercen)
library(dplyr)
library(ggplot2)
library(pgscales)
library(tim)

ctx = tercenCtx()

getData = function(con){
  df = con %>% 
    select(.ri, .ci, .y, .x)
  
  clrVal = con$select(all_of(ctx$colors))
  if(ncol(clrVal) != 1) stop("Need 1 numeric color  for color mapping.")
  colnames(clrVal) = "clrVal"
  
  paneldf = ctx$rselect()
  panels = paneldf %>% 
    as.matrix() %>% 
    apply(1, function(x)paste(x, collapse = "-"))
  paneldf = paneldf %>% 
    mutate(.ri = 0:(nrow(.)-1),
           panels = panels) %>% 
    select(.ri, panels)
  
  supergdf = ctx$cselect()
  superg = supergdf %>% 
    as.matrix() %>% 
    apply(1, function(x)paste(x, collapse = "-"))
  supergdf = supergdf %>% 
    mutate(.ci = 0:(nrow(.)-1),
           superg = superg) %>% 
    select(.ci, superg)
  
  df %>% 
    bind_cols(clrVal) %>% 
    left_join(paneldf, by = ".ri") %>% 
    left_join(supergdf, by = ".ci") %>%
    arrange(.ci) # Arrange by .ci
}

dots = function(x, clrLimits = c(-0.5, 0.5), szLimits = c(0, 2), szRange = c(0,6)){
  x %>% 
    ggplot(aes(x = .x, 
               y = superg, 
               colour = clrVal, 
               size= .y)) +
    geom_point() + 
    xlab("")  +
    ylab("") + 
    scale_colour_gradient2(low = "darkblue", high = "darkred",limits = clrLimits) + 
    scale_size_continuous(limits = szLimits,  range = szRange) + 
    theme_minimal() +
    guides(colour = guide_colorbar(title =cltitle ), 
           size = guide_legend(title = sltitle) )+ 
    theme(legend.title = element_text(size = lsize),
          legend.text = element_text(size = lsize)) 
}
stripwidth = function(x, bw = 1){
   nsg = x %>% 
    pull(superg) %>% 
    unique() %>% 
    length()
   
   bw + bw*nsg
}

layout = ctx$op.value("Layout", as.character, "Horizontal") 
lsize = ctx$op.value("LabelFontSize", as.numeric, 6)
clims = c(ctx$op.value("ColorLowerLimit", as.numeric, -0.5), ctx$op.value("ColorUpperLimit", as.numeric, 0.5))
slims = c(ctx$op.value("SizeLowerLimit", as.numeric, 0), ctx$op.value("SizeUpperLimit", as.numeric, 2))
dotSizeRange = c(ctx$op.value("MinDotSize", as.numeric, 0), ctx$op.value("MaxDotSize", as.numeric, 4))
pheight = ctx$op.value("PlotSize", as.numeric, 7)
cltitle = ctx$op.value("ColorLegendName", as.character, "Fold Change")
sltitle = ctx$op.value("Size LegendName", as.character, "Specificity")
            
df = ctx %>% 
  getData()

pdp =  df %>%
  mutate(clrVal = pmax(clims[1], pmin(clrVal, clims[2])),
         .y = pmax(slims[1], pmin(.y, slims[2]))) %>% 
  dots(clims, slims, dotSizeRange)

if(grepl("Horizontal", layout)){
  h = stripwidth(df)
  pdp = pdp + 
    theme(axis.text.x = element_text(angle = 45, size = lsize, hjust = 1),
          axis.text.y = element_text(size = lsize),
          strip.text.x = element_text(face= "bold", size = lsize, angle = 45),  # Rotate .ri labels (Kinase Family)
          legend.direction = "horizontal", 
          legend.position = "bottom") +
    facet_grid(.~panels, scales = "free_x", space = "free_x") 
  plot_file <- tim::save_plot(pdp, width = pheight,height = h, bg = "white")
} else if(grepl("Vertical", layout)){
  w = stripwidth(df) + .5
  pdp = pdp + 
    theme(axis.text.x = element_text(angle = 45, size = lsize, hjust = 1),
          axis.text.y = element_text(size = lsize)) +
    coord_flip() +
    facet_grid(panels~., scales = "free_y", space = "free") +
    theme(strip.text.y = element_text(angle = 0, face= "bold", size = lsize)) 
  plot_file <- tim::save_plot(pdp, height = pheight, width = w, bg = "white")
} else if(grepl("Wrap", layout)){
  pdp = pdp + 
    facet_wrap(~panels, scales = "free_x") +
    theme(axis.text.x = element_text(angle = 45, size = lsize, hjust = 1),
          axis.text.y = element_text(size = lsize),
          strip.text.x = element_text(face= "bold")) 
  plot_file <- tim::save_plot(pdp, bg = "white")
}

file_to_tercen(plot_file) %>% 
  as_relation() %>%
  as_join_operator(list(), list()) %>%
  save_relation(ctx)
