library(tidyverse)
library(lubridate)
source("analysis/gh_theme.R")
save_plot <- function(w = 720, h = 480, fname = "~/plt.png"){
    dev.copy(device = png, file = fname, width = w, height = h, units = "px", bg = "transparent")
    dev.off()
}

# Download export 84:
language_data <- rbind(
    language_data_survey_users <- read.csv("data_telemetry/languages_for_survey_users.csv") %>%
        mutate("user_type" = "survey\nparticipants"),
    language_data_all_users <- read.csv("~/Downloads/languages_for_all_users.csv") %>%
        mutate("user_type" = "all\nusers")
) %>%
    subset(language != "none") %>%
    mutate(language = factor(language, levels = c("TypeScript", "JavaScript", "Python", "other"))) %>%
    mutate(user_type = factor(user_type, levels = c("survey\nparticipants", "all\nusers")))

# graph for acceptance rates
language_data %>%
    ggplot +
    geom_col(aes(x = language, y = acceptance_rate, fill = user_type),
             position = "dodge") +
    scale_y_continuous("acceptance rate", labels = scales::percent, limits = c(0, NA)) +
    scale_x_discrete("") +
    scale_fill_manual("", values = github_colors("red_200", "blue_200") %>% unname) +
    geom_text(aes(x = language, y = acceptance_rate / 2, 
                  label = sprintf("%2.1f", 100 * acceptance_rate) %>% paste0("%"),
                  group = user_type), 
              size = 7,
              position = position_dodge(width = .9)) +
    theme_github_black(15)
save_plot(fname="languages.png")

language_data %>%
    ggplot +
    geom_col(aes(x = language, y = acceptance_rate, fill = user_type),
             position = "dodge") +
    scale_y_continuous("acceptance rate", labels = scales::percent, limits = c(0, NA)) +
    scale_x_discrete("") +
    scale_fill_manual("", values = github_colors("red_200", "blue_200") %>% unname) +
    geom_text(aes(x = language, y = acceptance_rate / 2, 
                  label = sprintf("%2.1f", 100 * acceptance_rate) %>% paste0("%"),
                  group = user_type), 
              size = 7,
              position = position_dodge(width = .9)) +
    theme_github(18) + theme(panel.grid = element_line(colour = github_colors("gray_100")))
save_plot(fname="languages_white.png")

# graph for language distribution
language_data %>%
    ggplot +
    geom_col(aes(x = user_type, y = n_shown, fill = language),
             position = "fill")
language_data %>% group_by(user_type) %>% mutate(language_ratio = n_shown/sum(n_shown))



data_cleaned <- read.csv('data/survey_telemetry_merged_cleaned.csv')
activity_data <- read.csv("data/summary_by_id.csv")
activity_data_lang <- read.csv("data/data_by_language.csv")
survey_data <- merge(data_cleaned, activity_data, on = "copilot_trackingId")
survey_data_lang <- merge(data_cleaned %>% select(aggregate_productivity, copilot_trackingId), activity_data_lang, on = "copilot_trackingId", all.y = T) %>%
    subset(n_shown > 0)
survey_data_lang %>% nrow

data_cleaned %>% with(cor.test(pct_acc, aggregate_productivity))
survey_data_lang %>% with(cor.test(n_acc / n_shown, aggregate_productivity))
survey_data_lang %>% 
    subset(language == "TypeScript") %>%
    with(cor.test(n_acc / n_shown, aggregate_productivity))
survey_data_lang %>% 
    subset(language == "JavaScript") %>%
    with(cor.test(n_acc / n_shown, aggregate_productivity))
survey_data_lang %>% 
    subset(language == "Python") %>%
    with(cor.test(n_acc / n_shown, aggregate_productivity))
survey_data_lang %>% 
    subset(language == "other" | language == "none") %>%
    group_by(copilot_trackingId) %>%
    summarize(n_shown = sum(n_shown), n_acc = sum(n_acc), pca_survey_first_component = mean(pca_survey_first_component)) %>%
    with(cor.test(n_acc / n_shown, pca_survey_first_component))
survey_data_lang %>% 
    group_by(copilot_trackingId) %>%
    summarize(n_shown = sum(n_shown), n_acc = sum(n_acc), pca_survey_first_component = mean(pca_survey_first_component)) %>%
    with(cor.test(n_acc / n_shown, pca_survey_first_component))
