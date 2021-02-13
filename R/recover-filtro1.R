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
                 host = "literature-review.cpq4sgesx7kb.ap-southeast-2.rds.amazonaws.com",
                 port = 5432,
                 user = "postgres")

 target.dir <- "WoS_psittacids_12095_20201023/"
 target.dir <- "bibtex/wildlife-trade"

 data.dir <- sprintf("%s/%s", script.dir,target.dir)
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


 kwds <- unique(trim(unlist(strsplit(ISI.search.df$DE,";"))))

# grep("POACH|EXTRACT|ILLEGAL|MARKET|PET",kwds,value=T)
ks <- grep("POACH|EXTRACT|ILLEGAL|MARKET|PET",kwds,value=T)
project <- "Illegal Wildlife Trade"
ks <- grep("DISTRIBUTION|ABUNDANCE|RANGE|NICHE|OCCURRENCE|PRESENCE|OCCUPANCY",kwds,value=T)
project <- "Species distribution models"
 for (kwd in ks) {
   qry <- sprintf("INSERT INTO psit.filtro1(ref_id,project,title) SELECT \"UT\",'%2$s','{%1$s}' FROM psit.bibtex WHERE \"TI\" like '%%%1$s%%' ON CONFLICT ON CONSTRAINT filtro1_pkey DO UPDATE SET title=array(select distinct unnest(psit.filtro1.title || EXCLUDED.title))",kwd,project)
   dbSendQuery(con,qry)
   qry <- sprintf("INSERT INTO psit.filtro1(ref_id,project,abstract) SELECT \"UT\",'%2$s','{%1$s}' FROM psit.bibtex WHERE \"AB\" like '%%%1$s%%' ON CONFLICT ON CONSTRAINT filtro1_pkey DO UPDATE SET abstract=array(select distinct unnest(psit.filtro1.abstract || EXCLUDED.abstract))",kwd,project)
   dbSendQuery(con,qry)
   qry <- sprintf("INSERT INTO psit.filtro1(ref_id,project,keyword) SELECT \"UT\",'%2$s','{%1$s}' FROM psit.bibtex WHERE \"DE\" like '%%%1$s%%' ON CONFLICT ON CONSTRAINT filtro1_pkey DO UPDATE SET keyword=array(select distinct unnest(psit.filtro1.keyword || EXCLUDED.keyword))",kwd,project)
   dbSendQuery(con,qry)

 }


dbDisconnect(con)
