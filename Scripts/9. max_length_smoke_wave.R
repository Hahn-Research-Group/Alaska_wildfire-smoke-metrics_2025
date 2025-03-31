# 9. max_length_smoke_wave.R

# Load packages
library(here)
library(tidyverse)

# Set working directory manually if i_am() is unable to find the file, for example:
# setwd("C:/Users/username/Alaska_wildfire-smoke-metrics_2025/Scripts")

# Set up working directory and here() paths
setwd(here::here())
here::i_am("Scripts/9. max_length_smoke_wave.R")
knitr::opts_knit$set(root.dir = here::here())

# Load Raw WFS PM2.5 tract averages
PM25_by_Tracts_WFS <- read.csv(here("Output/Daily_Average_WFS_PM25_by_Census_Tract.csv"))
PM25_by_Tracts_WFS$Date <- as.Date(PM25_by_Tracts_WFS$Date)
PM25_by_Tracts_WFS$Year <- as.numeric(format(PM25_by_Tracts_WFS$Date,'%Y'))

# If the data is over or equal to 9, it is a '1'. Everything else is now 0
PM25_by_Tracts_WFS$Binary <- ifelse(PM25_by_Tracts_WFS$PM2.5 >= 9, 1, 0)
  head(PM25_by_Tracts_WFS)

# Group the data by NAME and Year
grouped_data <- PM25_by_Tracts_WFS %>% group_by(NAME)

# Define a function to reorder the 'Date' column within each group
reorder_dates <- function(df) {
  df <- df %>% arrange(Date)
  return(df)
}

# Apply the function to each group in the grouped DataFrame
grouped_data <- grouped_data %>% group_modify(~ reorder_dates(.))
table(grouped_data$Binary)

# Remove smoky days (Value = 1) in which the day before or after was '0' 
# Minimum of two consecutive smoky days are rquired to be considered a smoke wave.

# Define a function to process each dataframe
process_df <- function(df) {
  # Identify the rows where 'Binary' is 1
  ones_indices <- which(df$Binary == 1)
  
  # Elimate non-consecutive smoky days
  for (i in ones_indices) {
    # Check if there is a '1' value in the day before or after
    if (i > 1 && df$Binary[i - 1] != 1 && i < nrow(df) && df$Binary[i + 1] != 1) {
      # If no '1' value in the day before or after, turn the '1' value into 0
      df$Binary[i] <- 0
    }
  }
  
  return(df)
}

# Apply the function to each dataframe in grouped_data
grouped_data <- grouped_data %>% group_modify(~ process_df(.))
table(grouped_data$Binary)

# Only keep values on days where PM2.5 is over or equal to 9
Smoke_Days_Only <- subset(grouped_data, Binary == "1")
Smoke_Days_Only$Date <- as.Date(Smoke_Days_Only$Date)

# Convert Unix timestamps to human-readable dates in 'Smoke_Days_Only'
Smoke_Days_Only <- Smoke_Days_Only %>%
  mutate(Date = as.Date(as.numeric(Date), origin = "1970-01-01"))

# Sort the dataframe by 'NAME', 'Year', and 'Date'
Smoke_Days_Only <- Smoke_Days_Only %>%
  arrange(NAME, Year, Date)

# Calculate the gap between consecutive smoke days (DateDiff)
Smoke_Days_Only <- Smoke_Days_Only %>%
  group_by(NAME, Year) %>%
  mutate(DateDiff = c(0, diff(Date)))

# Identify when a new sequence of smoke days starts (StartNewSeq)
#(1 if difference is not 1, 0 otherwise)
Smoke_Days_Only <- Smoke_Days_Only %>%
  mutate(StartNewSeq = ifelse(DateDiff != 1, 1, 0))

# Assign a unique ID to each sequence of consecutive smoke days (SmokeWaveID)
Smoke_Days_Only <- Smoke_Days_Only %>%
  mutate(SmokeWaveID = cumsum(StartNewSeq))

# Calculate the length, start date, and end date for each smoke wave
Smoke_Wave_Details <- Smoke_Days_Only %>%
  group_by(NAME, Year, SmokeWaveID) %>%
  reframe(
    WaveLength = n(),
    StartDate = min(Date),  # Get the minimum (earliest) date
    EndDate = max(Date),    # Get the maximum (latest) date
  )

# Convert the StartDate and EndDate columns to human-readable format
Smoke_Wave_Details <- Smoke_Wave_Details %>%
  mutate(
    StartDate = as.Date(StartDate, origin = "1970-01-01"),
    EndDate = as.Date(EndDate, origin = "1970-01-01")
  )

# Find the longest smoke wave for each tract and year
Longest_Smoke_Waves_Year <- Smoke_Wave_Details %>%
  group_by(NAME, Year) %>%
  reframe(
    LongestWave = max(WaveLength, na.rm = TRUE),
    StartDate = StartDate[WaveLength == max(WaveLength)],
    EndDate = EndDate[WaveLength == max(WaveLength)]
  )

# Create a grid of all combinations of NAME and Year (2003-2020)
all_years <- 2003:2020
all_names <- unique(PM25_by_Tracts_WFS$NAME)
complete_grid <- expand.grid(NAME = all_names, Year = all_years)

# Ensure StartDate and EndDate in Longest_Smoke_Waves_Complete are converted
Longest_Smoke_Waves_Complete <- complete_grid %>%
  left_join(Longest_Smoke_Waves_Year, by = c("NAME", "Year")) %>%
  mutate(
    LongestWave = ifelse(is.na(LongestWave), 0, LongestWave),
    StartDate = ifelse(is.na(StartDate), as.Date(NA), StartDate),
    EndDate = ifelse(is.na(EndDate), as.Date(NA), EndDate)
  )

# Assuming 'StartDate' is a Unix timestamp in 'Longest_Smoke_Waves_Complete'
Longest_Smoke_Waves_Complete$StartDate <- as.Date(Longest_Smoke_Waves_Complete$StartDate, origin = "1970-01-01")
Longest_Smoke_Waves_Complete$EndDate <- as.Date(Longest_Smoke_Waves_Complete$EndDate, origin = "1970-01-01")

# Extract the longest smoke waves from each tract to 'longest_smoke_waves_per_name'
longest_smoke_waves_per_name <- Longest_Smoke_Waves_Complete %>%
  group_by(NAME) %>%
  filter(LongestWave == max(LongestWave)) %>%
  ungroup()

head(longest_smoke_waves_per_name)

# Export
path <- here("Output/WFS_M5_smoke_wave_annual.csv")
  write_csv(Longest_Smoke_Waves_Complete, path)
path <- here("Output/WFS_M5_smoke_wave_max_length.csv")
  write_csv(longest_smoke_waves_per_name, path)