survey_data_lang %>% 
    group_by(copilot_trackingId) %>%
    summarize(n_acc = sum(n_acc), n_shown = sum(n_shown), aggregate_productivity = mean(aggregate_productivity)) %>%
    with(cor.test(n_acc / n_shown, aggregate_productivity))

data_cleaned$aggregate_productivity %>% head

cor.test(data_cleaned$pct_acc, data_cleaned$aggregate_productivity)



survey_data_lang$pca_survey_first_component %>% is.na %>% table
survey_data_lang$n_shown %>% is.na %>% table
survey_data_lang$n_acc %>% is.na %>% table
survey_data_lang$language %>% is.na %>% table

survey_data_lang %>%
    subset(n_shown > 0) %>%
    with(lm(aggregate_productivity ~ I(n_acc / n_shown) + language,
            weights = n_shown)) %>%
    summary

survey_data_lang %>%
    subset(n_shown > 0) %>%
    group_by(language) %>%
    summarize(lm(aggregate_productivity ~ I(n_acc / n_shown),
            weights = n_shown)$coefficients[2])
survey_data_lang %>%
    subset(n_shown > 0) %>%
    summarize(lm(aggregate_productivity ~ I(n_acc / n_shown),
            weights = n_shown)$coefficients[2])
survey_data_lang %>%
    subset(n_shown > 0) %>%
    group_by(language) %>%
    summarize(lm(aggregate_productivity ~ I(n_acc / n_shown),
            weights = n_shown)$coefficients[2])

survey_data_lang %>% group_by(copilot_trackingId) %>%
    summarize(acc_rate = sum(n_acc) / sum(n_shown))
activity_data_lang %>% head(20)
survey_data_lang %>% select(n_shown, n_acc, language) %>% head(20)

# how much % variance in languages is explained by acceptance rate?
mod <- survey_data_lang %>%
    subset(n_shown > 0) %>%
    subset(aggregate_productivity %>% is.na %>% `!`) %>%
    lm(formula = aggregate_productivity ~ I(n_acc / n_shown),
            weights = n_shown)
survey_data_lang %>%
    subset(n_shown > 0) %>%
    subset(aggregate_productivity %>% is.na %>% `!`) %>%
    mutate(pred = predict(mod)) %>%
    mutate(language = ifelse(language == "none", "other", language)) %>%
    group_by(language) %>%
    summarize(
        aggregate_productivity = weighted.mean(aggregate_productivity, n_shown),
        aggregate_prediction = weighted.mean(pred, n_shown),
        n_shown = sum(n_shown)) %>%
    mutate(average_productivity = weighted.mean(aggregate_productivity, n_shown)) %>%
    ungroup %>%
    print %>%
    summarize(
        total_variance = weighted.mean((aggregate_productivity - average_productivity)^2, n_shown),
        unexplained_variance = weighted.mean((aggregate_prediction - aggregate_productivity)^2, n_shown)) %>%
    print %>%
    summarize(r_squared = 1 - unexplained_variance / total_variance)
    
# other direction: how much % variance in p
survey_data_lang %>%
    subset(n_shown > 0) %>%
    subset(aggregate_productivity %>% is.na %>% `!`) %>%
    lm(formula = aggregate_productivity ~ I(n_acc / n_shown) + language,
            weights = n_shown) %>%
    summary

rs_1 <-
    survey_data_lang %>%
    subset(n_shown > 0) %>%
    subset(aggregate_productivity %>% is.na %>% `!`) %>%
    mutate(language = ifelse(language == "none", "other", language)) %>%
    group_by(language) %>%
    mutate(aggregate_prediction = weighted.mean(aggregate_productivity, n_shown)) %>%
    ungroup %>%
        lm(formula = aggregate_productivity ~ 
            #I(n_acc / n_shown)
            aggregate_prediction
            , weights = n_shown) %>%
    summary %>%
    with(r.squared)

rs_2 <-
survey_data_lang %>%
    subset(n_shown > 0) %>%
    subset(aggregate_productivity %>% is.na %>% `!`) %>%
    mutate(language = ifelse(language == "none", "other", language)) %>%
    group_by(language) %>%
    mutate(aggregate_prediction = weighted.mean(aggregate_productivity, n_shown)) %>%
    ungroup %>%
        lm(formula = aggregate_productivity ~ 
            I(n_acc / n_shown)
            #aggregate_prediction
            , weights = n_shown) %>%
    summary %>%
    with(r.squared)

rs_1 / rs_2
