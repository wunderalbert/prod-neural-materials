"""
regression.py

Fit regression models to the data.
"""
from math import sqrt
import numpy as np
import pathlib
import pandas as pd
import statsmodels.api as sm
import warnings
from sklearn.feature_selection import f_regression, r_regression
from sklearn.preprocessing import StandardScaler
from statsmodels.miscmodels.ordinal_model import OrderedModel
from statsmodels.tools.sm_exceptions import ConvergenceWarning, IterationLimitWarning
from process_data import run_pca
from variables import independent_vars, dependent_vars, demographics_dummies, demographics_ordinal, telemetry_name_mapping

warnings.simplefilter('ignore', ConvergenceWarning)
warnings.simplefilter('ignore', IterationLimitWarning)


def get_dummies(df, covariates):
    """Get dummy variable names for the specified variables, dropping zero-variance values."""
    columns = [col for col in df.columns for var in covariates if var in col]
    std = df[columns].std()
    non_constant = std[std > 0].index
    return list(non_constant)


def process_features_targets(df, independent_vars, dependent_vars, dummies, standardize=True, drop_na=True):
    # Get dummy variable names for categorical covariates, dropping zero-variance values.
    all_dummies = get_dummies(df, dummies)

    # Drop rows with missing values.
    if drop_na:
        df = df[independent_vars + dependent_vars + all_dummies].dropna()

    outcomes = df[dependent_vars].to_numpy()
    features = df[independent_vars].to_numpy()

    # Standardize features if specified to zero mean and unit variance.
    if standardize:
        scaler = StandardScaler()
        features = scaler.fit_transform(features)

    # Sanity check on scaled features
    non_na_features = ~np.isnan(features)
    assert np.allclose(np.mean(features[non_na_features], axis=0), [0])
    assert np.allclose(np.std(features[non_na_features], axis=0), [1])

    # Features are our behavioral metrics from telemetry data and user demographics.
    features = np.concatenate([features, df[all_dummies].to_numpy()], axis=1)

    return features, outcomes, all_dummies


def f_stat_regression(df, independent_vars, dependent_vars, standardize=True):
    """F-regression for the impact of a single variable."""
    results = {'independent': [], 'dependent': [], 'n': [], 'corr_coef': [], 'corr_f_stat': [], 'corr_p_value': []}
    for outcome in dependent_vars:
        for predictor in independent_vars:  # Extra loop to only drop missing values pairwise rather than across all
            features, outcomes, _ = process_features_targets(df, [outcome], [predictor], [], standardize)
            regression = f_regression(
                X=features,
                y=outcomes[:, 0])
            corrs = r_regression(
                X=features,
                y=outcomes[:, 0])
            results['independent'] += [predictor]
            results['dependent'] += [outcome]
            results['n'] += [features.shape[0]]
            results['corr_coef'] += corrs.tolist()
            results['corr_f_stat'] += regression[0].tolist()
            results['corr_p_value'] += regression[1].tolist()
    return pd.DataFrame(results).round(4)


