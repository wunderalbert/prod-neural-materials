library(tidyverse)
library(pls)
source("analysis/gh_theme.R")
save_plot <- function(w = 720, h = 480, fname = "~/plt.png"){
    dev.copy(device = png, file = fname, width = w, height = h, units = "px", bg = "transparent")
    dev.off()
}

#pls_data <- read.csv("~/Desktop/survey_telemetry_merged_cleaned.csv")
funnel_data <- read.csv('data/survey_telemetry_merged_cleaned.csv')

names = c(opportunity = "completion\nopportunity",
          shown = "completion\nshown",
          accepted = "completion\naccepted",
          `30` = "after\n30 seconds",
          `120` = "after\n2 minutes",
          `300` = "after\n5 minutes",
          `600` = "after\n10 minutes"
          )


#format_value <- function(value) paste0(round(value / 1000), "k")
#format_value <- function(value) formatC(value, format = "e", digits = 1)
format_value <- function(value) ifelse(value > 3000000, paste0(round(value / 1000000), "m"), paste0(round(value / 1000), "k"))

funnel_data %>%
    mutate(total_hours = sum(n_shown / n_shown_per_hour, na.rm = T)) %>%
    mutate(n_shown = n_shown, #/ total_hours,
           n_issued = n_shown / pct_shown,
           n_accepted = n_shown * pct_acc,
           n_accepted_mostly_unchanged = n_shown * pct_acc,
           n_unchanged_30_s = n_accepted * pct_unchanged_30_s,
           n_unchanged_120_s = n_accepted * pct_unchanged_120_s,
           n_unchanged_300_s = n_accepted * pct_unchanged_300_s,
           n_unchanged_600_s = n_accepted * pct_unchanged_600_s,
           n_mostly_unchanged_30_s = n_accepted * pct_mostly_unchanged_30_s,
           n_mostly_unchanged_120_s = n_accepted * pct_mostly_unchanged_120_s,
           n_mostly_unchanged_300_s = n_accepted * pct_mostly_unchanged_300_s,
           n_mostly_unchanged_600_s = n_accepted * pct_mostly_unchanged_600_s,
    ) %>%
    select(starts_with("n_")) %>%
    select(-ends_with("_hour")) %>%
    summarize_if(is.numeric, sum, na.rm = T) %>%
    (reshape2::melt) %>%
    mutate(time = case_when(
        variable == "n_issued" ~ names["opportunity"],
        variable == "n_shown" ~ names["shown"],
        variable %>% str_detect("n_accepted") ~ names["accepted"],
        TRUE ~ names[str_extract(variable, "\\d+")])) %>%
    mutate(user_rework = ifelse(str_detect(variable, "mostly_unchanged"),
        "< 30%", "0%")) %>%
    mutate(time = factor(time, levels = names)) %>%
    arrange(time) %>%
    print %>%
    ggplot +
    geom_ribbon(aes(x = time, ymin = 0, ymax = value, fill = user_rework, group = user_rework)) +
    geom_point(aes(x = time, y = value)) +
    #scale_y_log10("total events for survey users\nduring 4 week period (log scale)") +
    #geom_ribbon(aes(x = time, ymin = -value/2, ymax = value/2, fill = user_rework, group = user_rework)) +
    scale_y_continuous("total events for survey users",
                       #breaks = c(0, 5e+05, 1e+06, 2e+06)
                        ) +
    geom_label(aes(x = time, y = value, label = format_value(value)), 
        vjust = 1.5,
        data = function(x) x %>% subset(user_rework == "0%")) +
    geom_label(aes(x = time, y = value, label = format_value(value)), 
        vjust = -.5,
        data = function(x) x %>% subset(user_rework == "< 30%" & time %>% str_detect("later"))) +
    geom_label(aes(x = time, y = 5000000, label = paste0("↑\n", format_value(value))), 
        hjust = "center",
        data = function(x) x %>% subset(time %>% str_detect("opportunity"))) +
    coord_cartesian(ylim = 5000000 * c(0, 1)) +
    theme_github_black(15) +
    scale_fill_manual("user edits\nto completion", values = github_colors("purple_200", "blue_200") %>% unname) +
    theme(axis.text.x = element_text(angle = 270, vjust = 0.5, hjust=0)) +
    xlab("")
save_plot(fname="funnel_absolute.png")

format_value <- function(value) signif(value, 2)

