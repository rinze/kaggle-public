# Facebook Recruiting IV R script
# Classifier building, main file.
# Author: José María Mateos - chema@rinzewind.org


source("init.R")

#### INIT ####
# Reproducible
set.seed(1)

# Build the feature matrices ONLY if they do not exist already
if(!file.exists(ffile)) {
    cat("Feature file missing, calling features.R.\n")
    source("features.R")
} else {
    cat("Loading data from existing feature file...")
    load(ffile)
    cat(" OK\n")
}

# Normalise
#train[, -c(1, 2)] <- scale(train[, -c(1, 2)])
#test[, -1] <- scale(test[, -1])

#### FUNCTIONS ####

buildAndRunClassifier <- function(train, test) {
    train$outcome <- factor(train$outcome)
    
#     lm1 <- glm(outcome ~ bid_count + country_count + tmedian + link_mean + crime_mean_t, 
#                data = train, 
#                family = binomial())
#     res <- predict(lm1, test, type = "response")
#     return(res)

    rf1 <- randomForest(outcome ~ bid_count + max_bids + tmedian + link_mean + crime_mean_t,
                        train,
                        replace = FALSE)
    res <- predict(rf1, test, type = "prob")
    return(res[, 1])
    
#     c501 <- C5.0(outcome ~ bid_count + country_count + merchandise, train)
#     res <- predict(c501, test, type = "prob")
#     return(res[, 1])

#     gbm1 <- gbm(outcome ~ bid_count + country_count + tmedian + link_mean,
#                 distribution = "gaussian", 
#                 data = train,
#                 n.trees = 100,
#                 interaction.depth = 4,
#                 shrinkage = 0.01)
#     res <- predict(gbm1, test, type = "link", n.trees = 100)
#     return(res)

#     nnet1 <- nnet(outcome ~ bid_count + country_count + tmedian + link_mean, 
#                   train,
#                   size = 16,
#                   decay = 0.4,
#                   rang = 0.001,
#                   maxit = 500,
#                   trace = FALSE)
#     res <- predict(nnet1, test, type = "raw")
#     return(res)
                 
}

#### CLASSIFIER ####
# Consider this: should be remove the "suspicious" case?
#train <- train[-which(train$outcome == 0 & train$bid_count > 13.15), ]

# First column is the bidder and don't need it in train
train <- train[, -1]
train$outcome <- factor(train$outcome)

# Try to mess with merchandise
train$merchandise <- ifelse(train$merchandise == "computers", "computers", "not computers")
test$merchandise <- ifelse(test$merchandise == "computers", "computers", "not computers")
train$merchandise <- factor(train$merchandise)
test$merchandise <- factor(test$merchandise)

# Try a 10-fold cross-validation
aucs <- rep(0, nrow(train))
folds <- createFolds(factor(train$outcome), 10)
for (f in folds) {
    aucs[f] <- buildAndRunClassifier(train[-f, ], train[f, ])    
}

auc <- roc(train$outcome, aucs)$auc
cat(sprintf("CV AUC: %.5f\n", auc))

predTest <- buildAndRunClassifier(train, test)

result <- data.frame(bidder_id = test$bidder_id, prediction = predTest)
# Add the missing ones.
missingTest <- getMissingBidders("test")
result <- rbind(result, data.frame(bidder_id = missingTest, prediction = 0))
# Save result
resultfile <- sprintf("/tmp/fr4_result_%s.csv.gz", 
                      gsub(":", "", gsub(" ", "_", Sys.time())))
gzresultfile <- gzfile(resultfile)
write.csv(result, file = gzresultfile, quote = FALSE, row.names = FALSE)
cat("Result saved to", resultfile, "\n")