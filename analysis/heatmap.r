library(tidyverse)
library(pls)
source("analysis/gh_theme.R")
source("analysis/variables.R")

heatmap_data <- read.csv('data_telemetry/survey_telemetry_merged_cleaned.csv')

df_to_norm <- function(df) df %>% mutate_all(function(x) (x-mean(x, na.rm = T)) / sd(x, na.rm = T))

main_metrics %in% colnames(heatmap_data) %>% all %>% stopifnot
survey_questions %in% colnames(heatmap_data) %>% all %>% stopifnot
aggregate_metric %in% colnames(heatmap_data) %>% all %>% stopifnot

cor_matrix <- heatmap_data[, c(
    main_metrics # behaviour
    , survey_questions # productivity metrics
    , aggregate_metric # aggregate prod metric
    )] %>%
    df_to_norm %>%
    cor(use = "pairwise")

p_values <-
    heatmap_data[, c(
    main_metrics # behaviour
    , survey_questions # productivity metrics
    , aggregate_metric # aggregate prod metric
    )] %>%
    (function(df)
        expand.grid(Var1 = colnames(df), Var2 = colnames(df)) %>%
        mutate(p_value = mapply(function(Var1, Var2) cor.test(df[,Var1], df[,Var2])$p.value, 
                                Var1, Var2),
               r_value =  mapply(function(Var1, Var2) cor.test(df[,Var1], df[,Var2])$estimate, 
                                Var1, Var2)))

idc <- cor_matrix %>%
    heatmap(symm = T, col = c("blue", "red", "purple")) %>%
    with(colInd)
idc2 <- c(idc[idc > length(main_metrics)], idc[idc <= length(main_metrics)]) # keep the behaviour and productivity metrics together
idc3 <- c(idc2[1:20], idc2[27:35], idc2[26:21]) # pull out the block with acceptance rate 21:26
cor_matrix[idc3, idc3] %>% colnames



cor_matrix[idc3, idc3] %>%
    (reshape2::melt) %>%
    mutate(Var1 = factor(Var1, levels = Var1 %>% unique),
           Var2 = factor(Var2, levels = Var2 %>% unique)) %>%
    subset(paste0(Var1, Var2) %in% (
        p_values %>%
        subset(p_value < 0.05) %>%
        with(paste0(Var1, Var2))
        %>% unique
        )) %>%
ggplot +
    geom_tile(aes(x = Var1, y = Var2, fill = value)) +
    xlab("") + ylab("") +
    scale_fill_gradientn(
        name = "Spearman\ncorrelation",
        #values = c(0, .05, .2, .4, .6, .8, 1),
        #colors = github_colors("red_200", "red_400", "purple_400", "blue_400", "blue_300", "blue_200", "blue_100") %>% unname) +
        #colors = github_colors("green_200", "blue_200", "purple_400", "red_400", "red_300", "red_200", "red_100") %>% unname) +
        colors = github_colors("yellow_200", "red_400", "purple_400", "blue_400", "blue_300", "blue_200", "blue_100") %>% unname) +
    theme_github_black(20) +
    theme(axis.text.x = element_text(angle = 270, hjust = 1,
            face = c("bold", rep("plain", 33), "bold")),
            axis.text.y = element_text(face = c("bold", rep("plain", 33), "bold"))) +    
    coord_fixed()
save_plot(w=510*2, h=480*2)



cor_matrix[idc3, idc3] %>%
    (reshape2::melt) %>%
    mutate(Var1 = factor(Var1, levels = Var1 %>% unique),
           Var2 = factor(Var2, levels = Var2 %>% unique)) %>%
    subset(paste0(Var1, Var2) %in% (
        p_values %>%
        subset(p_value < 0.05) %>%
        with(paste0(Var1, Var2))
        %>% unique
        )) %>%
ggplot +
    geom_tile(aes(x = Var1, y = Var2, fill = value)) +
    xlab("") + ylab("") +
    scale_fill_gradientn(
        name = "Spearman\ncorrelation",
        #values = c(0, .05, .2, .4, .6, .8, 1),
        #colors = github_colors("red_200", "red_400", "purple_400", "blue_400", "blue_300", "blue_200", "blue_100") %>% unname) +
        #colors = github_colors("green_200", "blue_200", "purple_400", "red_400", "red_300", "red_200", "red_100") %>% unname) +
        colors = github_colors("yellow_200", "red_400", "purple_400", "blue_400", "blue_300", "blue_100", "white") %>% unname) +
    theme_github(20) + 
    theme(panel.grid = element_line(colour = github_colors("gray_400")), 
          panel.background = element_rect(fill = github_colors("gray_300"))) +
    theme(axis.text.x = element_text(angle = 270, hjust = 1,
            face = c("bold", rep("plain", 33), "bold")),
            axis.text.y = element_text(face = c("bold", rep("plain", 33), "bold"))) +    
    coord_fixed()
save_plot(fname = "heatmap_white.png", w=510*2, h=480*2)
