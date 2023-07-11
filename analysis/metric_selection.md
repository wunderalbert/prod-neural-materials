# Metric Selection

The core metric selection script is in `analysis/metric_selection.py`. It runs the following analyses with the following outputs. All corresponding stats reported in the paper are generated from this script or can be derived using the dataset(s) produced. The only metric selection analysis not included is the PLS regression from @wunderalbert which will be checked in separately as an R script.

## Data Inputs

The core data processing function is `analysis.process_data.process_data()`. It takes in the following files to produce `data_telemetry/survey_telemetry_merged_cleaned.csv` containing merged survey and telemetry variables.
* [`data_telemetry/merged-case-insensitive.tsv`](https://github.com/github/copilot-metrics-paper/blob/main/data_telemetry/merged-case-insensitive.tsv)
* [`summary_by_id.csv`](https://github.com/github/copilot-metrics-paper/blob/main/data_telemetry/summary_by_id.csv) from `data_telemetry/summary_by_id.kql`

All key variables are defined in `analysis/variables.py`:
* `independent_vars` = Behavioral metrics from telemetry data we're evaluating
* `dependent_vars` = Survey outcomes we're trying to predict with `independent_vars`. The raw survey data has one-hot encoded text headings. `dependent_mapping` contains a mapping of the combined variable we want to create during data processing and the survey text to search for in column names.

To add an additional metric to test or outcome to predict, you can generally add it to either list in `analysis/variables.py`.

New survey variables are generally created in `analysis.process_data.combine_survey_vars()`. New telemetry variables are generally created in `analysis.process_data.normalize_vars()`. 

## Correlations

The correlation analysis is performed in `regression.f_stat_regression()`. This produces Pearson's R correlation coefficients and their p-values using `sklearn.feature_selection.r_regression` and `sklearn.feature_selection.f_regression()` respectively. 

## Incremental Feature Selection

The incremental feature selection analysis is performed in `regression.residual_significance()`. This builds a tree via breadth first search where each node represents a behavioral (telemetry) metric fit in a univariate linear regression to the residual of a univariate linear regression with the variable in its parent node. For example, at the first level, all 25 `independent_vars` are each fit in one linear regression to the target outcome of `aggregate_productivity` for a total of 25 nodes each representing one model. Taking the `node_level_1_pct_acc` node as example, we get the residuals of the model using `pct_acc` to predict `aggregate_productivity` and denote it as `residuals_pct_acc`. We then fit the remaining 24 `independent_vars` each in one linear regression predicting `residuals_pct_acc`, yielding 24 child nodes for `node_level_1_pct_acc`. We repeat this process for a specified number of levels. 

This allows us to evaluate the statistical significance of how well one metric incrementally predicts our target outcome, given models fit with other metrics (or by itself in the root level case). In the paper we visualize `pct_acc` at the root level and all its statistically significant children.

## Descriptive Stats

All general descriptive stats in the Data and Methodology section are derived from `data_telemetry/survey_telemetry_merged_cleaned.csv`.
