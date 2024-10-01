# raw Julia code to accompany the Jupyter notebook for 
# week 38 of tidytuesday 2024

# import Pkg and then other required packages
using Pkg
Pkg.add(["CSV", "DataFrames", "HTTP", "Statistics", "StatsPlots", "Plots"])

# load
using CSV, DataFrames, HTTP, Statistics, StatsPlots, Plots

# Read directly from GitHub
hamlet_url="https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2024/2024-09-17/hamlet.csv"
macbeth_url = "https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2024/2024-09-17/macbeth.csv"
romeo_juliet_url = "https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2024/2024-09-17/romeo_juliet.csv"

# Create DataFrames
hamlet = CSV.read(HTTP.get(hamlet_url).body, DataFrame)
macbeth = CSV.read(HTTP.get(macbeth_url).body, DataFrame)
romeo_juliet = CSV.read(HTTP.get(romeo_juliet_url).body, DataFrame);

# Basic Description
println("We will want to take note of the fact that `line_number` is a string variable.")

describe(hamlet)


# Number of unique characters
unique_characters = unique(hamlet.character)
println("Number of unique characters: ", length(unique_characters))
     
# Most frequent characters
character_counts = combine(groupby(hamlet, :character), nrow => :Count)
sorted_counts = sort(character_counts, :Count, rev=true)
println("Top 10 Most frequent characters:\n", sorted_counts[1:10,:])

# Distribution of dialogue lengths
hamlet.dialogue_length = length.(hamlet.dialogue)

hamlet_hist = 
histogram(hamlet.dialogue_length, 
title="Distribution of Dialogue Lengths in Hamlet", 
xlabel="", 
ylabel="Count",
legend=false,
titlefontsize=12
)

# check out unique values within line_number
println("Clearly, there is a vagrant 'NA' value in or data that will not allow for line_number to be continuous.")
unique(hamlet.line_number)

# view rows that have line_number == "NA"
println("We can see that these are instances of stage direction, there are no lines. To show the behavior of character dialogue in the data. \nWe can remove these rows and deal with the rest of the data.\nWe will create a new dataframe for this so as to be able to go back and analyze the stage direction further if desired.")
hamlet[hamlet.line_number .== "NA", :]

# Define the function with type checking and error handling
function shakespeare_impute(df::DataFrame, col::Symbol;
    not_value="NA", 
    impute_with=missing, 
    format=Int)
# Replace `not_value` with `impute_with` in the specified column
df[!, col]=replace(df[!, col], not_value => impute_with)

# Remove rows with missing values in the specified column
df_clean=dropmissing(df, col)

# parse the format of the new column

df_clean[!, col]=parse.(format, df_clean[!, col])

return df_clean  # Return the modified DataFrame

end

# deal with the format of line_number
# Replace "NA" with missing values
# Remove rows with missing line numbers
# parse strings into integers
# via shakespeare_impute()

hamlet_no_stage_direction=shakespeare_impute(hamlet, :line_number)

describe(hamlet_no_stage_direction)

# Plot example using updated DataFrame
println("Here, we can compare the number of lines in each act,\npotentially showing us which acts include more dialogue.")

hamlet_scatter=
@df hamlet_no_stage_direction scatter(:line_number, 
        :act,
        group=:scene,
        palette=:Spectral,
        markeralpha=0.1,
        legend=false,
        title="Hamlet: Line Number Distribution by Act\nScene I - VII=color change", 
        xlabel="", 
        ylabel="Act",
        titlefontsize=12
)
yflip!()

hamlet_scatter

# Number of unique characters
unique_characters_macbeth=unique(macbeth.character)
println("Number of unique characters: ", length(unique_characters_macbeth))
     
# Most frequent characters
character_counts_macbeth=combine(groupby(macbeth, :character), nrow => :Count)
sorted_counts_macbeth=sort(character_counts_macbeth, :Count, rev=true)
println("Top 10 Most frequent characters:\n", sorted_counts_macbeth[1:10, :])

# Distribution of dialogue lengths
macbeth.dialogue_length=length.(macbeth.dialogue)

macbeth_hist=histogram(macbeth.dialogue_length, 
title="Distribution of Dialogue Lengths in Macbeth", 
xlabel="", 
ylabel="Count",
legend=false,
color=:orange,
titlefontsize=12
)

