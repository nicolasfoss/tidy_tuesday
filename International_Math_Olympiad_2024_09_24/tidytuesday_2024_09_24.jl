# Julia script to accompany the Jupyter notebook for
# week 39 of tidytuesday 2024

## Importing Required Packages
using Pkg
Pkg.add(["CSV", "DataFrames", "DataFramesMeta", "HTTP", "Statistics", "StatsPlots", "Plots", "Chain"])

# Load the necessary packages
using CSV, DataFrames, DataFramesMeta, HTTP, Statistics, StatsPlots, Plots, Chain

# URLs for the CSV files

country_url = "https://raw.githubusercontent.com/nicolasfoss/tidy_tuesday/6d27ab32c81dc1a8a2857a5fcfcf0c3e2f219a83/International_Math_Olympiad_2024_09_24/country_results_df.csv"
individual_url = "https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2024/2024-09-24/individual_results_df.csv"
timeline_url = "https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2024/2024-09-24/timeline_df.csv"

# Reading the data into DataFrames
country_results_df = CSV.read(HTTP.get(country_url).body, DataFrame)
individual_results_df = CSV.read(HTTP.get(individual_url).body, DataFrame)
timeline_df = CSV.read(HTTP.get(timeline_url).body, DataFrame);

# Display the first few rows and structure of country_results_df
first(country_results_df, 5)  # first 5 rows

# summary statistics
describe(country_results_df)

heatmap(
    Matrix(ismissing.(country_results_df)
    ),
    color = :grays,
    title = "Heatmap of Missing Values in country_results_df",
    titlefontsize = 12
)

# leader column

first(
    country_results_df[ismissing.(country_results_df.leader), :], 
    5 # number of rows to view
)

# deputy leader column
first(
    country_results_df[ismissing.(country_results_df.deputy_leader), :], 
    5 # number of rows to view
)

# Define the function with type checking and error handling
function imo_impute(df::DataFrame, col::Symbol;
    not_value="NA", 
    impute_with=missing, 
    format=Int)
# Replace `not_value` with `impute_with` in the specified column
df[!, col]=replace(df[!, col], not_value => impute_with)

# parse the format of the new column
df[!, col] = passmissing(parse).(format, df[!, col])

return df  # Return the modified DataFrame

end

# get column names of interest

format_names = [:team_size_male, :team_size_female, :p1, :p2, :p3, :p4, :p5, :p6, :p7, :total, :rank, :awards_gold, :awards_silver, :awards_bronze, :awards_honorable_mentions]

country_results_clean = copy(country_results_df)

# reformat

for column in format_names

country_results_clean = imo_impute(country_results_clean, column)

end

# check columns for problems
describe(country_results_clean)

# Display the first few rows and structure of individual_results_df
first(individual_results_df, 5)

# summary statistics
describe(individual_results_df)


# view some missing rows from award

first(
    individual_results_df[ismissing.(individual_results_df.award), :],
    5 # number of rows to view
)

# get names to format from the individual_results_df dataset
format_names2 = [:p1, :p2, :p3, :p4, :p5, :p6, :p7, :individual_rank]

# create a new df
individual_results_clean = copy(individual_results_df)

# iterate over columns with the custom function

for column in format_names2

    individual_results_clean = imo_impute(individual_results_clean, column)

end
     

# check for any problems

describe(individual_results_clean)

# award column 

heatmap(
    Matrix(
        ismissing.(individual_results_clean)
        ), 
        color=:grays,
        title = "Heatmap of Missing Values in individual_results_clean",
        titlefontsize = 12
)

# Display the first few rows and structure of timeline_df
first(timeline_df, 5)

# summary statistics
describe(timeline_df)

# new dataset

timeline_clean = copy(timeline_df)

# clean

timeline_clean = imo_impute(timeline_clean, :female_contestant);
     

# check for issues

describe(timeline_clean)

# visualize the missingness

heatmap(
    Matrix(ismissing.(timeline_clean)),
    color = :grays,
    title = "Heatmap of Missing Values in timeline_clean",
    titlefontsize = 12
)

# How many countries are there?
println("There are ", 
length(unique(country_results_df.country)),
" unique countries in the country_results_df dataset."
)

# the reason we need to do that, is visualizing the rankings over time would be a nightmare, observe:

