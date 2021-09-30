require(magrittr)
library(dplyr) #for data munging
require(ggplot2) #visualization
library(RColorBrewer)
library(tidytext)
library(tidyr)
##library(data.table)
library(rpostgis)
library(splitstackshape)

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

distmodel_ref %<>%
  ## reclasificar categorias de topics
  mutate(topics=case_when(
    topics %in% c("evolution") ~ "Evolution",
    topics %in% c("Bahavior","Biodiversity","Conservation", "Evolution","Ecology", "Invasion ecology", "Methodological issues") ~ topics))

distmodel_ref %>% select(paradigm, paradigm_type) %>% table(useNA="always")


# Figure 1

dim(all_refs)
dim(all_refs %>% filter(!is.na(reviewed_by) ))
all_refs %>% filter(!is.na(status)) %>% transmute(t=status %in% "included in review") %>% table
distmodel_ref %>% group_by(paradigm) %>% summarise(total=n())

all_refs %>% filter(!is.na(year)) %>% group_by(year) %>% 
  summarise(total=n_distinct(ref_id)) %>% mutate(grp=year<1990)-> pubs_year


mdl <- glm(total~year*grp,pubs_year,family=gaussian(log))
nwdt <- data.frame(year=seq(1900,2020,length=50))
nwdt$grp <- TRUE
nwdt$prd1990 <- predict(mdl,nwdt,type='response')
nwdt$grp <- FALSE
nwdt$prd2000 <- predict(mdl,nwdt,type='response')

  ggplot(pubs_year,aes(x=year,y=total,period)) + geom_col() +
  geom_line(col='blue',data=nwdt,aes(x=year,y=prd2000,linetype=year<1990),lwd=1.3) +
    theme_classic() + theme(legend.position = "none") + 
  ylab("Number of publications") + xlab("Year")

all_refs %>% filter(!is.na(reviewed_by)) %>% 
  mutate(`Filter 2`=if_else(status %in% 'included in review',2,1)) %>% 
  mutate(`Filter 2`=factor(`Filter 2`,labels=c("Rejected","Accepted"))) %>%
  group_by(year,`Filter 2`) %>% summarise(total=n_distinct(ref_id)) %>% 
  ggplot() + geom_col(aes(x=year,y=total,fill=`Filter 2`)) + 
  #  geom_line(col='blue',data=subset(nwdt,year>1970),aes(x=year,y=prd2000*0.01,linetype=year<1990),lwd=1.3) +
  theme_classic() + ylab("Number of publications") + xlab("Year")

pub_rates <- all_refs %>% filter(year>1974) %>% group_by(year) %>% 
  summarise(total=n(),filter1=sum(!is.na(reviewed_by)),
            filter2=sum(!is.na(status)),
            filter3=sum(status %in% "included in review"))

mdl <- glm(cbind(filter3,total-filter3)~year,data=subset(pub_rates,year>1985),
           family=binomial(link="probit"))
nwdt <- data.frame(year=seq(1985,2020,length=50))
nwdt$prd <- predict(mdl,nwdt,type='response')

ggplot(pub_rates) + geom_point(aes(x=year,y=filter3/total)) +
  geom_line(col='blue',data=nwdt,aes(x=year,y=prd),lwd=1.3) +
  theme_classic() + theme(legend.position = "none") + ylab("Proportion of studies on species distributions")
  

distmodel_ref %>% filter(!is.na(topics)) %>% left_join(my_bibtex,by=c("ref_id"="UT")) %>%
  transmute(ref_id,year=PY,topics)  -> publication_year_table

#By topics/year
publication_year_table %>%
  group_by(topics,year) %>% 
  summarise(n_pub = n_distinct(ref_id)) %>% 
  pivot_wider(id_cols=year,names_from=topics,values_from=n_pub) %>%
  arrange(year) -> py_table

py_table %>% 
  mutate(across(Biodiversity:`Methodological issues`,function(x) cumsum(coalesce(x,0)))) %>% 
  pivot_longer(Biodiversity:`Methodological issues`,names_to = 'Topic') -> fg1data

# A colorblind-friendly palette
cbbPalette <- c("#56B4E9", "#009E73", "#F0E442", "#E69F00", "#D55E00", "#CC79A7")
  fg1 <- ggplot(fg1data) + 
  geom_col(aes(x = year, y = value, fill = Topic)) +
  scale_fill_manual(values=cbbPalette) 
  
  fg1 + theme(axis.text.x=element_text(angle=45, size=8))

  fg1 + theme_classic() + ylab("Number of publications") +
    theme(axis.text.x=element_text(angle=45, size=12, hjust=1)) 
  
  
  
  
#By general application

distmodel_ref %>% filter(!is.na(general_application), !is.na(topics)) %>%
  transmute(topics, general_application,ref_id) -> my.app

## make long with cSplit
long_my.app <-  cSplit(my.app, c("topics", "general_application"), ",", "long")

