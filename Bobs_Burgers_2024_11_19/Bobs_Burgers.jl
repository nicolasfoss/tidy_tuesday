################################################################################
### Bob's Burgers Analysis!  ###################################################
### Week 47 - 2024-11-19     ###################################################
################################################################################

# Pkg
using Pkg

# packages
Pkg.add(["DataFrames", "CSV", "HTTP", "Statistics", "StatsPlots", "Plots", "DataFramesMeta",
	"Chain", "PlotThemes", "Dates", "Images",
])

# load
using DataFrames, CSV, HTTP, Statistics, StatsPlots, Plots, DataFramesMeta, Chain, PlotThemes, Dates, Images

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

# Fetch the BobsBurgersR image from the URL
img_url = "https://github.com/rfordatascience/tidytuesday/blob/ba56073e03b2ba931499ba13aaf0531f099e5b31/data/2024/2024-11-19/bobsburgersR.png?raw=true"

img = Images.load(HTTP.get(img_url).body)

# pivot the dataframe longer using the exclamation and question mark fields
episode_metrics_pivot = @chain begin
	episode_metrics_time
	stack([:question_ratio, :exclamation_ratio])
end

# plot theme
theme(:rose_pine)  # Apply rose_pine theme via PlotThemes

# Use a line plot to show the prevalence of excitement or thought-provoking
# questions in Bob's Burgers over time
questions_or_exclamations_plot = @df episode_metrics_pivot plot(
	:episode_number,  # x-axis
	:value,           # y-axis
	group = :variable,  # Different lines for each group
	color = [:pink :orange],  # Custom colors for each line
	linestyle = [:solid :dot],  # Optional: Different line styles for clarity
	grid = false,
	legend_position = :bottomleft,
	title = "Bob's Burgers Dialogue in Episodes 1-272\nIs it curiosity or excitement fueling the Belchers' banter?\n",
	xlabel = "",
	ylabel = "",
	label = ["exclamation ratio" "question ratio"],
	titlefontsize = 12,
	title_align = :left,
	fg_legend = :transparent,
	bg_legend = :transparent,
)

# Add the image as an annotation
annotate!(10, 0.8, text(" ", 8, :white, 0, 0), img)  # Adjust (x, y) for positioning
