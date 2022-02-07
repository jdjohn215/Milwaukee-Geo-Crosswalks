rm(list = ls())

library(tidyverse)
library(sf)

blocks.2020 <- read_rds("SourceData/MilwaukeeCensusBlocks2020.rds")
neighborhoods <- read_rds("SourceData/MilwaukeeNeighborhoods.rds") %>%
  st_transform(crs = st_crs(blocks.2020))
parcels.2021 <- read_rds("SourceData/ParcelBedrooms_2021.rds")
parcels.intersected <- parcels.2021 %>%
  group_by(x, y) %>%
  summarise(bedrooms = sum(bedroom_weight)) %>%
  ungroup() %>%
  st_as_sf(coords = c("x","y"), crs = 32054) %>%
  st_transform(crs = st_crs(blocks.2020)) %>%
  st_intersection(blocks.2020 %>% select(block)) %>%
  st_intersection(neighborhoods) %>%
  st_set_geometry(NULL)

blocks.to.neighborhoods <- parcels.intersected %>%
  group_by(block) %>%
  mutate(block_total = sum(bedrooms)) %>%
  group_by(block, neighborhood, block_total) %>%
  summarise(bedrooms = sum(bedrooms)) %>%
  ungroup() %>%
  mutate(prop_of_block = (bedrooms/block_total))

write_csv(blocks.to.neighborhoods, "Crosswalks/2020CensusBlocks_to_Neighborhoods.csv")
