################################################################################
### Bob's Burgers Analysis!  ###################################################
### Week 47 - 2024-11-19     ###################################################
################################################################################

# set the working directory

cd("C:/Users/ndfos/Documents/tidy_tuesday/Bobs_Burgers_2024_11_19")

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

# Fetch the BobsBurgersR image from the URL on GitHub
#= 

Adding ?raw=true at the end of the URL ensures that GitHub serves the file as a raw binary file instead of rendering it as a preview in the browser. Without ?raw=true, GitHub might display the image as part of its web interface, which includes HTML headers and other elements. This can lead to errors when trying to load the image programmatically in a script or application because the response would not be a clean binary image.

=#

img_url = "https://github.com/rfordatascience/tidytuesday/blob/ba56073e03b2ba931499ba13aaf0531f099e5b31/data/2024/2024-11-19/bobsburgersR.png?raw=true"

img = HTTP.get(img_url).body

# Load the image using an IOBuffer
img = Images.load(IOBuffer(img))

# pivot the dataframe longer using the exclamation and question mark fields
episode_metrics_pivot = @chain begin
	episode_metrics_time
	stack([:question_ratio, :exclamation_ratio])
end

# plot theme
theme(:rose_pine)  # Apply rose_pine theme via PlotThemes

# getting picky about fonts
default(
	titlefont = ("Work Sans", 8, :white),  # Title font with white color
	tickfont = ("Work Sans", 6, :white),            # Tick labels with white color
	legendfont = ("Work Sans", 6, :white),           # Legend font with white color
)

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
	title = "Bob's Burgers Dialogue in Episodes 1-272\nDoes curiosity or excitement fuel the Belchers' banter?\n",
	xlabel = "",
	ylabel = "",
	label = ["exclamation ratio" "question ratio"],
	title_align = :left,
	fg_legend = :transparent,
	bg_legend = :transparent,
	dpi = 300,
);

# Add the image to the top-right corner and save back to the same variable
questions_or_exclamations_plot = plot!(
	questions_or_exclamations_plot,  # Overlay on the existing plot
	img,
	inset = bbox(0.8, 0.15, 0.15, 0.15),  # Position and size (x, y, width, height)
	subplot = 2,  # Overlay on the main plot
	framestyle = :none,  # Remove box/frame around the inset
	axes = :none,  # Remove axes
	ticks = [],    # Remove ticks
	background_color = :transparent,  # Transparent background
	grid = false,  # Disable grid
	dpi = 1000,
);

# save the plot and get it out there to the people!
savefig(questions_or_exclamations_plot, "bobs_burgers_plot.png")
