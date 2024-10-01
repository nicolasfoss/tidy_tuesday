# Julia script to accompany week 40 TidyTuesday in 2024 Jupyter Notebook in this repo

# installation
using Pkg
Pkg.add(["DataFrames", "CSV", "HTTP", "StatsPlots", 
"StatsBase", "Plots", "SummaryTables", "DataFramesMeta", 
"Chain", "CategoricalArrays", "Measures", "PlotThemes"
])

# load
using DataFrames, CSV, HTTP, StatsPlots, StatsBase, Plots, SummaryTables, DataFramesMeta, Chain, CategoricalArrays, Measures, PlotThemes

# get url
url = "https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2024/2024-10-01/chess.csv"

# use HTTP package
response = HTTP.get(url)

# import data via CSV / HTTP
chess = CSV.read(IOBuffer(response.body), DataFrame)

# inspect
describe(chess)

# make it easy to identify winners and their rating
chess_rank = @chain begin
    chess
    @transform(:winner_rating = ifelse.(:winner .== "white", :white_rating,
                                    ifelse.(:winner .== "black", :black_rating, 0)),
                :winner_id = ifelse.(:winner .== "white", :white_id,
                ifelse.(:winner .== "black", :black_id, "none"))
                                    )
end;

# get a summary for plotting / further analysis of # wins and avg rating per player
chess_rank_summary = @chain begin
    chess_rank
    groupby(:winner_id)
    combine([:winner_id => length => :N_wins,
            :winner_rating => mean => :Avg_rating
    ])
    sort(:N_wins, rev = true)
    filter(:winner_id => x -> x != "none", _)
end;

common_openings = combine(groupby(chess, :opening_name), nrow => :Frequency)
sorted_openings = sort(common_openings, :Frequency, rev=true)

# Display top 10 common openings
top_sorted_openings = first(sorted_openings, 10)

# get a filtered chess dataset using the top opening_names
chess_filtered = filter(:opening_name => x -> x in unique(top_sorted_openings.opening_name), chess)

# summarize using table_one
table_one(
    chess_filtered,
    [:opening_name => "Opening Name", ],
    groupby = :victory_status => "Victory Status",
    show_n = true
)

length(unique(chess_rank.winner_rating))

# most common opening moves by ranks
chess_rank_filter = filter(:winner_rating => x -> x != 0, chess_rank) 

@df chess_rank_filter histogram(:winner_rating, legend = false, 
title = "Distribution of Winner Ratings\nLichess Game Dataset\n\n",
titlefontsize = 15, titlealign = :left
)

# Define ranking categories
chess_rank.ranking_band = cut(chess.white_rating, [600, 800, 1000, 1200, 1400, 1600, 1800, 2000, 2200, 2400, 2600, 2800])

@chain begin
    chess_rank
    groupby(:ranking_band)
    combine(:ranking_band => length => :Count)
end

# Group by ranking band and calculate average game length
turns_by_ranking = combine(groupby(chess_rank, :ranking_band), :turns => mean => :avg_turns)

# Plot the result
@df turns_by_ranking bar(:ranking_band, :avg_turns, 
legend = false, xlabel="", ylabel = "Average Turns", 
xrotation = 40, size = (1000, 565), margins = 10mm,
title = "Average Turns by Winner Rating Band\nLichess Game Dataset\n",
titlefontsize = 20, titlealign = :left, color = :coral
)

# Create a violin plot of the distribution of turns by ranking band
theme(:gruvbox_light)

@df chess_rank violin(:ranking_band, :turns, 
    xlabel = "Winner Rating Band", 
    ylabel = "Number of Turns", 
    legend = false, 
    title = "Do Higher Ranked Players Take Their Time Winning in Chess?\nLichess Chess Dataset\n\n",
    size = (1000, 565), 
    xrotation = 40, 
    margins = 10mm, 
    fillalpha = 0, 
    titlefontsize = 20,
    titlealign = :left)
# Overlay the scatter plot with mean values
@df chess_rank scatter!(:ranking_band, :turns, 
group = :ranking_band,
markeralpha = 0.25,
legend = false)

# create a table that summarizes avg turns per the top 10 opening moves and winning rating band

# get a filtered chess dataset using the top opening_names
chess_rank_filtered = filter(:opening_name => x -> x in unique(top_sorted_openings.opening_name), chess_rank)

# summarize using table_one
table_one(
    chess_rank_filtered,
    [:opening_name => "Opening Name", :turns => "Turns"],
    groupby = :ranking_band => "Winner Ranking Band",
    show_n = true
)