def multiple_regression_single_pred(model_type, df, independent_vars, controls, dependent_vars, dummies, standardize=True, verbose=True):
    """OLS linear regression or ordinal regression for multivariate models."""
    # Features are our behavioral metrics from telemetry data and user demographics.
    # Outcomes are self-reported measures of user productivity.
    features, outcomes, all_dummies = process_features_targets(df, independent_vars + controls, dependent_vars, dummies, standardize)
    features, controls_dummies = features[:, :len(independent_vars)], features[:, len(independent_vars):]

    results = {'independent': [], 'dependent': [], f'{model_type}_coefficient': [], f'{model_type}_t_p-value': []}
    if model_type == 'ols':
        features = sm.add_constant(features)
        controls_dummies_baseline = sm.add_constant(controls_dummies)
        results['ols_model_rsquared'] = []
        results['ols_model_rsquared_adj'] = []
        model = sm.OLS
    elif model_type == 'logit':
        features = sm.add_constant(features)
        controls_dummies_baseline = sm.add_constant(controls_dummies)
        results['logit_pseudo_rsquared'] = []
        model = sm.Logit
    elif model_type == 'ordinal':
        results['ordinal_model_log_likelihood'] = []
        model = OrderedModel
    else:
        raise ValueError('Model type must be either "ols" or "ordinal" or "logit".')

    print(f'Running {model_type} regression on {features.shape[0]} samples.')
    # Fit regression model for each dependent variable.
    for i, outcome in enumerate(dependent_vars):
        # Fit the base model with controls only.
        try:
            regression = model(outcomes[:, i], controls_dummies_baseline).fit(disp=0)
            results['independent'] += controls + all_dummies
            results['dependent'] += [outcome] * controls_dummies.shape[1]
            if model_type == 'ols':
                results['ols_model_rsquared'] += [regression.rsquared] * controls_dummies.shape[1]
                results['ols_model_rsquared_adj'] += [regression.rsquared_adj] * controls_dummies.shape[1]
                results[f'{model_type}_coefficient'] += regression.params[1:].tolist()  # Drop intercept coefficient.
                results[f'{model_type}_t_p-value'] += regression.pvalues[1:].tolist()  # Drop intercept coefficient.
            elif model_type == 'logit':
                results['logit_pseudo_rsquared'] += [regression.prsquared] * controls_dummies.shape[1]
                results[f'{model_type}_coefficient'] += regression.params[1:].tolist()  # Drop intercept coefficient.
                results[f'{model_type}_t_p-value'] += regression.pvalues[1:].tolist()  # Drop intercept coefficient.
            else:
                results['ordinal_model_log_likelihood'] += [regression.llf] * controls_dummies.shape[1]
                results[f'{model_type}_coefficient'] += regression.params[:-4].tolist()
                results[f'{model_type}_t_p-value'] += regression.pvalues[:-4].tolist()
        except Exception:
            print('Failed to fit baseline model for', outcome)
                
        # Fit a model with all demographics and controls plus each predictor.
        for j, predictor in enumerate(independent_vars):
            try:
                regression = model(
                    outcomes[:, i], 
                    np.concatenate([
                        features[:, 0][:, None],
                        features[:, j + 1][:, None],
                        controls_dummies
                    ], axis=1)).fit(disp=0)
            except Exception:
                print('Failed to fit predictor model for', outcome)
                continue
            if verbose:
                print(f'{outcome}:\n{regression.summary()}')

            # Add results to full results dictionary.
            results['independent'] += [predictor]
            results['dependent'] += [outcome]
            if model_type == 'ols':
                results['ols_model_rsquared'] += [regression.rsquared]
                results['ols_model_rsquared_adj'] += [regression.rsquared_adj]
                results[f'{model_type}_coefficient'] += [regression.params[1]]  # Drop intercept coefficient.
                results[f'{model_type}_t_p-value'] += [regression.pvalues[1]]  # Drop intercept coefficient.
            elif model_type == 'logit':
                results['logit_pseudo_rsquared'] += [regression.prsquared]
                results[f'{model_type}_coefficient'] += [regression.params[1]]  # Drop intercept coefficient.
                results[f'{model_type}_t_p-value'] += [regression.pvalues[1]]  # Drop intercept coefficient.
            else:
                results['ordinal_model_log_likelihood'] += [regression.llf]
                results[f'{model_type}_coefficient'] += [regression.params[0]]
                results[f'{model_type}_t_p-value'] += [regression.pvalues[0]]
    return pd.DataFrame(results).round(4).sort_values(by='independent')


def multiple_regression(model_type, df, independent_vars, controls, dependent_vars, dummies, standardize=True, verbose=True):
    """OLS linear regression or ordinal regression for multivariate models."""
    # Features are our behavioral metrics from telemetry data and user demographics.
    # Outcomes are self-reported measures of user productivity.
    features, outcomes, all_dummies = process_features_targets(df, independent_vars + controls, dependent_vars, dummies, standardize)

    results = {'independent': [], 'dependent': [], f'{model_type}_coefficient': [], f'{model_type}_t_p-value': []}
    if model_type == 'ols':
        features = sm.add_constant(features)
        results['ols_model_rsquared'] = []
        results['ols_model_rsquared_adj'] = []
        n_features = features.shape[1] - 1
    elif model_type == 'logit':
        features = sm.add_constant(features)
        results['logit_pseudo_rsquared'] = []
        n_features = features.shape[1] - 1
    elif model_type == 'ordinal':
        results['ordinal_model_log_likelihood'] = []
        n_features = features.shape[1]
    else:
        raise ValueError('Model type must be either "ols" or "ordinal" or "logit".')

    print(f'Running {model_type} regression on {features.shape[0]} samples.')
    # Fit regression model for each dependent variable.
    for i, outcome in enumerate(dependent_vars):
        try:
            if model_type == 'ols':
                regression = sm.OLS(outcomes[:, i], features).fit()
            elif model_type == 'ordinal':
                regression = OrderedModel(outcomes[:, i], features).fit()
            elif model_type == 'logit':
                regression = sm.Logit(outcomes[:, i], features).fit()
        except Exception:
            print('Failed to fit model for', outcome)
        if verbose:
            print(f'{outcome}:\n{regression.summary()}')

        # Add results to full results dictionary.
        results['independent'] += independent_vars + controls + all_dummies
        results['dependent'] += [outcome] * n_features
        if model_type == 'ols':
            results['ols_model_rsquared'] += [regression.rsquared] * n_features
            results['ols_model_rsquared_adj'] += [regression.rsquared_adj] * n_features
            results[f'{model_type}_coefficient'] += regression.params[1:].tolist()  # Drop intercept coefficient.
            results[f'{model_type}_t_p-value'] += regression.pvalues[1:].tolist()  # Drop intercept coefficient.
        elif model_type == 'logit':
            results['logit_pseudo_rsquared'] += [regression.prsquared] * n_features
            results[f'{model_type}_coefficient'] += regression.params[1:].tolist()  # Drop intercept coefficient.
            results[f'{model_type}_t_p-value'] += regression.pvalues[1:].tolist()  # Drop intercept coefficient.
        else:
            results['ordinal_model_log_likelihood'] += [regression.llf] * n_features
            results[f'{model_type}_coefficient'] += regression.params[:-4].tolist()
            results[f'{model_type}_t_p-value'] += regression.pvalues[:-4].tolist()

    return pd.DataFrame(results).round(4).sort_values(by='independent')


