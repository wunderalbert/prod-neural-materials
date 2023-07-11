library(tidyverse)
library(lubridate)
source("analysis/telemetry/gh_theme.R")
save_plot <- function(w = 720, h = 480, fname = "~/plt.png"){
    dev.copy(device = png, file = fname, width = w, height = h, units = "px", bg = "transparent")
    dev.off()
}

demo_data <- data.frame(
    question = c(
        "Think of the language\nyou have used the\nmost with OurTool. How\nproficient are you\nin that language?" %>% rep(4),
        "Which best describes\nyour programming\nexperience?" %>% rep(7),
        "Which of the following\nbest describes\nwhat you do?" %>% rep(7),
        "What programming\nlanguages do you\nusually use?\nChoose up to three\nfrom the list" %>% rep(10)),
    answer = c(
        "Beginner", "Intermediate", "Advanced",
        "",
        "Student / Learning", "0-2 Years Prof. Experience", "3-5 Years Prof. Experience",
        "6-10 Years Prof. Experience", "11-15 Years Prof. Experience", "16+ Years Prof. Experience",
        " ",
        "Student", "Professional", "Hobbyist", "Consultant/Freelancer", "Researcher", "Other ",
        "  ",
        "Python", "JavaScript", "TypeScript", "Java", "Ruby", "Go", "C#", "Rust", "Html", "Other"),
    count = c(132, 1043, 872, 0, 396, 539, 421, 284, 181, 226, 0, 701, 1029, 168, 71, 38, 39, 0, 953, 1405, 786, 291, 103, 173, 244, 84, 729, 605)) %>%
    mutate(answer = factor(answer, levels = answer %>% unique %>% c("Other") %>% rev %>% unique %>% rev),
           question = factor(question, levels = question %>% unique %>% rev))

cols <- github_colors("red_200", "orange_200", "yellow_200", "green_200", "blue_200", "purple_200", "red_400", "orange_400", "green_400", "grey_200") %>% unname
cols <- github_colors("red_200", "purple_200", "blue_200", "green_200", "yellow_200", "orange_200", "red_400", "purple_400", "blue_400", "grey_200") %>% unname

demo_data %>%
    ggplot + 
    geom_col(aes(x = question, y = count, fill = answer), position = "fill") + 
    scale_fill_manual("", values = c(
        cols[1:3], "black", cols[1:6], "black", cols[1:5], github_colors("grey_200"), "black", cols) %>% unname) +
    scale_y_continuous("", labels = scales::percent) +
    xlab("") +
    theme_github_black(15) +
    guides(fill=guide_legend(ncol=1)) +
    coord_flip()
save_plot(fname="survey_demographics.png", h = 560)

demo_data %>% group_by(question) %>% summarize(sum(count))




demo_data %>%
    ggplot + 
    geom_col(aes(x = question, y = count, fill = answer), position = "fill") + 
    scale_fill_manual("", values = c(
        cols[1:3], "white", cols[1:6], "white", cols[1:5], github_colors("grey_200"), "white", cols) %>% unname) +
    scale_y_continuous("", labels = scales::percent) +
    xlab("") +
    theme_github(18) + theme(panel.grid = element_line(colour = github_colors("gray_100"))) +
    guides(fill=guide_legend(ncol=1, override.aes = list(col = "white"))) +
    coord_flip()
save_plot(fname="survey_demographics_white.png", h = 560)
