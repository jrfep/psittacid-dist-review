#! R --vanilla
## Load required packages
library(bibliometrix) #the library for bibliometrics

## Set up working environment (customize accordingly...)
script.dir <- Sys.getenv("SCRIPTDIR")
work.dir <- Sys.getenv("WORKDIR")
Rdata.dir <- sprintf("%s/Rdata", script.dir)

setwd(work.dir)
target.dir <- "bibtex/wildlife-trade"
data.dir <- sprintf("%s/%s", script.dir,target.dir)
rda.arch <- sprintf("%s/%s.rda",Rdata.dir,basename(target.dir))

if (file.exists(rda.arch)) {
  cat(sprintf("File %s already exists, ",rda.arch))
} else {
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

  ISI.search.df$UT <- ifelse(is.na(ISI.search.df$UT),sprintf("AY%016s",1:1384),ISI.search.df$UT)



  require("RPostgreSQL")
  drv <- dbDriver("PostgreSQL") ## remember to update .pgpass file

  con <- dbConnect(drv, dbname = "litrev",
                   host = ifelse( system("hostname -s",intern=T)=="terra","localhost","terra.ad.unsw.edu.au"),
                   port = 5432,
                   user = "jferrer")

dbWriteTable(con,name=c("psit","bibtex"),data.frame(ISI.search.df))

  work.dir <- Sys.getenv("WORKDIR")
  script.dir <- Sys.getenv("SCRIPTDIR")

  setwd(work.dir)

## That's it!, we are ready for the next step.
