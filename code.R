library(tidyverse)
library(arrow)
library(magrittr)
library(sf)
library(ggalluvial)

# Read OA to LSOA / DZ / SDZ Lookup
UK_OA_Agg <- read_csv("https://raw.githubusercontent.com/alexsingleton/UK_Census_Geography/refs/heads/main/data/lookup/LSOA_DZ_SDZ/UK.csv")

# Read OAC Input OA
Final_OAC <- read_parquet("./data/UK_OAC_Final.parquet")
Final_OAC %<>% rename(OA = Geography_Code)

# Get total population data
E_W <- read_parquet("https://github.com/Geographic-Data-Service/Census_2021_Output_Areas/raw/refs/heads/main/output_data/parquet/ts001.parquet")  # Residence type: Total; measures: Value
S <- read_parquet("https://github.com/Geographic-Data-Service/Scotland_Census_2022_OA/raw/refs/heads/main/output_data/parquet/UV101b.parquet") #UV1120001 - Usual resident population by sex by age (6) - All people: All people: Total - UV101b0001
NI <- read_parquet("https://github.com/Geographic-Data-Service/Northern_Ireland_Census_2022_Data_Zone/raw/refs/heads/main/output_data/parquet/ni193.parquet") # Sex: All PEOPLE - ni1930001

E_W %<>%
  rename(totpop = ts0010001) %>%
  select(OA, totpop)

S %<>%
  rename(totpop = UV101b0001)%>%
  select(OA, totpop)

NI %<>%
  rename(totpop = ni1930001)%>%
  rename(OA = DZ)%>%
  select(OA, totpop)

UK_Pop <- E_W %>%
  bind_rows(S,NI) %>%
  as_tibble()

# Create the combined tibble
UK_OA_Agg %<>%
  left_join(Final_OAC) %>%
  left_join(UK_Pop)

# Allocation
LSOA_DZ_SDZ_Lookup <- UK_OA_Agg %>%
    group_by(geography_code, Subgroup) %>%
      summarize(totpop = sum(totpop, na.rm = TRUE)) %>%
      group_by(geography_code) %>%
      slice_max(totpop, n = 1, with_ties = FALSE) %>%
      mutate(Group = substr(Subgroup,1,2)) %>%
      mutate(Supergroup = substr(Subgroup,1,1)) %>%
      select(-totpop)

write_csv(LSOA_DZ_SDZ_Lookup, "./data/LSOA_DZ_SDZ_Lookup.csv")
write_parquet(LSOA_DZ_SDZ_Lookup, "./data/LSOA_DZ_SDZ_Lookup.parquet")

# Create gpkg

urls <- paste0(
  "https://github.com/alexsingleton/UK_Census_Geography/raw/refs/heads/main/data/LSOA_DZ_SDZ/chunk_",
  1:9,
  "UK_LSOA_DZ_SDZ.gpkg"
)

LSOA_DZ_SDZ_SF <- urls %>%
  map_dfr(~ read_sf(.x))


# Append lookup and export

LSOA_DZ_SDZ_SF %<>% 
  left_join(LSOA_DZ_SDZ_Lookup)

st_write(LSOA_DZ_SDZ_SF,"LSOA_DZ_SDZ_SF.gpkg")





# Compare OA and LSOA DZ SDZ Distribution

LSOA_DZ_SDZ_Lookup %<>%
  rename(Subgroup_Agg = Subgroup,
         Group_Agg = Group,
         Supergroup_Agg = Supergroup)

Compare_Classification <- UK_OA_Agg %>%
  left_join(LSOA_DZ_SDZ_Lookup)


# --------------------------------
# % Alluvial Plot
# --------------------------------


