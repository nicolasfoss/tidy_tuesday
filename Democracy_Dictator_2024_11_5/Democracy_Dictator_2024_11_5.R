################################################################################
### Democracy or Dictator? #####################################################
### Plotting script for Tidy Tuesday Week 45 2024-11-05 ########################
################################################################################

###_____________________________________________________________________________
### Setup: packages, custom functions
###_____________________________________________________________________________

# working dir

setwd("C:/Users/ndfos/Documents/tidy_tuesday/Democracy_Dictator_2024_11_5/")

# gets a vector a package names and loads some cool functions I created for my work
rstudioapi::jobRunScript(path = "C:/Users/ndfos/Documents/custom functions/custom_functions.R",
                         name = "Install/Load Packages, and Get Custom Functions in the Global Environment",
                         workingDir = "C:/Users/ndfos/Documents/tidy_tuesday/Democracy_Dictator_2024_11_5/",
                         exportEnv = "R_GlobalEnv"
                         )

# load packages
# here that is tidyverse, ggplot2, 
sapply(packages, library, character.only = TRUE, quietly = TRUE)

# preferences
conflict_preferences_set()

# load tidytuesdayR
#library(tidytuesdayR) for the data!
#library(fontawesome) # for some icons
#library(showtext) fonts look GREAT
#library(sysfonts) for some helper functions
#library(ggtext)

###_____________________________________________________________________________
### Set up a cool caption!
### Check out Nicola Rennie's post here for more info
### https://nrennie.rbind.io/blog/adding-social-media-icons-ggplot2/
###_____________________________________________________________________________

# You may need to run this to get the font awesome 6 brands font
# you can also download the fonts from
# https://fontawesome.com/download
# and add them directly to your C:\Windows\Fonts folder

sysfonts::font_add(family = "Font Awesome 6 Brands",
                   regular = "C:/Users/ndfos/Documents/fontawesome-free-6.6.0-desktop/otfs/Font Awesome 6 Brands-Regular-400.otf")

# activate showtext for RStudio
showtext_auto()

showtext_opts(dpi = 300)

###_____________________________________________________________________________
# Nicola Rennie gave me this idea!  
# get your icons from https://fontawesome.com/icons
###_____________________________________________________________________________

# LinkedIn icon
linkedin_icon <- "&#xf08c"
linkedin_user <- "nicolas-foss"

# Github
github_icon <- "&#xf09b"
github_user <- "nicolasfoss"

# make a cool caption!

social_caption <- glue::glue("<span style='font-family:\"Font Awesome 6 Brands\";'>&#xf08c;</span> <span style='color: #03617A;'>{linkedin_user}</span> &nbsp;|&nbsp; <span style='font-family:\"Font Awesome 6 Brands\";'>&#xf09b;</span> <span style='color: #03617A;'>{github_user}</span>")


###_____________________________________________________________________________
### Load data and pre-processing
###_____________________________________________________________________________

# load
tuesdata <- tidytuesdayR::tt_load('2024-11-05')

# get the data into memory
democracy_data <- tuesdata$democracy_data

# filter down to the year 2020 to see most recent trends
democracy_data_2020 <- democracy_data %>% 
  filter(year == 2020) %>%
  mutate(regime_category = replace_na(regime_category, "Not Documented"),
    regime_group = case_when(
      regime_category %in% "Not Documented" ~ "Not Documented (1)",
      regime_category %in% c(
        "Parliamentary democracy",
        "Presidential democracy",
        "Mixed democratic"
      ) ~ "Democracies (115)",
      regime_category %in% c(
        "Civilian dictatorship",
        "Military dictatorship",
        "Royal dictatorship"
      ) ~ "Dictatorships (76)",
      TRUE ~ "Territories/Dependencies (16)"
    ),
  )

###_____________________________________________________________________________
### EDA
###_____________________________________________________________________________

# how many different regime types are there?

democracy_counts_2020 <- democracy_data_2020 %>% 
  count(regime_category, sort = T)

