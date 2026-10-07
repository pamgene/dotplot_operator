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

## Tercen unit test (`tests/`)

Required by the Tercen library and the release install check (missing → `operator.run.test.not.found`, which also blacklists the UKA dotplot apps). It is a smoke test: Tercen installs the release, runs it on `tests/dotplot_input.csv` with every property pinned in `tests/test.json`, and checks that it returns the PNG relation (`ds0.filename`, `ds0.mimetype`, `.content`). `skipColumns` skips the random filename and the image bytes, so visual changes do not break it.

Watch the row count: `file_to_tercen()` splits the PNG into 125 KB chunks, one row each. The test PNG is ~173 KB (2 rows); if a change makes it < 125 KB or > 250 KB, regenerate `tests/dotplot_out_1.csv`.

Regenerate in Tercen Studio (project `dotplot_operator_dev`, workflow `dotplot dev`, step `Dotplot test`; built from `tests/dotplot_input.csv` with the test's crosstab and properties):

```bash
docker run --rm --network tercen_studio_tercen -v "$PWD:/src" --entrypoint Rscript dotplot_operator:dev -e 'options(tercen.workflowId="e4118104-a987-4128-b4a8-89499697ba83", tercen.stepId="5635b3cb-00ef-43cd-b877-07d55c16e709", tercen.username="admin", tercen.password="admin", tercen.serviceUri="http://tercen:5400/"); source("/src/main.R"); cat(ctx$task$id)'
```

Then export the task's output relation (`computedRelation.joinOperators[0].rightRelation.id`) with `tercenctl --context studio data export-csv -s <id> --filePath tests/dotplot_out_1.csv`, prefix `filename`/`mimetype` with `ds0.` (a real operator run namespaces them; dev mode does not), and update `nRows` in the `.schema` sidecar. If the studio step's property values change, keep them identical to `tests/test.json`.

## Release

- Push to `main`: CI builds `ghcr.io/pamgene/dotplot_operator` tagged with the branch name and commit SHA.
- Tag `x.y.z`: the release workflow pins that image in `operator.json`, runs a Tercen install check (pamgene org secrets `TERCEN_TEST_OPERATOR_*`), and creates the GitHub release.
- `tim::save_plot` was replaced by the local `save_plot()` helper (`ggsave` to a tempfile, 300 dpi); keep output sizes in inches.
