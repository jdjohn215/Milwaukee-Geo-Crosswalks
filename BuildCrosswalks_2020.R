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

# intersect by centroid
unincluded.blocks <- blocks.2020 %>%
  filter(! block %in% blocks.to.neighborhoods$block) %>%
  mutate(geometry = st_centroid(geometry)) %>%
  select(block, geometry) %>%
  st_intersection(neighborhoods) %>%
  st_set_geometry(NULL) %>%
  mutate(prop_of_block = 1)

unincluded.blocks2 <- blocks.2020 %>%
  filter(! block %in% blocks.to.neighborhoods$block,
         ! block %in% unincluded.blocks$block,
         pop > 0) %>%
  select(block)
st_nearest_feature(unincluded.blocks2, neighborhoods)
unincluded.blocks2.1 <- unincluded.blocks2 %>%
  mutate(neighborhood = c(neighborhoods$neighborhood[65], neighborhoods$neighborhood[127])) %>%
  mutate(prop_of_block = 1)

blocks.to.neighborhoods2 <- blocks.to.neighborhoods %>%
  bind_rows(unincluded.blocks, unincluded.blocks2.1)
blocks.2020 %>%
  filter(block %in% blocks.to.neighborhoods2$block) %>% pull(pop) %>% sum()

write_csv(blocks.to.neighborhoods2, "Crosswalks/2020CensusBlocks_to_Neighborhoods.csv")
