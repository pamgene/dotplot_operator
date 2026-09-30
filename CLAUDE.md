# Dot Plot Operator

Tercen R operator (`main.R`) that draws a faceted dot plot of Upstream Kinase Analysis (UKA) results and returns it as a PNG. Runs in its own container on `tercen/runtime-r44` (R 4.4.3); packages are pinned in `renv.lock`.

## Preview renders: show them after every change

After any change to `main.R` or `operator.json`, render the preview PNGs and show them to the user before committing. They are transient, for inspection only: `dev/preview/` is git- and docker-ignored.

```bash
docker build -t dotplot_operator:dev .        # only needed when Dockerfile/renv.lock changed
docker run --rm -v "$PWD:/src" --entrypoint Rscript dotplot_operator:dev /src/dev/preview.R
```

`dev/preview.R` runs the unmodified `main.R` against a mock Tercen context built from the example data. Every property is taken from its `operator.json` `defaultValue`, exactly as Tercen passes it, unless a case overrides it.

Standard set: 12 PNGs, one per combination of:

- data: `example_uka_input_short.csv`, `example_uka_input_long.csv`
- layout: `Horizontal`, `Vertical`, `Wrap`
- palette: `divergent_blue-red`, `divergent_green-purple`

Crosstab mapping (as in the PamGene UKA workflows):

| Tercen crosstab | Column in example data |
|---|---|
| columns | `Sgroup_contrast` (comparison) |
| rows | `Kinase Family` (group) |
| x-axis | `Kinase Name` |
| y-axis (dot size) | `Specificity Score` |
| colour | `Kinase Statistic` |

The user may ask for extra cases while developing: add rows to `cases` in `dev/preview.R` (other properties go into `props`), and keep the standard 12. Open `dev/preview/index.html` for an overview, and look at the PNGs yourself before reporting.

## Release

- Push to `main`: CI builds `ghcr.io/pamgene/dotplot_operator` tagged with the branch name and commit SHA.
- Tag `x.y.z`: the release workflow pins that image in `operator.json`, runs a Tercen install check (pamgene org secrets `TERCEN_TEST_OPERATOR_*`), and creates the GitHub release.
- `tim::save_plot` was replaced by the local `save_plot()` helper (`ggsave` to a tempfile, 300 dpi); keep output sizes in inches.
