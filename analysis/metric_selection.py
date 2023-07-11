"""
metric_selection.py

Analyses for selecting behavioral metrics that most impact self-reported metrics.
"""
import pathlib
import pandas as pd

from process_data import process_data

from regression import f_stat_regression, multiple_regression, multiple_regression_single_pred, residual_significance
from variables import independent_vars, dependent_vars, demographics_dummies, demographics_ordinal_mapping

model_fns = {
    'vary_single_predictor': multiple_regression_single_pred,
    'model_all_predictors': multiple_regression
}


def main(data=True, correlation=True, regression=True, rsquared=True, model_type='model_all_predictors', residuals=True):
    parent_dir = pathlib.Path(__file__).parent.parent.resolve()

    if data:
        df = process_data(
            parent_dir / 'data_telemetry/merged-case-insensitive.tsv',
            parent_dir / 'data_telemetry/summary_by_id.csv',
            parent_dir / 'data_telemetry/survey_telemetry_merged_cleaned.csv',
        deduplication_column='What is your GitHub username?-Open-Ended Response')
    else:
        df = pd.read_csv(parent_dir / 'data_telemetry/survey_telemetry_merged_cleaned.csv').rename(columns=telemetry_name_mapping)
    all_dummies = [col for col in df.columns for var in demographics_dummies if var in col]

    # Sanity checks on key variables
    df[independent_vars].describe().transpose().to_csv(parent_dir / 'outputs/analysis/descriptive_stats_independent.csv')
    df[dependent_vars + [f'{d}_bool' for d in dependent_vars if 'aggregate' not in d]].describe().transpose().to_csv(parent_dir / 'outputs/analysis/descriptive_stats_dependent.csv')
    df[list(demographics_ordinal_mapping.keys()) + all_dummies].describe().transpose().to_csv(parent_dir / 'outputs/analysis/descriptive_stats_demographics.csv')

    if correlation:        
        # F-regression for single variable (i.e. the significance of the correlation coefficient)
        f_regression_results = f_stat_regression(df, independent_vars, dependent_vars)
        f_regression_results.sort_values(by='independent').to_csv(parent_dir / 'outputs/analysis/correlations_with_pvalues.csv', index=False)

    if residuals:
        # Incrementally fit new univariate regressions to the residual
        # Just use the 30-second versions of all the unchanged variables
        independent_vars_subset = [v for v in independent_vars if ('unchanged' not in v) or ('unchanged' in v and '30_' in v)]
        independent_vars_subset = ["accepted_per_shown", "accepted_per_opportunity", "accepted_char_per_active_hour"]
        #independent_vars_subset = ["accepted_per_shown"]
        # ['opportunity', 'shown', 'accepted', 'accepted_char', 'active_hour', 'opportunity_per_active_hour', 'shown_per_active_hour', 'accepted_per_active_hour', 'shown_per_opportunity', 'accepted_per_opportunity', 'accepted_per_shown', 'accepted_char_per_active_hour', 'accepted_char_per_opportunity', 'accepted_char_per_shown', 'accepted_char_per_accepted', 'mostly_unchanged_30_per_active_hour', 'mostly_unchanged_30_per_opportunity', 'mostly_unchanged_30_per_shown', 'mostly_unchanged_30_per_accepted', 'unchanged_30_per_active_hour', 'unchanged_30_per_opportunity', 'unchanged_30_per_shown', 'unchanged_30_per_accepted']
        residuals_analysis = residual_significance(df, independent_vars_subset, [], 'aggregate_productivity', [])
        residuals_analysis.to_csv(parent_dir / 'outputs/analysis/residual_significance.csv')


if __name__ == '__main__':
    main()
