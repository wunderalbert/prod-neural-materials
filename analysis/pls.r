library(tidyverse)
library(pls)
source("analysis/gh_theme.R")
source("analysis/variables.R")

pls_data <- read.csv('data_telemetry/survey_telemetry_merged_cleaned.csv')
pls_data %>% head
(pls_data %>% colnames)[c(2:24)] # includes n_shown
(pls_data %>% colnames)[c(69:80)] 
(pls_data %>% colnames)

df_to_norm_matrix <- function(df) df %>% mutate_all(function(x) (x-mean(x, na.rm = T)) / sd(x, na.rm = T)) %>% as.matrix

X = pls_data[,main_metrics] %>% df_to_norm_matrix
Y = pls_data$aggregate_productivity   # main comp
# Y = pls_data[,69:80] %>% df_to_norm_matrix # neutral imputed
#Y = pls_data[,80:91] %>% df_to_norm_matrix # median imputed
pls1 <- plsr(Y ~ X)

summary(pls1)
pls1$coefficients[,1,1:2] # coefficients
explvar(pls1) # explained variance

pls1$coefficients[,1,1:2] %>% round(4) %>% as.data.frame %>%
    mutate(paste0("& ", `1 comps`, " & ", `2 comps`))

data.frame(name = names(pls1$coefficients[,1,1] %>% sort(decreasing = F)),
           value = - pls1$coefficients[,1,1] %>% sort(decreasing = F), 
           row.names = NULL) %>%
    arrange(value) %>% 
    print %>%
    mutate(name = factor(name, levels = unique(name))) %>%
    ggplot + 
    geom_col(aes(x = name, y = value)) +
    coord_flip() +
    xlab("How much it matters according to PLS") + ylab("")


data.frame(name = names(pls1$coefficients[,1,1]),
           comp1 = pls1$coefficients[,1,1],
           comp2 = pls1$coefficients[,1,2],
           row.names = NULL) %>% 
    arrange(comp1) %>% 
    mutate(name = factor(name, levels = unique(name))) %>%
    group_by(name) %>%
    summarize(comp1 = c(0, comp1), comp2 = c(0, comp2)) %>%
    arrange(-comp2) %>%
    as.data.frame %>% 
    print %>%
    mutate(metric = case_when(
        name == "accepted_per_shown" ~ "acceptance rate",
        str_detect(name, "accepted_per") ~ "acceptance frequency",
        name == "accepted_char_per_active_hour" ~ "amount contribution (char)",
        str_detect(name, "^unchanged.*accepted") ~ "persistence rate",
        str_detect(name, "^unchanged.*") ~ "flawless suggestion frequency",
        str_detect(name, "^mostly_unchanged.*accepted") ~ "fuzzy persistence rate",
        str_detect(name, "^shown$") ~ "shown overall",
        str_detect(name, "shown_per") ~ "shown rate",
        TRUE ~ "other")) %>%
    mutate(metric = factor(metric, levels = unique(c(
        "acceptance rate", "acceptance frequency", "amount contribution (char)", "flawless suggestion frequency", "persistence rate", "fuzzy persistence rate", "shown overall", "shown rate", "other")))) %>%
    arrange(abs(comp1) + abs(comp2)) %>%
    print %>%
    ggplot + 
    geom_path(aes(x = comp1, y = comp2, group = name, col = metric), arrow = arrow()) +
    xlab("projection on first latent structure") + 
    ylab("projection on second latent structure") +
    scale_color_manual("metric", values = github_colors("yellow_200", "orange_200", "red_200", "purple_200", "blue_400", "blue_200", "green_400", "green_200") %>% unname) +
    theme_github_black(15)
save_plot(fname="pls.png")



