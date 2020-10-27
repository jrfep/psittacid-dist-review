#! R --vanilla
## Load required packages
library(bibliometrix) #the library for bibliometrics
require(readxl)
require(topicmodels) #for topic modeling
library(quanteda) #a library for quantitative text analysis
require(ggplot2) #visualization
library(dplyr) #for data munging
library(RColorBrewer) # user friendly color palettes
library(tidytext)
library(ldatuning)

## Set up working environment (customize accordingly...)
script.dir <- Sys.getenv("SCRIPTDIR")
work.dir <- Sys.getenv("WORKDIR")
Rdata.dir <- sprintf("%s/Rdata", script.dir)

setwd(work.dir)
target.dir <- "bibtex/wildlife-trade"
rda.arch <- sprintf("%s/%s.rda",Rdata.dir,basename(target.dir))

data.dir <- sprintf("%s/%s", script.dir,"data")


orig.search <- read_xlsx(sprintf("%s/%s",data.dir,"ConceptualFramework_20200903.xlsx"),sheet=3)


  require("RPostgreSQL")
  drv <- dbDriver("PostgreSQL") ## remember to update .pgpass file

  con <- dbConnect(drv, dbname = "litrev",
                   host = ifelse( system("hostname -s",intern=T)=="terra","localhost","terra.ad.unsw.edu.au"),
                   port = 5432,
                   user = "jferrer")

qry <- "SELECT \"UT\",\"AU\",\"TI\",\"DI\" FROM psit.bibtex"
res <- dbGetQuery(con,qry)

res <- subset(res,!is.na(UT))
orig.search$UT <- res$UT[match(orig.search$TI,res$TI)]
table(is.na(orig.search$UT))

orig.search$UT <- ifelse(is.na(orig.search$UT),res$UT[match(orig.search$DI,res$DI)],orig.search$UT)
table(is.na(orig.search$UT))

orig.search$UT <- ifelse(is.na(orig.search$UT),res$UT[match(tolower(orig.search$DI),tolower(res$DI))],orig.search$UT)
table(is.na(orig.search$UT))

orig.search$UT <- ifelse(is.na(orig.search$UT),res$UT[pmatch(substr(orig.search$TI,1,50),res$TI)],orig.search$UT)
table(is.na(orig.search$UT))



orig.search$TI[is.na(orig.search$UT)]


load(rda.arch)
 subset(orig.search,DI %in% wildlifetrade.df$DI) %>% select(DI)

 subset(orig.search,(TI %in% wildlifetrade.df$TI) | (DI %in% wildlifetrade.df$DI)) %>% select(TI,DI) %>% print.AsIs


 Filtro1 <- rep(NA,nrow(wildlifetrade.df))

 wildlifetrade.df$TI[is.na(Filtro1)]

grep("CYTOTOXIC ACTIVITY",wildlifetrade.df$TI,value=T)

incluir <- c("CHLAMYDIA-PSITTACI","CHLAMYDIA PSITTACI","CHLAMYDOPHILA PSITTACI","AMAZON PARROT","COCKATOO","PET PSITTACI","PET TRADE","PARAKEET","PET PARROT","YELLOW-HEADED PARROT", "MACAW SPECIES","PARROT TRADE","CONSERVATION OF PARROT","PSITTACIFORMES","TRADE IN THE ENDANGERED","CHACOAN MACAW","PSITTACULA","INFLUENCE OF MARKETS","EXTRACTIVISM","SUSTAINABLE AGRO-FORESTRY","APPROPRIATE PETS","PET-KEEP","PARROT MARKET","TRADED WILD BIRD","TRADED BIRD")
excluir <- c("PARROT FISH","PARROTFISH","CALLIPHOR","DUNG","PETROL","YAHOO!","PETROGRAPH","CYTOTOXIC ACTIVITY","MACAW PALM","LEISHMANIA","COMMERCIAL STEMS HARVESTED","HUMIC EXTRACTS", "HUMIC ACID", "DRUG ADDICTION","PETROGENETIC","SCARAB BEETLE","AQUEOUS EXTRACT","LIQUID-LIQUID EXTRACT","YELLOW-FOOTED TORTOISE","OIL EXTRACT","PARROT-FISH","AMAZON CACAO","SALT TRADING","AMAZON.COM","HARVESTED RIVER TURTLES","WILD FISH POPULATION","MORINGA OLE","FISH DIET","PLANT EXTRACTS","FISH MARKET","WOOD EXTRACTIV","PARROTT","ALGORITHMIC PRICING")
Filtro1[grep(paste(excluir,collapse="|"),wildlifetrade.df$TI)] <- F
Filtro1[grep(paste(incluir,collapse="|"),wildlifetrade.df$TI)] <- T
table(Filtro1,useNA='always')
sample(wildlifetrade.df$TI[is.na(Filtro1)],30)




