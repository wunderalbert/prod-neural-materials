library(tidyverse)
library(lubridate)
source("analysis/gh_theme.R")
save_plot <- function(w = 720, h = 480, fname = "~/plt.png"){
    dev.copy(device = png, file = fname, width = w, height = h, units = "px", bg = "transparent")
    dev.off()
}

cyclical_data <- read.csv("data/cyclical_data.csv") %>% mutate(in_us = in_us == "true")


cyclical_data %>% 
    subset(in_us) %>%
    group_by(hour) %>%
    summarize(n_acc = sum(n_acc) / sum(n_shown)) %>%
    plot




data_by_time_kind <- read.csv("data/acc_rate_by_time_type_and_user.csv") %>%
    mutate(workhour = workhour == "true") %>%
    mutate(weekday = weekday == "true")
data_by_time_kind %>%
    group_by(weekday, workhour) %>%
    summarize(acc_rate = sum(n_acc) / sum(n_shown), n_shown = sum(n_shown))

# want to say whether it's because _different_ users are on, or because the same user is different
data_by_time_kind %>%
  group_by(copilot_trackingId) %>%
  mutate(
      avg_workhour = weighted.mean(workhour, n_shown),
      avg_weekday = weighted.mean(weekday, n_shown)) %>%
  ungroup %>%
  group_by(group = ntile(avg_weekday, 10), weekday) %>%
  summarize(acc_rate_stratified = sum(n_acc) / sum(n_shown)) %>%
  ggplot +
  geom_point(aes(x = group, y = acc_rate_stratified, color = weekday))

data_by_time_kind %>%
  group_by(copilot_trackingId) %>%
  mutate(
      avg_workhour = weighted.mean(workhour, n_shown),
      avg_weekday = weighted.mean(weekday, n_shown))

data_by_time_kind %>%
  group_by(copilot_trackingId) %>%
  mutate(
      avg_workhour = weighted.mean(workhour, n_shown),
      avg_weekday = weighted.mean(weekday, n_shown)) %>%
  ungroup %>%
  subset(n_shown > 1) %>%
  with(glm(n_acc / n_shown ~ avg_workhour + workhour), weights = n_shown) %>%
  summary
# what matters is that this is the kind of person who works / kind of work that gets done
# on weekends, not whether it actually happens on weekends.

data_by_time_kind %>%
  group_by(copilot_trackingId) %>%
  mutate(
      avg_workhour = weighted.mean(workhour, n_shown),
      avg_weekday = weighted.mean(weekday, n_shown)) %>%
  ungroup %>%
  subset(n_shown > 1) %>%
  with(glm(n_acc / n_shown ~ avg_weekday + weekday), weights = n_shown) %>%
  summary
# does that mean if you're the kind of person who works weekends,
# and now work weekdays, you're actually more indulgent than you'd otherwise have been?

data_by_time_kind %>%
  group_by(copilot_trackingId) %>%
  mutate(
      avg_workhour = weighted.mean(workhour, n_shown),
      avg_weekday = weighted.mean(weekday, n_shown)) %>%
  ungroup %>%
  subset(n_shown > 1) %>%
  with(glm(n_acc / n_shown ~ avg_weekday : weekday + weekday), weights = n_shown) %>%
  summary

make_kind_model_weighted <- function(df, timekind) {
    df$time_kind = df[,timekind]
    df %>% 
    group_by(copilot_trackingId) %>%
    mutate(avg_kind = weighted.mean(time_kind, n_shown)) %>%
    ungroup %>%
    mutate(usual_time_kind = ifelse(time_kind, avg_kind, 1 - avg_kind)) %>%
    ungroup %>%
    subset(n_shown > 1) %>%
    mutate(time_kind = time_kind + 0) %>%
    with({
        print(select(., avg_kind, usual_time_kind, time_kind) %>% summarize_all(var))
        .}) %>%
    with(glm(n_acc / n_shown ~ avg_kind + usual_time_kind + time_kind),
                weights = n_shown,
                family = binomial)
}

make_kind_model <- function(df, timekind) {
    df$time_kind = df[,timekind]
    df %>% 
    group_by(copilot_trackingId) %>%
    mutate(avg_kind = weighted.mean(time_kind, n_shown)) %>%
    ungroup %>%
    mutate(usual_time_kind = ifelse(time_kind, avg_kind, 1 - avg_kind)) %>%
    ungroup %>%
    subset(n_shown > 1) %>%
    mutate(time_kind = time_kind + 0) %>%
    with({
        print(select(., avg_kind, usual_time_kind, time_kind) %>% summarize_all(var))
        .}) %>%
    with({
        lm(n_acc / n_shown ~ avg_kind + usual_time_kind + time_kind
                #, weights = n_shown
                #, family = binomial
    )})
}


