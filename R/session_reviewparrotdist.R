setwd("~/Documentos/Publicaciones/Ferrer-Paris & Sánchez-Mercado_ReviewParrotDistribution")
  
library(bibliometrix) #the library for bibliometrics
library(dplyr) #for data munging
require(ggplot2) #visualization
library("RColorBrewer")
library(tidytext)
library(tidyr)
library(RPostgreSQL)
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
#distmodel_ref <- dbGetQuery(con, "SELECT * FROM psit. distmodel_ref")
#write.csv(distmodel_ref, "distmodel_ref.csv")

distmodel_ref <- read.csv("distmodel_ref.csv",sep=",",header=T, dec=".", stringsAsFactors=F)
str(distmodel_ref) # 160 obs. of  13 variables

#Specie list
species_ref <- dbGetQuery(con, "SELECT * FROM psit. species_ref")
#write.csv(species_ref, "species_ref.csv")
species_ref <- read.csv("species_ref.csv",sep=",",header=T, dec=".", stringsAsFactors=F)
str(species_ref) #4494 obs. of  5 variables

#Country list
country_ref <- dbGetQuery(con, "SELECT * FROM psit. country_ref")
#write.csv(country_ref, "country_ref.csv")
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

#write.csv(my.bibtex, "my.bibtex.csv")
my.bibtex <- read.csv("my.bibtex.csv",sep=",",header=T, dec=".", stringsAsFactors=F)
dim(my.bibtex) #160  69

####
#STEP 1: SUPPORTING FILES
####
my.iucn<- read.csv("birdlife_list.csv",sep=",",header=T, dec=".", stringsAsFactors=F)
str(my.iucn)#419   4
aggregate(my.iucn$scientific_name, list(my.iucn$family), length)

#Combine annotated document with list of countries




my.data <- merge(distmodel_ref, country_ref, by = "ref_id")
dim(my.data)#155 17
  
#Delete quotation marks
my.data<-as.data.frame(sapply(my.data, function(x) gsub("\"", "", x)))
#Delete brackets
my.data<-as.data.frame(sapply(my.data, function(x) gsub("\\{|}", "", x)))
my.data<-as.data.frame(sapply(my.data, function(x) gsub("\\(|)", "", x)))

#Model type
table(my.data$model_type)
#Reclasy them
for (tt in c("Bayesian logistic regressions", "General Linear Model GLM",
             "Generalized Additive Models GAM", "Generalized Linear Models GLM")) {
  my.data$model_type <- gsub(tt, "Regression_Models", my.data$model_type)
}

for (tt in c("dynamic occupancy models", "N-mixture models", 
             "Single Season Occupancy Model SS-OM", "multi-season occupancy models")) {
  my.data$model_type <- gsub(tt, "OM", my.data$model_type)
}

for (tt in c("Ensemble model", "Ensemble Models")) {
  my.data$model_type <- gsub(tt, "Ensemble_Approach", my.data$model_type)
}

for (tt in c("GENETIC ALGORITHM FOR RULE-SET PREDICTION GARP")) {
  my.data$model_type <- gsub(tt, "GARP", my.data$model_type)
}

for (tt in c("Maximum Entropy MaxEnt")) {
  my.data$model_type <- gsub(tt, "MaxEnt", my.data$model_type)
}

for (tt in c("Maximum likelihood distribution model MaxLike",
             "Random Forest RF",
             "Bioclimatic enveloped",
             "theoretical Weibull probability distribution",
             "kernel methods", "ENFA", "Mixed procedure of SAS",
             "spatial point pattern")) {
  my.data$model_type <- gsub(tt, "Other_NMmodels", my.data$model_type)
}

for (tt in c("Distance",
             "Detectability test", "Jaccard index")) {
  my.data$model_type <- gsub(tt, "none", my.data$model_type)
}

table(my.data$model_type)

#One document reports several models type, lets split delimited strings in a column and insert as new rows
my.data <- cSplit(my.data, "model_type", ",", "long")
dim(my.data) #161 17
table(my.data$model_type)

#Subset the documents with "none" models because those are false positives
my.data2 <- subset(my.data, model_type != "none")
dim(my.data2) #78 17
my.data2$model_type <-droplevels(my.data2$model_type) #drop unused levels
table(my.data2$model_type)

