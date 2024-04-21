# bubblegam<img src="https://github.com/Geo-99/geospatial_circles_anim/assets/132048605/4b5d4c31-5b31-4c36-b3a1-4df29c169861" align="right" alt="logo" width="200" height="185">
Welcome to *bubblegam*! An R package to efficiently merge (geo)dataframes, identify, and move "spatial outliers" in geodata, create geographic plots, bubbleplots and the animation between these plots.
&nbsp;

*Authors: [Georg Starz](http://students.eagle-science.org/students/students-2023/georg/) (Code) & [Anna Bischof](http://students.eagle-science.org/students/students-2023/anna/) (Code, Package Idea)*

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

Here, we want to create this animation (based on a geopackage of the federal states of Spain and data on the GDP):

&nbsp;

![animation_red_edge_delayed](https://github.com/Geo-99/geospatial_circles_anim/assets/132048605/b4e0d73d-344c-4295-8daf-99dd389d53d9)

&nbsp;

For a detailed description of all functions and their parameters, refer to the documentation, e.g. `?find_sim_change`.

&nbsp;

The source data is supplied with the installation of the package.`spain_gdp` is a data.frame and `spain_gpkg` is a sf data.frame.
We use the `find_sim_change` function to synchronize the names of the Spanish federal states for the subsequent merge function. There are three features, which are spelled slightly differently in the two datasets:
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


**Optional**: "Spatial outliers" in the geodata (in this case the Canary Islands) can complicate the map display. To automatically identify and then delete/define these outliers use `outlier_identify` and answer the prompts in the console (warnings may be displayed, which can be ignored):
&nbsp;
```R
spain_merged_outliers <- outlier_identify(geodata = spain_merged, id_col = "Texto")
```

If the Canary Islands were defined as an outlier, their multipolygon can be "moved closer" towards mainland Spain using `outlier_moving`:
&nbsp;
```R
spain_merged_moved <- outlier_moving(geodata = spain_merged_outliers)
```
![Step2](https://github.com/Geo-99/geospatial_circles_anim/assets/132048605/06ee2f34-30ba-4bc7-b849-27e8c911c2c6)

&nbsp;

Use `create_bubbles` to create the bubble geodata:
&nbsp;
```R
spain_bubbles <- create_bubbles(merged_gdf = spain_merged_moved, col_name = "PIB_anual_EURO")
```

We define the plot limit coordinates by referring to both geodataframes (map & bubbles) using `define_limits`. **Note:** This is done to ensure a consistent plot extent within the animation:

```R
spain_limits_combined <- define_limits(data_start = spain_merged_moved, data_end = spain_bubbles)
```

Next, we can create our start and bubble plot with `plot_cont_data` (you can then save the plots using `ggsave()`):
&nbsp;
```R
spain_plot <-  plot_cont(gdf = spain_merged_moved, column = "PIB_Per_Capita_EURO",     
                          plot_limits = spain_limits_combined,
                          fill_colorscale = c("lightyellow", "#f1434a","darkred"),
                          legend_limits = c(20000,40000),
                          edge_color = "#323232", edge_width = 0.1,
                          legend_text = 14,
                          title = "GDP per Capita in Spain 2022 [€]",
                          title_size = 24)
spain_plot

bubbles_plot <- plot_cont(gdf = spain_bubbles, column = "PIB_Per_Capita_EURO",     
                          plot_limits = spain_limits_combined,
                          fill_colorscale = c("lightyellow", "#f1434a","darkred"),
                          legend_limits = c(20000,40000),
                          edge_color = "#323232", edge_width = 0.1,
                          legend_text = 14,
                          title = "GDP per Capita in Spain 2022 [€]\n→ Bubble Size: Total GDP per state",
                          title_size = 24)
bubbles_plot
```

&nbsp;

Now, to start the creation of the animation, we first need to calculate the transition steps between `spain_gdp_moved` and `spain_bubbles` by using `create_transition` (warnings may be displayed, which can be ignored):

```R
spain_transition <- create_transition(gdf = spain_merged_moved, bubble_gdf = spain_bubbles, 
                                      color_col = "PIB_Per_Capita_EURO", bubble_col = "PIB_anual_EURO")

```
`anim_cont_raw` is used to create the raw animation (slow sequence of all frames) and save it. **Note:** all parameters from plot_limits onwards are based on `plot_cont_data`:
```R
anim_cont_raw(transition_df = spain_transition, path_file_name = "path/to/anim_raw.gif",
              anim_width = 1900, anim_height = 2000, anim_res = 400,
              plot_limits = spain_limits_combined,
              fill_colorscale = c("lightyellow", "#f1434a","darkred"),
              legend_limits = c(20000,40000),
              edge_color = "#323232", 
              legend_text = 10,
              title = "GDP per Capita in Spain 2022 [€]\n→ Bubble Size: Total GDP per state",
              title_face = "bold", title_size = 15)
```
To define the frames per second of the animation and add a delay at the start and end plot use `anim_finalize`:
```R
anim_finalize(anim_raw = "path/to/anim_raw.gif", anim_path_file = "path/to/anim_final.gif",
              fps_anim = 10, delay_anim = TRUE, delay_frames = 60)
```

&nbsp;

Creating the animation can be quite time-intensive depending on the input data. As an alternative, you can use the following code to create a higher-resolution animation (execute as a whole). However, in our experience, this takes even longer:
```R
library(magick)

img <- image_graph()
datalist <- split(spain_transition, spain_transition$.frame)
sf_datalist <- lapply(datalist, function(datalist) st_as_sf(datalist))
out <- lapply(sf_datalist, plot_cont,
              column = "v_plot1", plot_limits = spain_limits_combined,
              fill_colorscale = c("lightyellow", "#f1434a","darkred"),
              legend_limits = c(20000,40000),
              edge_color = "#323232", edge_width = 0.2,
              legend_text = 14,
              title = "GDP per Capita in Spain 2022 [€]\n→ Bubble Size: Total GDP per state",
              title_face = "bold", title_size = 24)
out
dev.off()

animation <- image_animate(img, fps = 10)
animation_delayed <- animation[c(rep(1, each = 60), 2:(length(datalist)-1), rep(length(datalist), each = 60))]

image_write(animation, "path/to/anim_fps.gif")
image_write(animation_delayed, "path/to/anim_fps_delayed.gif")
```

&nbsp;

## Further notes
- We are happy if you find our bubblegam package useful! When using it, please link our repo (e.g., like so: *bubblegam R package, https://github.com/Geo-99/bubblegam*)
- Feel free to send us plots and animations that you have created with bubblegam :)
- We are sure there are many possible code improvements. We're looking forward to any suggestions you might have!
- tbc

&nbsp;

## Common problems
- tbc
- 

&nbsp;

## Acknowledgements
This package is inspired by and partly based on [zumbov2's](https://github.com/zumbov2/votemapswitzerland?tab=readme-ov-file#land-doesnt-vote-people-do) version of Karim Douïeb's famous vizualization [Land Doesn't Vote... People Do.](https://storymaps.arcgis.com/stories/0e636a652d44484b9457f953994b212b) 

We want to thank [Dr. Martin Wegmann](https://eagle-science.org/lecturer/wegmann/) and the [Earth Observation Research Cluster's](https://earth-observation.org/) DevLab for the support and feedback during the development of the package. 

This is a submission for the course *Introduction to Programming and Statistics for Remote Sensing and GIS* as part of the M.Sc. [EAGLE](https://eagle-science.org/) program at the University of Würzburg.

&nbsp;

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