def ols_pca(df, independent_vars, dependent_vars, dummies, explained_variance=0.95, verbose=True):
    all_dummies = get_dummies(df, dummies)
    df = df[independent_vars + dependent_vars + all_dummies].dropna()

    # Select k features with PCA that explains at least the specified percent of variance.
    transformed_features, components, n_components = run_pca(
        df,
        independent_vars,
        standardize=True,
        explained_variance=explained_variance)
    transformed_features = np.concatenate([transformed_features, df[all_dummies].to_numpy()], axis=1)
    transformed_features = sm.add_constant(transformed_features)

    print(f'Running OLS regression with PCA features on {transformed_features.shape[0]} samples.')
    # Fit linear regression for each dependent variable using the PCA features.
    outcomes = df[dependent_vars].to_numpy()
    results = {'component': [], 'dependent': [], 'coefficient': [], 't_p-value': [], 'model_rsquared_adj': []}
    for i, outcome in enumerate(dependent_vars):
        model = sm.OLS(outcomes[:, i], transformed_features)
        regression = model.fit()

        if verbose:
            print(f'{outcome}:\n{regression.summary()}')

        # Add results to full results dictionary.
        results['component'] += [f'component-{i}' for i in range(n_components)] + all_dummies
        results['dependent'] += [outcome] * (n_components + len(all_dummies))
        results['coefficient'] += regression.params[1:].tolist()
        results['t_p-value'] += regression.pvalues[1:].tolist()
        results['model_rsquared_adj'] += [regression.rsquared_adj] * (n_components + len(all_dummies))

    return pd.DataFrame(results).round(4).sort_values(by='component'), components


def rsquared_contribution(full_rsquared, df, independent_vars, dependent_vars, dummies, standardize=True, verbose=True):
    """Calculate the decrease in Rsquared for each independent variable when removed from model."""
    features, outcomes, all_dummies = process_features_targets(df, independent_vars, dependent_vars, dummies, standardize)

    results = {'independent': [], 'dependent': [], 'adj_rsquared_without': [], 'rsquared_without': []}
    features = sm.add_constant(features)

    # Fit regression model for each dependent variable without each independent variable and with only each independent variable.
    for i, outcome in enumerate(dependent_vars):
        for j, regressor in enumerate(independent_vars):
            features_dropped = np.delete(features, j + 1, axis=1)
            regression = sm.OLS(outcomes[:, i], features_dropped).fit()

            # Add results to full results dictionary.
            results['independent'].append(regressor)
            results['dependent'].append(outcome)
            results['adj_rsquared_without'].append(regression.rsquared_adj)
            results['rsquared_without'].append(regression.rsquared)

    results = pd.DataFrame(results).round(4)
    results = pd.merge(results, full_rsquared, on=['dependent'], how='left')
    results['rsquared_contribution'] = results['ols_model_rsquared'] - results['rsquared_without']
    results['rsquared_contribution_pct'] = results['rsquared_contribution'] / results['ols_model_rsquared']
    results['adj_rsquared_contribution'] = results['ols_model_rsquared_adj'] - results['adj_rsquared_without']
    results['adj_rsquared_contribution_pct'] = results['adj_rsquared_contribution'] / results['ols_model_rsquared_adj']

    return pd.DataFrame(results).round(4).sort_values(by=['dependent', 'rsquared_contribution_pct'], ascending=False)