data.frame(name = names(pls1$coefficients[,1,1]),
           comp1 = pls1$coefficients[,1,1],
           comp2 = pls1$coefficients[,1,2],
           row.names = NULL) %>% 
    arrange(comp1) %>% 
    mutate(name = factor(name, levels = unique(name))) %>%
    group_by(name) %>%
    summarize(comp1 = c(0, comp1), comp2 = c(0, comp2)) %>%
    arrange(-comp2) %>%
    as.data.frame %>% 
    print %>%
    mutate(metric = case_when(
        name == "accepted_per_shown" ~ "acceptance rate",
        str_detect(name, "accepted_per") ~ "acceptance frequency",
        name == "accepted_char_per_active_hour" ~ "amount contribution (char)",
        str_detect(name, "^unchanged.*accepted") ~ "persistence rate",
        str_detect(name, "^unchanged.*") ~ "flawless suggestion frequency",
        str_detect(name, "^mostly_unchanged.*accepted") ~ "fuzzy persistence rate",
        str_detect(name, "^shown$") ~ "shown overall",
        str_detect(name, "shown_per") ~ "shown rate",
        TRUE ~ "other")) %>%
    mutate(metric = factor(metric, levels = unique(c(
        "acceptance rate", "acceptance frequency", "amount contribution (char)", "flawless suggestion frequency", "persistence rate", "fuzzy persistence rate", "shown overall", "shown rate", "other")))) %>%
    arrange(abs(comp1) + abs(comp2)) %>%
    print %>%
    ggplot + 
    geom_path(aes(x = comp1, y = comp2, group = name, col = metric), arrow = arrow()) +
    xlab("projection on first latent structure") + 
    ylab("projection on second latent structure") +
    scale_color_manual("metric", values = github_colors("red_200", "orange_200", "yellow_300", "purple_200", "blue_400", "blue_200", "green_400", "green_200") %>% unname) +
    theme_github(18) + theme(panel.grid = element_line(colour = github_colors("gray_100")))
save_plot(fname="pls_white.png")




X = pls_data[c(2:23)] %>% df_to_norm_matrix
Y = pls_data[,69:80] %>% df_to_norm_matrix # neutral imputed
pls2 <- plsr(Y ~ X)

summary(pls2)
pls2$coefficients[,1,1:2] # coefficients
pls2$coefficients[,2,1:2] # coefficients

pls2$loadings[,1:2]

explvar(pls2) # explained variance




data.frame(name = names(pls1$coefficients[,1,1] %>% sort(decreasing = F)),
           value = - pls1$coefficients[,1,1] %>% sort(decreasing = F), 
           row.names = NULL) %>%
    arrange(value) %>% 
    print %>%
    mutate(name = factor(name, levels = unique(name))) %>%
    ggplot + 
    geom_col(aes(x = name, y = value)) +
    coord_flip() +
    xlab("How much it matters according to PLS") + ylab("")


data.frame(name = names(pls2$loadings[,1]),
           comp1 = pls2$loadings[,1],
           comp2 = pls2$loadings[,2],
           row.names = NULL) %>% 
    arrange(comp1) %>% 
    mutate(name = factor(name, levels = unique(name))) %>%
    group_by(name) %>%
    summarize(comp1 = c(0, comp1), comp2 = c(0, comp2)) %>%
    arrange(-comp2) %>%
    as.data.frame %>% 
    print %>%
    mutate(metric = case_when(
        name == "pct_acc" ~ "acceptance rate",
        str_detect(name, "pct_unchanged.*issued") ~ "flawless suggestions",
        str_detect(name, "pct_unchanged") ~ "persistence rate",
        str_detect(name, "pct_mostly_unchanged") ~ "fuzzy persistence rate",
        str_detect(name, "n_shown") ~ "n_shown",
        TRUE ~ "other")) %>%
    mutate(metric = factor(metric, levels = unique(metric))) %>%
    arrange(abs(comp1) + abs(comp2)) %>%
    print %>%
    ggplot + 
    geom_path(aes(x = comp1, y = comp2, group = name, col = metric), arrow = arrow()) +
    xlab("projection on first latent structure") + 
    ylab("projection on second latent structure") +
    scale_color_manual("metric", values = github_colors("yellow_200", "orange_200", "red_200", "purple_200", "blue_200", "green_200") %>% unname) +
    theme_github_black(15)
save_plot()

