require(magrittr)
library(dplyr) #for data munging
require(ggplot2) #visualization
library(RColorBrewer)
library(tidytext)
library(tidyr)
##library(data.table)
library(rpostgis)
library(splitstackshape)
require(ggpubr)
library(dplyr)

#Figure 4
species_ref %>%
  inner_join(distmodel_ref,by="ref_id") %>%
  select(ref_id, scientific_name,species_range,general_application,topics) -> table_species_ref

long_spp_list <-  cSplit(table_species_ref, c("topics","general_application", "species_range"), ",", "long")

long_spp_list %<>%
  ## reclasificar categorias de topics
  mutate(topics=case_when(
    topics %in% c("evolution") ~ "Evolution",
    general_application %in% c("Threats monitoring","Climate change", "Spatial prediction", "Assessment of distribution","Conservation issues") ~ "Conservation",
    general_application %in% c("Co-occurence of parrot species", "Relation with environmental variables","Macroecology", "Ecological communities") ~ "Ecology",
    general_application %in% c("Temporal distribution patterns","Habitat use related to behaviour types") ~ "Behaviour",
    general_application %in% c("Biogeographic patterns" ) ~ "Evolution",
    general_application %in% c("Predictions of invasion risk","Invasion effect") ~ "Invasion ecology",
    general_application %in% c("Improving estimation") ~ "Methodological issues",
    
    TRUE ~ topics))


long_spp_list %>% filter(!is.na(general_application), !is.na(topics), !is.na(species_range)) %>%
  inner_join(Index_of_CITES_Species,by=c("scientific_name"="scientific.AF8.name")) %>%
  transmute(ref_id,topics, scientific_name, general_application, species_range, Genus) -> table_app_spp

table_app_spp %>%
  group_by(Genus, general_application, species_range) %>%
  summarise(total=n_distinct(ref_id))-> fg4data
  
fg4data %<>%
  filter(!is.na(general_application)) %>%
  mutate(general_application = factor(general_application, levels=ordlevels))

  
  ggplot(fg4data, aes(x= general_application, y= Genus, size= total, color= species_range)) +
  geom_point(alpha=0.5) +
  scale_radius(range = c(2, 10),name="Number of documents") +
  theme_bw()+
  theme(axis.text.x = element_text(angle=45, size=9, hjust = 1))


