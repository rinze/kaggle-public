# Facebook Recruiting IV R script
# Feature creation file.
# Author: José María Mateos - chema@rinzewind.org

source("init.R")

#### FUNCTIONS ####
getBidders <- function(table) {
    db <- SQLite()
    dbconn <- dbConnect(drv = db, fr4db)
    query <- sprintf("SELECT DISTINCT bidder_id FROM %s", table)
    res <- dbGetQuery(dbconn, statement = query)
    dbDisconnect(dbconn)
    return(res$bidder_id)
}

getCountryCrime <- function(tier_number = 10) {
    # Divide the countries into tier_number "crime tiers" and return
    # a data.frame with the proper division.
    db <- SQLite()
    dbconn <- dbConnect(drv = db, fr4db)
    query <- paste0("SELECT bids.bidder_id, bids.country, AVG(train.outcome) ",
                    "FROM bids JOIN train ON bids.bidder_id = train.bidder_id ",
                    "GROUP BY country")
    res <- dbGetQuery(dbconn, statement = query)
    dbDisconnect(dbconn)
    
    # Compute crime tiers
    res <- res[, -1]
    names(res) <- c("country", "crime")
    tiers <- as.numeric(cut(res$crime, 
                            quantile(res$crime, 
                                     probs = seq(0, 1, 1 / tier_number)), 
                            labels = 1:tier_number))
    tiers[is.na(tiers)] <- 0
    res$tiers <- tiers
    
    crime <- res
    
    # Now get each bidder_id with the number of times an operation is made
    # from a given country.
    db <- SQLite()
    dbconn <- dbConnect(drv = db, fr4db)
    query <- paste0("SELECT bidder_id, country, COUNT(country) as country_count ",
                    "FROM bids GROUP BY bidder_id, country")
    res <- dbGetQuery(dbconn, statement = query)
    dbDisconnect(dbconn)
    
    crime <- merge(crime, res)
    
    # Compute aggregated results
    crime_mean_p <- by(crime, crime$bidder_id, 
                       function(x) mean(x$crime))
    crime_median_p <- by(crime, crime$bidder_id, 
                       function(x) median(x$crime))
    crime_mean_pw <- by(crime, crime$bidder_id, 
                       function(x) weighted.mean(x$crime, x$country_count))
    crime_mean_t <- by(crime, crime$bidder_id, 
                       function(x) mean(x$tier))
    crime_median_t <- by(crime, crime$bidder_id, 
                       function(x) median(x$tier))
    crime_mean_tw <- by(crime, crime$bidder_id, 
                        function(x) weighted.mean(x$tier, x$country_count))
    crime_max_p <- by(crime, crime$bidder_id, 
                      function(x) max(x$crime))
    crime_max_t <- by(crime, crime$bidder_id, 
                       function(x) max(x$tier))
    
    return(data.frame(bidder_id = names(crime_mean_p),
                      crime_mean_p = as.numeric(crime_mean_p),
                      crime_median_p = as.numeric(crime_median_p),
                      crime_mean_pw = as.numeric(crime_mean_pw),
                      crime_mean_t = as.numeric(crime_mean_t),
                      crime_median_t = as.numeric(crime_median_t),
                      crime_mean_tw = as.numeric(crime_mean_tw),
                      crime_max_p = as.numeric(crime_max_p),
                      crime_max_t = as.numeric(crime_max_t)))
}

getMissingBidders <- function(allBidders, myBidders) {
    return(allBidders[!allBidders %in% myBidders])
}

getNumberBids <- function() {
    db <- SQLite()
    dbconn <- dbConnect(drv = db, fr4db)
    query <- paste0("SELECT bidder_id, COUNT(bidder_id) as bid_count ",
                    "FROM bids GROUP BY bidder_id")
    res <- dbGetQuery(dbconn, statement = query)
    dbDisconnect(dbconn)
    return(res)
}

getNumberCountries <- function() {
    db <- SQLite()
    dbconn <- dbConnect(drv = db, fr4db)
    query <- paste0("SELECT bidder_id, COUNT(DISTINCT country) ", 
                    "as country_count FROM bids GROUP BY bidder_id")
    res <- dbGetQuery(dbconn, statement = query)
    dbDisconnect(dbconn)
    return(res)    
}

getNumberDevices <- function() {
    db <- SQLite()
    dbconn <- dbConnect(drv = db, fr4db)
    query <- paste0("SELECT bidder_id, COUNT(DISTINCT device) ", 
                    "as device_count FROM bids GROUP BY bidder_id")
    res <- dbGetQuery(dbconn, statement = query)
    dbDisconnect(dbconn)
    return(res)    
}

