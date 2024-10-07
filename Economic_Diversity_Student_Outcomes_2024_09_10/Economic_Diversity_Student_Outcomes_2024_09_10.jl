##################################################
### Tidy Tuesday 9.10.2024 #######################
### Economic Diversity and Student Outcomes ######
##################################################

# installation
using Pkg
Pkg.add(["DataFrames", "CSV", "HTTP", "StatsPlots",
    "StatsBase", "Plots", "SummaryTables", "DataFramesMeta",
    "Chain", "CategoricalArrays", "Measures", "PlotThemes"
])

# load
using DataFrames, CSV, HTTP, StatsPlots, StatsBase, Plots, SummaryTables, DataFramesMeta, Chain, CategoricalArrays, Measures, PlotThemes

# Load the dataset
url = "https://opportunityinsights.org/wp-content/uploads/2023/07/CollegeAdmissions_Data.csv"

# file
response = HTTP.get(url)

# import
college_admissions = CSV.read(response.body, DataFrame)

