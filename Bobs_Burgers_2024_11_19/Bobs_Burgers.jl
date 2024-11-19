################################################################################
### Bob's Burgers Analysis!  ###################################################
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