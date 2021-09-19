library(bibliometrix) #the library for bibliometrics
library(dplyr) #for data munging
library(tidytext)
library(tidyr)
library(data.table)
library(rpostgis)
library(splitstackshape)

###
# Update tables from DATA BASE
####

# source this code to read database credential from file $HOME/.database.ini
source("env/database-credentials.R")

## if we have database credential we can update all objects:
if (dbinfo["host"] != "") {
  # loads the PostgreSQL driver
  drv <- dbDriver("PostgreSQL")
  # creates a connection to the postgres database
  # note that "con" will be used later in each connection to the database
  con <- dbConnect(drv, dbname = dbinfo["database"],
                     host = dbinfo["host"], port = dbinfo["port"],
                     user = dbinfo["user"])

  #To see the tables in the database
  dbGetQuery(con,
             "SELECT table_name FROM information_schema.tables
                       WHERE table_schema='psit'")

  #Query names of the columns in the table bibtex
  dbGetQuery(con, "SELECT column_name
   FROM information_schema.columns
  WHERE table_schema = 'psit'
    AND table_name   = 'bibtex'")

  #Create objects with all information from these tables in the database

  tables <- c("distmodel_ref","species_ref","country_ref","bibtex")

  for (tt in tables) {
    if (tt %in% "bibtex") {
      # UT column name needs to be surrounded in quotes:
      qry <- "SELECT * FROM psit.bibtex WHERE \"UT\" IN
      (SELECT ref_id FROM psit.distmodel_ref)"
      outcsv <- sprintf("input/my_%s.csv",tt)
    } else {
      qry <- sprintf("SELECT * FROM psit.%s",tt)
      outcsv <- sprintf("input/%s.csv",tt)
    }

    qryTable <- dbGetQuery(con, qry)
    write.csv(qryTable, outcsv)
    assign(tt,qryTable)
  }
  dbDisconnect(con)
}

###
# Read tables from input folder
####
## if there is no database connection, we will read the csv files in output folder:

tables <- c("distmodel_ref", "species_ref", "country_ref", "my_bibtex", "birdlife_list", "iso_countries")
for (tt in tables) {
  if (!exists(tt)) {
    incsv <- sprintf("input/%s.csv",tt)
    assign(tt,read.csv(incsv,sep=",",header=T, dec=".", stringsAsFactors=F))
  }
}
str(distmodel_ref) # 160 obs. of  13 variables
str(species_ref) #4494 obs. of  5 variables
#Country list
str(country_ref) #5313 obs. of  5 variables
str(my_bibtex) #160  69
# Rename column where names is "UT"
names(my_bibtex)[names(my_bibtex) == "UT"] <- "ref_id"

#SUPPORTING FILES
str(birdlife_list)#419   4
aggregate(birdlife_list$scientific_name, list(birdlife_list$family), length)
#country and regions list
str(iso_countries)

#END