long_my.app %<>%
  filter(!is.na(general_application), !is.na(topics)) %>%
  mutate(general_application = factor(general_application, levels=c("Threats monitoring","Climate change", "Spatial prediction", "Assessment of distribution", "Conservation issues","Co-occurence of parrot species",
                                                                    "Relation with environmental variables","Macroecology",
                                                                    "Ecological communities", "Temporal distribution patterns","Habitat use related to behaviour types", 
                                                                  "Biogeographic patterns", "Predictions of invasion risk","Invasion effect", "Improving estimation")))



long_my.app %>%
  filter(!is.na(general_application), !is.na(topics)) %>%
  group_by(topics, general_application) %>%
  summarise(n_pub = n_distinct(ref_id)) -> fg2data

fg2 <- ggplot(fg2data,aes(x = general_application, y=n_pub, fill = topics)) +
  geom_bar(stat="identity") +
  scale_fill_manual(values=cbbPalette)

fg2 + theme_classic() + ylab("Number of publications") +
  theme(axis.text.x=element_text(angle=45, size=12, hjust=1)) 


## Figure 3

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
  mutate(general_application = factor(general_application, levels=c("Threats monitoring","Climate change", "Spatial prediction", "Assessment of distribution", "Conservation issues","Co-occurence of parrot species",
                                                                    "Relation with environmental variables","Macroecology",
                                                                    "Ecological communities", "Temporal distribution patterns","Habitat use related to behaviour types", 
                                                                    "Biogeographic patterns", "Predictions of invasion risk","Invasion effect", "Improving estimation")))

#Just check variables with NAs
long_app_country %>% filter(is.na(general_application)) %>% pull(ref_id)
long_app_country %>% filter(is.na(species_range)) %>% pull(ref_id)

## table by paradigm
long_app_country %>%
  group_by(paradigm_type,general_application,species_range) %>%
  summarise(total=n_distinct(ref_id)) %>%
  ggplot(aes(fill=species_range, y=total, x="")) +
  geom_bar(stat="identity", position=position_stack(reverse = TRUE))+
  facet_grid(paradigm_type ~ general_application) +
  labs(x = "General applications", y = "Number of publications")+
  theme(
    legend.position="none",
    axis.text.x = element_blank(),
    panel.spacing = unit(0.2, "lines"),
    strip.text.x = element_text(size = 8, angle = 45, vjust =0, hjust = 0),
    strip.background = element_blank(),
    plot.margin = unit(c(1,6,1,6), "cm"))


## table by region
long_app_country %>%
  group_by(region, general_application,species_range) %>%
  summarise(total=n_distinct(ref_id)) %>%
  ggplot(aes(fill=species_range, y=total, x="")) +
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
  transmute(ref_id,topics,general_application, specific_issue)-> my.table

## make long with cSplit
long_table_1 <-  cSplit(my.table, c("topics","general_application", "specific_issue"), ",", "long")

long_table_1 %>% filter(!is.na(topics), !is.na(general_application)) %>%
  transmute(ref_id,topics,general_application, specific_issue) ->supl.mat1

path <- "R/output"
write.csv(supl.mat1, file.path(path, "supl.mat1.csv"))

supl.mat1%>%
  filter(!is.na(specific_issue)) %>%
  group_by(topics, general_application, specific_issue) %>%
  summarise(n_pub = n_distinct(ref_id)) -> table_1

  write.csv(table_1, file.path(path, "table_1.csv"))

# slc <-   my_bibtex %>% slice(grep("FERRER",AU)) %>% pull(UT)

#Figure 4
species_ref %>%
  inner_join(distmodel_ref,by="ref_id") %>%
  select(ref_id, scientific_name,species_range,general_application,topics) -> table_species_ref
  
long_spp_list <-  cSplit(table_species_ref, c("topics","general_application", "species_range"), ",", "long")

long_spp_list %>% filter(!is.na(general_application), !is.na(topics), !is.na(species_range)) %>%
    inner_join(Index_of_CITES_Species,by=c("scientific_name"="scientific.AF8.name")) %>%
    transmute(ref_id,topics, scientific_name, general_application, species_range, Genus) %>%
    mutate(general_application = factor(general_application, levels=c("Threats monitoring","Climate change", "Spatial prediction", "Assessment of distribution", "Conservation issues","Co-occurence of parrot species",
                                                                  "Relation with environmental variables","Macroecology",
                                                                  "Ecological communities", "Temporal distribution patterns","Habitat use related to behaviour types", 
                                                                  "Biogeographic patterns", "Predictions of invasion risk","Invasion effect", "Improving estimation"))) -> table_app_spp

  table_app_spp %>%
  group_by(Genus, general_application, species_range) %>%
  summarise(total=n_distinct(ref_id)) %>%
  ggplot(aes(x= general_application, y= Genus, size= total, color= species_range)) +
  geom_point(alpha=0.5) +
    scale_radius(range = c(2, 10),name="Number of documents") +
  theme_bw()+
  theme(axis.text.x = element_text(angle=45, size=9, hjust = 1))

  
