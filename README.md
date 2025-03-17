# Metrics for assessing the population health impact of wildfire smoke in Alaska
### Created by: Melissa Bradley, Nelsha Athauda
### Version: 03/16/2025

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

These metrics were derived to measure the frequency, duration, and concentration of long-term exposure to smoke PM2.5.

### Person-Days Calculations

Person-days is a metric for quantifying population health impacts of wildfire smoke that combines the spatial distribution of the hazard with population distribution. The dataset of daily average WFS PM2.5 values by census tract was classified using the EPA's Air Quality Index standards for PM2.5:

* Good AQI: PM2.5 levels 0.0–9.0 µg/m³, minimal health risk.
* Unhealthy for Sensitive Groups AQI: PM2.5 levels 9.1–35.4 µg/m³, moderate health risk, especially for sensitive groups.
* Unhealthy and higher AQI: PM2.5 levels >35.5 µg/m³, substantial health risks.

Unhealthy for Sensitive Groups AQI days were classified as Medium smoke density days, and Unhealthy and higher AQI level days were classified as Heavy smoke density days. For each census tract and day, we calculated person-days for each exposure level by multiplying each census tract’s population by each level’s indicator variable.The dataset was structured to include daily person-days calculations by smoke density levels, which were then aggregated by year and exposure category to allow for temporal and spatial trend analyses.

### Wildfire Smoke Social Vulnerability Index 

## Data

Available in the **/raw_data/** folder are the following subfolders and files:
**/Shapefiles/**
- **Tracts2020.dbf, Tracts2020.prj, Tracts2020.sbn, Tracts2020.sbx, Tracts2020.shp, Tracts2020.shp, Tracts2020.shx** - These files form the Alaska Census Tract Boundaries shapefile from the [Alaska 
Department of Labor and Workforce Development](https://live.laborstats.alaska.gov/article/maps-gis-data)

**/Total PM2.5/**
- This folder contains 215 netCDF files with raw, year-round GEOS-Chem modeled PM2.5 data from all sources

**/Wildfire Smoke PM2.5/**
- This folder contains 90 netCDF files with raw GEOS-Chem modeled PM2.5 data attributed to wildfire smoke during the wildfire season (May–September)

### Linked Data Sources

Housed externally from the repo are the following sources used in the present code: 

**[Alaska Wildfire Number of Fires and Acres Burned Since 1950](https://fire.ak.blm.gov/content/aicc/Statistics%20Directory/Alaska%20Fire%20History%20Chart.pdf)**

- This chart from the [Alaska Interagency Coordination Center](https://fire.ak.blm.gov/) contains yearly burned acreage for the state of Alaska since 1950.
  
**[2020 State-Level CDC Social Vulnerability Index (SVI) by Census Tract dataset](https://www.atsdr.cdc.gov/place-health/php/svi/svi-data-documentation-download.html)**

-The CDC SVI is a composite dataset derived from variables sourced from the Behavioral Risk Factor Surveillance System (BRFSS), the U.S. Census, and the ACS 5-Year Estimates.

**[2024 CDC PLACES Dataset](https://www.atsdr.cdc.gov/place-health/php/svi/svi-data-documentation-download.html)**

-This composite dataset includes Census Tract-level model-based estimates generated using 2021–2022 BRFSS data, 2020 Census population data, and ACS 2018–2022 estimates. The 2024 release was selected to align with the 2020 Census geographic boundaries, marking the first release to do so.

### Other Sources

-US Census Bureau American Community Survey (ACS) 5-Year Estimates were accessed via the Census API using the R package <i> [tidycensus](https://walker-data.com/tidycensus/) </i>.

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