#Specific issues
for (tt in c("Simulating effects of threats/actions")) {
  my.data2$specific_issue <- gsub(tt, "Threat effect on distribution/occupancy", 
                                  my.data2$specific_issue)
}

for (tt in c("potential distribution", "Identifying potential habitat")) {
  my.data2$specific_issue <- gsub(tt, "Identifying potential habitat", 
                                  my.data2$specific_issue)
}

for (tt in c("change in distribution", "Change in distribution driven by habitat loss")) {
  my.data2$specific_issue <- gsub(tt, "Change in distribution driven by habitat loss", 
                                  my.data2$specific_issue)
}

for (tt in c("assessment of threats", "Threat distribution")) {
  my.data2$specific_issue <- gsub(tt, "Threat distribution", 
                                  my.data2$specific_issue)
}
table(my.data2$specific_issue)

#Split the list of specific issues
my.data2 <- cSplit(my.data2, "specific_issue", ",", "long")
table(my.data2$specific_issue)

#Specific issues
xx <- my.data2 %>%
  filter(is.na(specific_issue) == FALSE) %>%
  group_by(specific_issue) %>%
  summarise(n_pub = n())

#Paradigms
table(my.data2$paradigm)
my.data2 <- cSplit(my.data2, "paradigm", ",", "long")
my.data2$paradigm[my.data2$paradigm == "not clear"] <- NA
my.data2$paradigm <-droplevels(my.data2$paradigm) #drop unused levels
table(my.data2$paradigm)
#NM  OM       RSF 
#76 15         6 

#Native versus non-native
table(my.data2$species_range)
#Native Non-native 
#88            12

#Topics
table(my.data2$topics)
my.data2 <- cSplit(my.data2, "topics", ",", "long")
my.data2$topics[my.data2$topics == "current occurrence"] <- NA
my.data2$topics[my.data2$topics == "establishment of non-native species"] <- NA
my.data2$topics <-droplevels(my.data2$topics) #drop unused levels
table(my.data2$topics)

#General applications
aggregate(my.data2$ref_id, list(my.data2$general_application), length)

for (tt in c("Seasonality/Migratory movements")) {
  my.data2$general_application <- gsub(tt, "Temporal distribution patterns", my.data2$general_application)
}

for (tt in c("Coverage in protected areas")) {
  my.data2$general_application <- gsub(tt, "Spatial prediction", my.data2$general_application)
}

for (tt in c("Biodiversity", "Co-occurence of parrot species")) {
  my.data2$general_application <- gsub(tt, "Co-occurence of parrot species", my.data2$general_application)
}

my.data2 <- cSplit(my.data2, "general_application", ",", "long")
dim(my.data2) #176  19

table(my.data2$topics, my.data2$general_application)

#Reclasify
my.data2 <-my.data2 %>% 
  mutate(topics2 = as.character(topics)) %>% 
  mutate(topics2 = if_else(general_application == "Temporal distribution patterns", "Ecology", topics2))%>% 
  mutate(topics2 = if_else(general_application == "Spatial prediction", "Conservation", topics2)) %>% 
  mutate(topics2 = if_else(general_application == "Relation with environmental variables", "Ecology", topics2))%>% 
  mutate(topics2 = if_else(general_application == "Predictions of invasion risk", "Invasion ecology", topics2)) %>% 
  mutate(topics2 = if_else(general_application == "Improving estimation", "Methodological issues", topics2)) %>% 
  mutate(topics2 = if_else(general_application == "Co-occurence of parrot species", "Ecology", topics2))%>% 
  mutate(topics2 = if_else(general_application == "Climate change", "Conservation", topics2))%>% 
  mutate(topics2 = if_else(general_application == "Biodiversity", "Ecology", topics2))%>%
  mutate(topics2 = if_else(general_application == "Assessment of distribution", "Ecology", topics2))

table(my.data2$topics2, my.data2$general_application)

#Which is the most frequent application?
# A colorblind-friendly palette
cbbPalette <- c("#56B4E9", "#009E73", "#F0E442", "#E69F00", "#D55E00", "#CC79A7")

