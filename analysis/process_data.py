"""
process_data.py

Cleans and processes input data for analysis.
Optionally generate visualizations for descriptive stats. 
"""
import numpy as np
import pandas as pd
import pathlib
from sklearn.decomposition import PCA
from sklearn.impute import SimpleImputer
from sklearn.preprocessing import StandardScaler

from variables import independent_vars, dependent_vars, dependent_mapping, demographics_dummies, demographics_ordinal_mapping, telemetry_name_mapping


def process_data(survey_input,
                 telemetry_input,
                 output_file,
                 deduplication_column,
                 impute=True,
                 pca=True):
    """
    Process input data, merging survey and telemtry files.

    :param survey_input: Path to survey file.
    :param telemetry_input: Path to telemetry file.
    :param output_file: Path to file to write cleaned data to.
    :param impute: If True, impute missing values for independent and dependent vars.
    """
    survey_df = process_survey(survey_input, deduplication_column, impute=impute, pca=pca)
    telemetry_df = process_telemetry(telemetry_input)

    # Merge survey and telemetry data
    merged_df = pd.merge(survey_df, telemetry_df, on='copilot_trackingId')

    # Keep only variables used in analysis, i.e. those specified in variables.py
    all_dummies = [col for col in merged_df.columns for var in demographics_dummies if var in col]
    all_cols_keep = ['copilot_trackingId'] + independent_vars + dependent_vars + [f'{v}_bool' for v in dependent_vars if 'aggregate' not in v] + all_dummies + list(demographics_ordinal_mapping.keys())
    if pca:
        all_cols_keep += ['pca_survey_first_component']
    if impute:
        all_cols_keep += [f'{v}_imp_neutral' for v in dependent_vars if 'aggregate' not in v]
        all_cols_keep += [f'{v}_imp_median' for v in dependent_vars if 'aggregate' not in v]

    merged_df[all_cols_keep].dropna(how='all').to_csv(output_file, index=False)

    return merged_df


def process_survey(input_file, deduplication_column, impute=True, pca=True):
    """
    Process survey data.

    :param input_file: Path to file containing raw data to read in.
    """
    # Top two rows of file have question and responses
    survey_df = pd.read_csv(input_file, sep='\t', header=[0, 1])

    # Process first two headers into a single column header and clean up excess text
    last_question = None
    new_cols = []
    for question, response in survey_df.columns:
        question = question.replace(
            'Thinking of your experience using Copilot so far, please indicate your level of agreement with the following statements.', '')
        if 'Unnamed:' not in question:
            last_question = question
        response = '' if 'Unnamed:' in response else response
        if last_question and response:
            new_col = f'{last_question}-{response}'
        elif last_question:
            new_col = last_question
        else:
            new_col = response
        new_cols.append(new_col)
    survey_df.columns = new_cols
    
    # Drop duplicates
    survey_df = survey_df.drop_duplicates()

    unskipped_columns = [col for col in survey_df if not col.endswith('N/A')]
    # how often do these hold a pd.notna string? write that to a new column
    survey_df['n_notna'] = survey_df[unskipped_columns].apply(lambda row: sum(pd.notna(row)), axis=1)
    survey_df = survey_df.sort_values(by='n_notna', ascending=False)
    survey_df = survey_df.drop_duplicates(subset=deduplication_column, keep='first')
    survey_df = survey_df.sort_values(by='Start Date', ascending=True)
    
    # Generate boolean dummies for demographic vars
    for covariate in demographics_dummies:
        for value in [c for c in new_cols if covariate in c]:
            survey_df[value] = survey_df[value].notnull().astype(int)

    # Combine single-choice questions currently dummy-coded into single column
    survey_df = combine_survey_vars(survey_df, impute=impute)

    # PCA on target variables
    if pca:
        pca_features, _, _ = run_pca(
            survey_df,
            [f'{k}_imp_neutral' for k in dependent_mapping.keys()],
            n_components=1)
        survey_df['pca_survey_first_component'] = pca_features[:, 0]

    return survey_df


def process_telemetry(input_file):
    """
    Process telemetry data.

    :param input_file: Path to file containing raw data to read in.
    """
    # Top two rows of file have question and responses
    telemetry_df = pd.read_csv(input_file).rename(columns=telemetry_name_mapping)

    # Compute normalized variables
    telemetry_df = normalize_vars(telemetry_df)

    return telemetry_df


def normalize_vars(df):

    # calculate mostly_unchanged_X measure
    for duration in [30,120,300,600]:
        df["mostly_unchanged_%s" % duration] = df["accepted"] - df["substantially_changed_%s" % duration]

    normalizing_events = ["active_hour",
              "opportunity", 
              "shown", 
              "accepted"]

    extra_events = ["accepted_char",
                    "mostly_unchanged_30", "mostly_unchanged_120", "mostly_unchanged_300", "mostly_unchanged_600",
                    "unchanged_30", "unchanged_120", "unchanged_300", "unchanged_600"]

    for (i,event) in enumerate(normalizing_events):
        for other_event in normalizing_events[0:i]:
            df["%s_per_%s" % (event, other_event)] = df[event] / df[other_event]
    
    for event in extra_events:
        for other_event in normalizing_events:
            df["%s_per_%s" % (event, other_event)] = df[event] / df[other_event]

    return df


