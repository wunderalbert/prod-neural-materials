library(tidyverse)
library(lubridate)
source("analysis/gh_theme.R")
save_plot <- function(w = 720, h = 480, fname = "~/plt.png"){
    dev.copy(device = png, file = fname, width = w, height = h, units = "px", bg = "transparent")
    dev.off()
}


# Load data
data_cleaned <- read.csv('data/survey_telemetry_merged_cleaned.csv')
activity_data <- read.csv("data/summary_by_id.csv")

activity_data %>% summarize(sum(n_acc) / sum(n_shown))
data_cleaned %>% head
data_cleaned %>% nrow

activity_data %>% nrow
data_cleaned$copilot_trackingId %>% table %>% table

double_ids <- survey_data %>% group_by(copilot_trackingId) %>% summarize(n = n()) %>% filter(n > 1) %>% with(copilot_trackingId) %>% sort %>% tail(-1)
survey_data %>% subset(copilot_trackingId %in% double_ids) %>% select(copilot_trackingId, Respondent.ID, Group, Start.Date, End.Date)
survey_data %>% colnames

doubles <- survey_data %>% subset(copilot_trackingId %in% double_ids)
doubles %>% arrange(copilot_trackingId, Start.Date) %>% write.csv("data/doubles.csv")
# %>% select(Start.Date, Which.of.the.following.best.describes.what.you.do., X, X.1, X.2, X.3, X.4, X.5, X.6, X.7, X.8, X.9, X.10, X.11, X.12, X.13)


data_cleaned[data_cleaned$copilot_trackingId %in% double_ids,] %>%
select(What.programming.languages.do.you.usually.use..Choose.up.to.three.from.the.list.TypeScript, copilot_trackingId)

data_cleaned[data_cleaned$copilot_trackingId %in% double_ids,] %>%
select(What.programming.languages.do.you.usually.use..Choose.up.to.three.from.the.list.Java, copilot_trackingId)




# Upper and lower half:
data_cleaned %>% 
    subset(!is.na(copilot_productivity)) %>%
    group_by(quartile = ntile(copilot_productivity, 4)) %>%
    summarize(mean(pct_acc, na.rm = T), rate = sum(pct_acc * n_shown, na.rm = T) / sum(n_shown), sum(n_shown), n()) %>%
    print %>%
    ggplot(aes(x = quartile, y = rate, fill = quartile)) +
    #geom_point(pch = "x", size = 5) + geom_line() +
    geom_col() +
    scale_x_reverse("Quartile for perceived productivity benefit", breaks = 1:4, labels = c(
        `1` = "0 - 25% of users with\nleast productivity gain",
        `2` = "25% of users with\nlow productivity gain",
        `3` = "25% of users with\nhigh productivity gain",
        `4` = "25% of users with\nhighest productivity gain"
    )) +
    scale_y_continuous("% of shown suggestions\nthat were accepted", labels = scales::percent, limits = c(0, NA)) +
    coord_flip()