data.frame(name = names(pls2$Yloadings[,1]),
           comp1 = pls2$Yloadings[,1],
           comp2 = pls2$Yloadings[,2],
           row.names = NULL) %>% 
    arrange(comp1) %>% 
    mutate(name = factor(name, levels = unique(name))) %>%
    group_by(name) %>%
    summarize(comp1 = c(0, comp1), comp2 = c(0, comp2)) %>%
    arrange(-comp2) %>%
    as.data.frame %>% 
    print %>%
    mutate(metric = case_when(
        name == "pct_acc" ~ "acceptance rate",
        str_detect(name, "pct_unchanged.*issued") ~ "flawless suggestions",
        str_detect(name, "pct_unchanged") ~ "persistence rate",
        str_detect(name, "pct_mostly_unchanged") ~ "fuzzy persistence rate",
        str_detect(name, "n_shown") ~ "n_shown",
        TRUE ~ "other")) %>%
    mutate(metric = factor(metric, levels = unique(metric))) %>%
    arrange(abs(comp1) + abs(comp2)) %>%
    print %>%
    ggplot + 
    geom_path(aes(x = comp1, y = comp2, group = name, col = name), arrow = arrow()) +
    xlab("projection on first latent structure") + 
    ylab("projection on second latent structure") +
    #scale_color_manual("metric", values = github_colors("yellow_200", "orange_200", "red_200", "purple_200", "blue_200", "green_200") %>% unname) +
    theme_github_black(15)








pls_data <- read.csv('data_telemetry/survey_telemetry_merged_cleaned.csv')
pls_data %>% head
(pls_data %>% colnames)[c(2:56)] # everything
(pls_data %>% colnames)[c(69:80)] 
(pls_data %>% colnames)

df_to_norm_matrix <- function(df) df %>% mutate_all(function(x) (x-mean(x, na.rm = T)) / sd(x, na.rm = T)) %>% as.matrix

X = pls_data[c(2:56)] %>% df_to_norm_matrix
#pls_data[,c(2:23)] %>% df_to_norm_matrix
Y = pls_data$aggregate_productivity   # main comp
# Y = pls_data[,69:80] %>% df_to_norm_matrix # neutral imputed
#Y = pls_data[,80:91] %>% df_to_norm_matrix # median imputed
pls1 <- plsr(Y ~ X)


summary(pls1)
pls1$coefficients[,1,1:2] # coefficients
explvar(pls1) # explained variance

pls1$coefficients[,1,1] %>% round(4) %>% sort

data.frame(name = names(pls1$coefficients[,1,1] %>% sort(decreasing = F)),
           value = - pls1$coefficients[,1,1] %>% sort(decreasing = F), 
           row.names = NULL) %>%
    arrange(value) %>% 
    print %>%
    mutate(name = factor(name, levels = unique(name))) %>%
    ggplot + 
    geom_col(aes(x = name, y = value)) +
    coord_flip() +
    xlab("How much it matters according to PLS") + ylab("")

data.frame(name = names(pls1$coefficients[,1,1]),
           comp1 = pls1$coefficients[,1,1],
           comp2 = pls1$coefficients[,1,2],
           row.names = NULL) %>% 
    arrange(comp1) %>% 
    mutate(name = factor(name, levels = unique(name))) %>%
    group_by(name) %>%
    summarize(comp1 = c(0, comp1), comp2 = c(0, comp2)) %>%
    arrange(-comp2) %>%
    as.data.frame %>% 
    print %>%
    mutate(metric = case_when(
        name == "accepted_per_shown" ~ "acceptance rate",
        str_detect(name, "^unchanged_(.)*_per_opportunity") ~ "flawless suggestions",
        str_detect(name, "^unchanged_(.)*_per_shown") ~ "persistence rate",
        str_detect(name, "mostly_unchanged_(.)*_per_shown") ~ "fuzzy persistence rate",
        str_detect(name, "unchanged_(.)*\\d$") ~ "count of persisted",
        name %in% c("shown", "opportunity", "accepted", "active_hour") ~ "event count",
        str_detect(name, "_per_active_hour") ~ "frequency",
        TRUE ~ "other")) %>%
    mutate(metric = factor(metric, levels = unique(metric))) %>%
    arrange(abs(comp1) + abs(comp2)) %>%
    print %>%
    ggplot + 
    geom_path(aes(x = comp1, y = comp2, group = name, col = metric), arrow = arrow()) +
    xlab("projection on first latent structure") + 
    ylab("projection on second latent structure") +
    scale_color_manual("metric", values = github_colors("yellow_200", "orange_200", "red_200", "purple_200", "blue_200", "green_200", "grey_200", "red_400", "blue_400", "yellow_400") %>% unname) +
    theme_github_black(15)
