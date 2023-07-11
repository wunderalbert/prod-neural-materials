library(tidyverse)
library(ggnewscale)
source("analysis/gh_theme.R")

save_plot <- function(w = 720, h = 480, fname = "~/plt.png"){
    dev.copy(device = png, file = fname, width = w, height = h, units = "px", bg = "transparent")
    dev.off()
}

data_cleaned <- read.csv('data_telemetry/survey_telemetry_merged_cleaned.csv')
activity_data_lang <- read.csv("data/data_by_language.csv")
survey_data_lang <- merge(data_cleaned %>% select(aggregate_productivity, copilot_trackingId), activity_data_lang, on = "copilot_trackingId", all.y = T) %>%
    subset(n_shown > 0)

experiences <- c( "none",
                      "≤ 2 y",
                       "3 - 5 y",
                       "6 - 10 y",
                        "11 - 15 y",
                        "≥ 16 y")
languages <- c("JavaScript",
                        "TypeScript",
                        "Python",
                        "other")
colours <- github_colors(
    "yellow_300", "yellow_500", "orange_300", "red_300", "red_600", "red_800",
    "blue_500", "blue_200", "green_500", "green_200"
)
names(colours) <- c(experiences, languages)

survey_data_lang %>%   
     mutate(shown = n_shown, accepted = n_acc) %>%
     select(language, shown, accepted, aggregate_productivity) %>%
    mutate(programming_experience = NA) %>%
     mutate(language = ifelse(language == "none", "other", language)) %>%
     rbind(
         data_cleaned %>%
             select(programming_experience, shown, accepted, aggregate_productivity) %>% 
             mutate(language = NA)
     ) %>% 
     mutate(group = ifelse(is.na(language), programming_experience, language)) %>%
     mutate(group = factor(
                 group, 
                 levels = c(1:6, languages), 
                 labels = c(experiences, languages)
             )) %>%
     mutate(acceptance_rate = accepted / shown) %>%
     subset(!is.na(acceptance_rate) & !is.na(aggregate_productivity)) %>%
     group_by(group) %>%
     mutate(cor = cor(acceptance_rate, aggregate_productivity)) %>%
     ungroup %>% 
     (function(df) {
         # output some data to use
         # cors
        df %>% group_by(group) %>% summarize(cor = cor.test(acceptance_rate, aggregate_productivity)$p.value, n = n()) %>% print
         # how many are outside of the range of acceptance rate > .5 that's shown?
         df %>% with(acceptance_rate <= 0.5) %>% table %>% print
         df
     }) %>%
     ggplot +
     facet_wrap(~ ifelse(is.na(programming_experience), "language", "experience")) +
     geom_smooth(aes(x = acceptance_rate, y = aggregate_productivity, 
                     color = group, group = group,
                     weight = shown),
                 method = stats::lm,
                 fullrange = TRUE,
                 se = FALSE) +
     scale_color_manual("experience", values = colours, breaks = experiences,
         guide = guide_legend(override.aes = list(size = 2, linetype = 1))) +
     new_scale_color() +
     scale_color_manual("language", values = colours, breaks = languages,
         guide = guide_legend(override.aes = list(size = 2, linetype = 1))) +
     # same but formula is 1 to give averages, and make it a dashed line
     geom_smooth(aes(x = acceptance_rate, y = aggregate_productivity,
                     color = group, group = group,
                     weight = shown),
                method = stats::lm,
                 se = FALSE,
                 formula = y ~ 1,
                 fullrange = TRUE,
                 size = .5,
                 linetype = "dashed") +
     geom_segment(
         data = function(df) df %>%
             group_by(group, language, programming_experience) %>% 
             summarize(acceptance_rate = weighted.mean(acceptance_rate, shown)) %>%
             ungroup,
         aes(x = acceptance_rate, xend = acceptance_rate, y = -Inf, yend = Inf, col = group),
         linetype = "dashed", size = .5
         ) +
    coord_cartesian(ylim = c(3.5, 4.4), xlim = c(0, .5)) +
     xlab("acceptance rate") + ylab("aggregate productivity") +
     theme_github(18)
save_plot(fname="single_groups_white.png")
