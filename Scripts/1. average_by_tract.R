# 1. average_by_tract.R

# Set up working directory and here() paths
setwd(here::here())
here::i_am("Scripts/1. average_by_tract.R")
knitr::opts_knit$set(root.dir = here::here())

# Load packages
library(ncdf4)
library(raster)
library(chron)
library(sf)
library(here)
library(tidyverse)
library(terra)
library(exactextractr)

# Load files
directory_WFS <- here("Raw_Data/Wildfire Smoke PM2.5")
  nc_files_WFS <- list.files(directory_WFS, full.names = TRUE) # WFS Files

directory_Total <- here("Raw_Data/Total PM2.5")
  nc_files_Total <- list.files(directory_Total, full.names = TRUE) # Total PM Files  

# Create an 'Output' folder
  if (!dir.exists("Output")) {
    dir.create("Output")
  }
  
# Cut up projection of Alaska Tracts to remove eastern portion
path_tracts_2020 <- here("Raw_Data/Shapefiles/Tracts2020.shp")
  Tracts2020 <- st_read(path_tracts_2020)
  Tracts2020 <- st_transform(Tracts2020, crs = "EPSG:4326") # Reproject to WFS 84

# Define the extent of the desired area of Alaska (e.g., using bounding box)
extent <- st_bbox(c(xmin = -180, ymin = 50, xmax = -130, ymax = 72), crs = st_crs(Tracts2020))

# Clip the shapefile to the defined extent
Tracts2020_clipped <- st_crop(Tracts2020, extent)
  plot(Tracts2020_clipped["NAME"])

# Create raster data from the netcdf files
# Create empty lists to store cleaned raster data
cleaned_rast_list_WFS <- list()
cleaned_rast_list_Total <- list()

# Loop through each NetCDF file for data cleaning - WFS PM
for (nc_file in nc_files_WFS) {
    # Load the raster data from NetCDF file
    rast_data_WFS <- rast(nc_file)
    
    # Replace negative values with zeros
    rast_data_WFS[rast_data_WFS < 0] <- 0
    
    # Add the cleaned raster data to the list
    cleaned_rast_list_WFS[[basename(nc_file)]] <- rast_data_WFS
}

# Loop through each NetCDF file for data cleaning - Total PM
for (nc_file in nc_files_Total) {
    # Load the raster data from NetCDF file
    rast_data_Total <- rast(nc_file)
    
    # Replace negative values with zeros
    rast_data_Total[rast_data_Total < 0] <- 0
    
    # Add the cleaned raster data to the list
    cleaned_rast_list_Total[[basename(nc_file)]] <- rast_data_Total
}

# Use Zonal Statistics to average by census tract
# Create empty lists to store zonal statistics dataframes
zonal_stats_list_WFS <- list()
zonal_stats_list_Total <- list()

# Loop through each cleaned raster data for zonal statistics calculation - WFS
for (nc_file in names(cleaned_rast_list_WFS)) {
    # Get the cleaned raster data
    rast_data_WFS <- cleaned_rast_list_WFS[[nc_file]]
    
    # Calculate zonal statistics
    mean_values_WFS <- exact_extract(rast_data_WFS, Tracts2020, fun = 'mean')
    
    # Create a dataframe for this file's results
    temp_df_WFS <- data.frame(NAME = Tracts2020$NAME,
                          PM2.5 = unlist(mean_values_WFS))
     
    # Store the dataframe in the list
    zonal_stats_list_WFS[[nc_file]] <- temp_df_WFS
}

# Loop through each cleaned raster data for zonal statistics calculation - Total
for (nc_file in names(cleaned_rast_list_Total)) {
    # Get the cleaned raster data
    rast_data_Total <- cleaned_rast_list_Total[[nc_file]]
    
    # Calculate zonal statistics
    mean_values_Total <- exact_extract(rast_data_Total, Tracts2020, fun = 'mean')
    
    # Create a dataframe for this file's results
    temp_df_Total <- data.frame(NAME = Tracts2020$NAME,
                          PM2.5 = unlist(mean_values_Total))
     
    # Store the dataframe in the list
    zonal_stats_list_Total[[nc_file]] <- temp_df_Total
}

# Merge these lists into a single dataframe
combined_results_WFS <- do.call(rbind, zonal_stats_list_WFS)
combined_results_Total <- do.call(rbind, zonal_stats_list_Total)

# Create Date Variable
# Extract year and month from rownames
date_info_WFS <- gsub('.*_(\\d{6})_.*\\.\\d+$', '\\1', rownames(combined_results_WFS))
date_info_Total <- gsub('.*_(\\d{6})_.*\\.\\d+$', '\\1', rownames(combined_results_Total))