save_plot()





main_vars = c("accepted_per_shown", "accepted_per_opportunity", "accepted_per_active_hour", "unchanged_30_per_opportunity", 
    "unchanged_30_per_active_hour", "unchanged_120_per_active_hour", "unchanged_120_per_opportunity", "unchanged_300_per_active_hour", 
    "unchanged_300_per_opportunity", "unchanged_600_per_active_hour", "unchanged_600_per_opportunity", "accepted_char_per_active_hour", 
    "shown_per_active_hour", "shown_per_opportunity", "mostly_unchanged_30_per_accepted", "unchanged_30_per_accepted", 
    "mostly_unchanged_120_per_accepted", "unchanged_120_per_accepted", "mostly_unchanged_600_per_accepted",
    "mostly_unchanged_300_per_accepted", "unchanged_300_per_accepted", "shown", "unchanged_600_per_accepted")

X = pls_data[,main_vars] %>% df_to_norm_matrix
main_vars %in% colnames(X) %>% all %>% stopifnot
pls1 <- plsr(Y ~ X)

summary(pls1)
pls1$coefficients[,1,1:2] # coefficients
explvar(pls1) # explained variance

pls1$coefficients[,1,1] %>% round(4) %>% sort

data.frame(name = names(pls1$coefficients[,1,1] %>% sort(decreasing = F)),
           value = - pls1$coefficients[,1,1] %>% sort(decreasing = F), 
           row.names = NULL) %>%
    arrange(value) %>% 
    print %>%
    mutate(name = factor(name, levels = unique(name))) %>%
    ggplot + 
    geom_col(aes(x = name, y = value)) +
    coord_flip() +
    xlab("How much it matters according to PLS") + ylab("")

data.frame(name = names(pls1$coefficients[,1,1]),
           comp1 = pls1$coefficients[,1,1],
           comp2 = pls1$coefficients[,1,2],
           row.names = NULL) %>% 
    arrange(comp1) %>% 
    mutate(name = factor(name, levels = unique(name))) %>%
    group_by(name) %>%
    summarize(comp1 = c(0, comp1), comp2 = c(0, comp2)) %>%
    arrange(-comp2) %>%
    as.data.frame %>% 
    print %>%
    mutate(metric = case_when(
        name == "accepted_per_shown" ~ "acceptance rate",
        name == "accepted_per_active_hour" ~ "acceptance frequency",
        name == "accepted_per_opportunity" ~ "acceptance per opportunity",
        str_detect(name, "^unchanged_.*_per_opportunity") ~ "flawless suggestion rate",
        str_detect(name, "mostly_unchanged_.*_per_.*") ~ "fuzzy persistence rate",
        str_detect(name, "^unchanged_.*_per_active_hour") ~ "persistence frequency",
        str_detect(name, "^unchanged_.*_per_accepted") ~ "persistence rate",
        str_detect(name, "unchanged_(.)*\\d$") ~ "count of persisted",
        name %in% c("shown", "opportunity", "accepted", "active_hour") ~ "event count",
        str_detect(name, "_per_active_hour") ~ "frequency",
        TRUE ~ "other")) %>%
    mutate(metric = factor(metric, levels = unique(metric))) %>%
    arrange(abs(comp1) + abs(comp2)) %>%
    print %>%
    ggplot + 
    geom_path(aes(x = comp1, y = comp2, group = name, col = metric), arrow = arrow()) +
    xlab("projection on first latent structure") + 
    ylab("projection on second latent structure") +
    scale_color_manual("metric", values = github_colors("yellow_200", "orange_200", "red_200", "purple_200", "blue_200", "green_200", "grey_200", "red_400", "blue_400", "yellow_400") %>% unname) +
    theme_github_black(15)
save_plot()

