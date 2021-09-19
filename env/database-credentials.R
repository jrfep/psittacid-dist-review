#!R --vanilla
if (file.exists("~/.database.ini")) {
   tmp <-     system("grep -A4 psit-litrev $HOME/.database.ini", intern=TRUE)[-1]
   dbinfo <- gsub("[a-z]+=","",tmp)
   names(dbinfo) <- gsub("([a-z]+)=.*","\\1",tmp)
}