@df country_results_clean plot(:year, :rank, 
group=:country, 
palette=:Spectral, 
title="Country Rankings Over Time\nInternational Mathematical Olympiad", 
xlabel="Year", 
ylabel="Rank", 
legend=:outertopright, 
titlefontsize=12
)

# Step 1: Filter out rows where `rank` is missing, then get the sum of `rank == 1` by country
first_place_counts = @chain begin 
    country_results_clean
    dropmissing(:rank)  # Step 1: Remove rows with missing rank
    filter(row -> row.rank == 1, _)  # Apply filter to the dataframe passed through the chain, "_" refers to the dataframe we pass
    groupby(:country)  # Group by country
    combine(:rank => length => :first_place_count)  # Count first-place finishes
end

# Step 2: Sort countries by the number of first-place ranks and keep the top 5
top_5_countries = 
@chain begin 
    first_place_counts
    sort(:first_place_count, rev=true)
    first(5)
end

# Step 3: Extract the names of the top 10 countries
top_5_country_names = top_5_countries.country

# Step 4: Filter the main dataset for only these top 10 countries
top_5_country_results = @chain begin
    country_results_clean_no_missing
    filter(:country => (x -> x in top_5_country_names), _)
end

# check our work
describe(top_5_country_results, :mean, :std, :min, :nunique, :nmissing, :nnonmissing, :first, :last, :eltype)

# Check out the top 5 countries with the most first Placements
top_5_countries

# Step 5: Plot rank over time for the top 10 countries
@df top_10_country_results scatter(:year, :rank, group=:country, 
    xlabel="", ylabel="Rank", 
    title="Countries' Rankings Over Time\nAmong Countries with the Most First Placements",
    lw=3, palette=:darktest,
    legend=:outerbottomright, legendtitle = "Country",
    size=(800, 450))

# Gender distribution: Summing male and female participants per year
gender_distribution = combine(groupby(timeline_clean, :year), 
    :male_contestant => sum => :male_sum, 
    :female_contestant => sum => :female_sum)

    gender_distribution_pivot = stack(gender_distribution, [:male_sum, :female_sum], :year)

# Plotting gender distribution over time
@df gender_distribution_pivot plot(:year, 
    :value, group=:variable, 
    xlabel="Year", ylabel="Number of Participants", 
    label=["Female" "Male"], 
    title="International Mathematical Olympiad\nGender Distribution Over Time", 
    lw=2, legend=:outertopright, size=(800,450), palette=[:purple, :green],
    titlefontfize = 12
    )

# Histogram of top scores from individual results
@df individual_results_clean histogram(:total, 
    bins=30, xlabel="Total Score", ylabel="Frequency", 
    title="Distribution of Total Scores", 
    legend=false, color=:blue)

# Step 1: Get summary statistics on participants
top_scorers = @chain individual_results_clean begin
    filter(row -> !(row.contestant in ["*", "?"]), _)  # Filter out contestants with names "*" or "?"
    groupby(:contestant)
    combine( 
        :total => mean => :Avg_Score,   # Calculate average score
        :total => sum => :Total_Points,   # Calculate total points
        :year => length => :N_Competitions  # Count unique years competed
    )
end

# Step 2: Create a flipped bar charts of top scorers
top_scorers_total = @chain begin top_scorers
    sort(:Total_Points, rev=true)  # Sort by total score in descending order
    first(10)  # Select the top 10 scoring participants
    end
    
    # create the first bar chart illustrating total points (i.e. participation!)
    top_score_total_bar = @df top_scorers_total bar(:contestant, :Total_Points, permute=(:x, :y), 
        ylabel="Sum of Scores", xlabel="", 
        title="Participants with the Greatest Sums of Scores", 
        legend=false, titlefontsize=10, color=:dodgerblue, size=(800, 450))
    yflip!()
    
    # create the second illustrating the mean (i.e. performance if multiple showings)
    top_scorers_avg = @chain begin top_scorers
        sort(:Avg_Score, rev=true)  # Sort by total score in descending order
        first(10)  # Select the top 10 scoring participants
        end
        
        # create the first bar chart illustrating total points (i.e. participation!)
        top_score_avg_bar = @df top_scorers_avg bar(:contestant, :Avg_Score, permute=(:x, :y), 
            ylabel="Avg Score", xlabel="", 
            title="Participants with the highest Avg Score", 
            legend=false, titlefontsize=10, color=:orange, size=(1000, 561))
        yflip!()
    
    bar_plots = [top_score_total_bar top_score_avg_bar]
    
    plot(bar_plots..., layout=(1,2))


