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
  transmute(topics, general_application,ref_id) -> my.app

## make long with cSplit
long_my.app <-  cSplit(my.app, c("topics", "general_application"), ",", "long")

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



# Figure 2

long_my.app %>% filter(!is.na(topics)) %>% left_join(my_bibtex,by=c("ref_id"="UT")) %>% transmute(ref_id,year=PY,topics) %>% filter(!is.na(year))  -> publication_year_table

publication_year_table %>% filter(year<2005)

#By topics/year
publication_year_table %>%
  group_by(topics,year) %>% 
  summarise(n_pub = n_distinct(ref_id)) %>% 
  pivot_wider(id_cols=year,names_from=topics,values_from=n_pub) %>%
  arrange(year) -> py_table

py_table %>% 
  mutate(across(Behaviour:`Methodological issues`,function(x) cumsum(coalesce(x,0)))) %>% 
  pivot_longer(Behaviour:`Methodological issues`,names_to = 'Topic') %>% filter(year>2003) -> fg1data

py_table %>% mutate(across(Behaviour:`Methodological issues`,
                           function(x) cumsum(coalesce(x,0)))) %>% 
  rowwise %>% mutate(total=sum(c_across(Behaviour:`Methodological issues`))) %>% 
  ungroup %>% transmute(year,ecology.p=Ecology/total,conservation.p=Conservation/total,invasion.p=`Invasion ecology`/total)

# A colorblind-friendly palette
cbbPalette <- c("#56B4E9", "#009E73", "#F0E442", "#E69F00", "#D55E00", "#CC79A7")
fg2 <- ggplot(fg1data) + 
  geom_col(aes(x = year, y = value, fill = Topic)) +
  scale_fill_manual(values=cbbPalette) 

fg2 + theme(axis.text.x=element_text(angle=45, size=8))

(fg2 + theme_classic() + ylab("Number of publications") + xlab("Year") +
  theme(axis.text.x=element_text(angle=45, size=12, hjust=1)) -> fg2a)

long_my.app %>%
  filter(!is.na(general_application), !is.na(topics)) %>%
  group_by(topics, general_application) %>%
  summarise(n_pub = n_distinct(ref_id)) %>% arrange(topics,n_pub)-> fg2data

ordlevels <- fg2data %>% pull(general_application)
fg2data %<>%
  filter(!is.na(general_application), !is.na(topics)) %>%
  mutate(general_application = factor(general_application, levels=ordlevels))



(fg2 <- ggplot(fg2data,aes(x = general_application, y=n_pub, fill=topics)) +
    geom_bar(stat="identity") +
    scale_fill_manual(values=cbbPalette))

(fg2 + theme_classic() + ylab("Number of publications") + xlab("") +
  theme(axis.text.x=element_text(angle=45, size=10, hjust=1),legend.position = "none") -> fg2b)








 ggarrange( fg2a, fg2b, labels = c("a", "b"), label.x=0.5,label.y=.1,ncol = 2, nrow = 1,common.legend = TRUE,legend="bottom")


