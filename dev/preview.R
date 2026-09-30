# Render preview PNGs of main.R from the example UKA data, without Tercen.
#
# Runs the unmodified main.R against a mock Tercen context. Run it inside the
# operator image so R and packages match production (see CLAUDE.md):
#
#   docker run --rm -v "$PWD:/src" --entrypoint Rscript dotplot_operator:dev /src/dev/preview.R
#
# Crosstab used (as in the UKA workflows):
#   rows = Kinase Family, columns = Sgroup_contrast, x = Kinase Name,
#   y (dot size) = Specificity Score, colour = Kinase Statistic.
# Every other operator property is left at its default unless listed in `cases`.

suppressMessages({library(dplyr); library(ggplot2)})

src = "/src"
out_dir = file.path(src, "dev", "preview")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
unlink(list.files(out_dir, full.names = TRUE))

datasets = c(short = "example_uka_input_short.csv", long = "example_uka_input_long.csv")
layouts = c("Horizontal", "Vertical", "Wrap")
palettes = c("divergent_blue-red", "divergent_green-purple")

# One row per rendered PNG: extend this grid for extra inspection cases.
cases = expand.grid(data = names(datasets), layout = layouts, palette = palettes,
                    stringsAsFactors = FALSE)

read_uka = function(file) {
  d = read.csv(file.path(src, file), check.names = FALSE, stringsAsFactors = FALSE)
  names(d) = sub("^.*UKA60\\.", "", names(d))
  d %>%
    filter(`Kinase Name` != "", !is.na(`Specificity Score`)) %>%
    transmute(family = `Kinase Family`, contrast = Sgroup_contrast, .x = `Kinase Name`,
              .y = `Specificity Score`, statistic = `Kinase Statistic`)
}

# Tercen passes every property with its operator.json defaultValue, so the mock
# does the same (jsonlite is not in the image; the file layout is regular).
json = paste(readLines(file.path(src, "operator.json"), warn = FALSE), collapse = " ")
m = regmatches(json, gregexpr('"name"\\s*:\\s*"[^"]+"\\s*,\\s*"defaultValue"\\s*:\\s*("[^"]*"|[^,} ]+)', json))[[1]]
json_defaults = setNames(as.list(gsub('"', "", sub('.*"defaultValue"\\s*:\\s*', "", m))),
                         sub('"name"\\s*:\\s*"([^"]+)".*', "\\1", m))

# Mock of the tercen ctx API used by main.R; Tercen indexes row/column factor
# levels in sorted order, starting at 0.
mock_ctx = function(d, props) {
  props = modifyList(json_defaults, props)
  rows = sort(unique(d$family))
  cols = sort(unique(d$contrast))
  qt = d %>% mutate(.ri = match(family, rows) - 1L, .ci = match(contrast, cols) - 1L)
  ctx = list(
    colors = "statistic",
    op.value = function(name, type, default) if (!is.null(props[[name]])) type(props[[name]]) else default,
    select = function(cols) dplyr::select(qt, {{ cols }}),
    rselect = function() data.frame(family = rows),
    cselect = function() data.frame(contrast = cols),
    data = qt
  )
  class(ctx) = "mockctx"
  ctx
}
select.mockctx = function(.data, ...) dplyr::select(.data$data, ...)

# Intercept the output chain of main.R: keep the PNG instead of uploading it.
file_to_tercen = function(file) file
as_relation = function(x) x
as_join_operator = function(x, ...) x
save_relation = function(x, ctx) file.copy(x, current_out, overwrite = TRUE)

main_src = parse(file.path(src, "main.R"))
main_src = main_src[!vapply(main_src, function(e) identical(e, quote(library(tercen))), logical(1))]

for (i in seq_len(nrow(cases))) {
  cs = cases[i, ]
  props = list(Layout = cs$layout, ColorPalette = cs$palette)
  tercenCtx = function() mock_ctx(read_uka(datasets[[cs$data]]), props)
  current_out = file.path(out_dir, sprintf("%s_%s_%s.png", cs$data, cs$layout, cs$palette))
  eval(main_src, envir = globalenv())
  cat(basename(current_out), "\n")
}

# One overview page (open dev/preview/index.html in a browser).
pngs = sort(basename(list.files(out_dir, pattern = "[.]png$")))
writeLines(c('<!doctype html><meta charset="utf-8"><title>Dotplot preview</title>',
             '<style>body{font-family:sans-serif;margin:16px;background:#fff}',
             'figure{margin:0 0 32px}figcaption{font-weight:bold;margin-bottom:6px}',
             'img{max-width:100%;max-height:900px;border:1px solid #ddd}</style>',
             sprintf('<figure><figcaption>%s</figcaption><img src="%s"></figure>',
                     sub("[.]png$", "", pngs), pngs)),
           file.path(out_dir, "index.html"))
cat("wrote", length(pngs), "PNGs to", out_dir, "\n")
