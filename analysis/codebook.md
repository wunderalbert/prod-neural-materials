# Codebook

This file contains descriptions of key variables used in analysis and shared in our dataset.

## Telemetry

The following variables are derived from telemetry events in Copilot.

* `n_shown`: Number of synthesized completions from Copilot shown to the user in the specified time period.
* `n_acc`: Number of synthesized completions from Copilot accepted by the user in the specified time period.
* `n_unchanged_30_s`: Number of accepted completions from Copilot in the specified time period that remained unchanged 30 seconds after acceptance.
* `n_unchanged_120_s`: Number of accepted completions from Copilot in the specified time period that remained unchanged 120 seconds after acceptance.
* `n_unchanged_300_s`: Number of accepted completions from Copilot in the specified time period that remained unchanged 300 seconds after acceptance.
* `n_unchanged_600_s`: Number of accepted completions from Copilot in the specified time period that remained unchanged 600 seconds after acceptance.
* `n_py`: Number of synthesized Python completions from Copilot shown to the user in the specified time period.
* `n_js`: Number of synthesized JavaScript completions from Copilot shown to the user in the specified time period.
* `n_ts`: Number of synthesized TypeScript completions from Copilot shown to the user in the specified time period.
* `sum_char`: Number of total characters from synthesized completions accepted by the user in the specified time period.
* `n_partial_hours`: Count of distinct hours in which the user was shown a synthesized completion in the specified time period.
* `pct_unchanged_30_s`: Percent of accepted completions unchanged after 30 seconds.
* `pct_unchanged_120_s`: Percent of accepted completions unchanged after 120 seconds.
* `pct_unchanged_300_s`: Percent of accepted completions unchanged after 300 seconds.
* `pct_unchanged_600_s`: Percent of accepted completions unchanged after 600 seconds.
* `n_acc_per_hour`: Number of accepted completions divided by number of active distinct hours.
* `n_char_per_hour`: Number of accepted characters in completions divided by number of active distinct hours.

## Survey

The following variables are derived from user survey responses.

* `copilot_productivity`: Agreement (1 = Strongly Disagree, 5 = Strongly Agree) for the statement "I am more productive when using Copilot."
* `copilot_useful`: Agreement (1 = Strongly Disagree, 5 = Strongly Agree) for the statement "Copilot is useful."
* `stay_in_flow`: Agreement (1 = Strongly Disagree, 5 = Strongly Agree) for the statement "Using Copilot helps me stay in the flow."
* `tasks_faster`: Agreement (1 = Strongly Disagree, 5 = Strongly Agree) for the statement "I complete tasks faster when using Copilot."
* `repetitive_faster`: Agreement (1 = Strongly Disagree, 5 = Strongly Agree) for the statement "I complete repetitive programming tasks faster when using Copilot."
* `unfamiliar_progress`: Agreement (1 = Strongly Disagree, 5 = Strongly Agree) for the statement "While working with an unfamiliar language, I make progress faster when using Copilot."
* `more_fulfilled`: Agreement (1 = Strongly Disagree, 5 = Strongly Agree) for the statement "I feel more fulfilled with my job when using Copilot."
* `focus_satisfying`: Agreement (1 = Strongly Disagree, 5 = Strongly Agree) for the statement "I can focus on more satisfying work when using Copilot."
* `less_effort_repetitive`: Agreement (1 = Strongly Disagree, 5 = Strongly Agree) for the statement "I spend less mental effort on repetitive programming tasks when using Copilot."
* `learn_from`: Agreement (1 = Strongly Disagree, 5 = Strongly Agree) for the statement "I learn from the suggestions Copilot shows me."
* `less_frustrated`: Agreement (1 = Strongly Disagree, 5 = Strongly Agree) for the statement "I find myself less frustrated during coding sessions when using Copilot."
* `less_time_searching`: Agreement (1 = Strongly Disagree, 5 = Strongly Agree) for the statement "I spend less time searching for information or examples when using Copilot."
* `better_code`:` Agreement (1 = Strongly Disagree, 5 = Strongly Agree) for the statement "The code I write using Copilot is better than the code I would have written without Copilot."
* `aggregate_productivity`: Mean of all Likert-scale variables described above.
* `language_proficiency`: 1 = Beginner, 2 = Intermediate, 3 = Advanced for "Think of the language you have used the most with Copilot. How proficient are you in that language?" 
* `programming_experience`: 1 = Student, 2 = 0-2 years, 3 = 3-5 years, 4 = 6-10 years, 5 = 11-15 years, 6 = 16+ years for 'Which best describes your programming experience?'