getNumberIPs <- function() {
    db <- SQLite()
    dbconn <- dbConnect(drv = db, fr4db)
    query <- paste0("SELECT bidder_id, COUNT(DISTINCT ip) as ip_count, ",
                    "auction FROM bids GROUP by bidder_id, auction")
    res <- dbGetQuery(dbconn, statement = query)
    dbDisconnect(dbconn)
    # This needs a bit of post-processing
    f1 <- aggregate(ip_count ~ bidder_id, res, mean)
    f2 <- aggregate(ip_count ~ bidder_id, res, median)
    res <- data.frame(bidder_id = f1$bidder_id,
                      ip_mean = f1$ip_count,
                      ip_median = f2$ip_count)
    return(res)
}

getNumberLinks <- function() {
    db <- SQLite()
    dbconn <- dbConnect(drv = db, fr4db)
    query <- paste0("SELECT bidder_id, COUNT(DISTINCT url) as link_count, ",
                    "auction FROM bids GROUP by bidder_id, auction")
    res <- dbGetQuery(dbconn, statement = query)
    dbDisconnect(dbconn)
    #This needs a bit of post-processing
    f1 <- aggregate(link_count ~ bidder_id, res, mean)
    f2 <- aggregate(link_count ~ bidder_id, res, median)
    res <- data.frame(bidder_id = f1$bidder_id,
                      link_mean = f1$link_count,
                      link_median = f2$link_count)
    return(res)
}

getMaxBids <- function() {
    db <- SQLite()
    dbconn <- dbConnect(drv = db, fr4db)
    
    query <- paste0("SELECT bidder_id, auction, COUNT(bidder_id) as count_bids ",
                    "FROM bids GROUP BY bidder_id, auction")
    res <- dbGetQuery(dbconn, statement = query)
    dbDisconnect(dbconn) 
    
    res <- aggregate(count_bids ~ bidder_id, res, mean)
    names(res) <- c("bidder_id", "max_bids")
    return(res)
}

getMaxCountries <- function() {
    db <- SQLite()
    dbconn <- dbConnect(drv = db, fr4db)
    query <- paste0("SELECT bidder_id, COUNT(DISTINCT country) ", 
                    "as country_count, auction FROM bids GROUP BY bidder_id")
    res <- dbGetQuery(dbconn, statement = query)
    dbDisconnect(dbconn)
    res <- aggregate(country_count ~ bidder_id, res, max)
    names(res) <- c("bidder_id", "max_country_count")
    return(res)    
}

getMerchandises <- function() {
    db <- SQLite()
    dbconn <- dbConnect(drv = db, fr4db)
    
    query <- paste0("SELECT bidder_id, COUNT(DISTINCT auction) as count_m, ",
                    "merchandise FROM bids GROUP BY bidder_id, merchandise")
    res <- dbGetQuery(dbconn, statement = query)
    dbDisconnect(dbconn)    
    
    # There is a duplicated result, remove it
    res <- res[!duplicated(res$bidder_id), ]
    return(res)
}

getTimeDiff <- function() {
    # Do it simple at first: just build the diff for all the (ordered)
    # time points for each user
    db <- SQLite()
    dbconn <- dbConnect(drv = db, fr4db)
    query <- "SELECT bidder_id, auction, time FROM bids"
    res <- dbGetQuery(dbconn, statement = query)
    dbDisconnect(dbconn)
    
    tmean <- aggregate(time ~ bidder_id, res, 
                       function(x) mean(diff(sort(x))))
#     tmean <- aggregate(time ~ bidder_id, tmean, 
#                        function(x) median(x, na.rm = TRUE), na.action = na.pass)
                           
    tsd <- aggregate(time ~ bidder_id, res, 
                     function(x) sd(diff(sort(x))))
#     tsd <- aggregate(time ~ bidder_id, tsd, 
#                      function(x) median(x, na.rm = TRUE), na.action = na.pass)
    
    tmedian <- aggregate(time ~ bidder_id, res, 
                         function(x) median(diff(sort(x))))
#     tmedian <- aggregate(time ~ bidder_id, tmedian, 
#                          function(x) median(x, na.rm = TRUE), na.action = na.pass)

    tmin <- aggregate(time ~ bidder_id, res,
                      function(x) min(diff(sort(x))))
    
    tfast <- aggregate(time ~ bidder_id, res, function(x) {
            dv <- diff(sort(x))
            md <- mean(dv)
            if (!is.na(md)) {
                return(sum(dv < md) / length(dv))
            } else {
                return(0.0)
            }
    })
    
    # Keep the NAs, see how it goes
    tmean[is.na(tmean$time), 2] <- 2 * max(tmean$time, na.rm = TRUE)
    tsd[is.na(tsd$time), 2] <- 2 * max(tsd$time, na.rm = TRUE)
    tmedian[is.na(tmedian$time), 2] <- 2 * max(tmedian$time, na.rm = TRUE)
    tmin[is.infinite(tmin$time), 2] <- 2 * max(tmin[!is.infinite(tmin$time), 
                                                    "time"], 
                                               na.rm = TRUE)
    res <- data.frame(bidder_id = tmean$bidder_id,
                      tmean = tmean$time,
                      tsd = tsd$time,
                      tmedian = tmedian$time,
                      tmin = tmin$time,
                      tfast = tfast$time)
    return(res)
}