def combine_likert(row):
    """
    Assuming each column in the row is single-choice value ordered from Strongly Agree to Strongly Disagree,
    converts to numeric value where Strongly Agree = 5 and Strongly Disagree = 1.
    """
    for i in range(5):
        if not pd.isnull(row.iloc[i]):
            return 5 - i


def combine_ordinal(row):
    """
    Assuming each of n columns in the row is single-choice value ordered from least to most,
    converts to numeric value from 1 to n.
    """
    for i, val in enumerate(row):
        if not pd.isnull(row.iloc[i]):
            return i + 1


def combine_bool(row):
    """
    Assuming each of n columns in the row is single-choice value ordered from least to most,
    converts to numeric value from 1 to n.
    """
    if pd.notnull(row.iloc[0]) or pd.notnull(row.iloc[1]):
        return 1
    elif pd.notnull(row.iloc[2]) or pd.notnull(row.iloc[3]) or pd.notnull(row.iloc[3]):
        return 0
    else:
        return None


def combine_survey_vars(df, likert_mapping=dependent_mapping, ordinal_mapping=demographics_ordinal_mapping, impute=True):
    # Combine Likert variables into single variable
    for var, text in likert_mapping.items():
        df[var] = df[[
            f'{text} - {val}'
            for val in ['Strongly Agree', 'Agree', 'Neither Agree or Disagree', 'Disagree', 'Strongly Disagree']
            ]].apply(
        lambda x: combine_likert(x), axis=1)
    if impute:
        imputer = SimpleImputer(missing_values=np.nan, strategy='median')
        median_imputed = imputer.fit_transform(df[list(likert_mapping.keys())].to_numpy())
        df[[f'{v}_imp_median' for v in likert_mapping.keys()]] = None  # Get a weird NotImplementedError without this
        df[[f'{v}_imp_median' for v in likert_mapping.keys()]] = median_imputed
        df[[f'{v}_imp_neutral' for v in likert_mapping.keys()]] = df[likert_mapping.keys()].fillna(3)
    df['aggregate_productivity'] = df[list(likert_mapping.keys())].mean(axis=1)

    # Create binary variables for Likert outcomes
    for var, text in likert_mapping.items():
        df[f'{var}_bool'] = df[[
            f'{text} - {val}'
            for val in ['Strongly Agree', 'Agree', 'Neither Agree or Disagree', 'Disagree', 'Strongly Disagree']
            ]].apply(
        lambda x: combine_bool(x), axis=1)

    # Combine values for ordinal demographic vars
    for var, text in ordinal_mapping.items():
        df[var] = df[[c for c in df.columns if text in c]].apply(
            lambda x: combine_ordinal(x), axis=1)

    return df


def run_pca(df, vars, n_components=None, standardize=True, explained_variance=0.95):
    """Select k features with PCA that explains at least the specified percent of variance."""
    df = df[vars].dropna()

    # Standardize features if specified to zero mean and unit variance.
    if standardize:
        features = df[vars].to_numpy()
        scaler = StandardScaler()
        features = scaler.fit_transform(features)
    pca_model = PCA(n_components=n_components)
    transformed_features = pca_model.fit_transform(features)

    # Create dataframe of principal components.
    components = pd.DataFrame(pca_model.components_, columns=vars)
    components['pct_explained_variance'] = pca_model.explained_variance_ratio_

    # Retain features explaining desired amount of explained variance.
    if n_components is None:
        cumulative_explained = components['pct_explained_variance'].cumsum()
        n_components = cumulative_explained[cumulative_explained.gt(explained_variance)].idxmin() + 1

    transformed_features = transformed_features[:, :n_components]

    return transformed_features, components.round(4).iloc[:n_components], n_components


if __name__ == '__main__':
    df = process_data(
        pathlib.Path(__file__).parent.parent.resolve() / 'data/merged-case-insensitive.tsv',
        pathlib.Path(__file__).parent.parent.resolve() / 'data_telemetry/summary_by_id.csv',
        pathlib.Path(__file__).parent.parent.resolve() / 'data_telemetry/survey_telemetry_merged_cleaned.csv',
        deduplication_column='What is your GitHub username?-Open-Ended Response')

    # Sanity checks on key variables
    print(df[independent_vars].describe().transpose())
    print(df[dependent_vars].describe().transpose())
    print(df[demographics_ordinal_mapping.keys()].describe().transpose())
