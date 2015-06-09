source("init.R")
set.seed(1)

load(ffile)

train <- train[, -1]
train$outcome <- factor(train$outcome, labels = c('legit', 'bot'))

tc <- trainControl(method = "repeatedcv", 
                   summaryFunction = twoClassSummary, 
                   classProb = TRUE)

train1 <- train(outcome ~ ., train, 
                method = "gbm", 
                metric = "ROC",
                trControl = tc, 
                verbose = FALSE)

predTest <- predict(train1, test, type = "prob")[, 2]
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