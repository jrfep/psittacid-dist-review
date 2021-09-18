setwd("~/Documentos/Publicaciones/Ferrer-Paris & Sánchez-Mercado_ReviewParrotDistribution")
require(magrittr)
library(dplyr) #for data munging
require(ggplot2) #visualization
library("RColorBrewer")
library(tidytext)
library(tidyr)
library(data.table)
library(rpostgis)
library(splitstackshape)

distmodel_ref <- read.csv("distmodel_ref.csv",sep=",",header=T, dec=".", stringsAsFactors=F)


## limpiar variables:
distmodel_ref %<>% # operador para sobreescribir el objeto con el resultado 
  ## quitar corchetes y parentesis 
  mutate(paradigm=gsub("\\{|\\}|\\(|\\)","",paradigm),
   model_type=gsub("\\{|\\}|\\(|\\)","",model_type),
   general_application=gsub("\\{|\\}|\\(|\\)","",general_application),
   species_range=gsub("\\{|\\}|\\(|\\)","",species_range),
   topics=gsub("\\{|\\}|\\(|\\)","",topics),
   specific_issue=gsub("\\{|\\}|\\(|\\)","",specific_issue)) %>%
  ## quitar comillas
  mutate(general_application=gsub("\"","",general_application,fixed=T)) %>%
  mutate(topics=gsub("\"","",topics,fixed=T))%>%
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

distmodel_ref %<>%
  ## reclasificar categorias de topics
  mutate(topics=case_when(
    topics %in% c("evolution") ~ "Evolution",
    topics %in% c("Bahavior","Biodiversity","Conservation", "Evolution","Ecology", "Invasion ecology", "Methodological issues") ~ topics))

distmodel_ref %>% select(paradigm, paradigm_type) %>% table(useNA="always")


# Figure 1

distmodel_ref %>% filter(!is.na(paradigm)) %>% left_join(my.bibtex,by="ref_id") %>% 
  transmute(ref_id,year=PY,paradigm_type)  -> publication_year_table

#By paradigm
publication_year_table %>%
  group_by(paradigm_type, year) %>%
  summarise(n_pub = n_distinct(ref_id)) %>%
  mutate(csum = cumsum(n_pub)) -> py_table

clrs <- brewer.pal(4,"Dark2") 
names(clrs) <- c("OM","RSF","other","NM")
  ggplot(py_table) + 
  geom_line(aes(x = year, y = csum, color = paradigm_type)) + 
  scale_color_manual(values=clrs) +theme(axis.text.x=element_text(angle=45, size=8))

#By general applycation
# A colorblind-friendly palette
cbbPalette <- c("#56B4E9", "#009E73", "#F0E442", "#E69F00", "#D55E00", "#CC79A7")

distmodel_ref %>% filter(!is.na(general_application), !is.na(topics)) %>%
  transmute(topics, general_application,ref_id) -> my.app

## make long with cSplit
long_my.app <-  cSplit(my.app, c("topics", "general_application"), ",", "long")


long_my.app %<>%
  filter(!is.na(general_application), !is.na(topics)) %>%
  mutate(general_application = factor(general_application, levels=c("Conservation issues","Threats monitoring","Climate change","Spatial prediction", "Assessment of distribution",
                                                                    "Relation with environmental variables", "Macroecology",
                                                                    "Co-occurence of parrot species",
                                                                    "Temporal distribution patterns","Habitat use related to behaviour types", "Ecological communities",
                                                                    "Biogeographic patterns","Predictions of invasion risk", "Invasion effect", "Improving estimation")))


long_my.app %>%
  filter(!is.na(general_application), !is.na(topics)) %>%
group_by(topics, general_application) %>%
  summarise(n_pub = n_distinct(ref_id)) %>%
  ggplot(aes(x = general_application, y=n_pub, fill = topics)) +
  geom_bar(stat="identity") +
  scale_fill_manual(values=cbbPalette)+
  theme(axis.text.x=element_text(angle=45, size=12, hjust=1))
  

## Figure 2
iso_countries<- read.csv("iso_countries.csv",sep=",",header=T, dec=".", stringsAsFactors=F)

