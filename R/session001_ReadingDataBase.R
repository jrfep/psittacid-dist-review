setwd("~/Documentos/Publicaciones/Ferrer-Paris_Sanchez-Mercado_ReviewParrotDistribution/input") 
library(bibliometrix) #the library for bibliometrics
library(dplyr) #for data munging
library(tidytext)
library(tidyr)
library(data.table)
library(rpostgis)
library(splitstackshape)

###
#INSIDE THE DATA BASE
####
# loads the PostgreSQL driver
drv <- dbDriver("PostgreSQL")
# creates a connection to the postgres database
# note that "con" will be used later in each connection to the database
con <- dbConnect(drv, dbname = "litrev",
                   host = "literature-review.cpq4sgesx7kb.ap-southeast-2.rds.amazonaws.com", port = 5432,
                   user = "postgres")
#To see the tables in the database  
dbGetQuery(con,
           "SELECT table_name FROM information_schema.tables
                     WHERE table_schema='psit'")

#Create object with each table
distmodel_ref <- dbGetQuery(con, "SELECT * FROM psit. distmodel_ref")
write.csv(distmodel_ref, "distmodel_ref.csv")

distmodel_ref <- read.csv("distmodel_ref.csv",sep=",",header=T, dec=".", stringsAsFactors=F)
str(distmodel_ref) # 160 obs. of  14 variables

#Specie list
species_ref <- dbGetQuery(con, "SELECT * FROM psit. species_ref")
write.csv(species_ref, "species_ref.csv")
species_ref <- read.csv("species_ref.csv",sep=",",header=T, dec=".", stringsAsFactors=F)
str(species_ref) #4494 obs. of  5 variables

#Country list
country_ref <- dbGetQuery(con, "SELECT * FROM psit. country_ref")
write.csv(country_ref, "country_ref.csv")
country_ref <- read.csv("country_ref.csv",sep=",",header=T, dec=".", stringsAsFactors=F)
str(country_ref) #5313 obs. of  5 variables

#See the names of the columns in the table bibtex
dbGetQuery(con, "SELECT column_name
  FROM information_schema.columns
 WHERE table_schema = 'psit'
   AND table_name   = 'bibtex'")

# As annotate_ref$ref_id is a character, you'll have to surround this in quotes:
qry2 <- "SELECT * FROM psit.bibtex WHERE \"UT\" IN 
(SELECT ref_id FROM psit.distmodel_ref)"
my.bibtex <- dbGetQuery(con, qry2)

write.csv(my.bibtex, "my.bibtex.csv")
my.bibtex <- read.csv("my.bibtex.csv",sep=",",header=T, dec=".", stringsAsFactors=F)
str(my.bibtex) #160  69
# Rename column where names is "UT"
names(my.bibtex)[names(my.bibtex) == "UT"] <- "ref_id"

#LOAD SUPPORTING FILES

my.iucn<- read.csv("birdlife_list.csv",sep=",",header=T, dec=".", stringsAsFactors=F)
str(my.iucn)#419   4
aggregate(my.iucn$scientific_name, list(my.iucn$family), length)

#country and regions list
iso_countries<- read.csv("iso_countries.csv",sep=",",header=T, dec=".", stringsAsFactors=F)
str(iso_countries)

#END