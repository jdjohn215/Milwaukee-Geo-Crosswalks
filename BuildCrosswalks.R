library(tidyverse)
library(sf)
options(stringsAsFactors = FALSE,
        scipen = 999)

# get current parcel outlines from https://data.milwaukee.gov/dataset/parcel-outlines
# this version was last updated December 12, 2019
parcels <- readRDS("SourceData/ParcelPolygons.rds")

# get Milwaukee geographies
neighborhoods <- readRDS("SourceData/MilwaukeeNeighborhoods.rds")
tracts <- readRDS("SourceData/MilwaukeeCensusTracts2017.rds")
blocks <- readRDS("SourceData/MilwaukeeCensusBlocks2010.rds")
wards <- readRDS("SourceData/MilwaukeeWards2018.rds")
blockgroups <- readRDS("SourceData/MilwaukeeBlockGroups2017.rds")

# 1. select residential parcels
# 2. reduce to centroids
# 3. add geography codes
residential <- parcels %>%
  filter(LandUse < 5) %>%
  select(Taxkey, bedrooms = NumberOfBe) %>%
  # change studio apartments to 1-bedrooms (because they have 1 bed)
  mutate(bedrooms = replace(bedrooms, bedrooms == 0, 1)) %>%
  st_centroid() %>%
  st_intersection(neighborhoods) %>%
  st_intersection(tracts) %>%
  st_intersection(wards) %>%
  st_intersection(blocks) %>%
  st_intersection(blockgroups)


# this function creates a crosswalk between two geographies
make.crosswalk <- function(target_geo, data_geo){
  residential %>%
    st_set_geometry(NULL) %>%
    # find total bedrooms in data_geo
    group_by({{data_geo}}) %>%
    mutate(data.geo.total = sum(bedrooms)) %>%
    # find bedrooms in target_geo data_geo overlap
    group_by({{target_geo}}, {{data_geo}}) %>%
    summarise(bedrooms = sum(bedrooms),
              pct.of.data.geo = bedrooms/first(data.geo.total)) %>%
    group_by({{target_geo}}) %>%
    mutate(pct.of.target.geo = bedrooms/sum(bedrooms)) %>%
    ungroup()
}

tracts.to.neighborhood <- make.crosswalk(target_geo = neighborhood, data_geo = tract) %>%
  rename(pct.of.neighborhood = pct.of.target.geo,
         pct.of.tract = pct.of.data.geo)
blocks.to.neighborhood <- make.crosswalk(target_geo = neighborhood, data_geo = block) %>%
  rename(pct.of.neighborhood = pct.of.target.geo,
         pct.of.block = pct.of.data.geo)
wards.to.neighborhood <- make.crosswalk(target_geo = neighborhood, data_geo = ward) %>%
  rename(pct.of.neighborhood = pct.of.target.geo,
         pct.of.ward = pct.of.data.geo)
blocks.to.wards <- make.crosswalk(target_geo = ward, data_geo = block) %>%
  rename(pct.of.ward = pct.of.target.geo,
         pct.of.block = pct.of.data.geo)
blockgroups.to.wards <- make.crosswalk(target_geo = ward, data_geo = blockgroup) %>%
  rename(pct.of.ward = pct.of.target.geo,
         pct.of.blockgroup = pct.of.data.geo)
blocksgroups.to.neighborhood <- make.crosswalk(target_geo = neighborhood, data_geo = blockgroup) %>%
  rename(pct.of.neighborhood = pct.of.target.geo,
         pct.of.blockgroup = pct.of.data.geo)

write_csv(tracts.to.neighborhood, "Crosswalks/2017CensusTracts_to_Neighborhoods.csv")
write_csv(blocks.to.neighborhood, "Crosswalks/2010CensusBlocks_to_Neighborhoods.csv")
write_csv(wards.to.neighborhood, "Crosswalks/2018VotingWards_to_Neighborhoods.csv")
write_csv(blocks.to.wards, "Crosswalks/2010CensusBlocks_to_2018VotingWards.csv")
write_csv(blockgroups.to.wards, "Crosswalks/2017CensusBlockGroups_to_2018VotingWards.csv")
write_csv(blocksgroups.to.neighborhood, "Crosswalks/2017CensusBlockGroups_to_Neighborhoods.csv")
