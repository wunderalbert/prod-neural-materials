library(tidyverse)
library(lubridate)
source("analysis/gh_theme.R")
save_plot <- function(w = 720, h = 480, fname = "~/plt.png"){
    dev.copy(device = png, file = fname, width = w, height = h, units = "px", bg = "transparent")
    dev.off()
}

clock_times <- read.csv("data_telemetry/clock_times.csv") %>%
    mutate(TimeGenerated = TimeGenerated %>% ymd_hms) %>%
    mutate(time_on_the_clock_utc = hour(TimeGenerated),
           weekend = TimeGenerated %>% with_tz(tz = "America/Los_Angeles") %>% weekdays %in% c("Sunday", "Saturday"),
           time_on_the_clock_pst = TimeGenerated %>% with_tz(tz = "America/Los_Angeles") %>% hour) %>%
    mutate(time_kind = ifelse(weekend, "weekend", ifelse(time_on_the_clock_utc > 0 & time_on_the_clock_utc < 14, "off hours", "working hours")))

clock_times %>% 
    group_by(weekend, time_on_the_clock_utc, time_kind, weekdays(TimeGenerated)) %>%
    summarize(TimeGenerated = min(TimeGenerated + days(ifelse(TimeGenerated < ymd_h("2022-01-15 8"), 
                                         7,
                                         0))), 
              acc_min = min(n_acc / n_shown),
              acc_max = max(n_acc / n_shown),
              n_acc = sum(n_acc), n_shown = sum(n_shown)) %>%
    #mutate(time_kind = ifelse(weekend, "weekend", ifelse(time_on_the_clock > 0 & time_on_the_clock < 14, "off hours", "working day"))) %>%
    ggplot +
    #geom_rect(aes(xmin = TimeGenerated, xmax = TimeGenerated + days(1), ymin = -Inf, ymax = Inf,
    #    col = ifelse(weekend, "weekend", ifelse(time_on_the_clock > 0 & time_on_the_clock < 14, "off hours", "working day")))) +
    scale_color_manual("", values = github_colors("blue_200", "purple_200", "red_200") %>% unname) +
    scale_fill_manual("", values = github_colors("blue_200", "purple_200", "red_200") %>% unname) +
    geom_ribbon(aes(x = TimeGenerated, y = n_acc / n_shown, ymin = acc_min, ymax = acc_max, 
                    fill = time_kind, group = paste0(time_kind, day(TimeGenerated - hours(1)))), alpha = .3) +
    geom_line(aes(x = TimeGenerated, y = n_acc / n_shown), col = github_colors("gray_200")) +
    geom_point(aes(x = TimeGenerated, y = n_acc / n_shown, col = time_kind)) +
    scale_y_continuous("acceptance rate", labels = scales::percent) +
    ggtitle("Daily and weekly patterns in acceptance rate in the US\n(all users between 2022-01-15 and 2022-02-12)") +
    scale_x_datetime("weekday and time (PST)", #date_breaks = "12 hours", minor_breaks = "8 hours",
                     limits = function(x) c(min(x), max(x)),
                     breaks = ymd_h("2022-01-15 0") + 12*hours(0:14),
                     labels = function(dt) {
                         paste0(
                             ifelse(hour(dt) == 12, weekdays(dt), ""),
                             "\n",
                             hour(dt),# (hour(dt) + 16) %% 24, 
                             ":00")
                     }) +
    theme_github_black(13)
save_plot(fname = "patterns.png")



