require(magrittr)
library(dplyr) #for data munging
require(DT)
library(splitstackshape)

#Table 1
distmodel_ref %>% filter(!is.na(paradigm)) %>%
  transmute(ref_id,topics,general_application, specific_issue)-> my.table

## make long with cSplit
long_table_1 <-  cSplit(my.table, c("topics","general_application", "specific_issue"), ",", "long")

long_table_1 %>% filter(!is.na(topics), !is.na(general_application)) %>%
  transmute(ref_id,topics,general_application, specific_issue) ->supl.mat1
