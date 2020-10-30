#! R --vanilla
## Load required packages
library(bibliometrix) #the library for bibliometrics
require(readxl)
require(ISOcodes)
library(googlesheets4)
require(dplyr)

require("RPostgreSQL")

## Set up working environment (customize accordingly...)
script.dir <- Sys.getenv("SCRIPTDIR")
work.dir <- Sys.getenv("WORKDIR")
Rdata.dir <- sprintf("%s/Rdata", script.dir)
setwd(work.dir)

drv <- dbDriver("PostgreSQL") ## remember to update .pgpass file
con <- dbConnect(drv, dbname = "litrev",
                 host = ifelse( system("hostname -s",intern=T)=="terra","localhost","terra.ad.unsw.edu.au"),
                 port = 5432,
                 user = "jferrer")

dbWriteTable(con,name=c("psit","countries"),ISOcodes::ISO_3166_1,overwrite=F)

birdlife.list <- read_sheet("1PFiB9g9whPPlD-AZH-s0mvI_DQeUjoJSDt7qjqSPRMM",sheet="BirdLife list")
dbWriteTable(con,name=c("psit","birdlife"),data.frame(birdlife.list),overwrite=F)



action.tab <- read_sheet("1PFiB9g9whPPlD-AZH-s0mvI_DQeUjoJSDt7qjqSPRMM",sheet="Framework")

for (j in 1:nrow(action.tab)) {
  qries <- sprintf("INSERT INTO psit.actions(trade_chain,aims,action_type,action) values('%s','%s','%s','%s') ON CONFLICT DO NOTHING",
    action.tab$Side[j],
    action.tab$`Actions aims`[j],
    action.tab$`Action types`[j],
    trim(strsplit(action.tab$`Action examples`[j],",")[[1]]))
    for (qry in qries) {
      dbSendQuery(con,qry)
    }
}



target.dir <- "WoS_psittacids_12095_20201023/"
data.dir <- sprintf("%s/%s", work.dir,target.dir)
  cat(sprintf("Loop through bibtex files in directory %s\n",target.dir))
  for (arch in dir(data.dir,pattern=".bib",full.names=T)) {
    # read file and transform to data frame

    M0 <- convert2df(arch, dbsource = "isi", format = "bibtex")
    # add a column with the topic (taken from file name)
    M0$search.group <- gsub(".bib", "", basename(arch))
    # bind data frames by rows
    if (!exists("ISI.search.df")) {
      ISI.search.df <- M0
    } else {
      cc1 <- colnames(ISI.search.df)
      cc2 <- colnames(M0)
      for (cc in cc1[!cc1 %in% cc2])
        M0[,cc] <- NA
      for (cc in cc2[!cc2 %in% cc1])
        ISI.search.df[,cc] <- NA

      ISI.search.df <- rbind(ISI.search.df,M0)
    }
    # clean-up
    rm(M0)
  }

  ISI.search.df <- ISI.search.df[!(duplicated(ISI.search.df$UT) | duplicated(ISI.search.df$TI)), ]

arch <- sprintf("%s/bibtex/wildlife-trade/My Collection.bib",script.dir)
  M0 <- convert2df(arch, dbsource = "isi", format = "bibtex")
  # add a column with the topic (taken from file name)
  M0$search.group <- gsub(".bib", "", basename(arch))
  cc1 <- colnames(ISI.search.df)
  cc2 <- colnames(M0)
  for (cc in cc1[!cc1 %in% cc2])
    M0[,cc] <- NA
  for (cc in cc2[!cc2 %in% cc1])
    ISI.search.df[,cc] <- NA
  M0$UT <- ifelse(is.na(M0$UT),sprintf("AY%016s",1:nrow(M0)),M0$UT)
  M0 <- subset(M0,!TI %in% ISI.search.df$TI)
  ISI.search.df <- rbind(ISI.search.df,M0[,colnames(ISI.search.df)])

ISI.search.df <- ISI.search.df[rev(order(ISI.search.df$UT)),]
ISI.search.df <- ISI.search.df[!(duplicated(ISI.search.df$UT) | duplicated(ISI.search.df$TI)), ]

