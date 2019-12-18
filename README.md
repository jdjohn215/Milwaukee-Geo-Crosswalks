
# Milwaukee-Geo-Crosswalks

This repo creates crosswalks between common Milwaukee geographies, e.g
census tracts and neighborhood.

**Download the crosswalks as CSVs**

  - [Census blocks (2010) to voting wards
    (2018)](https://github.com/jdjohn215/Milwaukee-Geo-Crosswalks/blob/master/Crosswalks/2010CensusBlocks_to_2018VotingWards.csv)
  - [Census blocks (2010) to
    neighborhoods](https://github.com/jdjohn215/Milwaukee-Geo-Crosswalks/blob/master/Crosswalks/2010CensusBlocks_to_Neighborhoods.csv)
  - [Census tracts (2017) to
    neighborhoods](https://github.com/jdjohn215/Milwaukee-Geo-Crosswalks/blob/master/Crosswalks/2017CensusTracts_to_Neighborhoods.csv)
  - [Voting wards (2018) to
    neighborhoods](https://github.com/jdjohn215/Milwaukee-Geo-Crosswalks/blob/master/Crosswalks/2018VotingWards_to_Neighborhoods.csv)

## What is this?

When working with spatial data, the info we want is often available for
a different kind of geography than the areas we care about. For example,
some Census tracts are located entirely within neighborhoods, but others
straddle two or more. The crosswalk files I’ve provided above allow data
users to conveniently (dis)aggregate data from geography into another.

## Method

A quick way of creating a crosswalk is just to intersect the land areas
of the two geographies. If 45% of geography A’s land lies within
geography B, then 45% of geography A’s data is assigned to geography B.
My method is a bit more sophisticated. I take the centroid of every
residential parcel in the City of Milwaukee and intersect it with the
data source geography. Then I calculate the proportion of *bedrooms* in
geography A which are also in geography B.

## How it works

Here is what the crosswalks look like.

There is 1 row for every target geography TO data geography
combination–in this case Census blocks to neighborhoods. The first
line tells us that there are 154 bedrooms in both Alcott Park and Census
block 550790195001005. These 154 bedrooms make up 100% of the bedrooms
in the Census block, and they make up 9.4% of the bedrooms in Alcott
Park.

| neighborhood | block           | bedrooms | pct.of.block | pct.of.neighborhood |
| :----------- | :-------------- | -------: | -----------: | ------------------: |
| ALCOTT PARK  | 550790195001005 |      154 |            1 |           0.0939597 |
| ALCOTT PARK  | 550790195001006 |      238 |            1 |           0.1452105 |
| ALCOTT PARK  | 550790195001007 |      113 |            1 |           0.0689445 |
| ALCOTT PARK  | 550790195001008 |      109 |            1 |           0.0665040 |
| ALCOTT PARK  | 550790195002008 |      133 |            1 |           0.0811470 |
| ALCOTT PARK  | 550790195002009 |      138 |            1 |           0.0841977 |

Here are the 2010 decennial census population counts for each block.

| block           | pop |
| :-------------- | --: |
| 550790001011003 | 139 |
| 550790001011000 |  77 |
| 550790001011001 | 235 |
| 550790001011002 |  73 |
| 550790001011004 | 865 |
| 550790001012006 | 156 |

Merge them. Calculate the population in each neighborhood/block combo by
multiplying the pct.of.block adjustment factor by the population of the
block. Group by neighborhood, then summarize.

``` r
blocks.to.neighborhoods %>%
  inner_join(total.pop) %>%
  mutate(pop.in.neighborhood = pop * pct.of.block) %>%
  group_by(neighborhood) %>%
  summarise(pop = sum(pop.in.neighborhood)) %>%
  arrange(desc(pop))
```

    ## # A tibble: 186 x 2
    ##    neighborhood                pop
    ##    <chr>                     <dbl>
    ##  1 BAY VIEW                 16613 
    ##  2 LINCOLN VILLAGE          13062 
    ##  3 OLD NORTH MILWAUKEE      12226.
    ##  4 HISTORIC MITCHELL STREET 12016 
    ##  5 MUSKEGO WAY              11932 
    ##  6 HARAMBEE                 11815 
    ##  7 RIVERWEST                11520 
    ##  8 SILVER SPRING            11441 
    ##  9 LOWER EAST SIDE          10333.
    ## 10 MORGANDALE                9040 
    ## # … with 176 more rows

The above process works as long as you are dealing with a population
count. If you want to (dis)aggregate a summary value (like median age),
you can use the `pct.of.neighborhood` value to calculate a weighted
mean.

``` r
blocks.to.neighborhoods %>%
  inner_join(median.age) %>%
  group_by(neighborhood) %>%
  summarise(median_age = weighted.mean(x = age, w = pct.of.neighborhood, na.rm = T)) %>%
  arrange(desc(median_age))
```

    ## # A tibble: 186 x 2
    ##    neighborhood     median_age
    ##    <chr>                 <dbl>
    ##  1 FREEDOM VILLAGE        70.8
    ##  2 WHISPERING HILLS       65.8
    ##  3 HILLSIDE               64.4
    ##  4 BRYNWOOD               61.3
    ##  5 GRANVILLE WOODS        54.4
    ##  6 VALLEY FORGE           52.0
    ##  7 MACK ACRES             51.3
    ##  8 MILL VALLEY            48.0
    ##  9 GOLDEN GATE            47.4
    ## 10 COPERNICUS PARK        46.6
    ## # … with 176 more rows

## How accurate is it?

The smaller the data source geography, the more likely that it will fit
entirely within the target geography. The table below shows how each
crosswalk performs. Each cell shows the percent of bedrooms matched at
the degree of overlap indicated in the first column

  - 99.1% of bedrooms in Census blocks fell entirely within a single
    neighborhood.
  - 99.9% of bedrooms Census blocks fell entirely within a single ward.
  - Tracts are much more likely to straddle geographies. Just 27.8% of
    tract-bedrooms fell within a single neighborhood. 31.5% of bedrooms
    in tracts are assigned to a neighborhood with less than 50% overlap.
  - Wards can be merged to neighborhoods more accurately than tracts,
    but less accurately than blocks. 37.1% of wards lie entirely within
    a single
neighborhood.

| geo overlap  | blocks to neighborhoods | blocks to wards | tracts to neighborhoods | wards to neighborhoods |
| :----------- | ----------------------: | --------------: | ----------------------: | ---------------------: |
| 100%         |                   99.13 |           99.93 |                   27.83 |                  37.14 |
| 98-100       |                    0.08 |            0.00 |                    5.96 |                   4.95 |
| 90-98        |                    0.21 |            0.04 |                    4.58 |                   4.76 |
| 80-90        |                    0.09 |            0.00 |                    4.55 |                   6.96 |
| 70-80        |                    0.15 |            0.00 |                    7.40 |                   8.79 |
| 60-70        |                    0.07 |            0.01 |                    6.12 |                   9.61 |
| 50-60        |                    0.09 |            0.00 |                   12.49 |                   5.98 |
| less than 50 |                    0.18 |            0.01 |                   31.09 |                  21.80 |