funnel_data %>%
    mutate(total_hours = sum(n_shown / n_shown_per_hour, na.rm = T)) %>%
    mutate(n_shown = n_shown / total_hours,
           n_issued = n_shown / pct_shown,
           n_accepted = n_shown * pct_acc,
           n_accepted_mostly_unchanged = n_shown * pct_acc,
           n_unchanged_30_s = n_accepted * pct_unchanged_30_s,
           n_unchanged_120_s = n_accepted * pct_unchanged_120_s,
           n_unchanged_300_s = n_accepted * pct_unchanged_300_s,
           n_unchanged_600_s = n_accepted * pct_unchanged_600_s,
           n_mostly_unchanged_30_s = n_accepted * pct_mostly_unchanged_30_s,
           n_mostly_unchanged_120_s = n_accepted * pct_mostly_unchanged_120_s,
           n_mostly_unchanged_300_s = n_accepted * pct_mostly_unchanged_300_s,
           n_mostly_unchanged_600_s = n_accepted * pct_mostly_unchanged_600_s,
    ) %>%
    select(starts_with("n_")) %>%
    select(-ends_with("_hour")) %>%
    summarize_if(is.numeric, sum, na.rm = T) %>%
    (reshape2::melt) %>%
    mutate(time = case_when(
        variable == "n_issued" ~ names["opportunity"],
        variable == "n_shown" ~ names["shown"],
        variable %>% str_detect("n_accepted") ~ names["accepted"],
        TRUE ~ names[str_extract(variable, "\\d+")])) %>%
    mutate(user_rework = ifelse(str_detect(variable, "mostly_unchanged"),
        #"< 30%", "0%")) %>%
        "mostly unchanged", "unchanged")) %>%
    mutate(time = factor(time, levels = names)) %>%
    arrange(time) %>%
    print %>%
    ggplot +
    geom_ribbon(aes(x = time, ymin = 0, ymax = value, fill = user_rework, group = user_rework)) +
    geom_point(aes(x = time, y = value)) +
    #scale_y_log10("total events for survey users\nduring 4 week period (log scale)") +
    #geom_ribbon(aes(x = time, ymin = -value/2, ymax = value/2, fill = user_rework, group = user_rework)) +
    scale_y_continuous("average number of events\nper survey user active hour",
                       #breaks = c(0, 5e+05, 1e+06, 2e+06)
                        ) +
    geom_label(aes(x = time, y = value, label = format_value(value)), 
        vjust = 1.5,
        data = function(x) x %>% subset(user_rework == "unchanged")) +
    geom_label(aes(x = time, y = value, label = format_value(value)), 
        vjust = -.5,
        data = function(x) x %>% subset(user_rework == "mostly unchanged" & time %>% str_detect("after"))) +
    geom_label(aes(x = time, y = 50, label = paste0("↑\n", format_value(value))), 
        hjust = "center",
        data = function(x) x %>% subset(time %>% str_detect("opportunity"))) +
    coord_cartesian(ylim = 50 * c(0, 1)) +
    theme_github_black(15) +
    scale_fill_manual("completion", values = github_colors("purple_200", "blue_200") %>% unname) +
    theme(axis.text.x = element_text(angle = 270, vjust = 0.5, hjust=0)) +
    xlab("")
save_plot(fname="funnel.png")



format_value <- function(value) signif(value, 2)

funnel_data %>%
    mutate(total_hours = sum(n_shown / n_shown_per_hour, na.rm = T)) %>%
    mutate(n_shown = n_shown / total_hours,
           n_issued = n_shown / pct_shown,
           n_accepted = n_shown * pct_acc,
           n_accepted_mostly_unchanged = n_shown * pct_acc,
           n_unchanged_30_s = n_accepted * pct_unchanged_30_s,
           n_unchanged_120_s = n_accepted * pct_unchanged_120_s,
           n_unchanged_300_s = n_accepted * pct_unchanged_300_s,
           n_unchanged_600_s = n_accepted * pct_unchanged_600_s,
           n_mostly_unchanged_30_s = n_accepted * pct_mostly_unchanged_30_s,
           n_mostly_unchanged_120_s = n_accepted * pct_mostly_unchanged_120_s,
           n_mostly_unchanged_300_s = n_accepted * pct_mostly_unchanged_300_s,
           n_mostly_unchanged_600_s = n_accepted * pct_mostly_unchanged_600_s,
    ) %>%
    select(starts_with("n_")) %>%
    select(-ends_with("_hour")) %>%
    summarize_if(is.numeric, sum, na.rm = T) %>%
    (reshape2::melt) %>%
    mutate(time = case_when(
        variable == "n_issued" ~ names["opportunity"],
        variable == "n_shown" ~ names["shown"],
        variable %>% str_detect("n_accepted") ~ names["accepted"],
        TRUE ~ names[str_extract(variable, "\\d+")])) %>%
    mutate(user_rework = ifelse(str_detect(variable, "mostly_unchanged"),
        #"< 30%", "0%")) %>%
        "mostly unchanged", "unchanged")) %>%
    mutate(time = factor(time, levels = names)) %>%
    arrange(time) %>%
    print %>%
    ggplot +
    geom_ribbon(aes(x = time, ymin = 0, ymax = value, fill = user_rework, group = user_rework)) +
    geom_point(aes(x = time, y = value)) +
    #scale_y_log10("total events for survey users\nduring 4 week period (log scale)") +
    #geom_ribbon(aes(x = time, ymin = -value/2, ymax = value/2, fill = user_rework, group = user_rework)) +
    scale_y_continuous("average number of events\nper survey user active hour",
                       #breaks = c(0, 5e+05, 1e+06, 2e+06)
                        ) +
    geom_label(aes(x = time, y = value, label = format_value(value)), 
        vjust = 1.5,
        data = function(x) x %>% subset(user_rework == "unchanged")) +
    geom_label(aes(x = time, y = value, label = format_value(value)), 
        vjust = -.5,
        data = function(x) x %>% subset(user_rework == "mostly unchanged" & time %>% str_detect("after"))) +
    geom_label(aes(x = time, y = 50, label = paste0("↑\n", format_value(value))), 
        hjust = "center",
        data = function(x) x %>% subset(time %>% str_detect("opportunity"))) +
    coord_cartesian(ylim = 50 * c(0, 1)) +
    theme_github(15) + theme(panel.grid = element_line(colour = github_colors("gray_100"))) + 
    scale_fill_manual("completion", values = github_colors("purple_200", "blue_200") %>% unname) +
    theme(axis.text.x = element_text(angle = 270, vjust = 0.5, hjust=0)) +
    xlab("")
save_plot(fname="funnel_white.png")