data.frame(a = c(T, F, T, T, T, F), b = c(.1, .2, .3, .1, .2, .3), c = 1:3) %>%
    with(glm(a ~ b, family = binomial)) %>%
    summary
data.frame(a = c(T, F, T, T, T, F), b = c(.1, .2, .3, .1, .2, .3), c = 1:3) %>%
    group_by(c, b) %>%
    summarize(a = mean(a)) %>%
    with(glm(a ~ b, family = binomial)) %>% 
    summary

data_by_time_kind %>% subset(weekday) %>% make_kind_model_weighted("workhour") %>% summary
data_by_time_kind %>% subset(n_shown >= n_acc) %>% make_kind_model_weighted("weekday") %>% summary

data_by_time_kind %>% group_by(weekday) %>% summarize(sum(n_acc) / sum(n_shown))
data_by_time_kind %>% subset(weekday) %>% group_by(workhour) %>% summarize(sum(n_acc) / sum(n_shown))

bootstrap_statistic <- replicate(10000,
data_by_time_kind %>% mutate(weekday = sample(weekday, replace=T), workhour=sample(workhour, replace=T)) %>%
    subset(!(weekday & workhour)) %>%
    group_by(weekday) %>% summarize(a = sum(n_acc) / sum(n_shown)) %>% with(diff(a)))
mean(bootstrap_statistic - 0.005)


data_by_time_kind %>%
    mutate(time_kind = weekday) %>%
    group_by(copilot_trackingId) %>%
    mutate(avg_kind = weighted.mean(time_kind, n_shown)) %>%
    ungroup %>%
    mutate(usual_time_kind = ifelse(time_kind, avg_kind, 1 - avg_kind)) %>%
    ungroup %>%
    subset(n_shown > 1) %>%
    mutate(time_kind = time_kind + 0) %>%
    group_by(usual = avg_kind %>% ntile(7), time_kind) %>%
    summarize(acc = sum(n_acc) / sum(n_shown), avg_kind = median(avg_kind), usual_time_kind = median(usual_time_kind)) %>%
    ggplot +
    geom_line(aes(x = avg_kind, y = acc, col = time_kind %>% factor))

data_by_time_kind %>%
    mutate(time_kind = weekday) %>%
    group_by(copilot_trackingId) %>%
    mutate(avg_kind = weighted.mean(time_kind, n_shown)) %>%
    ungroup %>%
    mutate(usual_time_kind = ifelse(time_kind, avg_kind, 1 - avg_kind)) %>%
    ungroup %>%
    subset(n_shown > 1) %>%
    group_by(avg_kind > .9, time_kind) %>%
    summarize(sum(n_acc)/sum(n_shown), sum(n_shown))

### This is the data reported on@
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
save_plot(h = 300)


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
    theme_github(18) + theme(panel.grid = element_line(colour = github_colors("gray_100")))
save_plot(fname = "workhours_white.png", h = 300)


data_by_time_kind %>%
    mutate(time_kind = weekday) %>%
    group_by(copilot_trackingId) %>%
    mutate(avg_kind = weighted.mean(time_kind, n_shown)) %>%
    ungroup %>%
    mutate(usual_time_kind = ifelse(time_kind, avg_kind, 1 - avg_kind)) %>%
    subset(n_shown > 1) %>%
    mutate(time_kind = time_kind + 0) %>%
    with({
        lm(n_acc / n_shown ~ avg_kind + usual_time_kind + time_kind
                #, weights = n_shown
                #, family = binomial
    )}) %>%
    summary



data_by_time_kind %>%
    mutate(time_kind = workhour) %>%
    group_by(copilot_trackingId) %>%
    mutate(avg_kind = weighted.mean(time_kind, n_shown), time_kind) %>%
    ungroup %>%
    group_by(avg_kind > .5, time_kind) %>%
    summarize(n_acc = sum(n_acc), n_shown = sum(n_shown), acc_rate = n_acc / n_shown) %>%
    arrange(acc_rate)

data_by_time_kind %>%
    mutate(time_kind = weekday) %>%
    group_by(copilot_trackingId) %>%
    mutate(avg_kind = weighted.mean(time_kind, n_shown), time_kind) %>%
    ungroup %>%
    group_by(avg_kind > .5, time_kind) %>%
    summarize(n_acc = sum(n_acc), n_shown = sum(n_shown), acc_rate = n_acc / n_shown) %>%
    arrange(acc_rate)


