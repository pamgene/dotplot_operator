library(tercen)
library(dplyr)
library(ggplot2)

ctx = tercenCtx()

save_plot = function(plt, ...) {
  tmp = tempfile(fileext = ".png")
  ggsave(tmp, plot = plt, ...)
  tmp
}

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

colourScale = function(palette, clrLimits){
  if (palette == "divergent_green-purple") {
    # white fixed at 0, same midpoint behaviour as scale_colour_gradient2
    scale_colour_gradientn(colours = c("#4dbd05", "#94d769", "white", "#b98dba", "#9b45a3"),
                           values = c(0, 0.25, 0.5, 0.75, 1),
                           rescaler = function(x, to = c(0, 1), from = range(x, na.rm = TRUE)) {
                             scales::rescale_mid(x, to = to, from = from, mid = 0)
                           },
                           limits = clrLimits)
  } else {
    scale_colour_gradient2(low = "darkblue", high = "darkred", limits = clrLimits)
  }
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
    colourScale(palette, clrLimits) +
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
lsize = ctx$op.value("LabelFontSize", as.numeric, 10)
csize = ctx$op.value("ComparisonFontsize", as.numeric, 10)
gsize = ctx$op.value("GroupFontsize", as.numeric, 6)
lface = if (ctx$op.value("LabelFontBold", as.logical, TRUE)) "bold" else "plain"
clims_automatic = ctx$op.value("ColorLimitAutomatic", as.logical, TRUE)
clims = c(ctx$op.value("ColorLowerLimit", as.numeric, -0.5), ctx$op.value("ColorUpperLimit", as.numeric, 0.5))
slim_automatic = ctx$op.value("SizeLimitAutomatic", as.logical, TRUE)
slims = c(ctx$op.value("SizeLowerLimit", as.numeric, 0), ctx$op.value("SizeUpperLimit", as.numeric, 2))
dotSizeRange = c(ctx$op.value("MinDotSize", as.numeric, 0), ctx$op.value("MaxDotSize", as.numeric, 6))
pheight = ctx$op.value("PlotSize", as.numeric, 12)
cltitle = ctx$op.value("ColorLegendName", as.character, "Fold Change")
sltitle = ctx$op.value("SizeLegendName", as.character, "Specificity")
palette = ctx$op.value("ColorPalette", as.character, "divergent_blue-red")
            
df = ctx %>% 
  getData()

if (clims_automatic) {
  q2 <- quantile(df$clrVal, 0.2, na.rm = TRUE)
  q8 <- quantile(df$clrVal, 0.8, na.rm = TRUE)
  min_val <- min(df$clrVal, na.rm = TRUE)
  max_val <- max(df$clrVal, na.rm = TRUE)
  if (min_val < 0 && max_val > 0) {
    clims = c(min_val, max_val)
  } else {
    clims = c(q2, q8)
  }
}

if (slim_automatic){
  slims = c(0, quantile(df$.y, 0.75, na.rm = TRUE))
}

pdp =  df %>%
  mutate(clrVal = pmax(clims[1], pmin(clrVal, clims[2])),
         .y = pmax(slims[1], pmin(.y, slims[2]))) %>% 
  dots(clims, slims, dotSizeRange)

# label/legend space grows with font size; the short plot side must too,
# otherwise the panel with the dots collapses (sizes were tuned for 6pt)
lscale = max(1, max(lsize, gsize) / 6)

if(grepl("Horizontal", layout)){
  h = stripwidth(df) * lscale
  pdp = pdp +
    guides(colour = guide_colorbar(title = cltitle,
                                   theme = theme(legend.key.width = unit(20 * lsize, "pt")))) +
    theme(axis.text.x = element_text(angle = 45, size = lsize, face = lface, hjust = 1),
          axis.text.y = element_text(size = csize, face = lface),
          strip.text.x = element_text(face= "bold", size = gsize, angle = 45),  # Rotate .ri labels (Kinase Family)
          legend.direction = "horizontal", 
          legend.position = "bottom") +
    facet_grid(.~panels, scales = "free_x", space = "free_x") 
  plot_file <- save_plot(pdp, width = pheight,height = h, bg = "white")
} else if(grepl("Vertical", layout)){
  w = (stripwidth(df) + .5) * lscale
  pdp = pdp + 
    theme(axis.text.x = element_text(angle = 45, size = csize, face = lface, hjust = 1),  # comparisons (flipped)
          axis.text.y = element_text(size = lsize, face = lface)) +
    coord_flip() +
    facet_grid(panels~., scales = "free_y", space = "free") +
    theme(strip.text.y = element_text(angle = 0, face= "bold", size = gsize))
  plot_file <- save_plot(pdp, height = pheight, width = w, bg = "white")
} else if(grepl("Wrap", layout)){
  pdp = pdp + 
    facet_wrap(~panels, scales = "free_x") +
    theme(axis.text.x = element_text(angle = 45, size = lsize, face = lface, hjust = 1),
          axis.text.y = element_text(size = csize, face = lface),
          strip.text.x = element_text(face= "bold", size = gsize))
  plot_file <- save_plot(pdp, bg = "white")
}

file_to_tercen(plot_file) %>% 
  as_relation() %>%
  as_join_operator(list(), list()) %>%
  save_relation(ctx)
