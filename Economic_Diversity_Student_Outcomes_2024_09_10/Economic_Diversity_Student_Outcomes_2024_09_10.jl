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

# describe the raw DataFrame

describe(college_admissions)

# how many unique parent income brackets are there?

length(unique(college_admissions.par_income_lab))

# see unique levels of the parent income labels

unique(college_admissions.par_income_lab)

#=
## Cleaning

We'll clean the data similarly to the R code. Dropping the redundant "tier_name" variable and recoding the public and flagship columns.

=#

college_admissions_clean = @chain begin
    college_admissions
    select(Not(:tier_name))  # Drop redundant variable
    transform(:public => ByRow(==("Public")) => :public)  # Recode public as boolean
    transform(:flagship => ByRow(Bool) => :flagship)  # Recode flagship as boolean
end;

# summarize averages

# tier and parent income
college_admissions_summary = @chain begin
    college_admissions_clean
    filter(:par_income_lab => x -> !(x in ["Top 0.1", "Top 1"]), _)
    groupby([:tier, :par_income_lab])
    @combine(:avg_rel_attend = mean(:rel_attend),
        :avg_rel_apply = mean(:rel_apply);
        ungroup=true
    )
    @transform(:tier = ifelse.(:tier .== "Other elite schools (public and private)", "Other elite schools\n(public and private)", :tier))
end

# tier
college_admissions_summary_tier = @chain begin
    college_admissions_clean
    filter(:par_income_lab => x -> !(x in ["Top 0.1", "Top 1"]), _)
    groupby(:tier)
    @combine(:avg_rel_attend = mean(:rel_attend),
        :avg_rel_apply = mean(:rel_apply);
        ungroup=true
    )
    @transform(:tier = ifelse.(:tier .== "Other elite schools (public and private)", "Other elite schools\n(public and private)", :tier))
end

# parent income
college_admissions_summary_income = @chain begin
    college_admissions_clean
    filter(:par_income_lab => x -> !(x in ["Top 0.1", "Top 1"]), _)
    groupby(:par_income_lab)
    @combine(:avg_rel_attend = mean(:rel_attend),
        :avg_rel_apply = mean(:rel_apply);
        ungroup=true
    )
end;

# plot long format 
theme(:gruvbox_light)  # Apply gruvbox theme

# Plotting side-by-side bars with divisions based on `avg_rel_attend`
college_admissions_summary_attend = @df college_admissions_summary groupedbar(:tier, :avg_rel_attend,
    group=:par_income_lab,
    title="",
    xlabel="",
    xticks=false,
    ylabel="Relative Attendance",
    permute=(:x, :y),
    size=(800, 600),
    grid=false,
    titlealign=:left,
    legend=false,
    legendtitle="Parent Income Bin",
    margins=12mm
)
yflip!()

# Plotting side-by-side bars with divisions based on `avg_rel_apply`
college_admissions_summary_apply = @df college_admissions_summary groupedbar(:tier, :avg_rel_apply,
    group=:par_income_lab,
    title="Are Student Relative Attendance and Application Rates\na Function of Parent Income?",
    xlabel="School Tier",
    ylabel="Relative Application Rate",
    permute=(:x, :y),
    size=(800, 600),
    grid=false,
    titlealign=:left,
    legend=false,
    legendtitle="Parent Income Bin",
    margins=12mm
)
yflip!()
annotate!(1, 6.75, text("Source: Opportunity Insights | College Student Attendance/Application Data", :darkblue, 8))

plot_vector = [college_admissions_summary_apply, college_admissions_summary_attend]

plot(plot_vector...)

#=

## Next steps!

The plot above shows how it can be more effective to utilize a pivot long format for summarized data.  It is difficult to read and inserting a legend would be messy.

Now, we have a cleaned dataset and visualized the data - we will now pivot long.  Let's create a few visualizations for the long format that can help us understand economic diversity and student outcomes.

## Visualization: Long Format (`rel_attend` and `rel_apply`)
We can use a combined bar plot to visualize the distribution of the average `rel_attend` and `rel_apply` values across schools, grouped by the income bins (`par_income_lab`) and `tier`s, for example. This will provide insights into the trends in each group.

* Theme: `gruvbox_light` from `PlotThemes.jl`

## Pivot the Data
Now, we can use the `@chain` macro for both long pivoting.

### Long Format

=#

# tier
long_college_admissions_summary_tier = @chain begin
    college_admissions_summary_tier
    stack([:avg_rel_attend, :avg_rel_apply])
    select([:tier, :variable, :value])
end

describe(long_college_admissions_summary_tier)

# parent income
long_college_admissions_summary_income = @chain begin
    college_admissions_summary_income
    stack([:avg_rel_attend, :avg_rel_apply])
    select([:par_income_lab, :variable, :value])
end

describe(long_college_admissions_summary_income)

#=

## Plot using pivoted data

It's much cleaner!

=#

# Plotting side-by-side bars with divisions based on `avg_rel_apply`

theme(:rose_pine)

college_admissions_summary_bar_tier = @df long_college_admissions_summary_tier groupedbar(:tier, :value,
    group=:variable,
    title="Do Different College Tiers Have Differing Attendance\nand/or Application Rates?",
    xlabel="School Tier",
    ylabel="Relative Rate",
    permute=(:x, :y),
    size=(800, 600),
    grid=false,
    titlealign=:left,
    legend=:bottomright,
    labels=["Avg Relative Application Rate" "Avg Relative Attendance Rate"],
    legendtitle="Parent Income Bin",
    margins=10mm
)
yflip!()
annotate!(1, 6.75, text("Source: Opportunity Insights | College Student Attendance/Application Data", :white, 8))

theme(:rose_pine)

college_admissions_summary_bar_income = @df long_college_admissions_summary_income groupedbar(:par_income_lab, :value,
    group=:variable,
    title="Are Student Relative Attendance and Application Rates\na Function of Parent Income?",
    xlabel="Parent Income Bin",
    ylabel="Relative Rate",
    permute=(:x, :y),
    size=(800, 600),
    grid=false,
    titlealign=:left,
    legend=:bottomright,
    labels=["Avg Relative Application Rate" "Avg Relative Attendance Rate"],
    legendtitle="Metrics",
    margins=10mm
)
yflip!()
annotate!(2.5, 13.75, text("Source: Opportunity Insights | College Student Attendance/Application Data", :white, 8))