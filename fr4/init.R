library(RSQLite)
library(caret)
library(ggplot2)
library(pROC)
library(randomForest)
library(C50)
library(nnet)
library(gbm)

# Database path
fr4db <- "~/tmp/kaggle/fr4/fr4.sqldb"

ffile <- "~/Dropbox/kaggle/fr4/extractedFeatures.Rda"

#### Functions ####
exploreAll <- function() {
    for (i in 2:ncol(train)) {
        dd <- train[, c(1, i)]
        names(dd) <- c("outcome", "var")
        nam <- names(train)[i]
        print(ggplot(dd) + geom_density(aes(x = var, fill = outcome), 
                                        alpha = 0.4) + ggtitle(nam))
    }
}

getMissingBidders <- function(table) {
    # Get missing bidders from the selected table
    db <- SQLite()
    dbconn <- dbConnect(drv = db, fr4db)
    query <- paste0(sprintf("SELECT DISTINCT bidder_id FROM %s ", table),
                    "WHERE bidder_id NOT IN ",
                    "(SELECT DISTINCT bidder_id FROM bids)")
    res <- dbGetQuery(dbconn, statement = query)
    dbDisconnect(dbconn)
    return(res$bidder_id)
}