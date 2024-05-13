# bubblegam<img src="https://github.com/Geo-99/bubblegam/assets/132048605/ca6a55d8-c76b-44ec-aae9-fe8b954a61b3" align="right" alt="logo" width="200" height="185">
Welcome to *bubblegam*! An R package to efficiently merge (geo)dataframes, identify, and move "spatial outliers" in geodata, create geographic plots, bubbleplots and the animation between these plots.
&nbsp;

*Authors: [Georg Starz](http://students.eagle-science.org/students/students-2023/georg/) (Code) & [Anna Bischof](http://students.eagle-science.org/students/students-2023/anna/) (Code, Package Idea)*

*Contact: georg.starz@stud-mail.uni-wuerzburg.de & anna.bischof@stud-mail.uni-wuerzburg.de*

&nbsp;

## Plot & animation examples
![animation_green_delayed](https://github.com/Geo-99/bubblegam/assets/132048605/30e8a96b-af66-42d3-a96e-f37d12e94918)Data source: [Destatis](https://www.statistikportal.de/de/ugrdl/ergebnisse/energie)

&nbsp;

![animation_footprint_delayed](https://github.com/Geo-99/bubblegam/assets/132048605/d5623da6-5f63-423f-b294-e0687ecbe2b1)Data source: [EDGAR](https://edgar.jrc.ec.europa.eu/report_2023)

&nbsp;

![animation_usa_outline_delayed](https://github.com/Geo-99/bubblegam/assets/132048605/3aec18db-31de-4fc6-b510-9b032410a953)Data source: [STATSAMERICA](https://www.statsamerica.org/sip/rank_list.aspx?rank_label=pcpi1)

&nbsp;

## Installation
The package was developed with R version 4.3.1 on Windows. Mac & Linux haven't been tested so far. To install and load bubblegam, enter these commands in your R console:
&nbsp;
```R
library(devtools)
install_github("Geo-99/bubblegam")
library(bubblegam)
```

When testing the package we encountered some yet to be solved issues with two package dependencies. Therefore, for now, we recommend manually loading `library(animation)` & `library(sf)`.

&nbsp;

## Example workflow to demonstrate the different functions

Here, we want to create this animation (based on a geopackage of the federal states of Spain and data on the GDP):

&nbsp;

![animation_red_edge_delayed](https://github.com/Geo-99/bubblegam/assets/132048605/b0506db7-84f0-4943-8e81-e6d8b5207b17)

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
![Step2](https://github.com/Geo-99/bubblegam/assets/132048605/18f219b7-a93c-4ff1-acd6-8a777dddc119)

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

Next, we can create our start and bubble plot with `plot_cont` (you can then save the plots using `ggsave()`):
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
`anim_cont_raw` is used to create the raw animation (slow sequence of all frames) and save it. **Note:** all parameters from plot_limits onwards are based on `plot_cont`:
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
- 4 bubblegam functions weren't shown in the Spain GDP example:
    - `merge_df_df` enables inner merge of dataframes similar to `merge_gd_df`
    - `outlier_restructure` reincludes moved outlier subfeatures
    - `plot_discr`: same as `plot_cont` but for discrete data
    - `anim_discr_raw`: same as `anim_cont_raw` but for discrete data

&nbsp;

## Common problems
- If your geodata uses a geographic and not a projected CRS, the bubbles can turn into ellipses in the plots/animations. Therefore, we recommend reprojecting it beforehand using `st_transform()`.![animation](https://github.com/Geo-99/bubblegam/assets/132048605/348036ea-4250-477c-83ea-d2656750ba26)
- To be continued ...

&nbsp;

## Acknowledgements
This package is inspired by and partly based on [zumbov2's](https://github.com/zumbov2/votemapswitzerland?tab=readme-ov-file#land-doesnt-vote-people-do) Switzerland version of Karim Douïeb's famous vizualization [Land Doesn't Vote... People Do.](https://storymaps.arcgis.com/stories/0e636a652d44484b9457f953994b212b) 

We want to thank [Dr. Martin Wegmann](https://eagle-science.org/lecturer/wegmann/) and the [Earth Observation Research Cluster's](https://earth-observation.org/) DevLab for the support and feedback during the development of the package. 

This is a submission for the course *Introduction to Programming and Statistics for Remote Sensing and GIS* as part of the M.Sc. [EAGLE](https://eagle-science.org/) program at the University of Würzburg.

&nbsp;

## Appendix
![switz_plot](https://github.com/Geo-99/bubblegam/assets/132048605/8d062cde-e032-4acb-a664-83b54c19b496)

&nbsp;

![switz_bubbles_plot](https://github.com/Geo-99/bubblegam/assets/132048605/6d4ffdbb-98a5-4699-bac4-6d71850ca7d1)

&nbsp;

![animation_cantons](https://github.com/Geo-99/bubblegam/assets/132048605/96445abb-eb6f-43af-991a-67d7362e294b)

&nbsp;

![animation_cantons_smaller_outline](https://github.com/Geo-99/bubblegam/assets/132048605/4eca6832-b319-4908-8c18-00679ed199c8)

&nbsp;

![animation_NEW_delayed](https://github.com/Geo-99/bubblegam/assets/132048605/7ed2338e-d14c-434f-9b68-3ea45e7db72f)

&nbsp;

![Spain_red_bubbles_borders](https://github.com/Geo-99/bubblegam/assets/132048605/c319df04-dc7b-4631-9a39-8f9ec001871d)

&nbsp;

![plot_UNFCC](https://github.com/Geo-99/bubblegam/assets/132048605/22d87ede-5c80-417d-a1de-89ba1c36667a)
