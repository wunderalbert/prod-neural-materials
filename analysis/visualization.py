import pandas as pd
from pyvis.network import Network


def visualize_incremental_graph(results_file, output_file, max_levels=2, max_children_per_node=None, root=None):
    """
    Reads in the output of regression.residual_significance to construct a graph visualization
    of the relationship between each incremental predictor.
    """
    results_df = pd.read_csv(results_file)
    results_df['label'] = (
        results_df['independent']
        + '\np-value = '
        + results_df['p-value'].round(2).astype('str')
        + '\ncoef = '
        + results_df['coefficient'].round(2).astype('str')
        + '\nssr = '
        + results_df['ssr'].round(2).astype('str'))
    results_df['id'] = results_df.index
    results_df['parent_id'] = None

    g = Network(layout='hierarchical', height=1200, width=1800, directed=True)

    top_nodes = results_df[results_df['n_predictors'] == 1].sort_values(by='ssr')
    if root is None:
        if max_children_per_node is not None:
            top_nodes = top_nodes.head(max_children_per_node)
    else:
        top_nodes = top_nodes[top_nodes['independent'] == root]
    to_add = top_nodes.to_dict(orient="records")
    while to_add:
        node = to_add.pop()
        g.add_node(node['id'], label=node['label'])
        if node['parent_id'] is not None:
            g.add_edge(node['parent_id'], node['id'])
        if node['n_predictors'] < max_levels:
            if node['baseline'] == '[]':
                children = results_df[results_df['baseline'] == node['baseline'].replace(
                    ']', f"'{node['independent']}']")].sort_values(by='ssr')
            else:
                children = results_df[results_df['baseline'] == node['baseline'].replace(
                    ']', f", '{node['independent']}']")].sort_values(by='ssr')
            if max_children_per_node:
                children = children.head(max_children_per_node)
            else:
                children = children[children['p-value'] < 0.05]
            children['parent_id'] = node['id']
            to_add += children.to_dict(orient="records")

    g.show(output_file)


if __name__ == '__main__':
    from variables import demographics_ordinal, demographics_dummies

    visualize_incremental_graph(
        'outputs/analysis/residual_significance.csv', 
        'outputs/visualizations/incremental_graph.html',
        max_levels=3,
        root='pct_acc')

    # df = pd.read_csv('data_telemetry/survey_telemetry_merged_cleaned.csv')
    # for var in demographics_ordinal:
    #     print(df[var].value_counts().sort_index())
    #     print(df[var].value_counts(normalize=True).sort_index())

    # all_dummies = [col for col in df.columns for var in demographics_dummies if var in col]
    # for var in all_dummies:
    #     print(df[var].value_counts().sort_index(), df[var].mean())