dbWriteTable(con,name=c("psit","bibtex"),data.frame(ISI.search.df),overwrite=T)
qry <- 'ALTER TABLE  psit.bibtex ADD CONSTRAINT ref_id PRIMARY KEY ("UT")';
dbSendQuery(con,qry)

kwds <- unique(trim(unlist(strsplit(ISI.search.df$DE,";"))))

for (kwd in grep("POACH|EXTRACT|ILLEGAL|MARKET|PET",kwds,value=T)) {
  qry <- sprintf("INSERT INTO psit.filtro1(ref_id,title) SELECT \"UT\",'{%1$s}' FROM psit.bibtex WHERE \"TI\" like '%%%1$s%%' ON CONFLICT ON CONSTRAINT filtro1_pkey DO UPDATE SET title=array(select distinct unnest(psit.filtro1.title || EXCLUDED.title))",kwd)
  dbSendQuery(con,qry)
  qry <- sprintf("INSERT INTO psit.filtro1(ref_id,abstract) SELECT \"UT\",'{%1$s}' FROM psit.bibtex WHERE \"AB\" like '%%%1$s%%' ON CONFLICT ON CONSTRAINT filtro1_pkey DO UPDATE SET abstract=array(select distinct unnest(psit.filtro1.abstract || EXCLUDED.abstract))",kwd)
  dbSendQuery(con,qry)
  qry <- sprintf("INSERT INTO psit.filtro1(ref_id,keyword) SELECT \"UT\",'{%1$s}' FROM psit.bibtex WHERE \"DE\" like '%%%1$s%%' ON CONFLICT ON CONSTRAINT filtro1_pkey DO UPDATE SET keyword=array(select distinct unnest(psit.filtro1.keyword || EXCLUDED.keyword))",kwd)
  dbSendQuery(con,qry)

}



orig.search <- read_sheet("1PFiB9g9whPPlD-AZH-s0mvI_DQeUjoJSDt7qjqSPRMM",sheet="Articles")

orig.search %>% mutate(UT=ISI.search.df$UT[match(orig.search$TI,ISI.search.df$TI)]) %>% mutate(UT=ifelse(is.na(UT),ISI.search.df$UT[match(DI,ISI.search.df$DI)],UT)) %>% mutate(UT=ifelse(is.na(UT),ISI.search.df$UT[match(tolower(DI),tolower(ISI.search.df$DI))],UT)) %>% mutate(UT=ifelse(is.na(UT),ISI.search.df$UT[pmatch(substr(orig.search$TI,1,50),ISI.search.df$TI)],UT)) -> orig.search

table(is.na(orig.search$UT))

orig.search %>% filter(!is.na(UT) & status %in% c('rejected off topic illegal trade' , 'rejected off topic parrots' , 'rejected illegal trade circunstancial' , 'rejected opinion','rejected overview','included in review','not available')) %>% transmute(qry=sprintf("INSERT INTO psit.filtro2(ref_id,status) VALUES('%s','%s') ON CONFLICT DO NOTHING",UT,status)) -> qries

for (qry in qries$qry)
  dbSendQuery(con,qry)



subset(orig.search) %>% filter(!actions_13 %in% c("na","NA",NA)) %>% select(trade_chain,actions_11,actions_12,actions_13) %>% unique -> actions.obs
  qries <- sprintf("INSERT INTO psit.actions(trade_chain,aims,action_type,action) values('%s','%s','%s','%s') ON CONFLICT DO NOTHING",
    actions.obs$trade_chain,
    actions.obs$actions_11,
    actions.obs$actions_12,
    actions.obs$actions_13)
    for (qry in qries) {
      dbSendQuery(con,qry)
    }



orig.search %>% filter(!is.na(UT),!( contribution %in% c("na","NA",NA)), !(actions_13 %in% c("na","NA",NA))) %>% select(UT,contribution,actions_13,data_type,country) %>% mutate(dts=gsub(" :: ",",",data_type),ISO2 = ISO_3166_1$Alpha_2[match(country,tolower(ISO_3166_1$Name))]
) %>% mutate(ISO2=ifelse(is.na(ISO2),gsub(" :: ",",",country),ISO2))-> tab1



