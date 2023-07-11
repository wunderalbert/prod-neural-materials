###### Colors #####
# according to https://styleguide.github.com/primer/support/color-system/#color-palette

github_colors <- function(...){
  github_colors <- c(
    black = "#1b1f23",  white = "#ffffff",  
    blue = "#005cc5", gray = "#586069", green = "#22863a", orange = "#e36209", purple = "#5a32a3", red = "#cb2431", yellow = "#f9c513",
    blue_000 = "#dbedff",  blue_100 = "#c8e1ff",  blue_200 = "#79b8ff",  blue_300 = "#2188ff",  blue_400 = "#0366d6",  blue_500 = "#005cc5",  blue_600 = "#044289",  blue_700 = "#032f62",  blue_800 = "#05264c",  
    gray_000 = "#f6f8fa",  gray_100 = "#e1e4e8",  gray_200 = "#d1d5da",  gray_300 = "#959da5",  gray_400 = "#6a737d",  gray_500 = "#586069",  gray_600 = "#444d56",  gray_700 = "#2f363d",  gray_800 = "#24292e",  
    green_000 = "#dcffe4",  green_100 = "#bef5cb",  green_200 = "#85e89d",  green_300 = "#34d058",  green_400 = "#28a745",  green_500 = "#22863a",  green_600 = "#176f2c",  green_700 = "#165c26",  green_800 = "#144620",  
    orange_000 = "#ffebda",  orange_100 = "#ffd1ac",  orange_200 = "#ffab70",  orange_300 = "#fb8532",  orange_400 = "#f66a0a",  orange_500 = "#e36209",  orange_600 = "#d15704",  orange_700 = "#c24e00",  orange_800 = "#a04100",  
    purple_000 = "#e6dcfd",  purple_100 = "#d1bcf9",  purple_200 = "#b392f0",  purple_300 = "#8a63d2",  purple_400 = "#6f42c1",  purple_500 = "#5a32a3",  purple_600 = "#4c2889",  purple_700 = "#3a1d6e",  purple_800 = "#29134e",  
    red_000 = "#ffdce0",  red_100 = "#fdaeb7",  red_200 = "#f97583",  red_300 = "#ea4a5a",  red_400 = "#d73a49",  red_500 = "#cb2431",  red_600 = "#b31d28",  red_700 = "#9e1c23",  red_800 = "#86181d",  
    yellow_000 = "#fffbdd",  yellow_100 = "#fff5b1",  yellow_200 = "#ffea7f",  yellow_300 = "#ffdf5d",  yellow_400 = "#ffd33d",  yellow_500 = "#f9c513",  yellow_600 = "#dbab09",  yellow_700 = "#b08800",  yellow_800 = "#735c0f"
  )
  
  colors <- c(...) %>% 
    str_replace("-", "_")
  
  if (length(colors) == 0)
    return(github_colors)
  
  github_colors[colors]
}

show_github_colors <- function(...){
  cols = c(...)
  github_colors(cols) %>%
    as.data.frame(stringsAsFactors = FALSE) %>%
    `colnames<-`("hex") %>%
    (function(x) {x$name <- rownames(x); x}) %>%
    mutate(primary = ifelse(name %>% str_detect("_"),
                            name %>% str_extract(".*_") %>% str_sub(1, -2),
                            name),
           light = name %>% str_extract("_.*") %>% str_sub(2) %>% as.double) %>%
    arrange(desc(light)) %>%
    mutate(hex = hex %>% factor(levels = unique(hex)),
           light = light %>% factor(levels = unique(light) %>% c(NA) %>% rev)) %>%
    ggplot + 
    geom_tile(aes(x = primary, 
                  y = light, 
                  fill = hex)) +
    geom_text(aes(x = primary, 
                  y = light,
                  label = name)) +
    scale_fill_identity(guide = "none") +
    theme(panel.background = element_rect(fill = NA), 
          axis.ticks = element_line(color = NA))
}