# view the tenacity award winners

@chain begin top_scorers
    sort(:N_Competitions, rev=true)
end

# Step 1: Summarize total scores and team size by country
team_size_analysis = @chain country_results_clean begin
    groupby(:country)
    combine(_, 
        :total => mean => :Avg_Score,   # Total score for the country
        :team_size_all => sum => :Total_Team_Size;  # Total number of contestants
        ungroup=true
    )
    dropmissing(:Avg_Score) # must remove the 1 missing value here to get regression line
end

# Step 2: Calculate Pearson's r for Total Team Size and Avg Score
pearsons_r = round(cor(team_size_analysis.Total_Team_Size, team_size_analysis.Avg_Score), digits=3)

# Step 3: Create a scatter plot to visualize the relationship
@df team_size_analysis scatter(:Total_Team_Size, :Avg_Score,
    xlabel="Total Team Size", ylabel="Avg Score",
    title="International Mathematical Olympiad: Does Team Size Predict Avg. Score?",
    legend=false, smooth=true, size=(800, 450), markercolor=:red,
    linealpha=1, markeralpha=0.5, linewidth=3, linecolor=:blue,
    titlefontsize=12
)
annotate!([(100, 200, text("Pearson's (r): " * string(pearsons_r), 10, :black, :top))])

# we need a dataframe with the country each participant corresponds to
country_participants = unique(individual_results_clean[:, [:country, :contestant]]);

# Step 1: Summarize total scores and team composition by contestant
participant_types = @chain individual_results_clean begin
    filter(row -> !(row.contestant in ["*", "**", "*** ***", "?"]), _)  # Filter out contestants with names "*" or "?"
    groupby(:contestant)
    @combine(:Cumulative_Participation = length(:year); ungroup=true)  # Create a cumulative count
    @transform(:Participant_Type = ifelse.(:Cumulative_Participation .> 1, "Veteran", "Novice"))
    sort(:Cumulative_Participation, rev=true)
    leftjoin(country_participants, on=:contestant)
    groupby(:country)
    @combine(:Veteran_Count = sum(:Participant_Type .== "Veteran"),
             :Novice_Count = sum(:Participant_Type .== "Novice")
    )
    @transform(:Veteran_Ratio = :Veteran_Count ./ :Novice_Count
                                    )
end

first(participant_types, 5)

# explore counts of Team_Type groups

@chain begin participant_types
    groupby(:Team_Type)
    combine(:Team_Type => length => :n)
    @transform(:percent = string.(round.(:n / sum(:n) * 100, digits=2), "%"))
end

# Step 2: Count total first-time participants and veterans for each country
team_composition_analysis = @chain country_results_clean begin
    groupby(:country)
    combine(:total => mean => :Avg_Score, 
        :team_size_all => sum => :Total_Team_Size,  # Total team size for the country
        :awards_gold => sum => :Total_Gold_Awards,   # Total gold awards
        :awards_silver => sum => :Total_Silver_Awards,  # Total silver awards
        :awards_bronze => sum => :Total_Bronze_Awards,  # Total bronze awards
        :awards_honorable_mentions => sum => :Total_Honorable_Mentions  # Total honorable mentions
    )
    # Join with first_time_participants to include first-time counts
    leftjoin(_, participant_types, on=:country)
    # Filter out rows where Avg_Score is missing
    filter(row -> !ismissing(row.Avg_Score), _)
end

# Step 3: Calculate Pearson's r for the Veteran Ratio
pearsons_r_composition = round(
    cor(team_composition_analysis.Veteran_Ratio, team_composition_analysis.Avg_Score), 
    digits=3
    )

# Step 4: Create a scatter plot for First-Time Participants vs. Total Score
composition_scatter = @df team_composition_analysis scatter(:Veteran_Ratio, :Avg_Score,
    xlabel="Ratio of Veterans to Novices", ylabel="Avg. Score",
    title="International Mathematical Olympiad: Does the Ratio of Veterans Predict Avg. Score?",
    legend=false, smooth=true, size=(800, 450), marker=:diamond,
    markeralpha=0.5, markercolor=:black, linecolor=:magenta, linewidth=3,
    titlefontsize=11
)
annotate!([(1.25, 200, text("Pearson's (r): " * string(pearsons_r_composition), 10, :black, :top))])