my.data2 %>%
  filter(is.na(general_application) == FALSE) %>%
  mutate(general_application = factor(general_application, levels=c("Climate change","Threats monitoring", "Spatial prediction", 
                                                                    "Macroecology","Assessment of distribution", "Biodiversity", "Co-occurence of parrot species",
                                                                    "Temporal distribution patterns","Relation with environmental variables",
                                                        "Biogeographic patterns", "Invasion effect","Predictions of invasion risk", "Improving estimation")))%>%
  group_by(topics2, general_application) %>%
  summarise(n_pub = n()) %>%
  ggplot(aes(x = general_application, y=n_pub, fill = topics2)) +
  geom_bar(stat="identity")+
  scale_fill_manual(values=cbbPalette)+
  theme(axis.text.x=element_text(angle=45, size=12, hjust=1))

##########
#G    EOGRAPHIC PATTERN
#########
#lets associate countries to regions
#country and regions list
iso_countries<- read.csv("iso_countries.csv",sep=",",header=T, dec=".", stringsAsFactors=F)
str(iso_countries)
table (my.data$iso2)

my.data22 <-merge(my.data2, iso_countries, by = "iso2") 
dim(my.data22) #49 22
#Exclude the Country "Macao, MAC" because is a false positive
my.data3 <- subset(my.data22,iso2 !="MO")
dim(my.data3) #170 23

aggregate(my.data3$iso2, list(my.data3$region), length)

#Explore distribution of applications by regions
my.data3 %>%
  filter(is.na(general_application) == FALSE) %>%
  filter(is.na(region) == FALSE) %>%
  filter(is.na(species_range) == FALSE) %>%
  mutate(general_application = factor(general_application, levels=c("Climate change","Threats monitoring", "Spatial prediction", 
                                                                    "Macroecology","Assessment of distribution", "Biodiversity", "Co-occurence of parrot species",
                                                                    "Temporal distribution patterns","Relation with environmental variables",
                                                                    "Biogeographic patterns", "Invasion effect","Predictions of invasion risk", "Improving estimation")))%>%
  group_by(general_application, region, species_range)%>%
  summarise(Freq= n())%>%
  ggplot( aes(x= general_application, y= region, size= Freq, color= species_range)) +
  geom_point(alpha=0.5) +
  scale_size(range = c(1, 10), name="Number of publications")+
  theme_bw()+
  theme(axis.text.x = element_text(angle=45, size=12, hjust = 1))


#Explore distribution of applications by paradigm
my.data3 %>%
  filter(is.na(general_application) == FALSE) %>%
  filter(is.na(paradigm) == FALSE) %>%
  filter(is.na(species_range) == FALSE) %>%
  mutate(general_application = factor(general_application, levels=c("Climate change","Threats monitoring", "Spatial prediction", 
                                                                    "Macroecology","Assessment of distribution", "Biodiversity", "Co-occurence of parrot species",
                                                                    "Temporal distribution patterns","Relation with environmental variables",
                                                                    "Biogeographic patterns", "Invasion effect","Predictions of invasion risk", "Improving estimation")))%>%
  group_by(general_application, paradigm, species_range)%>%
  summarise(Freq= n())%>%
  ggplot( aes(x= general_application, y= paradigm, size= Freq, color= species_range)) +
  geom_point(alpha=0.5) +
  scale_size(range = c(1, 10), name="Number of publications")+
  theme_bw()+
  theme(axis.text.x = element_text(angle=45, size=12, hjust = 1))

#####
#TEMPORAL PATTERNS
####
#Combine my.data2 with my.biblio
str(my.bibtex)
# Rename column where names is "UT"
names(my.bibtex)[names(my.bibtex) == "UT"] <- "ref_id"
table(my.bibtex$ref_id)

my.biblio <- merge.data.frame(my.data3, my.bibtex, by ="ref_id", all.x = T)
str(my.biblio) #52 obs. of  90 variables

#General temporal pattern in scientific production
tmp <-my.biblio %>%
  filter(is.na(PY) == FALSE) %>%
  group_by(PY) %>%
    summarise(paradigm = sum(paradigm), n_pub = n()) %>%
  mutate(csum = cumsum(n_pub))

#By paradigm
tmp <-my.biblio %>%
  filter(is.na(PY) == FALSE, is.na(paradigm)==FALSE) %>%
  group_by(paradigm, PY) %>%
  summarise(n_pub = n_distinct(ref_id)) %>%
  mutate(csum = cumsum(n_pub))

ggplot(tmp) + 
  geom_col(aes(x = PY, y = n_pub), size = 1, color = "darkblue", fill = "white") + 