getOutcome <- function() {
    db <- SQLite()
    dbconn <- dbConnect(drv = db, fr4db)
    query <- "SELECT bidder_id, outcome FROM train"
    res <- dbGetQuery(dbconn, statement = query)
    dbDisconnect(dbconn)
    return(res)
}

#### FEATURE BUILDING ####
# Build data.frames for the actual classification problem
cat("Building initial data.frames... ")
train <- data.frame(bidder_id = getBidders("train"))
train <- merge(train, getOutcome())
test <- data.frame(bidder_id = getBidders("test"))
cat("OK\n")

### Get number of bids per bidder ###
cat("Computing (log) bid count per user... ")
bid_count <- getNumberBids()
# It is better to use the logarithm
bid_count$bid_count <- log1p(bid_count$bid_count)
train <- merge(train, bid_count)
test <- merge(test, bid_count)
cat("OK\n")

### Get number of countries per bidder ###
cat("Computing number of countries per user... ")
country_count <- getNumberCountries()
train <- merge(train, country_count)
test <- merge(test, country_count)
cat("OK\n")

### Get number of IPs per bidder ###
cat("Computing (log) mean number of IPs per user per auction... ")
ip_count <- getNumberIPs()
ip_count$ip_mean <- log1p(ip_count$ip_mean)
ip_count$ip_median <- log1p(ip_count$ip_median)
train <- merge(train, ip_count)
test <- merge(test, ip_count)
cat("OK\n")

### Get number of links per bidder ###
cat("Computing (log) mean number of links per user per auction... ")
link_count <- getNumberLinks()
link_count$link_mean <- log1p(link_count$link_mean)
link_count$link_median <- log1p(link_count$link_median)
train <- merge(train, link_count)
test <- merge(test, link_count)
cat("OK\n")

### Get number of devices per bidder ###
cat("Computing mean number of devices per user per auction... ")
device_count <- getNumberDevices()
train <- merge(train, device_count)
test <- merge(test, device_count)
cat("OK\n")


### Get which items does each user bid for ###
cat("Computing merchandise per user... ")
merchandises <- getMerchandises()
merchandises$count_m <- NULL
train <- merge(train, merchandises)
test <- merge(test, merchandises)
train$merchandise <- factor(train$merchandise)
test$merchandise <- factor(test$merchandise)
# There are no "auto parts" on test set
train[train$merchandise == "auto parts", "merchandise"] <- "clothing"
train$merchandise <- factor(train$merchandise)
cat("OK\n")

### Time vectors
cat("Computing time difference statistics per user... ")
tvectors <- getTimeDiff()
# Log-normalize
tvectors[, 2:5] <- log1p(tvectors[, 2:5])
train <- merge(train, tvectors)
test <- merge(test, tvectors)
cat("OK\n")

### Max bids per auction
cat("Computing max bids per auction per user... ")
max_bids  <- getMaxBids()
max_bids$max_bids <- log1p(max_bids$max_bids)
train <- merge(train, max_bids)
test <- merge(test, max_bids)
cat("OK\n")

### Max countries used in a single auction
cat("Computing max countries used in a single auction per user... ")
max_country <- getMaxCountries()
train <- merge(train, max_country)
test <- merge(test, max_country)
cat("OK\n")

### Crime tiers
cat("Computing crime-country statistics per bidder_id... ")
country_crime <- getCountryCrime(10)
train <- merge(train, country_crime)
test <- merge(test, country_crime)
cat("OK\n")

### Save file
save(train, test, file = ffile)
cat("Feature file created.\n")
