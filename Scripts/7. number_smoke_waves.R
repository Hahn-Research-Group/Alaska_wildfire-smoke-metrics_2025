# 7. number_smoke_waves.R

# Load packages
library(here)
library(tidyverse)

# Set up working directory and here() paths
setwd(here::here())
here::i_am("Scripts/7. number_smoke_waves.R")
knitr::opts_knit$set(root.dir = here::here())

# Load Raw WFS PM2.5 tract averages
PM25_by_Tracts_WFS <- read.csv(here("Output/Daily_Average_WFS_PM25_by_Census_Tract.csv"))
PM25_by_Tracts_WFS$Date <- as.Date(PM25_by_Tracts_WFS$Date)
PM25_by_Tracts_WFS$Year <- as.numeric(format(PM25_by_Tracts_WFS$Date,'%Y'))

# If the data is over or equal to 9, it is a '1'. Everything else is now 0
PM25_by_Tracts_WFS$Binary <- ifelse(PM25_by_Tracts_WFS$PM2.5 >= 9, 1, 0)
head(PM25_by_Tracts_WFS)

# Group the data by NAME and Year
grouped_data <- PM25_by_Tracts_WFS %>%
  group_by(NAME)

# Define a function to reorder the 'Date' column within each group
reorder_dates <- function(df) {
  df <- df %>% arrange(Date)
  return(df)
}

# Apply the function to each group in the grouped DataFrame
grouped_data <- grouped_data %>% group_modify(~ reorder_dates(.))
table(grouped_data$Binary)

# Remove smoky days (Value = 1) in which the day before or after was '0' 
# Minimum of two consecutive smoky days are required to be considered a smoke wave.

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

#Count how many chunks of '1' values are present in each tract, for each year.
#Sum up the number of waves each year to calculate the total. 

# Function to count chunks of consecutive '1' values
count_chunks <- function(x) {
  # Identify and count the chunks of consecutive '1' values
  chunks <- rle(x == 1)
  num_chunks <- sum(chunks$values & chunks$lengths >= 2)
  return(num_chunks)
}

# Count chunks of consecutive '1' values for each group
chunk_counts <- grouped_data %>%
  group_by(NAME, Year) %>%  # Group by NAME and Year
  reframe(Smoke_Waves = count_chunks(Binary), .groups = 'drop') # Count per year

# Calculate total smoke waves across all years for each NAME
total_counts <- chunk_counts %>%
  group_by(NAME) %>%
  reframe(Total_Smoke_Waves = sum(Smoke_Waves), .groups = 'drop')

# Combine yearly counts with total counts
WFS_M4 <- chunk_counts %>% left_join(total_counts, by = "NAME")
  head(WFS_M4)

# Transform the data to have 'NAME' and separate columns for each year's smoke wave count
WFS_M4 <- WFS_M4 %>%
  pivot_wider(
    names_from = Year,  # Column to spread (Years)
    values_from = Smoke_Waves,  # Values to fill in the new columns
    values_fill = list(Smoke_Waves = 0)  # Fill NA with 0 for years with no waves
  ) %>%
  # Rename the total smoke waves column
  rename(Total_Smoke_Waves = Total_Smoke_Waves)

# Reorder the columns to move 'Total_Smoke_Waves' to the end
WFS_M4 <- WFS_M4[, c("NAME", colnames(WFS_M4)[-c(1, 2)], colnames(WFS_M4)[2])]
  head(WFS_M4)

# Remove .groups variables
WFS_M4 <- WFS_M4[, !(colnames(WFS_M4) %in% c(".groups.y", ".groups.x"))]
  
# Export 
path <- here("Output/WFS_M4_smoke_waves.csv")
write_csv(WFS_M4, path)