# Define the labels for Supergroups
supergroup_labels <- c(
  "1: Retired Professionals",
  "2: Suburbanites\n& Peri-Urbanites",
  "3: Multicultural\n& Educated Urbanites",
  "4: Low-Skilled Migrant\n& Student Communities",
  "5: Ethnically Diverse\nSuburban Professionals",
  "6: Baseline UK",
  "7: Semi &\nUn-Skilled Workforce",
  "8: Legacy Communities"
)

# Replace Supergroup numbers with labels
Compare_Classification <- Compare_Classification %>%
  mutate(Supergroup  = factor(Supergroup, levels = 1:8, labels = supergroup_labels)) %>%
  mutate(Supergroup_Agg = factor(Supergroup_Agg, levels = 1:8, labels = supergroup_labels))

# Create cross-tabulation
cross_tab <- Compare_Classification %>%
  count(Supergroup, Supergroup_Agg) %>%
  rename(Freq = n)


# Plot flows using ggalluvial
plot <- ggplot(cross_tab, aes(
  axis1 = Supergroup,
  axis2 = Supergroup_Agg,
  y = Freq
)) +
  geom_alluvium(aes(fill = Supergroup)) +
  geom_stratum() +
  geom_text(stat = "stratum", aes(label = after_stat(stratum)), size= 2.5) +
  labs(
    x = NULL,
    y = NULL
  ) +
  scale_fill_manual(values = c("#C7BB9D","#6DAB57","#E23921","#E38ABC","#E88631","#F2CB4C","#5881F6","#8C569E")) +
  theme_minimal() +
  theme(
    axis.text.x = element_blank(),  # Remove x-axis tick labels
    axis.text.y = element_blank(),  # Remove y-axis tick labels
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    legend.position = "none"
  )

ggsave("./plot/Comparison.png", plot = plot, device = "png", width = 6, height = 4, dpi = 300)




# Stats

# These three tables show the frequency of OAC classes within each LSOA, DZ, SDZ 

Compare_Subgroup <- Compare_Classification %>%
          # Count distinct Subgroups per geography_code
          group_by(geography_code) %>%
          summarize(n_subgroups = n_distinct(Subgroup)) %>%
          # Count how many geography_code have each distinct n_subgroups value
          count(n_subgroups) %>%
          # Calculate %
          mutate(percentage = round(n / sum(n) * 100))

Compare_Group <- Compare_Classification %>%
          # Count distinct Subgroups per geography_code
          group_by(geography_code) %>%
          summarize(n_groups = n_distinct(Group)) %>%
          # Count how many geography_code have each distinct n_subgroups value
          count(n_groups) %>%
          # Calculate %
          mutate(percentage = round(n / sum(n) * 100))

Compare_Supergroup <- Compare_Classification %>%
          # Count distinct Subgroups per geography_code
          group_by(geography_code) %>%
          summarize(n_supergroup = n_distinct(Supergroup)) %>%
          # Count how many geography_code have each distinct n_subgroups value
          count(n_supergroup) %>%
          # Calculate %
          mutate(percentage = round(n / sum(n) * 100))


# This creates the counts by LSOA, DZ, SDZ

n_Supergroup <- Compare_Classification %>%
                distinct(geography_code, Supergroup) %>% # Get unique combinations
                group_by(geography_code) %>% # Group by geography_code
                summarise(Supergroup_count = n())

n_Group <- Compare_Classification %>%
                distinct(geography_code, Group) %>% # Get unique combinations
                group_by(geography_code) %>% # Group by geography_code
                summarise(Group_count = n())

n_Subgroup <- Compare_Classification %>%
                distinct(geography_code, Subgroup) %>% # Get unique combinations
                group_by(geography_code) %>% # Group by geography_code
                summarise(Subgroup_count = n())


# Combine Results
n_all <- n_Supergroup %>%
         left_join(n_Group) %>%
         left_join(n_Subgroup)

LSOA_DZ_SDZ_SF %<>% 
  left_join(n_all)

st_write(LSOA_DZ_SDZ_SF,"LSOA_DZ_SDZ_SF_Counts.gpkg")




