source('preproc.R')
# First model, very simple

predObj <- predictor(train)
predtrain <- loo(train, predObj)
plot(predtrain, train$revenue, pch = 19, col = train$Type)
abline(a = 0, b = 1)

# Predict with the initial model
lm1 <- lm(revenue ~ lage + lage*City.Group + log1p(P2), train)
pred <- predict(predObj, test)

# Use a linear regression to include information for Type FC or IL
train1 <- train[train$Type != 'DT', ]
train1$Type <- factor(train1$Type)
lm1 <- lm(revenue ~ lage + lage*Type + lage*City.Group + log1p(P2), train1)
pred[test$Type %in% c('FC', 'IL')] <- predict(lm1, test[test$Type %in% c('FC', 'IL'), ])

# Now use the City information (only Istambul or Ankara), any other thing
# is probably going to overfit.
ai <- test$City %in% c('Ankara', 'İstanbul')
test2 <- test
ctmp <- as.character(test2$City)
ctmp[!ai] <- "Other"
ctmp <- factor(ctmp)
test2$City <- ctmp

ai <- train$City %in% c('Ankara', 'İstanbul')
train2 <- train
ctmp <- as.character(train2$City)
ctmp[!ai] <- "Other"
ctmp <- factor(ctmp)
train2$City <- ctmp

predObj2 <- randomForest(revenue ~ lage + City.Group + P2 + City, 
                         data = train2,
                         ntrees = 500)
pred <- predict(predObj2, test2)              

res <- data.frame(Id = test$Id, Prediction = pred)
resultfile <- sprintf("/tmp/restrevresult_%s.csv.gz", 
                      gsub(":", "", gsub(" ", "_", Sys.time())))
gzresultfile <- gzfile(resultfile)
write.csv(res, file = gzresultfile, quote = FALSE, row.names = FALSE)