## filtrar falsos positivos de "Macao, MAC"
country_ref %>% filter(iso2 !="MO") %>% left_join(iso_countries,by="iso2") %>% select(ref_id,iso2,region) -> table_country_ref 

distmodel_ref %>% filter(!is.na(paradigm)) %>%  
  inner_join(table_country_ref,by="ref_id") %>% 
  transmute(ref_id,paradigm_type,species_range,general_application,region) -> table_app_country

## make long with cSplit
long_app_country <-  cSplit(table_app_country, "general_application", ",", "long")

long_app_country %<>%
## reclasificar categorias de general_application
mutate(general_application=case_when(
  general_application %in% c("Seasonality/Migratory movements") ~ "Temporal distribution patterns",
  general_application %in% c("Coverage in protected areas")~ "Spatial prediction",
  general_application %in% c("Biodiversity", "Co-occurence of parrot species") ~
    "Co-occurence of parrot species",
  general_application %in% c("Assessment of distribution")~ "Relation with environmental variables",
  is.na(general_application) ~ as.character(NA),
  TRUE~ as.character(general_application)
))

long_app_country %<>%
  mutate(general_application = factor(general_application, levels=c("Conservation issues","Climate change","Threats monitoring", "Spatial prediction", 
                                                                  "Macroecology","Assessment of distribution","Co-occurence of parrot species",
                                                                  "Temporal distribution patterns","Habitat use related to behaviour types", "Ecological communities","Relation with environmental variables",
                                                                  "Biogeographic patterns", "Invasion effect","Predictions of invasion risk", "Improving estimation")))
  
#Just check variables with NAs
long_app_country %>% filter(is.na(general_application)) %>% pull(ref_id)
long_app_country %>% filter(is.na(species_range)) %>% pull(ref_id)

## table by paradigm
long_app_country %>% 
  group_by(paradigm_type,general_application,species_range) %>% 
  summarise(total=n_distinct(ref_id)) %>%
  ggplot(aes(fill=species_range, y=total, x=species_range)) + 
  geom_bar(position="dodge", stat="identity")+
  facet_grid(paradigm_type ~ general_application) +
  labs(x = "General applications", y = "Number of publications")+
  theme(
    legend.position="none",
    axis.text.x = element_blank(),
    panel.spacing = unit(0.1, "lines"),
    strip.text.x = element_text(size = 8, angle = 90, vjust =0, hjust = 0),
    strip.background = element_blank(),
    plot.margin = unit(c(1,6,1,6), "cm"))

  
## table by region
long_app_country %>%
  group_by(region, general_application,species_range) %>% 
  summarise(total=n_distinct(ref_id)) %>%
  ggplot(aes(fill=species_range, y=total, x=species_range)) + 
  geom_bar(position="dodge", stat="identity")+
  facet_grid(region ~ general_application) +
  labs(x = "General applications", y = "Number of publications")+
  theme(
    legend.position="none",
    axis.text.x = element_blank(),
    panel.spacing = unit(0.1, "lines"),
    strip.text.x = element_text(size = 8, angle = 90, vjust =0, hjust = 0),
    strip.background = element_blank(),
    plot.margin = unit(c(1,6,1,6), "cm"))# top, right, bottom, left


#Table 1
distmodel_ref %>% filter(!is.na(paradigm)) %>%  
  transmute(ref_id,topics,general_application, specific_issue)-> my.table

## make long with cSplit
long_table_1 <-  cSplit(my.table, c("topics","general_application", "specific_issue"), ",", "long")

long_table_1 %>% filter(!is.na(topics), !is.na(general_application)) %>%  
  transmute(ref_id,topics,general_application, specific_issue) ->supl.mat1

path <- "~/Documentos/Publicaciones/Ferrer-Paris_Sanchez-Mercado_ReviewParrotDistribution/output"
write.csv(supl.mat1, file.path(path, "supl.mat1.csv"))  

supl.mat1%>%
  filter(!is.na(specific_issue)) %>%
  group_by(topics, general_application, specific_issue) %>%
  summarise(n_pub = n_distinct(ref_id)) -> table_1

  write.csv(table_1, file.path(path, "table_1.csv"))  