qries <- with(tab1,sprintf("INSERT INTO psit.annotate_ref(ref_id,contribution,action,data_type,country_list) VALUES('%s','%s','%s','{%s}','{%s}') ON CONFLICT DO NOTHING", UT, contribution, actions_13,dts,ISO2))
for (qry in qries)
  dbSendQuery(con,qry)


  spp.list <- read_sheet("1PFiB9g9whPPlD-AZH-s0mvI_DQeUjoJSDt7qjqSPRMM",sheet="Species list")
  spp.list$UT <- orig.search$UT[match(spp.list$TI,orig.search$TI)]

  spp.list %>% filter(!is.na(UT),scientific_name %in% birdlife.list$scientific_name) -> tab1


  qries <- with(tab1,sprintf("INSERT INTO psit.species_ref(ref_id,scientific_name,individuals) VALUES('%s','%s',%s) ON CONFLICT DO NOTHING", UT, scientific_name,ifelse(is.na(individuals),'NULL',individuals)))
  for (qry in qries)
    dbSendQuery(con,qry)


qries <- with(birdlife.list,sprintf("INSERT INTO psit.species_ref (ref_id,scientific_name,reviewed_by)
SELECT \"UT\",'%s','Rsaurio' from psit.bibtex where \"TI\" ilike '%%%s%%' OR \"TI\" ilike '%%%s%%' ON CONFLICT DO NOTHING",scientific_name,scientific_name,gsub("'","%",english_name)))
for (qry in qries)
  dbSendQuery(con,qry)

qries <- with(birdlife.list,sprintf("INSERT INTO psit.species_ref (ref_id,scientific_name,reviewed_by)
SELECT \"UT\",'%s','Rsaurio' from psit.bibtex where \"AB\" ilike '%%%s%%' OR \"AB\" ilike '%%%s%%' ON CONFLICT DO NOTHING",scientific_name,scientific_name,gsub("'","%",english_name)))
for (qry in qries)
  dbSendQuery(con,qry)

qries <- with(birdlife.list,sprintf("INSERT INTO psit.species_ref (ref_id,scientific_name,reviewed_by)
SELECT \"UT\",'%s','Rsaurio' from psit.bibtex where \"DE\" ilike '%%%s%%' OR \"DE\" ilike '%%%s%%' ON CONFLICT DO NOTHING",scientific_name,scientific_name,gsub("'","%",english_name)))
for (qry in qries)
  dbSendQuery(con,qry)


qries <- with(ISO_3166_1,sprintf("INSERT INTO psit.country_ref (ref_id,iso2,reviewed_by)
SELECT \"UT\",'%1$s','Rsaurio' from psit.bibtex where \"TI\" ilike '%%%2$s%%' OR \"AB\" ilike '%%%2$s%%'OR \"AB\" ilike '%%%2$s%%' ON CONFLICT DO NOTHING",Alpha_2,gsub("'","%",Name)))
for (qry in qries)
  dbSendQuery(con,qry)

  qries <- with(subset(ISO_3166_1,!is.na(Common_name)),sprintf("INSERT INTO psit.country_ref (ref_id,iso2,reviewed_by)
  SELECT \"UT\",'%1$s','Rsaurio' from psit.bibtex where \"TI\" ilike '%%%2$s%%' OR \"AB\" ilike '%%%2$s%%'OR \"AB\" ilike '%%%2$s%%' ON CONFLICT DO NOTHING",Alpha_2,gsub("'","%",Common_name)))
  for (qry in qries)
    dbSendQuery(con,qry)

  qries <- with(subset(ISO_3166_1,!is.na(Official_name)),sprintf("INSERT INTO psit.country_ref (ref_id,iso2,reviewed_by)
  SELECT \"UT\",'%1$s','Rsaurio' from psit.bibtex where \"TI\" ilike '%%%2$s%%' OR \"AB\" ilike '%%%2$s%%'OR \"AB\" ilike '%%%2$s%%' ON CONFLICT DO NOTHING",Alpha_2,gsub("'","%",Official_name)))

for (qry in qries)
  dbSendQuery(con,qry)


dbDisconnect(con)
