# Create Sankey diagram of outpatient appointments
# Date: 13/12/2022
library(foreign)
library(ggplot2)
library(ggsankey)
library(dplyr)

data <- read.csv("output/input.csv")
myvars <- c("outpatient_appt_2019", "outpatient_appt_2020", "outpatient_appt_2021", "patient_id")
cut_data <- data[myvars]
# Create stage variable for category of outpatient appointments for each year
cut_data$outpatient_cat_2019 <- cut(cut_data$outpatient_appt_2019,
                                breaks=c(0,1,3,Inf),
                                labels=c("None", "1-2", "3+"),
                                right = FALSE)
cut_data$outpatient_cat_2020 <- cut(cut_data$outpatient_appt_2020,
                                    breaks=c(0,1,3,Inf),
                                    labels=c("None", "1-2", "3+"),
                                    right = FALSE)
cut_data$outpatient_cat_2021 <- cut(cut_data$outpatient_appt_2021,
                                    breaks=c(0,1,3,Inf),
                                    labels=c("None", "1-2", "3+"),
                                    right = FALSE)
# Create numeric node variable for each year corresponding to category
cut_data$outpatient_node_2019 <- cut(cut_data$outpatient_appt_2019,
                                    breaks=c(0,1,3,Inf),
                                    labels=c("0", "1", "2"),
                                    right = FALSE)
cut_data$outpatient_node_2020 <- cut(cut_data$outpatient_appt_2020,
                                    breaks=c(0,1,3,Inf),
                                    labels=c("0", "1", "2"),
                                    right = FALSE)
cut_data$outpatient_node_2021 <- cut(cut_data$outpatient_appt_2021,
                                    breaks=c(0,1,3,Inf),
                                    labels=c("0", "1", "2"),
                                    right = FALSE)
sankey_data <- cut_data %>%
  make_long(outpatient_cat_2019, outpatient_cat_2020, outpatient_cat_2021)
# Plot Sankey diagram
p1 <- ggplot(sankey_data, aes(x = x,
                          next_x = next_x,
                          node = node,
                          next_node = next_node,
                          fill = factor(node),
                          label = node)) 
p1 <- p1 + geom_sankey(flow.alpha = 0.5,
                node.color = "black",
                show.legend = FALSE)
p1 <- p1 +geom_sankey_label(size = 3.5, color = 1, fill = "white")
p1 <- p1 +  theme_bw()
p1 <- p1 + theme(legend.position = "none")
p1 <- p1 +  theme(axis.title = element_blank()
                  , axis.text.y = element_blank()
                  , axis.ticks = element_blank()  
                  , panel.grid = element_blank())
p1 <- p1 + scale_fill_viridis_d(option = "inferno")
p1 <- p1 + labs(title = "Sankey diagram of outpatient appointmets")
p1 <- p1 + labs(fill = 'Nodes')
p1    


ggsave(filename = .output/"sankey.png",
        device = "png",
        plot = p1)