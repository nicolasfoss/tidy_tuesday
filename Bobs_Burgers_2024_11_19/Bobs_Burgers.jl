################################################################################
### Bob's Burgers Analysis!  ###################################################
### Week 47 - 2024-11-19     ###################################################
################################################################################

# Pkg
using Pkg

# packages
Pkg.add(["DataFrames", "CSV", "HTTP", "Statistics", "StatsPlots", "Plots", "DataFramesMeta",
    "Chain", "CategoricalArrays", "Measures", "PlotThemes", "Dates"
])

# load
using DataFrames, CSV, HTTP, Statistics, StatsPlots, Plots, DataFramesMeta, Chain, CategoricalArrays, Measures, PlotThemes, Dates

# get data
# read directly from GitHub

# Load the dataset
url = "https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2024/2024-11-19/episode_metrics.csv"

# file
response = HTTP.get(url)

# import
episode_metrics = CSV.read(response.body, DataFrame)

# inspect the data

describe(episode_metrics)

###_____________________________________________________________________________
### It might be interesting to see the episodes as an integer from 1:272
### in order to get a sort of time element without joining 
###_____________________________________________________________________________

episode_metrics_time = @chain episode_metrics begin
    @transform(:episode_number = 1:nrow(episode_metrics)) # Add a new column with sequential numbers
end

###_____________________________________________________________________________
### Let's examine dialogue density over time from Bob's Burgers
###_____________________________________________________________________________

# plot theme
theme(:gruvbox_light)  # Apply gruvbox theme

# pivot the dataframe longer using the exclamation and question mark fields

episode_metrics_pivot = @chain begin episode_metrics_time
    stack([:question_ratio, :exclamation_ratio])
end

# use a line plot to show the prevalence of excitement or throught provoking
# questions in Bob's Burgers over time

questions_or_exclamations_plot = @df episode_metrics_pivot plot(
    :episode_number,
    :value,
    group = :variable,
    grid = false,
    legend_position = :outsidetopright,
    legend_title = "Punctuation",
    title="Question Marks vs. Exclamation Points: The Battle of Bob's Burgers Dialogue!",

)