#loading in all manipulation and graphing functions
library(ggplot2)
library(sportyR)
library(tidyverse)

#this is our heatmap function. this creates a single density plot for pitcher positioning based on the data inputs.
plot_density <- function(data, filename) {
  #draws an MILB field as a background
  p <- sportyR::geom_baseball(league = "MiLB") +
    stat_density_2d_filled(
      data = data,
      aes(x = field_x, y = field_y, fill = after_stat(level)),
      alpha = 0.8,
      contour_var = "ndensity"
    ) +
    #correct coloring
    scale_fill_viridis_d(option = "plasma") +
    #this is for cropping purposes
    coord_fixed(xlim = c(-80, 80), ylim = c(-25, 150)) +  
    theme_void() +
    theme(legend.position = "none")
  
  # Save as 600x600 pixels
  ggsave(filename, plot = p, width = 2, height = 2, units = "in", dpi = 300)
}

#this is the function that automakes heatmap creation
generate_plots_for_field <- function(data, field_name, output_folder) {
  #creates folder
  dir.create(output_folder, showWarnings = FALSE)
  
  #Renaming arm bucket values for RSHINY purposes
  data <- data %>%
    mutate(arm_bucket = case_when(
      arm_bucket == "85-100" ~ "85+",
      TRUE ~ arm_bucket
    ))
  #Stores all unique values of base states, arm buckets, and hard hits to iterate through
  unique_base_states <- unique(data$base_state)
  unique_arm_buckets <- unique(data$arm_bucket)
  unique_hard_hits <- unique(data$hard_hit)
  
  #This creates an iteration over every value of base states arm buckets and hard hits.
  #walk iterates over the data
  walk(unique_base_states, function(bstate) {
    walk(unique_hard_hits, function(hit) {
      walk(unique_arm_buckets, function(bucket) {
        #filters the main dataset so that the base state hard hit and arm bucket are equal to the current values
        subset_data <- data %>% filter(base_state == bstate,
                                       hard_hit == hit,
                                       arm_bucket == bucket)
        #disregards if it is under 5
        if (nrow(subset_data) < 5) return()
        
        #creates a file name based on the values
        filename <- paste0(output_folder, "/", bstate, "_", field_name, "_", hit, "_", bucket, ".png")
        #generates the plot by going back to the function at the top. 
        plot_density(subset_data, filename)
      })
    })
  })
  
  #This is necessary because it maintains the all for hard_hits, while running through base state and bucket.
  #same process.
  walk(unique_base_states, function(bstate) {
    walk(unique_arm_buckets, function(bucket) {
      subset_data <- data %>% filter(base_state == bstate,
                                     arm_bucket == bucket)
      if (nrow(subset_data) < 5) return()
      
      filename <- paste0(output_folder, "/", bstate, "_", field_name, "_All_", bucket, ".png")
      plot_density(subset_data, filename)
    })
  })
  
  #This is necessary because it maintains the all for arm_buckets, while running through base state and hard_hits
  #same process.
  walk(unique_base_states, function(bstate) {
    walk(unique_hard_hits, function(hit) {
      subset_data <- data %>% filter(base_state == bstate,
                                     hard_hit == hit)
      if (nrow(subset_data) < 5) return()
      
      filename <- paste0(output_folder, "/", bstate, "_", field_name, "_", hit, "_All.png")
      plot_density(subset_data, filename)
    })
  })
  
  ##This is necessary because it maintains the all for hard_hits and arm buckets while running through base states.
  #same process.
  walk(unique_base_states, function(bstate) {
    subset_data <- data %>% filter(base_state == bstate)
    if (nrow(subset_data) < 5) return()
    
    filename <- paste0(output_folder, "/", bstate, "_", field_name, "_All_All.png")
    plot_density(subset_data, filename)
  })
}

#loading in data raw
raw_center <- read_csv("CF_positioning_arm_bucket_analysis.csv")
#eliminating NA's
center_data <- raw_center %>%
  filter(!is.na(arm_bucket) & !is.na(hard_hit) & !is.na(base_state))
#running function for our dataset 
generate_plots_for_field(center_data, "Center", "Center_pitcher_heatmaps")

#loading in data raw
raw_right <- read_csv("RF_positioning_arm_bucket_analysis.csv")
#eliminating NA's
right_data <- raw_right %>%
  filter(!is.na(arm_bucket) & !is.na(hard_hit) & !is.na(base_state))
#running function for our dataset
generate_plots_for_field(right_data, "Right", "Right_field_pitcher_heatmaps")

#loading in data raw
raw_left <- read_csv("LF_positioning_arm_bucket_analysis.csv")
#filtering for NA's
left_data <- raw_left %>%
  filter(!is.na(arm_bucket) & !is.na(hard_hit) & !is.na(base_state))
#running function for our dataset
generate_plots_for_field(left_data, "Left", "Left_field_pitcher_heatmaps")

#this is in the appendix. This is creating a grid of every graphic into one.
p <- sportyR::geom_baseball(league = "MiLB") +
  stat_density_2d_filled(
    data = center_data,
    aes(x = field_x, y = field_y, fill = after_stat(level)),
    alpha = 0.8,
    contour_var = "ndensity"
  ) +
  scale_fill_viridis_d(option = "plasma") +
  coord_fixed(xlim = c(-200, 200), ylim = c(-25, 400)) +
  facet_grid(hard_hit + base_state ~ arm_bucket, switch = "y") +
  theme_void() +
  theme(
    legend.position = "none",  # ✅ Remove the legend
    strip.placement = "outside",
    strip.text.y.right = element_text(angle = 0, hjust = 0),
    plot.margin = unit(c(1, 0.5, 0.5, 1), "in")
  )

#save graph
ggsave("pitcher_heatmap_grid.png", plot = p, width = 12, height = 18, dpi = 300)
