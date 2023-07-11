"""
correlation.py

Compute the correlation between pairs of variables.
"""
import numpy as np
import pathlib
import pandas as pd
from variables import independent_vars, dependent_vars, demographics_ordinal, demographics_dummies, telemetry_name_mapping


def compute_correlations(df, vars_x, vars_y, tril=False, drop_na=False):
    """
    Computes the correlation between two matrices of variables.
    """
    # If True this is a more aggressive drop keeping only samples with all variables present
    # If False, should will drop samples only in pairwise fashion
    # This function is deprecated in the main analysis for regression.f_stat_regression
    # It could still be useful to get a table view rather than a long view
    if drop_na:
        vars_df = df[vars_x + vars_y].dropna()
    else:
        vars_df = df[vars_x + vars_y]
    corr_matrix = vars_df.corr()
    if tril:
        corr_matrix = corr_matrix.loc[vars_x][vars_y]
    return corr_matrix


if __name__ == '__main__':
    df = pd.read_csv(pathlib.Path(__file__).parent.parent.resolve() / 'data_telemetry/survey_telemetry_merged_cleaned.csv').rename(columns=telemetry_name_mapping)
    all_dummies = [col for col in df.columns for var in demographics_dummies if var in col]
    correlations = compute_correlations(df, independent_vars + demographics_ordinal + all_dummies, dependent_vars)
    correlations.to_csv('outputs/analysis/correlations.csv')
    print(correlations)
