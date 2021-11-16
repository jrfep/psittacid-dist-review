########################################
## Step 1: read from database or csv files and reshape data
############################################

## Load libraries

library(dplyr)
library(tidyr)
library(rpostgis)
library(splitstackshape)
require(here)

###
# Update csv tables from DATA BASE
####

# source this code to read database credential from file $HOME/.database.ini
source(sprintf("%s/env/database-credentials.R",here()))

## if we have database credential we can update all objects:
if (dbinfo["host"] != "") {
  # loads the PostgreSQL driver
  drv <- dbDriver("PostgreSQL")
  # creates a connection to the postgres database
  # note that "con" will be used later in each connection to the database
  con <- try(dbConnect(drv, dbname = dbinfo["database"],
  host = dbinfo["host"], port = dbinfo["port"],
  user = dbinfo["user"]))

  if (any(class(con) %in% 'try-error')) {
    cat("no connection to database!")
    } else {
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
            outcsv <- sprintf("%s/input/my_%s.csv",here(),tt)
        } else {
          qry <- sprintf("SELECT * FROM psit.%s",tt)
          outcsv <- sprintf("%s/input/%s.csv",here(),tt)
        }

        qryTable <- dbGetQuery(con, qry)
        write.csv(qryTable, outcsv)
        assign(tt,qryTable)
      }

      # additional query: total number of publications per year
      outcsv <- sprintf("%s/input/all_refs.csv",here())
      qry <- "WITH bt AS (SELECT \"UT\" as ref_id,\"PY\" as year FROM psit.bibtex),
      f1 AS (SELECT ref_id,reviewed_by FROM psit.filtro1 WHERE project='Species distribution models'),
      f2 AS (SELECT ref_id,status FROM psit.filtro2 WHERE project='Species distribution models')
      SELECT year,ref_id,reviewed_by,status from bt
      LEFT JOIN f1 USING (ref_id)
      LEFT JOIN f2 USING (ref_id)"

      all_refs <- dbGetQuery(con, qry)
      write.csv(all_refs, outcsv)
      dbDisconnect(con)

  }
}

###
# Read tables from input folder
####
## if there is no database connection, we will read the csv files in output folder:

tables <- c("distmodel_ref", "species_ref", "country_ref", "my_bibtex", "birdlife_list", "iso_countries")
for (tt in tables) {
  if (!exists(tt)) {
    incsv <- sprintf("%s/input/%s.csv",here(),tt)
    assign(tt,read.csv(incsv,sep=",",header=T, dec=".", stringsAsFactors=F))
  }
}
str(distmodel_ref) # 160 obs. of  13 variables
str(species_ref) #4494 obs. of  5 variables
#Country list
str(country_ref) #5313 obs. of  5 variables
str(my_bibtex) #160  69

#SUPPORTING FILES
str(birdlife_list)#419   4
aggregate(birdlife_list$scientific_name, list(birdlife_list$family), length)
#country and regions list
str(iso_countries)

###
# Clean up and reshape data
####

distmodel_ref %<>% # operador para sobreescribir el objeto con el resultado
  ## quitar corchetes y parentesis
  mutate(across(c(paradigm,model_type,general_application,species_range,species_list,topics,specific_issue,data_source),~gsub("\\{|\\}|\\(|\\)","",.))) %>%
  ## quitar comillas
  mutate(across(c(general_application,species_list,topics,specific_issue),~gsub("\"","",.,fixed=T)))


distmodel_ref %<>%
    ## reclasificar categorias de paradigm
    mutate(paradigm_type=case_when(
      paradigm %in% c("RSF,NM","RSF,OM","RSF") ~ "RSF",
      paradigm %in% c("NM") ~ "ENM",
      paradigm %in% c("OM") ~ "OSM",
      is.na(paradigm) ~ as.character(NA),
      TRUE~ "other"
    )) %>%
    ## convertir en factor
    mutate(paradigm_type=factor(paradigm_type,levels=c("ENM","RSF","OSM","other")))


distmodel_ref %<>%
  ## reclasificar categorias de topics
  mutate(topics=case_when(
    topics %in% c("evolution") ~ "Evolution",
    topics %in% c("Bahavior") ~ "Behavior",
    topics %in% c("Behavior","Biodiversity","Conservation", "Evolution","Ecology", "Invasion ecology", "Methodological issues") ~ topics))


########################################
## END Step 1
############################################
