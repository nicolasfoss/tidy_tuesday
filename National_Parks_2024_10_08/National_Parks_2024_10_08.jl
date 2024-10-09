#=

# The National Parks Dataset for Tidy Tuesday!

Here is some great information about today's dataset!  

> The information in NPSpecies is available to the public. The exceptions to this are records for some sensitive, threatened, or endangered species, where widespread distribution of information could potentially put a species at risk.  
>
> An essential component of NPSpecies is evidence; that is, observations, vouchers, or reports that document the presence of a species in a park. Ideally, every species in a park that is designated as “present in park” will have at least one form of credible evidence substantiating the designation

Thanks to [f.hull](https://github.com/frankiethull) for putting the dataset together.  

Access the data and more, here! --> [link](https://github.com/rfordatascience/tidytuesday/blob/504d69514fc162bb6fb76a9ffd356941330f0df9/data/2024/2024-10-08/readme.md)


=#

# installation
using Pkg
Pkg.add(["DataFrames", "CSV", "HTTP", "StatsPlots",
    "StatsBase", "Plots", "SummaryTables", "DataFramesMeta",
    "Chain", "CategoricalArrays", "Measures", "PlotThemes",
    "SplitApplyCombine"
])

# load
using DataFrames, CSV, HTTP, StatsPlots, StatsBase, Plots, SummaryTables, DataFramesMeta, Chain, CategoricalArrays, Measures, PlotThemes, SplitApplyCombine

# Option 1: Fetch data directly from GitHub
url = "https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2024/2024-10-08/most_visited_nps_species_data.csv"

response = HTTP.get(url)

# Parse the CSV into a DataFrame
species_data = CSV.read(response.body, DataFrame)

# Verify the first few rows
first(species_data, 5)

# check the category name variable to see unique values
unique(species_data.CategoryName)

# check the data

describe(species_data)

# get a dataframe with CommonNames and the CategoryName for a join
common_names_categories = @chain begin
    species_data
    filter(:CategoryName => x -> x in ["Mammal", "Bird", "Reptile", "Amphibian", "Fish", "Insect"], _)
    @transform(:CommonNames = ifelse.(:CommonNames .== "NA", :SciName, :CommonNames))
    @transform(:CommonNames = ifelse.(occursin.(",", :CommonNames), first.(split.(:CommonNames, ",")), :CommonNames))  # Handle split only if comma exists
    select(:CommonNames, :CategoryName)
    unique(_)
end

#=

## Steps for the Analysis:
* Filter the dataset: Focus on the 15 most visited parks and ensure we capture relevant columns like `ParkName`, `CommonNames`, `Vouchers`, `Observations`, and `References`.
* Group and summarize: We'll summarize the abundance of species for each park.
* Create a stacked bar chart: We'll visualize species abundance by park for easy comparison.

## Code to Filter and Summarize:

=#

# Filter and summarize data using @chain macro
# get the most documented species in each park
species_abundance_summary = @chain begin
    species_data
    filter(:CategoryName => x -> x in ["Mammal", "Bird", "Reptile", "Amphibian", "Fish", "Insect"], _)
    @transform(:CommonNames = ifelse.(:CommonNames .== "NA", :SciName, :CommonNames))
    @transform(:CommonNames = ifelse.(occursin.(",", :CommonNames), first.(split.(:CommonNames, ",")), :CommonNames))  # Handle split only if comma exists
    groupby([:ParkName, :CommonNames])
    @combine(:Total_Documentation = :Vouchers .+ :Observations .+ :References; ungroup=true)
    sort([:ParkName, order(:Total_Documentation, rev=true)])
    groupby(:ParkName)
    subset(:Total_Documentation => x -> x .== maximum(x))
    groupby(:ParkName)
    combine(:ParkName => first => :ParkName, :CommonNames => first => :CommonNames, :Total_Documentation => first => :Total_Documentation)  # Combine with max sightings per ParkName
    leftjoin(common_names_categories, on=:CommonNames)
    select(:ParkName, :CategoryName, :CommonNames, :Total_Documentation)
    sort(:Total_Documentation, rev=true)
end

species_abundance_summary.ParkName = categorical(species_abundance_summary.ParkName, levels=unique(species_abundance_summary.ParkName), ordered=true)

species_abundance_summary

#=

### Stacked Bar Chart:

Once we have the summarized data, we can create the stacked bar chart.

This will produce a stacked bar chart where each bar represents a park, and the native/non-native species are stacked to show their total contributions.

=#

# Stacked bar chart for species abundance by park and nativeness
theme(:dao)
species_abundance_bar = @df species_abundance_summary bar(:ParkName, :Total_Documentation,
    title="Which Species are Most Documented in Each of the\nTop 15 National Parks in the U.S.?\n", xlabel="", ylabel="Total Documentation", legend=false, fill="dodgerblue", fillalpha=0.65,
    titlefontsize=15, titlealign=:left, permute=(:x, :y), size=(800, 600),
    grid=false, bottom_margin=12mm,

    # annotate the plot from within bar()
    text=text.(:CommonNames, 8,

        ## define the positioning of text based on order in the graph
        [:right, :left, :left, :left, :left, :left, :left, :left, :left, :left, :left, :left, :left, :left, :left]))
annotate!(-2, -2, 
text("Total Documentation = Vouchers + Observations + References", "sans serif", :center, 8)
)

#=
## Analysis Overview
1. Data Preparation:

    * Filtering by Categories: We filtered the dataset to include only relevant species categories: Mammal, Bird, Reptile, Amphibian, Fish, and Insect.
    * Handling Missing and Multiple Common Names:
    * Replaced missing common names with scientific names.
    * If a species had multiple common names separated by commas, we selected the first name.
    * Unique Species: We selected unique combinations of CommonNames and CategoryName for further analysis.

2. Summarizing Species Documentation:

    * Filtering Relevant Species: We repeated the category and common name filtering steps to ensure consistency.
    * Grouping by Park and Species: Grouped data by park and species, then calculated the total documentation count (sum of vouchers, observations, and references).
    * Sorting by Documentation: Sorted species data within each park by the total number of documentations.
    * Selecting Top Documented Species: For each park, we selected the species with the maximum documentation count.
    * Joining with Categories: Merged the top species data with category names for classification.

3. Data Visualization:

    * Creating a Stacked Bar Chart: Using a stacked bar chart to visualize the total documentation of the most frequently documented species per park.
    * Bar Labels: Each bar is labeled with the species' common name.
    * Annotating the Plot: An additional annotation below the plot explains that total documentation is the sum of vouchers, observations, and references.
=#