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
  ylab("Number of publications") + xlab("Year") -> fg1a

all_refs %>% filter(!is.na(reviewed_by)) %>% 
  mutate(`Filter 2`=if_else(status %in% 'included in review',2,1)) %>% 
  mutate(`Filter 2`=factor(`Filter 2`,labels=c("Rejected","Accepted"))) %>%
  group_by(year,`Filter 2`) %>% summarise(total=n_distinct(ref_id)) %>% 
  ggplot() + geom_col(aes(x=year,y=total,fill=`Filter 2`)) + 
  #  geom_line(col='blue',data=subset(nwdt,year>1970),aes(x=year,y=prd2000*0.01,linetype=year<1990),lwd=1.3) +
  theme_classic() + ylab("Number of publications") + xlab("Year") + theme(legend.position = "top") -> fg1b

pub_rates <- all_refs %>% filter(year>1974) %>% group_by(year) %>% 
  summarise(total=n(),filter1=sum(!is.na(reviewed_by)),
            filter2=sum(!is.na(status)),
            filter3=sum(status %in% "included in review"))

mdl <- glm(cbind(filter3,total-filter3)~year,data=subset(pub_rates,year>1985),
           family=binomial(link="probit"))
nwdt <- data.frame(year=seq(1985,2020,length=50))
nwdt$prd <- predict(mdl,nwdt,type='response')

fg1c <- ggplot(pub_rates) + geom_point(aes(x=year,y=filter3/total)) +
  geom_line(col='blue',data=nwdt,aes(x=year,y=prd),lwd=1.3) +
  theme_classic() + theme(legend.position = "none") + ylab("Proportion of studies")



ggarrange(fg1a, fg1b, fg1c, labels = c("(a)", "(b)", "(c)"), label.x=0.5,label.y=1,
           ncol = 3, nrow = 1,common.legend = FALSE, vjust = 0.9)

