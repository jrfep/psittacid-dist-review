require(magrittr)
library(dplyr) #for data munging
require(DT)
library(splitstackshape)

tables <- c("distmodel_ref")
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

#Table 1
distmodel_ref %>% filter(!is.na(paradigm)) %>%
  transmute(ref_id,topics,general_application, specific_issue)-> my.table

## make long with cSplit
long_table_1 <-  cSplit(my.table, c("topics","general_application", "specific_issue"), ",", "long")

long_table_1 %>% filter(!is.na(topics), !is.na(general_application)) %>%
  transmute(ref_id,topics,general_application, specific_issue) ->supl.mat1
