# Metrics for assessing the population health impact of wildfire smoke in Alaska
### Created by: Melissa Bradley, Nelsha Athauda
### Version: 03/15/2025

## Background

This repository provides R and Python code that was used for analysis of a longitudinal wildfire smoke dataset created for the state of Alaska for May-September of 2003 to 2020 in order to assess seasonal and long-term population exposure to wildfire smoke and identify geospatial subdivisions and demographic groups that are most vulnerable to the population health impacts of wildfire smoke events. The findings of these analyses are available here: (Update link after publication).

## Methods

This was a descriptive ecological study that quantified population exposure to wildfire smoke in Alaska and created a wildfire smoke-specific social vulnerability index for Census tract-level bivariate mapping. Wildfire-specific fine particulate matter (PM2.5) exposure estimates were generated aggregated to the census tract level for 2003-2020. Census tract information was obtained from the Alaska Department of Labor and Statistics. Next, we calculated the frequency and duration of smoke waves, person-days of exposure to medium and heavy smoke based on EPA AQI classification of "Unhealthy for Sensitive Groups" and "Unhealthy", and census tract-level wildfire smoke-specific social vulnerability rankings. 

### PM2.5 Concentration Averaging through Zonal Statistics
To accurately average smoke PM2.5 concentrations, we began by processing raw modeled data produced from our GEOS-Chem model. The model outputs smoke PM2.5 concentrations in a large set of NetCDF (Network Common Data Form) files. NetCDF is a platform-independent data format that efficiently stores and organizes large, multidimensional scientific data. Each NetCDF file contains geospatial and temporal data to store PM2.5 values in a large grid across Alaska, for each day from 2003 to 2020.

The first step in the averaging process involved applying zonal statistics to the raw GEOS-Chem NetCDF files. Zonal statistics is a spatial analysis technique used to summarize data values within specified geographic areas—in this case, the boundaries of Alaskan census tracts. Using this method, we extracted the smoke PM2.5 data from the gridded raw data and calculated daily PM2.5 concentration averages for each census tract. 

### Wildfire Smoke Metrics
Using the dataset of smoke PM2.5 values by census tract, we then calculated several wildfire smoke metrics:

1. Mean daily wildfire PM2.5 concentration during wildfire season
2. Annual mean daily wildfire PM2.5 concentration
3. Mean daily wildfire PM2.5 concentration on 10 days with highest PM2.5 concentration each year
4. Number of days with medium wildfire smoke density or worse
5. Number of days with heavy wildfire smoke density
6. Number of smoke waves
7. Maximum length of smoke wave

These metrics were derived to measure the frequency, duration, and concentration of long-term exposure to smoke PM2.5

### Person-Days Calculations

### Wildfire Smoke Social Vulnerability Index 

## Data

Available in the **/raw_data/** folder are the following subfolders and files:

## Scripts

Available in the **/scripts/** folder are the following files:
- **1. average_by_tract.R** - Averages WFS PM2.5 by census tract using zonal statistics
- **2. average_daily_wfs_pm25_during_wfs_season.ipynb** - Calculates and maps 'Mean daily wildfire PM2.5 concentration during wildfire season'
- **3. average_daily_wfs_pm25_full_year.ipynb** - Calculates and maps 'Annual mean daily wildfire PM2.5 concentration'
- **4. average_daily_wfs_pm25_10_smokiest_days.ipynb** - Calculates and maps 'Mean daily wildfire PM2.5 concentration on 10 days with highest PM2.5 concentration each year'
- **5. medium_smoke_days.ipynb** - Calculates and maps 'Number of days with medium wildfire smoke density or worse'
- **6. heavy_smoke_days.ipynb** - Calculates and maps 'Number of days with heavy wildfire smoke density'
- **7. number_smoke_waves.R** - Calculates 'Number of smoke waves'
- **8. number_smoke_waves_maps.ipynb** - Maps 'Number of smoke waves'
- **9. max_length_smoke_wave.R** -  Calculates 'Maximum length of smoke wave'
- **10. max_length_smoke_wave_maps.ipynb** - Maps 'Maximum length of smoke wave'
- **11. Population Person-Days.rmd** - Calculates person-days, assigns categorical level of exposure
- **12. High PM Tract Census Demographics and SVI.rmd** - Creates Wildfire Smoke Social Vulnerability Index and identifies + bivariate maps High PM and High WSSVI tracts
- **13. PM_Methods_Stats.r** - Produces prevalence rates of WSSVI metrics of High PM tracts in table form and identifies annual first and last weeks of Medium and Heavy smoke exposure by month