#First, extract and clean the abstract text and create a corpus

ISI.ss <- duplicatedMatching(wildlifetrade.df, Field = "UT", tol = 0.95)
ISI.ss <- subset(ISI.ss,!is.na(AB))


ISI.txt <- ISI.ss[,c("UT","AB")] #take two columns from the dataframe N2.
#Column UT is for Unique Article Identifier, and column AB is for abstracts.

#convert to lower case
ISI.txt$AB <- tolower(ISI.txt$AB)

## remove copyright text
ISI.txt$AB <- gsub("\\(c\\) [0-9 A-Za-z.-]+", "", ISI.txt$AB)
## remove some mathematical notation
ISI.txt$AB <- gsub("-|\\+|<|_|=|`", "", ISI.txt$AB)


#Create a corpus in which each abstract is a document
#keep the UT as document identifier
ISI.corpus <- corpus(ISI.txt, docid_field = "UT", text_field = "AB")


#Tokenization by word
#Notice that we remove any remaining punctuation and numbers along the way
temp_toks <- tokens(ISI.corpus, remove_punct = TRUE, remove_numbers = TRUE)

#Remove stop words and a customized list of filter words.
nostop_toks <- tokens_select(temp_toks, stopwords('en'), selection = 'remove')
nostop_toks <- tokens_select(nostop_toks, c("abstract", "study","the", "therefore",  "elsevier", "often", "based", "new", "due", "two", "use", "used", "km", "2", "24", "also", "may", "one", "within", "results", "found", "however", "many", "elsewhere",  "n", "can", "camera", "trap", "camera-trap", "deutsch", "gesellschaft", "saugetierkund"), selection = 'remove')

#Next > simplify words to avoid confusion with deriv and plural terms
ISI.toks <- tokens_wordstem(nostop_toks, language = quanteda_options("language_stemmer"))
#Create n-gram. (tokens in sequence)
  ISI.bigram <- tokens_ngrams(ISI.toks, n=2) #for bigram

  # exclude words from a list of meningless phrases
#  ISI.bigram <- tokens_select(ISI.bigram, exclude.words, selection = 'remove')


ISI.dfm <- dfm(ISI.bigram)
ISI.dfm <- dfm_trim(ISI.dfm, min_termfreq = 10)

ISI.dtm <- convert(ISI.dfm, to = "topicmodels")

ISI.lda <- LDA(ISI.dtm, control=list(seed=0), k = 25)


tt <- topics(ISI.lda)
docvars(ISI.dfm, 'topic') <- tt[match(row.names(ISI.dfm),names(tt))]

ISI.topics <- tidy(ISI.lda, matrix = "beta")

ISI.topics

ISI.top_terms <- ISI.topics %>%
group_by(topic) %>%
top_n(10, beta) %>%
ungroup() %>%
arrange(topic, -beta)


ISI.top_terms %>%
mutate(term = reorder_within(term, beta, topic)) %>%
ggplot(aes(term, beta, fill = factor(topic))) +
geom_col(show.legend = FALSE) +
facet_wrap(~ topic, scales = "free") +
coord_flip() +
scale_x_reordered()
