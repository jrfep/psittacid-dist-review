#cd $WORKDIR
# unzip $SCRIPTDIR/bibtex/WoS_psittacids_12095_20201023.zip

#! R --vanilla
## Load required packages
library(bibliometrix) #the library for bibliometrics
require(readxl)
require(ISOcodes)
library(googlesheets4)
require(dplyr)
require(rcrossref)
 require(magrittr)
 require(stringr)


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
data.dir <- sprintf("%s/%s", work.dir,target.dir)
data.dir <- sprintf("%s/bibtex", script.dir)

cat(sprintf("Loop through bibtex files in directory %s\n",target.dir))

for (arch in list.files(data.dir,recursive=T,pattern=".bib",full.names=T)) {
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

ISI.search.df %>% filter(!is.na(CR) & nchar(CR)>5) %>% transmute(qry=sprintf("INSERT INTO psit.bibtex (\"UT\",\"CR\") values('%s','%s') ON CONFLICT (\"UT\") DO UPDATE SET \"CR\"=EXCLUDED.\"CR\"",UT,gsub("'","''",CR))) %>% pull(qry) -> qries
for (qry in qries)
  dbSendQuery(con,qry)



ISI.search.df %>% filter(!is.na(CR) & nchar(CR)>5) -> ISI.search.ss

for (k in 1:nrow(ISI.search.ss)) {
  ISI.search.ss %>% slice(k) %>% pull(CR) -> slc
  ##strsplit(slc,";")
  str_split(slc,";",simplify=T) %>% str_split_fixed(" DOI ",n=2) -> cts

  colnames(cts) <- c("key","doi")
  cts <- data.frame(cts,stringsAsFactors=F)
  ISI.search.ss %>% slice(k) %>% pull(UT) -> cts$UT
  cts %<>% transmute(from=UT,ref_key=str_trim(key),doi) %>% mutate(qry=sprintf("INSERT INTO psit.added_refs (ref_code,doi) VALUES ('%s','%s') ON CONFLICT DO NOTHING",gsub("'","''",ref_key),doi))

  for (qry in cts$qry)
    dbSendQuery(con,qry)

  cts %<>%  mutate(qry=sprintf("INSERT INTO psit.citation_rels VALUES ('%s','UT cites SR','%s') ON CONFLICT DO NOTHING",from,gsub("'","''",ref_key)))

  for (qry in cts$qry)
    dbSendQuery(con,qry)

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


 qry <- sprintf("SELECT \"UT\",\"TI\",\"AB\",\"DI\",status FROM psit.filtro2 LEFT JOIN psit.bibtex ON ref_id=\"UT\" WHERE project='Species distribution models' AND status='included in review'")
  res <- dbGetQuery(con,qry)

res %>% filter(!is.na(DI)) %>% distinct(DI) %>% pull(DI) -> qry.dois


tst <- cr_works(dois=qry.dois)

links <- tibble()
for (k in 1:length(tst$data)) {
  tst$data %>% slice(k) %>% pull(doi) -> s.doi
  tst$data %>% slice(k) %>% pull(reference) -> refs
  if (!is.null(refs[[1]])) {
    refs[[1]] %>% filter(!is.na(DOI)) %>% pull(DOI) -> t.doi
    links %<>% bind_rows(data.frame(from=s.doi,to=t.doi))
  }
}


dbDisconnect(con)
