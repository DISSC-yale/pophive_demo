# Population Health Information and Visualization Exchange

An R package to establish and work within a data collection framework.

## Installation

```R
# install.packages("remotes")
remotes::install_github("dissc-yale/pophive_demo")
```

## Data Collection

The `data` directory contains **source projects**, which are initialized with the
`pophive_add_source` function:

```R
pophive_add_source("new_source")
```

Each source project includes an `ingest.R` script, which should download data to
the source project's `raw` directory where possible, and ultimately add data to
the source project's `standard` directory.

Data files in the `standard` directory should be in mixed, tabular format, meaning
locations and times are potentially repeated across rows, and any variables, including any
subsets, are spread across columns:

```
geography time       value_total value_partial
10        2020       10          2.34
10100     2020-01-01 20          2.44
```

Each data file in the `standard` directory should include two standard columns:

1. `geography`: Some sort of location ID, ideally in the form of a GEOID (e.g., `c("10", "10100")`).
2. `time`: Some sort of time, ideally in the format `YYYY-MM-DD HH:MM:SS` (e.g., `c("2020", "2020-01-01")`).

These ID columns are ideally hierarchical, such that their sub-parts have the same meaning
between levels. For instance, the first 2 characters identify a state, and the first 5 uniquely identify a county.

Additional columns are treated as the values of interest, and they should be documented in the
`measure_info.json` file.

### Processing and Checking

The `pophive_process` function executes the `ingest.R` file within a source project, then
creates / updates a `standard/datapackage.json` file base on the data found in the `standard` directory.

```R
pophive_process("new_source")
```

The `pophive_check_source` function runs some checks on the standard data and measure info
within a source project:

```R
pophive_check_source("new_source")
```

## Disclaimer

These data and PopHIVE statistical outputs are provided "as is", without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose, and noninfringement. In no event shall the authors, contributors, or copyright holders be liable for any claim, damages, or other liability, whether in an action of contract, tort, or otherwise, arising from, out of, or in connection with the data or the use or other dealings in the data.

The PopHIVE statistical outputs are research tools intended for use in the fields of public health and medicine. They are not intended for clinical decision making, are not intended to be used in the diagnosis or treatment of patients and may not be useful or appropriate for any clinical purpose. Users of the PopHIVE statistical outputs should be aware of their responsibilities to ensure the ethical and appropriate use of this technology, including adherence to any applicable legal and regulatory requirements.

The content and data provided with the statistical outputs do not replace the expertise of healthcare professionals. Healthcare professionals should use their professional judgment in evaluating the outputs of the PopHIVE statistical outputs.