# plot # countries by regime category

count_plot <- democracy_counts_2020 %>%
  # deal with a few long regime names and a missing category for Suriname
  mutate(
    regime_category = if_else(is.na(regime_category), "Unknown", regime_category),
    regime_category = str_wrap(regime_category, width = 50)
  ) %>%
  ggplot(aes(
    x = reorder(regime_category, n),
    y = n,
    fill = n,
    label = n
  )) +
  geom_col(color = "transparent", width = 0.5) +
  coord_flip() +
  labs(
    x = "Regime Category",
    y = "# of Countries",
    title = "Number of Countries per Regime Category",
    subtitle = "Year: 2020 | Data: Xavier Marquez Democracy and Dictatorship Dataset",
    caption = social_caption
  ) +
  geom_text(
    family = "Work Sans",
    fontface = "bold",
    color = "darkslategray",
    size = 8,
    nudge_y = if_else(democracy_counts_2020$n > 10, 2, 1)
  ) +
  scale_fill_paletteer_c(palette = "ggthemes::Orange-Blue Diverging", direction = -1) +
  # my custom theme, builds on theme_minimal()
  theme_cleaner(
    base_color = "darkslategray",
    base_size = 15,
    title_text_size = 20,
    subtitle_text_size = 18,
    base_family = "Work Sans",
    vjust_title = 1.75,
    vjust_subtitle = 1,
    legend_position = "inside",
    legend.position.inside = c(0.5, 0.25)
  ) +
  theme(
    axis.text.x = element_blank(),
    axis.title.x = element_blank(),
    axis.title.y = element_blank(),
    plot.caption = element_textbox_simple()
  )

ggsave(filename = "democracy_count_plot.png", plot = count_plot, path = getwd(), width = 8 * (16/9), height = 8, units = "in", dpi = 300)

###_____________________________________________________________________________
### Use the tigris package to create a map of countries colored by regime
### 
###_____________________________________________________________________________

library(sf)
library(rnaturalearth)
library(rnaturalearthdata)

# Load the world map shapefile
world <- ne_countries(scale = "medium", returnclass = "sf")

# Join democracy data to world shapefile on country codes
world_democracy <- world %>%
  left_join(democracy_data_2020, by = c("iso_a3" = "country_code")) %>% 
  mutate(regime_group = replace_na(regime_group, "Not in Data"),
         regime_group = factor(regime_group, levels = c("Democracies (115)", "Dictatorships (76)", "Territories/Dependencies (16)", "Not Documented (1)", "Not in Data"))
         )

# get counts of regime groups
world_democracy %>% 
  count(regime_group, sort = T)

# Plot the map with regime categories
world_democracy_map <- ggplot(data = world_democracy) +
  geom_sf(aes(fill = regime_group), color = "darkgray") +
  labs(title = "Power and People: Examining the World's Political Regimes",
       subtitle = "Data: Xavier Marquez Democracy and Dictatorship Dataset",
       caption = social_caption,
       fill = "Regime Category (count)") +
  theme_cleaner(base_size = 12,
                base_color = "darkslategray", 
                title_text_size = 20,
                subtitle_text_size = 18,
                base_family = "Work Sans"
                ) + 
  scale_fill_manual(
    values = c(
      "Democracies (115)" = "#377EB8",
      "Dictatorships (76)" = "#FF7F00",
      "Territories/Dependencies (16)" = "#4DAF4A",
      "Not Documented (1)" = "#999999",
      "Not in Data" = "#333333"
    )
  ) +  
  theme(legend.position = "inside",
        legend.position.inside = c(0.20, 0.35),
        plot.caption = element_textbox_simple(size = 15),
        panel.background = element_rect(fill = "lightblue", color = NA),
        plot.background = element_rect(fill = "lightblue", color = NA)
        )

# save!
ggsave(
  filename = "world_democracy_map.png",
  plot = world_democracy_map,
  path = getwd(),
  width = 8 * (16 / 9),
  height = 8,
  units = "in",
  dpi = 300
)