def residual_significance(df, independent_vars, controls, dependent_var, dummies, levels=4):
    """Calculate the p-value for each residual for each independent variable."""
    results = {'n_predictors': [], 'baseline': [], 'independent': [], 'dependent': [], 'coefficient': [], 'p-value': [], 'ssr': []}
    features, outcomes, all_dummies = process_features_targets(df, independent_vars + controls, [dependent_var], dummies)

    # Breadth first search where for every independent variable, try fitting its residual to all not-yet-modeled independent variables.
    search_frontier = [([], outcomes, v, i) for i, v in enumerate(independent_vars)]
    # Note: Not checking for visited paths because it turns out the order of the path does matter.

    while search_frontier:
        predictors, residuals, candidate, i = search_frontier.pop()
        candidate_features = sm.add_constant(features[:, i][:, None])
        regression = sm.OLS(residuals, candidate_features).fit()
        new_residuals = regression.resid
        correlation = r_regression(
                X=outcomes,
                y=regression.fittedvalues)
        
        print(f"candidate {candidate} from predictors {predictors}")

        print(f"  correlation outcomes with fitted values: {correlation}")
        
        # print variation in outcomes:
        print(f"  maximal var in data: {np.var(outcomes) * len(outcomes)}")
        print(f"  var remaining {regression.ssr}")
        print(f"'  cor' coeff: {sqrt(1 - regression.ssr / np.var(outcomes) / len(outcomes))}")

        #print(f"predictors: {predictors}")
        #print(f"residuals: {residuals}")
        #print(f"regression: {regression}")
        #print(f"target: {outcomes}")
        #print(f"regression params: {regression.params}")
        #print(f"new_residuals: {new_residuals}")
        #assert False

        # Add results to full results dictionary.
        results['baseline'].append(predictors)
        results['independent'].append(candidate)
        results['dependent'].append(dependent_var)
        results['coefficient'].append(correlation[0])
        results['p-value'].append(regression.pvalues[1])
        results['ssr'].append(regression.ssr)
        results['n_predictors'].append(len(predictors) + 1)

        if len(predictors) < levels:
            updated_predictors = predictors + [candidate]
            remaining_candidates = [(i, cand) for i, cand in enumerate(independent_vars) if cand not in updated_predictors]
            for new_candidate in remaining_candidates:
                search_frontier.append((updated_predictors, new_residuals, new_candidate[1], new_candidate[0]))

    return pd.DataFrame(results).round(4).sort_values(by=['n_predictors', 'ssr'], ascending=True)


if __name__ == '__main__':
    df = pd.read_csv(pathlib.Path(__file__).parent.parent.resolve() / 'data_telemetry/survey_telemetry_merged_cleaned.csv').rename(columns=telemetry_name_mapping)
    # F-regression for single variable
    f_regression_results = f_stat_regression(df, independent_vars + demographics_ordinal, dependent_vars, demographics_dummies)

    # Multivariate linear regression
    ols_regression_results = multiple_regression('ols', df, independent_vars + demographics_ordinal, dependent_vars, demographics_dummies, verbose=False)
    # ordinal_dependents = dependent_vars
    # ordinal_dependents.remove('aggregate_productivity')
    # ordinal_regression_results = multiple_regression('ordinal', df, independent_vars + demographics_ordinal, ordinal_dependents, demographics_dummies, verbose=True)

    # Combine results and write out to CSV
    merged = pd.merge(f_regression_results, ols_regression_results, on=['independent', 'dependent'], how='outer')
    # merged = pd.merge(merged, ordinal_regression_results, on=['independent', 'dependent'], how='outer')
    merged.sort_values(by='independent').to_csv('outputs/analysis/regression_results.csv', index=False)

    # Print statistically significant results
    print(merged[merged['ols_t_p-value'] < 0.05])
    print(merged[['dependent', 'ols_model_rsquared_adj']].drop_duplicates().sort_values(by='ols_model_rsquared_adj', ascending=False))

    # # Multivariate linear regression with PCA
    # ols_pca_results, components = ols_pca(df, independent_vars + demographics_ordinal, dependent_vars, demographics_dummies, verbose=False)
    # components.to_csv('outputs/analysis/principal_components.csv')
    # print(ols_pca_results[ols_pca_results['t_p-value'] < 0.05])
    # print(ols_pca_results[['dependent', 'model_rsquared_adj']].drop_duplicates().sort_values(by='model_rsquared_adj', ascending=False))
    # print(components.T)
