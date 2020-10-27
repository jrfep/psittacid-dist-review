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


kwds <- data.frame(keyword=unique(trim(unlist(strsplit(ISI.search.df$DE,";")))),
  filtro1="NO",stringsAsFactors=F)

kwds <- subset(kwds,!keyword %in% c("",NA))
kwds[grep("POACH|EXTRACT|ILLEGAL|MARKET",kwds$keyword),"filtro1"] <- "YES"


for (k in 1:nrow(kwds)) {
  qry <- sprintf("INSERT INTO psit.filtro1 (keyword,status) VALUES (%s,'%s') ON CONFLICT DO NOTHING", dbQuoteString(con,kwds$keyword[k]), kwds$filtro1[k])
#  dbSendQuery(con,qry)

}


orig.search <- read_sheet("1PFiB9g9whPPlD-AZH-s0mvI_DQeUjoJSDt7qjqSPRMM",sheet="Articles")

orig.search %>% mutate(UT=ISI.search.df$UT[match(orig.search$TI,ISI.search.df$TI)]) %>% mutate(UT=ifelse(is.na(UT),ISI.search.df$UT[match(DI,ISI.search.df$DI)],UT)) %>% mutate(UT=ifelse(is.na(UT),ISI.search.df$UT[match(tolower(DI),tolower(ISI.search.df$DI))],UT)) %>% mutate(UT=ifelse(is.na(UT),ISI.search.df$UT[pmatch(substr(orig.search$TI,1,50),ISI.search.df$TI)],UT)) -> orig.search

table(is.na(orig.search$UT))

orig.search %>% filter(!is.na(UT) & status %in% c('rejected off topic illegal trade' , 'rejected off topic parrots' , 'rejected illegal trade circunstancial' , 'rejected opinion','rejected overview','included in review','not available')) %>% transmute(qry=sprintf("INSERT INTO psit.filtro2(ref_id,status) VALUES('%s','%s') ON CONFLICT DO NOTHING",UT,status)) -> qries

for (qry in qries$qry)
  dbSendQuery(con,qry)

subset(orig.search,!is.na(UT) & !is.na(status)) %>% sprintf("INSERT INTO psit.filtro2(ref_id,status) VALUES('%s','%s')",`UT`,`status`) %>% print.AsIs()

subset(orig.search) %>% filter(!actions_13 %in% c("na","NA",NA)) %>% select(trade_chain,actions_11,actions_12,actions_13) %>% unique -> actions.obs
  qries <- sprintf("INSERT INTO psit.actions(trade_chain,aims,action_type,action) values('%s','%s','%s','%s') ON CONFLICT DO NOTHING",
    actions.obs$trade_chain,
    actions.obs$actions_11,
    actions.obs$actions_12,
    actions.obs$actions_13)
    for (qry in qries) {
      dbSendQuery(con,qry)
    }



tab1 <- subset(orig.search,!is.na(UT))[,c("UT","contribution","actions_13")]
tab1$reviewed_by <- "asanchez"
tab1$method <- "first round"

tab1 <- subset(tab1,!( contribution %in% c("na","NA",NA)) & !(actions_13 %in% c("na","NA",NA)))


qries <- with(tab1,sprintf("INSERT INTO psit.annotate_ref(ref_id,contribution,action) VALUES('%s','%s','%s') ON CONFLICT DO NOTHING", UT, contribution, actions_13))

for (qry in qries) {
  dbSendQuery(con,qry)
}




tab1 <- subset(orig.search,!is.na(UT) & !is.na(country) & country != "NA")[,c("UT","country")]
tab1$reviewed_by <- "asanchez"
tab1$ISO2 <- ISO_3166_1$Alpha_2[match(tab1$country,tolower(ISO_3166_1$Name))]

dbDisconnect(con)