# utilize the custom function to improve the scatterplot below

macbeth_no_stage_direction = shakespeare_impute(macbeth, :line_number)

# Plot line number distribution by act and scene
macbeth_scatter =
@df macbeth_no_stage_direction scatter(:line_number, 
:act, 
group=:scene,
palette=:PuOr,
markeralpha=0.1, 
legend=false, 
title="Macbeth: Line Number Distribution by Act\nScene I - VIII = color change", 
xlabel="", 
ylabel="Act",
titlefontsize=12
)
yflip!()

macbeth_scatter

# Basic Description
describe(romeo_juliet)

# Number of unique characters
unique_characters_rj = unique(romeo_juliet.character)
println("Number of unique characters: ", length(unique_characters_rj))
     
# Most frequent characters
character_counts_rj = combine(groupby(romeo_juliet, :character), nrow => :Count)
sorted_counts_rj = sort(character_counts_rj, :Count, rev=true)
println("Top 10 Most frequent characters:\n", sorted_counts_rj[1:10, :])

# Distribution of dialogue lengths
romeo_juliet.dialogue_length = length.(romeo_juliet.dialogue)

rj_hist = histogram(romeo_juliet.dialogue_length, 
title="Distribution of Dialogue Lengths in Romeo & Juliet", 
xlabel="", 
ylabel="Count",
color=:red,
legend=false,
titlefontsize=12
)

# deal with line_number formatting
rj_no_stage_direction = shakespeare_impute(romeo_juliet, :line_number)

# Plot line number distribution by act and scene
rj_scatter = 
@df rj_no_stage_direction scatter(:line_number, 
:act, 
group=:scene,
markeralpha=0.1,
palette=:BrBg, 
legend=false, 
title="Romeo and Juliet: Line Number Distribution by Act\nScenes Prologue to Scene VI = color change\n", 
xlabel="Line Number", 
ylabel="Act",
titlefontsize=12
)
yflip!()

# summarize each DataFrame

# hamlet
hamlet_summary = combine(hamlet, :dialogue_length .=> [minimum, median, maximum] .=> [:Min, :Median, :Max])
hamlet_summary.Play = ["Hamlet"] # add the character string to identify each row as a play

# macbeth
macbeth_summary = combine(macbeth, :dialogue_length .=> [minimum, median, maximum] .=> [:Min, :Median, :Max])
macbeth_summary.Play = ["Macbeth"]

# romeo and Juliet
romeo_juliet_summary = combine(romeo_juliet, :dialogue_length .=> [minimum, median, maximum] .=> [:Min, :Median, :Max])
romeo_juliet_summary.Play = ["Romeo and Juliet"]

# union
line_comparison_cat = vcat(hamlet_summary, macbeth_summary, romeo_juliet_summary)

# pivot longer

line_comparison_pivot = stack(line_comparison_cat, [:Min, :Median, :Max])

# set more intuitive names

line_comparison_df = rename!(line_comparison_pivot, Dict(

:variable => :Type,
:value => :Stat

))

# Construct the dumbbell plot
line_comparison_plot = 
@df line_comparison_df Plots.plot(:Stat, :Play, color=:darkgray, group=:Play, z_order=:back, linewidth = 2, legend=false, label="")
@df line_comparison_df scatter!(:Stat, :Play, 
group=:Type, markersize = 5, 
color=[:red :blue :darkgray], 
z_order=:front, 
legend = :outertopright,
xlabel = "N Characters",
ylabel = "",
title = "Comparison of Three Plays' Number of Characters per Line",
titlefontsize = 12,
legendtitle = "Statistic"
)

# create a vector of histograms
histogram_vector = [hamlet_hist macbeth_hist rj_hist]

# plot the histograms together in one viewport
Plots.plot(histogram_vector..., layout=(3,1))

# create a vector of the three dotplots

println("Here, we can see that Hamlet is the longest play of them all, with Romeo and Juliet coming in second.\nEach play has a slightly different structure with regard to how scenes are distributed within each act, and how long each act is.\nI hope you enjoyed reviewing this analysis, and that hyou get movitated to contribute to Tidy Tuesday as well!")
dotplot_vector = [hamlet_scatter macbeth_scatter rj_scatter]

Plots.plot(dotplot_vector..., layout=(3,1), size=(600, 1068))
