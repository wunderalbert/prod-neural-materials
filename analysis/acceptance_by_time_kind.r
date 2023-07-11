library(tidyverse)
library(lubridate)
source("analysis/gh_theme.R")
save_plot <- function(w = 720, h = 480, fname = "~/plt.png"){
    dev.copy(device = png, file = fname, width = w, height = h, units = "px", bg = "transparent")
    dev.off()
}

data_by_time_kind <- read.csv("~/telemetry_data/acceptance_by_time_kind.csv") %>%
    mutate(workhour = workhour == "true") %>%
    mutate(weekday = weekday == "true")


plot_data_workhour <- data_by_time_kind %>%
    mutate(time_kind = workhour) %>% subset(weekday) %>%
    #mutate(time_kind = weekday) %>%
    group_by(copilot_trackingId) %>%
    mutate(avg_kind = weighted.mean(time_kind, n_shown)) %>%
    ungroup %>%
    arrange(avg_kind) %>%
    subset(n_shown > 1) %>%
    mutate(percentile = cumsum(n_shown) / sum(n_shown)) %>%

    mutate(usual_time_kind = ifelse(time_kind, avg_kind, 1 - avg_kind)) %>%
    ungroup %>%
    with({
        lm(n_acc / n_shown ~ percentile + usual_time_kind + time_kind
                #, weights = n_shown
                #, family = binomial
        ) %>% summary %>% print
        .
    }) %>%
    mutate(tiles = ceiling(10 * percentile)) %>% 
    group_by(tiles, time_kind) %>%
    summarize(acc_rate = sum(n_acc)/sum(n_shown), sum(n_shown), min(avg_kind), max(avg_kind))

plot_data_weekends <- data_by_time_kind %>%
    #mutate(time_kind = workhour) %>% subset(weekday) %>%
    mutate(time_kind = weekday) %>%
    group_by(copilot_trackingId) %>%
    mutate(avg_kind = weighted.mean(time_kind, n_shown)) %>%
    ungroup %>%
    arrange(avg_kind) %>%
    subset(n_shown > 1) %>%
    mutate(percentile = cumsum(n_shown) / sum(n_shown)) %>%

    mutate(usual_time_kind = ifelse(time_kind, avg_kind, 1 - avg_kind)) %>%
    ungroup %>%
    with({
        lm(n_acc / n_shown ~ percentile + usual_time_kind + time_kind
                #, weights = n_shown
                #, family = binomial
        ) %>% summary %>% print
        .
    }) %>%
    mutate(tiles = ceiling(10 * percentile)) %>% 
    group_by(tiles, time_kind) %>%
    summarize(acc_rate = sum(n_acc)/sum(n_shown), sum(n_shown), min(avg_kind), max(avg_kind))


rbind(plot_data_weekends %>% mutate(kind = "weekdays"),
      plot_data_workhour %>% mutate(kind = "work hours")) %>%
    as.data.frame() %>%
    print %>%
    mutate(time_kind = ifelse(time_kind, "work hours / weekdays", "off hours / weekends")) %>%
    ggplot +
    facet_grid(~ kind) +
    geom_line(aes(x = tiles, y = acc_rate, col = time_kind %>% factor)) +
    geom_point(aes(x = tiles, y = acc_rate, col = time_kind %>% factor)) +
    scale_x_discrete("decile for concentration of user's\nactivity on work hours / weekdays") +
    scale_y_continuous("acceptance rate", labels=scales::percent) +
    scale_color_manual("contributions during", values = github_colors("red_200", "blue_200") %>% unname %>% rev) +
    theme_github_black(15)
save_plot(fname = "workhours.png", h = 300)





survey_telemetry_merged_cleaned <- read.csv('data/survey_telemetry_merged_cleaned.csv')
table(survey_telemetry_merged_cleaned$copilot_trackingId %in% data_by_time_kind$copilot_trackingId)

survey_telemetry_merged_cleaned$Which.of.the.following.best.describes.what.you.do..Student..full.time.or.part.time


d_workhour <- data_by_time_kind %>%
    mutate(time_kind = workhour) %>% subset(weekday) %>%
    group_by(copilot_trackingId) %>%
    summarize(avg_kind = weighted.mean(time_kind, n_shown), n_shown = sum(n_shown)) %>%
    ungroup %>%
    arrange(avg_kind) %>%
    subset(n_shown > 1) %>%
    mutate(percentile = cumsum(n_shown) / sum(n_shown)) %>%
    merge(survey_telemetry_merged_cleaned, on = "copilot_trackingId") %>% 
    mutate(what_you_do = case_when(
        Which.of.the.following.best.describes.what.you.do..Student..full.time.or.part.time == 1 ~ "Student",
        Which.of.the.following.best.describes.what.you.do..Professional.programmer..writing.code.for.work == 1 ~ "Programmer",
        Which.of.the.following.best.describes.what.you.do..Consultant.Freelancer == 1 ~ "Consultant",
        Which.of.the.following.best.describes.what.you.do..Researcher == 1 ~ "Researcher",
        TRUE ~ "Other"
    ))

d_weekday <- data_by_time_kind %>%
    mutate(time_kind = weekday) %>%
    group_by(copilot_trackingId) %>%
    summarize(avg_kind = weighted.mean(time_kind, n_shown), n_shown = sum(n_shown)) %>%
    ungroup %>%
    arrange(avg_kind) %>%
    subset(n_shown > 1) %>%
    mutate(percentile = cumsum(n_shown) / sum(n_shown)) %>%
    merge(survey_telemetry_merged_cleaned, on = "copilot_trackingId") %>% 
    mutate(what_you_do = case_when(
        Which.of.the.following.best.describes.what.you.do..Student..full.time.or.part.time == 1 ~ "Student",
        Which.of.the.following.best.describes.what.you.do..Professional.programmer..writing.code.for.work == 1 ~ "Programmer",
        Which.of.the.following.best.describes.what.you.do..Consultant.Freelancer == 1 ~ "Consultant",
        Which.of.the.following.best.describes.what.you.do..Researcher == 1 ~ "Researcher",
        TRUE ~ "Other"
    ))
d_weekday %>% group_by(what_you_do) %>%
    summarize(mean(percentile), median(percentile), mean(avg_kind), median(avg_kind), n()) %>%
    as.data.frame()
d_workhour %>% group_by(what_you_do) %>%
    summarize(mean(percentile), median(percentile), mean(avg_kind), median(avg_kind), n()) %>%
    as.data.frame()


survey_data$Which.of.the.following.best.describes.what.you.do. %>% table