clock_times %>% 
    group_by(weekend, time_on_the_clock_utc, time_kind, weekdays(TimeGenerated)) %>%
    summarize(TimeGenerated = min(TimeGenerated + days(ifelse(TimeGenerated < ymd_h("2022-01-15 8"), 
                                         7,
                                         0))), 
              acc_min = min(n_acc / n_shown),
              acc_max = max(n_acc / n_shown),
              n_acc = sum(n_acc), n_shown = sum(n_shown)) %>%
    #mutate(time_kind = ifelse(weekend, "weekend", ifelse(time_on_the_clock > 0 & time_on_the_clock < 14, "off hours", "working day"))) %>%
    ggplot +
    #geom_rect(aes(xmin = TimeGenerated, xmax = TimeGenerated + days(1), ymin = -Inf, ymax = Inf,
    #    col = ifelse(weekend, "weekend", ifelse(time_on_the_clock > 0 & time_on_the_clock < 14, "off hours", "working day")))) +
    scale_color_manual("", values = github_colors("blue_200", "purple_200", "red_200") %>% unname) +
    scale_fill_manual("", values = github_colors("blue_200", "purple_200", "red_200") %>% unname) +
    geom_ribbon(aes(x = TimeGenerated, y = n_acc / n_shown, ymin = acc_min, ymax = acc_max, 
                    fill = time_kind, group = paste0(time_kind, day(TimeGenerated - hours(1)))), alpha = .3) +
    geom_line(aes(x = TimeGenerated, y = n_acc / n_shown), col = github_colors("gray_200")) +
    geom_point(aes(x = TimeGenerated, y = n_acc / n_shown, col = time_kind)) +
    scale_y_continuous("acceptance rate", labels = scales::percent) +
    ggtitle("Daily and weekly patterns in acceptance rate in the US\n(all users between 2022-01-15 and 2022-02-12)") +
    scale_x_datetime("weekday and time (PST)", #date_breaks = "12 hours", minor_breaks = "8 hours",
                     limits = function(x) c(min(x), max(x)),
                     breaks = ymd_h("2022-01-15 0") + 12*hours(c(1, 3, 5, 7, 9, 11, 13)),
                     labels = function(dt) {
                         paste0(
                             ifelse(hour(dt) == 12, weekdays(dt), "\n"),
                             "\n",
                             hour(dt),# (hour(dt) + 16) %% 24, 
                             ":00")
                     }) +
    theme_github(18) + theme(panel.grid = element_line(colour = github_colors("gray_100"))) 
save_plot(fname = "patterns_white_2.png")

# once more without title

clock_times %>% 
    group_by(weekend, time_on_the_clock_utc, time_kind, weekdays(TimeGenerated)) %>%
    summarize(TimeGenerated = min(TimeGenerated + days(ifelse(TimeGenerated < ymd_h("2022-01-15 8"), 
                                         7,
                                         0))), 
              acc_min = min(n_acc / n_shown),
              acc_max = max(n_acc / n_shown),
              n_acc = sum(n_acc), n_shown = sum(n_shown)) %>%
    #mutate(time_kind = ifelse(weekend, "weekend", ifelse(time_on_the_clock > 0 & time_on_the_clock < 14, "off hours", "working day"))) %>%
    ggplot +
    #geom_rect(aes(xmin = TimeGenerated, xmax = TimeGenerated + days(1), ymin = -Inf, ymax = Inf,
    #    col = ifelse(weekend, "weekend", ifelse(time_on_the_clock > 0 & time_on_the_clock < 14, "off hours", "working day")))) +
    scale_color_manual("", values = github_colors("blue_200", "purple_200", "red_200") %>% unname) +
    scale_fill_manual("", values = github_colors("blue_200", "purple_200", "red_200") %>% unname) +
    geom_ribbon(aes(x = TimeGenerated, y = n_acc / n_shown, ymin = acc_min, ymax = acc_max, 
                    fill = time_kind, group = paste0(time_kind, day(TimeGenerated - hours(1)))), alpha = .3) +
    geom_line(aes(x = TimeGenerated, y = n_acc / n_shown), col = github_colors("gray_200")) +
    geom_point(aes(x = TimeGenerated, y = n_acc / n_shown, col = time_kind)) +
    scale_y_continuous("acceptance rate", labels = scales::percent) +
    scale_x_datetime("weekday and time (PST)", #date_breaks = "12 hours", minor_breaks = "8 hours",
                     limits = function(x) c(min(x), max(x)),
                     breaks = ymd_h("2022-01-15 0") + 12*hours(c(1, 3, 5, 7, 9, 11, 13)),
                     labels = function(dt) {
                         paste0(
                             ifelse(hour(dt) == 12, weekdays(dt), "\n"),
                             "\n",
                             hour(dt),# (hour(dt) + 16) %% 24, 
                             ":00")
                     }) +
    theme_github(18) + theme(panel.grid = element_line(colour = github_colors("gray_100"))) 
save_plot(fname = "patterns_white_2.png")