##### Palettes ######

github_palette_space <- list(
  `bold_first` = github_colors("red", "blue", "blue_300", "blue_200"),
  `subdued_first` = github_colors("red_300", "blue_400", "blue_300", "blue_200"),
  `bold_blues` = github_colors("blue", "blue_300"),
  `subdued_blues` = github_colors("blue_400", "blue_300", "blue_200"),
  `bold_rainbow` = github_colors("red", "purple", "blue", "green", "yellow", "orange"),
  `subdued_rainbow` = github_colors("red_300", "purple_300", "blue_300", "green_300", "yellow_300", "orange_300")
)

github_palette <- function(kind = c("rainbow", "max", "blues", "first"),
                           style = c("subdued", "bold"), 
                           reverse = FALSE, ...) {
  kind <- match.arg(kind)
  style <- match.arg(style)
  
  palette <- github_palette_space[[paste(style, 
                                         switch(kind,
                                                rainbow = "rainbow",
                                                max = "rainbow",
                                                blues = "blues",
                                                first = "first"), 
                                         sep = "_")]]
  
  maybe_reverse <- if (reverse) rev else I
  
  switch(kind,
         first = function(n) c(palette[1], 
                               colorRampPalette(palette %>% tail(-1), ...)(n-1)) %>% unname %>% maybe_reverse,
         max = colorRampPalette(palette %>% maybe_reverse, ...),
         blues = colorRampPalette(palette %>% maybe_reverse, ...),
         rainbow = function(n) colorRampPalette(palette %>% head(n) %>% maybe_reverse, ...)(n))
}


##### Themes #######

theme_github <- function(base_size = 15, style = "subdued") {
  half_line <- base_size / 2
  theme(text = element_text(size = base_size, color = github_colors("black")),
        strip.background = element_rect(fill = github_colors("gray_200"), colour = NA), 
        strip.text = element_text(colour = github_colors("black"), 
                                  size = rel(0.8), 
                                  margin = margin(0.8 * half_line, 0.8 * half_line, 0.8 * half_line, 0.8 * half_line)),
        panel.background = element_rect(fill = github_colors("grey_100"), color = NA))
}

theme_github_no_background <- function(base_size = 11, style = "subdued"){
  theme_void(base_size = base_size) +
    theme_github(base_size = base_size)
}

theme_github_black <- function(base_size = 15, style = "subdued") {
  half_line <- base_size / 2
  theme_dark(base_size = base_size) +
  theme(rect = element_rect(fill = "black"), 
        text = element_text(size = base_size, colour = github_colors("gray_200")),
        line = element_line(colour = github_colors("gray_300")),
        strip.background = element_rect(fill = github_colors("gray_300"), colour = NA), 
        strip.text = element_text(colour = github_colors("black"), 
                                  size = rel(0.8), 
                                  margin = margin(0.8 * half_line, 0.8 * half_line, 0.8 * half_line, 0.8 * half_line)),
        axis.line = element_line(colour = github_colors("gray_300")),
        panel.grid = element_line(colour = github_colors("gray_300")),
        axis.ticks = element_line(colour = github_colors("gray_300")), 
        axis.text = element_text(size = base_size, colour = github_colors("gray_300")),
        legend.key = element_rect(fill=github_colors("gray_700")),
        panel.background = element_rect(fill = github_colors("grey_100"), color = NA)
  )
}


theme_trans <- theme(
        panel.background = element_rect(fill = "transparent"), # bg of the panel
    plot.background = element_rect(fill = "transparent", color = NA), # bg of the plot
    panel.grid.major = element_blank(), # get rid of major grid
    panel.grid.minor = element_blank(), # get rid of minor grid
    legend.background = element_rect(fill = "transparent"), # get rid of legend bg
    legend.box.background = element_rect(fill = "transparent") # get rid of legend panel bg
    )