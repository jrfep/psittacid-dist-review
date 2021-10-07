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

tables <- c("all_refs","distmodel_ref", "species_ref", "country_ref", "my_bibtex", "birdlife_list", "iso_countries", "Index_of_CITES_Species")
for (tt in tables) {
  if (!exists(tt)) {
    incsv <- sprintf("input/%s.csv",tt)
    assign(tt,read.csv(incsv,sep=",",header=T, dec=".", stringsAsFactors=F))
  }
}


## limpiar variables:
distmodel_ref %<>% # operador para sobreescribir el objeto con el resultado
  ## quitar corchetes y parentesis
  mutate(paradigm=gsub("\\{|\\}|\\(|\\)","",paradigm),
         model_type=gsub("\\{|\\}|\\(|\\)","",model_type),
         general_application=gsub("\\{|\\}|\\(|\\)","",general_application),
         species_range=gsub("\\{|\\}|\\(|\\)","",species_range),
         species_list=gsub("\\{|\\}|\\(|\\)","",species_list),
         topics=gsub("\\{|\\}|\\(|\\)","",topics),
         specific_issue=gsub("\\{|\\}|\\(|\\)","",specific_issue)) %>%
  ## quitar comillas
  mutate(general_application=gsub("\"","",general_application,fixed=T)) %>%
  mutate(topics=gsub("\"","",topics,fixed=T))%>%
  mutate(species_list=gsub("\"","",species_list,fixed=T))%>%
  mutate(specific_issue=gsub("\"","",specific_issue,fixed=T))


distmodel_ref %<>%
  ## reclasificar categorias de paradigm
  mutate(paradigm_type=case_when(
    paradigm %in% c("RSF,NM","RSF,OM") ~ "RSF",
    paradigm %in% c("NM","OM","RSF") ~ paradigm,
    is.na(paradigm) ~ as.character(NA),
    TRUE~ "other"
  )) %>%
  ## convertir en factor
  mutate(paradigm_type=factor(paradigm_type,levels=c("NM","RSF","OM","other")))

distmodel_ref %>% select(paradigm, paradigm_type) %>% table(useNA="always")
distmodel_ref %>% filter(is.na(topics) & !is.na(paradigm)) 

#By general application

distmodel_ref %>% filter(!is.na(general_application) & !is.na(paradigm) & !(paradigm %in% "none")) %>%
  transmute(topics, general_application,ref_id, species_range) -> my.app

## make long with cSplit
long_my.app <-  cSplit(my.app, c("general_application"), ",", "long")

long_my.app %<>%
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

long_my.app %>% select(topics,general_application) %>% table(useNA="always")

#Figure 3
## filtrar falsos positivos de "Macao, MAC"
country_ref %>% filter(iso2 !="MO") %>% 
  left_join(iso_countries,by="iso2") %>% 
  select(ref_id,iso2,region) -> table_country_ref

long_my.app %>% filter(!is.na(general_application)  & !is.na(topics)) %>%
  inner_join(table_country_ref,by="ref_id") %>%
  transmute(ref_id, topics, species_range,general_application,region) -> table_app_country


#Figure 3
## table by region
table_app_country %>%
  filter(!is.na(general_application), !is.na(topics)) %>%
  group_by(region, general_application, species_range, topics) %>%
  summarise(total=n_distinct(ref_id)) %>%
 arrange(topics,total)-> fg3data

ordlevels <- fg3data %>% pull(general_application)

fg3data %<>%
  mutate(general_application = factor(general_application, levels=ordlevels))

  
    ggplot(fg3data, aes(fill=species_range, y=total, x="")) +
  geom_bar(stat="identity", position=position_stack(reverse = TRUE))+
  facet_grid(region ~ general_application) +
  labs(x = "General applications", y = "Number of publications")+
  theme(
    legend.position="none",
    axis.text.x = element_blank(),
    panel.spacing = unit(0.2, "lines"),
    strip.text.x = element_text(size = 8, angle = 45, vjust =0, hjust = 0),
    strip.background = element_blank(),
    plot.margin = unit(c(1,6,1,6), "cm"))# top, right, bottom, left


#Table 1
distmodel_ref %>% filter(!is.na(paradigm)) %>%
  transmute(ref_id,topics,general_application, specific_issue, paradigm_type)-> my.table

## make long with cSplit
long_table_1 <-  cSplit(my.table, c("topics","general_application", "specific_issue"), ",", "long")

long_table_1 %>% filter(!is.na(topics), !is.na(general_application)) %>%
  transmute(ref_id,topics,general_application, specific_issue, paradigm_type) -> supl.mat1

path <- "R/output"
write.csv(supl.mat1, file.path(path, "supl.mat1.csv"))

supl.mat1%>%
  filter(!is.na(specific_issue)) %>%
  group_by(topics, general_application, specific_issue) %>%
  summarise(n_pub = n_distinct(ref_id)) -> table_1

write.csv(table_1, file.path(path, "table_1.csv"))
