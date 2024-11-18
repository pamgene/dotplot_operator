library(tercen)
library(dplyr)
library(ggplot2)

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
    left_join(supergdf, by = ".ci")
}

dots = function(x, clrLimits = c(-0.8, 0.8), szLimits = c(0, 2.5)){
  x %>% 
    ggplot(aes(x = .x, 
               y = superg, 
               colour = clrVal, 
               size= .y)) +
    geom_point() + 
    xlab("")  +
    ylab("") + 
    scale_colour_gradient2(low = "darkblue", high = "darkred",limits = clrLimits) + 
    scale_size_continuous(limits = szLimits) +
    theme_minimal()
}

pdp = ctx %>% 
  getData() %>% 
  dots()

pdp = pdp + facet_grid(.~panels, scales = "free")




