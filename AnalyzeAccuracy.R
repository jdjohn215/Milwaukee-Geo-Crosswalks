library(tidyverse)

blocks.to.neighborhoods <- read_csv("Crosswalks/2010CensusBlocks_to_Neighborhoods.csv")
blocks.to.wards <- read_csv("Crosswalks/2010CensusBlocks_to_2018VotingWards.csv")
tracts.to.neighborhoods <- read_csv("Crosswalks/2017CensusTracts_to_Neighborhoods.csv")
wards.to.neighborhoods <- read_csv("Crosswalks/2018VotingWards_to_Neighborhoods.csv")

explore.blocks.to.neighborhoods <- blocks.to.neighborhoods %>%
  mutate(group = "100%",
         group = replace(group, pct.of.block < 1, "98-100"),
         group = replace(group, pct.of.block < 0.98, "90-98"),
         group = replace(group, pct.of.block < 0.9, "80-90"),
         group = replace(group, pct.of.block < 0.8, "70-80"),
         group = replace(group, pct.of.block < 0.7, "60-70"),
         group = replace(group, pct.of.block < 0.6, "50-60"),
         group = replace(group, pct.of.block < 0.5, "less than 50"),
         group = factor(group, levels = c("100%", "98-100", "90-98",
                                          "80-90", "70-80", "60-70",
                                          "50-60", "less than 50"))) %>%
  mutate(total.bedrooms = sum(bedrooms)) %>%
  group_by(group) %>%
  summarise(bedrooms = sum(bedrooms)/first(total.bedrooms)) %>%
  rename(`blocks to neighborhoods` = bedrooms)



explore.blocks.to.wards <- blocks.to.wards %>%
  mutate(group = "100%",
         group = replace(group, pct.of.block < 1, "98-100"),
         group = replace(group, pct.of.block < 0.98, "90-98"),
         group = replace(group, pct.of.block < 0.9, "80-90"),
         group = replace(group, pct.of.block < 0.8, "70-80"),
         group = replace(group, pct.of.block < 0.7, "60-70"),
         group = replace(group, pct.of.block < 0.6, "50-60"),
         group = replace(group, pct.of.block < 0.5, "less than 50"),
         group = factor(group, levels = c("100%", "98-100", "90-98",
                                          "80-90", "70-80", "60-70",
                                          "50-60", "less than 50"))) %>%
  mutate(total.bedrooms = sum(bedrooms)) %>%
  group_by(group) %>%
  summarise(bedrooms = sum(bedrooms)/first(total.bedrooms)) %>%
  rename(`blocks to wards` = bedrooms)


explore.tracts.to.neighborhoods <- tracts.to.neighborhoods %>%
  mutate(group = "100%",
         group = replace(group, pct.of.tract < 1, "98-100"),
         group = replace(group, pct.of.tract < 0.98, "90-98"),
         group = replace(group, pct.of.tract < 0.9, "80-90"),
         group = replace(group, pct.of.tract < 0.8, "70-80"),
         group = replace(group, pct.of.tract < 0.7, "60-70"),
         group = replace(group, pct.of.tract < 0.6, "50-60"),
         group = replace(group, pct.of.tract < 0.5, "less than 50"),
         group = factor(group, levels = c("100%", "98-100", "90-98",
                                          "80-90", "70-80", "60-70",
                                          "50-60", "less than 50"))) %>%
  mutate(total.bedrooms = sum(bedrooms)) %>%
  group_by(group) %>%
  summarise(bedrooms = sum(bedrooms)/first(total.bedrooms)) %>%
  rename(`tracts to neighborhoods` = bedrooms)


explore.wards.to.neighborhoods <- wards.to.neighborhoods %>%
  mutate(group = "100%",
         group = replace(group, pct.of.ward < 1, "98-100"),
         group = replace(group, pct.of.ward < 0.98, "90-98"),
         group = replace(group, pct.of.ward < 0.9, "80-90"),
         group = replace(group, pct.of.ward < 0.8, "70-80"),
         group = replace(group, pct.of.ward < 0.7, "60-70"),
         group = replace(group, pct.of.ward < 0.6, "50-60"),
         group = replace(group, pct.of.ward < 0.5, "less than 50"),
         group = factor(group, levels = c("100%", "98-100", "90-98",
                                          "80-90", "70-80", "60-70",
                                          "50-60", "less than 50"))) %>%
  mutate(total.bedrooms = sum(bedrooms)) %>%
  group_by(group) %>%
  summarise(bedrooms = sum(bedrooms)/first(total.bedrooms)) %>%
  rename(`wards to neighborhoods` = bedrooms)

explore.accuracy <- full_join(explore.blocks.to.neighborhoods,
                              explore.blocks.to.wards) %>%
  full_join(explore.tracts.to.neighborhoods) %>%
  full_join(explore.wards.to.neighborhoods) %>%
  pivot_longer(cols = -group) %>%
  mutate(value = value*100,
         value = replace(value, is.na(value), 0)) %>%
  pivot_wider(names_from = "name", values_from = "value")

saveRDS(explore.accuracy, "SourceData/AccuracyComparison.rds")
