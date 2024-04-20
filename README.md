# bubblegam<img src="https://github.com/Geo-99/geospatial_circles_anim/assets/132048605/4b5d4c31-5b31-4c36-b3a1-4df29c169861" align="right" alt="logo" width="200" height="185">
Welcome to *bubblegam*! An R package to efficiently merge (geo)dataframes, identify, and move spatial outliers in geodata, and create geographic plots, bubbleplots and the animation between these plots.
&nbsp;

*Authors: [Georg Starz](http://students.eagle-science.org/students/students-2023/georg/) & [Anna Bischof](http://students.eagle-science.org/students/students-2023/anna/)*

&nbsp;

## Plot & animation examples
![animation_green_delayed](https://github.com/Geo-99/geospatial_circles_anim/assets/132048605/a3911ea8-1b6e-4514-81d2-da1ee4fd5192)Data source: [Destatis](https://www.statistikportal.de/de/ugrdl/ergebnisse/energie)

&nbsp;

![animation_footprint_delayed](https://github.com/Geo-99/geospatial_circles_anim/assets/132048605/6652867a-8030-4fc6-93a2-50ce741d5fa0)Data source: [EDGAR](https://edgar.jrc.ec.europa.eu/report_2023)

&nbsp;

![animation_usa_outline_delayed](https://github.com/Geo-99/geospatial_circles_anim/assets/132048605/29e89c3f-2892-4029-9c0c-8d704a0cafa8)Data source: [STATSAMERICA](https://www.statsamerica.org/sip/rank_list.aspx?rank_label=pcpi1)

&nbsp;

## Installation
To install and load bubblegam, enter these commands in your R console:
&nbsp;
```R
library(devtools)
install_github("Geo-99/bubblegam")
library(bubblegam)
```

&nbsp;

## Example workflow to demonstrate the different functions

Here we want to create this animation (based on a shapefile of the federal states of Spain and data on the GDP):

&nbsp;

![animation_red_edge_delayed](https://github.com/Geo-99/geospatial_circles_anim/assets/132048605/b4e0d73d-344c-4295-8daf-99dd389d53d9)

&nbsp;

For a detailed description of all functions and their parameters, refer to the documentation, e.g. `?find_sim_change`.

&nbsp;

The source data is automatically supplied with the installation of the package.`spain_gdp` is a data.frame and spain_gpkg is a `sf data.frame`.
We use the `find_sim_change` function to synchronize the names of the Spanish federal states for the subsequent merge function. For three features, these are written slightly differently in the two datasets:
&nbsp;
```R
gdp_cleaned <- find_sim_change(df_main = spain_gpkg, df_main_col = "Texto",
                                df_change = spain_gdp, df_change_col = "CCAA")
```

Then, we merge both dataframes with `merge_gd_df`:
&nbsp;
```R
spain_merged <- merge_gd_df(gdf_left = spain_gpkg, id_left = "Texto",
                            df_right = gdp_cleaned, id_right = "CCAA",
                            cols_to_keep = c("PIB_Per_Capita_EURO", "PIB_anual_EURO"))
```

&nbsp;


**Optional**: "Spatial outliers" in the geodata (in this case the Canary Islands) can complicate the map display. To automatically identify and then delete/define these outliers use `outlier_identify`:
&nbsp;
```R
spain_merged_outliers <- outlier_identify(geodata = spain_merged, id_col = "Texto"))
```

If we defined the Canary Islands as an outlier, their multipolygon can be "moved closer" towards mainland Spain using `outlier_moving`:
&nbsp;
```R
spain_merged_moved <- outlier_moving(geodata = spain_merged_outliers)
```

&nbsp;

To create the bubble geodata use `create_bubbles`:
&nbsp;
```R
spain_bubbles <- create_bubbles(merged_gdf = spain_merged_moved, col_name = "PIB_anual_EURO")
```

Defining the plot limit coordinates by referring to both geodataframes (map & bubbles) works with `define_limits` (important for consistent plot extent in animation):
&nbsp;
```R
spain_limits_combined <- define_limits(data_start = spain_merged_moved, data_end = spain_bubbles)
```

## Further notes & common problems

## Acknowledgements
Idea:
Martin
EO Research Cluster DevLab
## Appendix
![switz_plot](https://github.com/Geo-99/geospatial_circles_anim/assets/132048605/e76f4809-c82b-4593-9137-67daf3f93b63)

&nbsp;

![switz_bubbles_plot](https://github.com/Geo-99/geospatial_circles_anim/assets/132048605/4c1d35da-2be2-4644-83da-7ddedcd5811b)

&nbsp;

![animation_cantons](https://github.com/Geo-99/geospatial_circles_anim/assets/132048605/dd92362f-8f1c-447d-a070-c766d3f8bccd)

&nbsp;

![animation_cantons_smaller_outline](https://github.com/Geo-99/geospatial_circles_anim/assets/132048605/51838687-218f-405e-b73c-b0b5a7f4ca4e)

&nbsp;

![animation_NEW_delayed](https://github.com/Geo-99/geospatial_circles_anim/assets/132048605/64b4e319-a5c4-44b6-8ffb-25c4312ae735)

&nbsp;

![Spain_red_bubbles_borders](https://github.com/Geo-99/geospatial_circles_anim/assets/132048605/fc804562-bc3a-4206-8969-57e12f8606fd)

&nbsp;

![plot_UNFCC](https://github.com/Geo-99/geospatial_circles_anim/assets/132048605/5aad0da4-b9e0-4617-bff4-202e7fb6d590)