# Extract the last set of characters after the last period
last_digit_WFS <- as.numeric(gsub('.*\\.(\\d+)$', '\\1', rownames(combined_results_WFS)))
last_digit_Total <- as.numeric(gsub('.*\\.(\\d+)$', '\\1', rownames(combined_results_Total)))

# Extract year and month
year_WFS <- sapply(date_info_WFS, function(x) substr(x, 1, 4))
month_WFS <- sapply(date_info_WFS, function(x) substr(x, 5, 6))

year_Total <- sapply(date_info_Total, function(x) substr(x, 1, 4))
month_Total <- sapply(date_info_Total, function(x) substr(x, 5, 6))


# Create month and year variables
combined_results_WFS$Year <- year_WFS
combined_results_WFS$Month <- month_WFS
combined_results_WFS$day_analog <- last_digit_WFS

combined_results_Total$Year <- year_Total
combined_results_Total$Month <- month_Total
combined_results_Total$day_analog <- last_digit_Total

# Arrange Dataframe

# Add a new column 'File_Layer' to store the previous row names
combined_results_WFS <- mutate(combined_results_WFS, File_Layer = rownames(combined_results_WFS))
combined_results_Total <- mutate(combined_results_Total, File_Layer = rownames(combined_results_Total))

# Group and arrange data - WFS
grouped_results_WFS <- combined_results_WFS %>%
  group_by(NAME, Month, Year) %>%
  arrange(day_analog) %>%
  # Add a new variable 'Day' that enumerates the rows within each group
  mutate(Day = row_number())

# Group and arrange data - Total PM
grouped_results_Total <- combined_results_Total %>%
  group_by(NAME, Month, Year) %>%
  arrange(day_analog) %>%
  # Add a new variable 'Day' that enumerates the rows within each group
  mutate(Day = row_number())

# Combine 'Month', 'Day', and 'Year' into a single date variable
grouped_results_WFS <- grouped_results_WFS %>%
  mutate(Date = as.Date(paste(Year, Month, Day, sep = "-")))

grouped_results_Total <- grouped_results_Total %>%
  mutate(Date = as.Date(paste(Year, Month, Day, sep = "-")))

# Print the grouped and sorted dataframe
head(grouped_results_WFS)
head(grouped_results_Total)

# Final Cleaning

# Ungroup the grouped dataframe
ungrouped_results_WFS <- grouped_results_WFS %>% ungroup()
ungrouped_results_Total <- grouped_results_Total %>% ungroup()

# Round values
ungrouped_results_WFS$PM2.5 <- round(ungrouped_results_WFS$PM2.5, 2)
ungrouped_results_Total$PM2.5 <- round(ungrouped_results_Total$PM2.5, 2)

summary(ungrouped_results_WFS$PM2.5)
summary(ungrouped_results_Total$PM2.5)

# Final Dataframe
PM25_by_Tracts_WFS <- ungrouped_results_WFS %>%
  dplyr::select(-Month, -Day, -Year, -File_Layer, -day_analog)
PM25_by_Tracts_Total <- ungrouped_results_Total %>%
  dplyr::select(-Month, -Day, -Year, -File_Layer, -day_analog)

# Clean Date Variable
PM25_by_Tracts_WFS$Date <- as.Date(PM25_by_Tracts_WFS$Date)
PM25_by_Tracts_Total$Date <- as.Date(PM25_by_Tracts_Total$Date)

#The WFS data needs to have zero values for all non-Wildfire season months (October-April)

# Create list of non-wfs dates
all_dates <- seq.Date(from = as.Date("2003-01-01"), to = as.Date("2020-12-31"), by = "day")
oct_to_april_dates <- all_dates[month(all_dates) %in% c(10, 11, 12, 1, 2, 3, 4)]

# Extract community names
unique_names <- unique(PM25_by_Tracts_WFS$NAME)

# Create a new dataframe with all combinations of NAME and dates for October-April, setting PM2.5 to zero
zero_data <- expand.grid(NAME = unique_names, Date = oct_to_april_dates)
zero_data$PM2.5 <- 0

# Combine the original dataframe with the new zero_data dataframe
PM25_by_Tracts_WFS_extended <- bind_rows(PM25_by_Tracts_WFS, zero_data)

# Arrange the combined dataframe by NAME and Date
PM25_by_Tracts_WFS <- PM25_by_Tracts_WFS_extended %>%
  arrange(NAME, Date)
tail(PM25_by_Tracts_WFS)

# Export
write.csv(PM25_by_Tracts_WFS, file = here("Output/Daily_Average_WFS_PM25_by_Census_Tract.csv") , row.names = FALSE)
write.csv(PM25_by_Tracts_Total, file = here("Output/Daily_Average_Total_PM25_by_Census_Tract.csv") , row.names = FALSE)
