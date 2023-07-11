"""
variables.py

Describes key variables in our dataset including independent, dependent, and demographic covariates.
Our independent variables are telemetry metrics and our dependent variables are survey responses.
We are seeking to understand what behaviors correlate with and explain subjective assessments
of how useful synthesized code is to developers using Copilot.
"""

telemetry_name_mapping = {
    "n_issued": "opportunity",
    "n_shown": "shown",
    "n_acc": "accepted",
    "n_unchanged_30_s": "unchanged_30",
    "n_unchanged_120_s": "unchanged_120",
    "n_unchanged_300_s": "unchanged_300",
    "n_unchanged_600_s": "unchanged_600",
    "n_substantially_changed_30_s": "substantially_changed_30",
    "n_substantially_changed_120_s": "substantially_changed_120",
    "n_substantially_changed_300_s": "substantially_changed_300",
    "n_substantially_changed_600_s": "substantially_changed_600",
    "n_py": "py",
    "n_js": "js",
    "n_ts": "ts",
    "sum_char": "accepted_char",
    "n_partial_hours": "active_hour",
}

telemetry_vars = [
    'n_issued'
    'n_shown',
    'n_acc',
    'n_unchanged_30_s',
    'n_unchanged_120_s',
    'n_unchanged_300_s',
    'n_unchanged_600_s',
    'n_substantially_changed_30_s',
    'n_substantially_changed_120_s',
    'n_substantially_changed_300_s',
    'n_substantially_changed_600_s',
    'n_py',
    'n_js',
    'n_ts',
    'sum_char',
    'median_char_len_acc'
    'n_partial_hours'
]

independent_vars = ['opportunity', 
                    'shown', 
                    'accepted',
                    'unchanged_30', 
                    'unchanged_120', 
                    'unchanged_300', 
                    'unchanged_600',
                    'accepted_char', 
                    'active_hour', 
                    'mostly_unchanged_30',
                    'mostly_unchanged_120', 
                    'mostly_unchanged_300', 
                    'mostly_unchanged_600',
                    'opportunity_per_active_hour', 
                    'shown_per_active_hour',
                    'accepted_per_active_hour',
                    'shown_per_opportunity', 
                    'accepted_per_opportunity', 
                    'accepted_per_shown',
                    'accepted_char_per_active_hour', 
                    'accepted_char_per_opportunity',
                    'accepted_char_per_shown', 
                    'accepted_char_per_accepted',
                    'mostly_unchanged_30_per_active_hour',
                    'mostly_unchanged_30_per_opportunity', 
                    'mostly_unchanged_30_per_shown',
                    'mostly_unchanged_30_per_accepted',
                    'mostly_unchanged_120_per_active_hour',
                    'mostly_unchanged_120_per_opportunity',
                    'mostly_unchanged_120_per_shown', 
                    'mostly_unchanged_120_per_accepted',
                    'mostly_unchanged_300_per_active_hour',
                    'mostly_unchanged_300_per_opportunity',
                    'mostly_unchanged_300_per_shown', 
                    'mostly_unchanged_300_per_accepted',
                    'mostly_unchanged_600_per_active_hour',
                    'mostly_unchanged_600_per_opportunity',
                    'mostly_unchanged_600_per_shown', 
                    'mostly_unchanged_600_per_accepted',
                    'unchanged_30_per_active_hour', 
                    'unchanged_30_per_opportunity',
                    'unchanged_30_per_shown', 
                    'unchanged_30_per_accepted',
                    'unchanged_120_per_active_hour', 
                    'unchanged_120_per_opportunity',
                    'unchanged_120_per_shown', 
                    'unchanged_120_per_accepted',
                    'unchanged_300_per_active_hour', 
                    'unchanged_300_per_opportunity',
                    'unchanged_300_per_shown', 
                    'unchanged_300_per_accepted',
                    'unchanged_600_per_active_hour', 
                    'unchanged_600_per_opportunity',
                    'unchanged_600_per_shown', 
                    'unchanged_600_per_accepted']

demographics_dummies = [
    'Which of the following best describes what you do?',
    'What programming languages do you usually use? Choose up to three from the list',
]

demographics_ordinal_mapping = {
    'language_proficiency': 'Think of the language you have used the most with Copilot. How proficient are you in that language?',
    'programming_experience': 'Which best describes your programming experience?',
}

demographics_ordinal = list(demographics_ordinal_mapping.keys())

dependent_mapping = {
    'more_productive': 'I am more productive when using Copilot',
    'stay_in_flow': 'Using Copilot helps me stay in the flow',
    'tasks_faster': 'I complete tasks faster when using Copilot',
    'repetitive_faster': 'I complete repetitive programming tasks faster when using Copilot',
    'unfamiliar_progress': 'While working with an unfamiliar language, I make progress faster when using Copilot',
    'more_fulfilled': 'I feel more fulfilled with my job when using Copilot',
    'focus_satisfying': 'I can focus on more satisfying work when using Copilot',
    'less_effort_repetitive': 'I spend less mental effort on repetitive programming tasks when using Copilot',
    'learn_from': 'I learn from the suggestions Copilot shows me',
    'less_frustrated': 'I find myself less frustrated during coding sessions when using Copilot',
    'less_time_searching': 'I spend less time searching for information or examples when using Copilot',
    'better_code': 'The code I write using Copilot is better than the code I would have written without Copilot'
}

dependent_vars = list(dependent_mapping.keys()) + ['aggregate_productivity']