#  scale_y_continuous(sec.axis = sec_axis(~./10, name = "Number of documents")) +
  geom_line(aes(x = PY, y = csum, group = paradigm), size = 1.5, color="red", group = 1)+
  theme(axis.text.x=element_text(angle=90, size=7))+  
  facet_wrap(~paradigm)+
  theme(axis.text.x=element_text(angle=90, size=9))

#By topics
tt <- my.biblio %>%
  filter(is.na(topics) == FALSE) %>%
  group_by(topics, PY) %>%
  summarise(n_pub = n()) %>%
  mutate(csum = cumsum(n_pub))

ggplot(tt) + 
  geom_col(aes(x = PY, y = n_pub), size = 1, color = "darkblue", fill = "white") + 
  scale_y_continuous(sec.axis = sec_axis(~./2, name = "Number of documents per year")) +
  geom_line(aes(x = PY, y = csum), size = 1.5, color="red", group = 1)+
  facet_wrap(~topics)+
  theme(axis.text.x=element_text(angle=90, size=9))

####  
#TAXONOMIC PATTERN
####
dim(my.data3) # 101 22
#Combine the manual review with the species review (species_ref)
my.cites<- read.csv("Index_of_CITES_Species.csv",sep=",",header=T, dec=".", stringsAsFactors=F)
str(my.cites)
# Rename column where names is "scientific.AF8.name"
names(my.cites)[names(my.cites) == "scientific.AF8.name"] <- "scientific_name"
aggregate(my.cites$scientific_name, list(my.cites$Genus), length)

str(species_ref)
tmp003 <- merge.data.frame(my.data3, species_ref, by ="ref_id", all.x = T)
tmp00X <- merge.data.frame(tmp003, my.iucn, by ="scientific_name", all.x = T)
my.pattern <- merge.data.frame(tmp00X, my.cites, by ="scientific_name", all.x = T)
dim(my.pattern) #277 obs. of  46 variables

#How many species?
(length(unique(my.pattern$scientific_name)))
  #52 species are reported in the SDM literature 

tmp004b <- my.pattern %>%
  filter(is.na(iucn) == FALSE) %>%
  group_by(iucn)%>%
  summarise(Freq= n())%>%
  mutate(percent = Freq / sum(Freq))
#Plot 
#Reorder specific actions as framework (action_type)
tmp004b$iucn <- factor(tmp004b$iucn, levels = 
                                c("CR","EN", "VU", "NT", "LC"))

cbp2 <- c("red", "orange", "yellow", "green",  "darkgreen")

ggplot(tmp004b, aes(x=percent, y= iucn, fill=as.factor(iucn))) +
  geom_bar(stat="identity")+
  scale_fill_manual(values=cbp2)

#The most studied species
uniqCSV <- function(x) { length(unique(x)) }
sp.scope <- as.data.frame(aggregate(my.pattern$ref_id, list(my.pattern$scientific_name), uniqCSV))
sp.scope2 <- sp.scope[order(sp.scope$x),]
sp.scope2
# Ara militaris 3
#         Pezoporus wallicus 3
#            Amazona oratrix 5
#        Myiopsitta monachus 5
#           Psittacula krameri 7

#Taxonomic analysis
#Compare taxonomic diversity of application by region
tmp005 <- my.pattern %>%
  filter(is.na(general_application) == FALSE) %>%
  filter(is.na(Genus) == FALSE) %>%
  filter(is.na(species_range) == FALSE) %>%
  mutate(general_application = factor(general_application, levels=c("Climate change","Threats monitoring", "Spatial prediction", 
                                                                    "Macroecology","Assessment of distribution", "Biodiversity", "Co-occurence of parrot species",
                                                                    "Temporal distribution patterns","Relation with environmental variables",
                                                                    "Biogeographic patterns", "Invasion effect","Predictions of invasion risk", "Improving estimation")))%>%
  group_by(general_application, Genus, species_range)%>%
  summarise(Freq = length(unique(scientific_name)))


ggplot(tmp005, aes(x= general_application, y= Genus, size= Freq, color= species_range)) +
  geom_point(alpha=0.5) +
  scale_size(range = c(1, 10), name="Number of species")+
  theme_bw()+
  theme(axis.text.x = element_text(angle=45, size=9, hjust = 1))

      #END
