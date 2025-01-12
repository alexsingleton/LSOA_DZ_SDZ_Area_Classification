# Aggregate ONS Output Area Classification (OAC) for UK LSOA/DZ/SDZ

This repository provides code to **aggregate** the 2021 Output Area Classification (OAC) from the lowest geographical level (Output Areas) to:

- 2021 **Lower Layer Super Output Areas (LSOA)** in England & Wales  
- 2022 **Data Zones (DZ)** in Scotland  
- 2021 **Super Data Zones (SDZ)** in Northern Ireland  

---

## Overview

This code **aggregates** OAC classifications from UK Census Output Areas up to their respective mid-level geographies (LSOA/DZ/SDZ). It then selects the *dominant* OAC Subgroup within each mid-level geography based on the largest total population contribution, effectively classifying each LSOA, DZ, or SDZ by the most populous Subgroup within it.

The workflow is as follows:

1. **Merge** a lookup table of Output Areas to LSOA/DZ/SDZ.  
2. **Import** OAC classifications for all Output Areas.  
3. **Join** total population counts.  
4. **Aggregate** OAC Subgroups to the mid-level geography.  
5. **Generate** a final aggregated classification.  
6. **Compare** original OA-level classification with aggregated classification using an alluvial plot.  
7. **Export** final outputs as CSV, Parquet, and GeoPackage files.

---

## Requirements

The script uses the following R packages:

- **tidyverse**  
- **arrow**  
- **magrittr**  
- **sf**  
- **ggalluvial**  

Make sure these packages are installed before running the script:
```r
install.packages(c("tidyverse", "magrittr", "sf", "ggalluvial"))
# For 'arrow', install from CRAN or the appropriate binary source
install.packages("arrow")
```

---

## Data Sources

1. **Lookup: OA to LSOA / DZ / SDZ**  
   - [github.com/alexsingleton/UK_Census_Geography](https://github.com/alexsingleton/UK_Census_Geography)  
   - Specifically: `./data/lookup/LSOA_DZ_SDZ/UK.csv`

2. **OAC Input**  
   - Parquet file: `./data/UK_OAC_Final.parquet`  

3. **Total Population Data**  
   - **England & Wales**: [ts001.parquet (GitHub)](https://github.com/Geographic-Data-Service/Census_2021_Output_Areas/raw/refs/heads/main/output_data/parquet/ts001.parquet)  
   - **Scotland**: [UV101b.parquet (GitHub)](https://github.com/Geographic-Data-Service/Scotland_Census_2022_OA/raw/refs/heads/main/output_data/parquet/UV101b.parquet)  
   - **Northern Ireland**: [ni193.parquet (GitHub)](https://github.com/Geographic-Data-Service/Northern_Ireland_Census_2022_Data_Zone/raw/refs/heads/main/output_data/parquet/ni193.parquet)

4. **Geographical Boundaries** (9 chunks of LSOA/DZ/SDZ in GeoPackage format):  
   - [github.com/alexsingleton/UK_Census_Geography/](https://github.com/alexsingleton/UK_Census_Geography)  
   - Specifically: `./data/LSOA_DZ_SDZ/chunk_[1-9]UK_LSOA_DZ_SDZ.gpkg`

---

## Usage

1. **Clone or download** this repository.  
2. **Place** the required data files in the correct directories, as indicated in the script (e.g., `./data/UK_OAC_Final.parquet`).
3. **Install** the required R packages (see [Requirements](#requirements)).
4. **Open** the R script (or copy-paste it into an R environment).  
5. **Run** the script from start to finish.  

The script will read data from the specified sources, perform the aggregation, and produce outputs including CSV, Parquet, GeoPackages, and a comparison plot.

---

## Comparison

The script produces an **alluvial plot** (`Comparison.png`) showing how **Supergroups** at the Output Area level flow into the **aggregated** Supergroups at the LSOA/DZ/SDZ level.  
- *Left Axis:* Original OA-level Supergroups  
- *Right Axis:* Aggregated LSOA/DZ/SDZ Supergroups  

This helps visualize the degree of alignment or shifts in classification that occur during aggregation.

### Statistical Summaries

Several tables and data frames show how many distinct **Subgroups**, **Groups**, and **Supergroups** are contained within each LSOA, DZ, or SDZ. This reveals how homogeneous or diverse each mid-level geography is in terms of OAC classes.  

- `Compare_Subgroup`, `Compare_Group`, and `Compare_Supergroup`  
  - Show distributions of how many different classes exist per LSOA/DZ/SDZ.  
- `n_all`  
  - Merges the counts of distinct Supergroups, Groups, and Subgroups.  

These outputs are joined to the spatial data frame and written to `LSOA_DZ_SDZ_SF_Counts.gpkg`.

---

## Acknowledgments

- **ONS Output Area Classification**: Data provided under the Open Government Licence.  
- **Geography Boundaries**: Sourced from [ONS](https://www.ons.gov.uk/), [NRS](https://www.nrscotland.gov.uk/), and [NISRA](https://www.nisra.gov.uk/).  
- **Code Contributors**: [@alexsingleton](https://github.com/alexsingleton), Geographic Data Service.  

For any questions or issues, please open a GitHub issue or reach out to the authors.

---  