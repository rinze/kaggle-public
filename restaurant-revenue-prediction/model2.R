# Second try, use something more elaborated

# Load
source('preproc.R')

# Should try to predict final result
predictTest <- FALSE

model2 <- function(train, test) {
    # Compute indexes for posterior corrections
#     idx1 <- which(test$P3 == 4 & test$City == "İstanbul" & test$P20 == 4 & 
#                       test$P10 == 4 & test$P13 == 4 & test$P9 == 4 & 
#                       test$P2 == 5 & test$P7 == 5 & test$P27 == 1)
    # First part, random forest
    trainrf <- train
    trainrf$City <- NULL
    trainrf$City.Group <- NULL    
    trainrf$Type <- NULL
    trainrf$Id <- NULL
    rf1 <- randomForest(revenue ~ ., 
                        data = trainrf,
                        ntrees = 1000)
    predrf1 <- predict(rf1, test)
        
    # Second part, linear model
    trainlm <- train    
    lm1 <- lm(revenue ~ ., trainlm)
    predlm1 <- predict(lm1, test)
    
    # Third part, SVM
    trainsvm <- train
    testsvm <- test
    trainsvm$Type <- NULL
    trainsvm$City <- NULL
    trainsvm$Id <- NULL    
    svm1 <- svm(revenue ~ ., trainsvm, kernel = "linear")    
    predsvm1 <- predict(svm1, testsvm)
        
    # Ensemble
    res <- cbind(predrf1)
    
    # Correct
    #res[idx1, ] <- 2 * res[idx1, ]
    
#     # SECOND PART: SPECIFIC CLASSIFIERS
#     intfact <- c("FC", "IL")
#     # 1: for Istambul
#     trainrf <- train[train$City.Group2 == "Istam" & 
#                      train$Type %in% intfact, ]
#     trainlm <- trainrf
#     
#     trainrf$Type <- factor(trainrf$Type)
#     trainrf$City <- NULL
#     trainrf$City.Group <- NULL
#     
#     idx <- test$City.Group2 == "Istam" & test$Type %in% c("FC", "IL")
#     test2 <- test[idx, ]
#     test2$Type <- factor(test2$Type)
#     if (length(levels(test2$Type)) == 1) {
#         if (levels(test2$Type) == "FC") {
#             levels(test2$Type) <- intfact
#         } else if (levels(test2$Type) == "IL") {
#             levels(test2$Type) <- rev(intfact)
#         }
#     }
#     
#     rf2 <- randomForest(revenue ~ lage + P2 + Type, 
#                         data = trainrf,
#                         ntrees = 1000, mtry = 1)        
#     predrf2 <- predict(rf2, test2)
#     
#     lm2 <- lm(revenue ~ lage * Type, trainlm)
#     predlm2 <- predict(lm2, test2)  
#     
#     res[idx, ] <- cbind(predrf2, predlm2)
#     
#     #2: for other big cities, not Istambul
#     trainrf <- train[train$City.Group2 == "Big Cities" & 
#                      train$Type %in% intfact, ]
#     trainlm <- trainrf
#     
#     trainrf$City <- NULL
#     trainrf$City.Group <- NULL
#     trainrf$Type <- factor(trainrf$Type)
#     
#     idx <- test$City.Group2 != "Istam" & test$Type %in% intfact
#     test2 <- test[idx, ]    
#     test2$Type <- factor(test2$Type)
#     if (length(levels(test2$Type)) == 1) {
#         if (levels(test2$Type) == "FC") {
#             levels(test2$Type) <- intfact
#         } else if (levels(test2$Type) == "IL") {
#             levels(test2$Type) <- rev(intfact)
#         }
#     }
#     
#     rf3 <- randomForest(revenue ~ ., 
#                         data = trainrf,
#                         ntrees = 1000, mtry = 1)
#     predrf3 <- predict(rf3, test2)    
#     
#     lm3 <- lm(revenue ~ lage : Type, trainlm)
#     predlm3 <- predict(lm3, test[idx, ]) 
#     
#     res[idx, ] <- cbind(predrf3, predlm3)
#     
#     #3: for small cities
#     trainrf <- train[train$City.Group2 == "Other" & 
#                      train$Type %in% c("FC", "IL"), ]
#     trainlm <- trainrf
#     
#     trainrf$City <- NULL
#     trainrf$City.Group <- NULL
#     trainrf$Type <- factor(trainrf$Type)
#     
#     idx <- test$City.Group2 == "Other" & test$Type %in% c("FC", "IL")
#     test2 <- test[idx, ]
#     test2$Type <- factor(test2$Type)
#     if (length(levels(test2$Type)) == 1) {
#         if (levels(test2$Type) == "FC") {
#             levels(test2$Type) <- intfact
#         } else if (levels(test2$Type) == "IL") {
#             levels(test2$Type) <- rev(intfact)
#         }
#     }
#     
#     rf4 <- randomForest(revenue ~ ., 
#                         data = trainrf,
#                         ntrees = 1000, mtry = 1)
#     predrf4 <- predict(rf4, test2)    
#     
#     lm4 <- lm(revenue ~ lage + Type, trainlm)
#     predlm4 <- predict(lm4, test[idx, ]) 
#     
#     res[idx, ] <- cbind(predrf4, predlm4)
#     
#     
    return(res)
}

model3 <- function(predicted, true, test) {
    # Computes the slope and rotates the results
    dd <- data.frame(pred = predicted, true = true)
    lm1 <- lm(true ~ sqrt(pred), dd)
    dd2 <- data.frame(pred = test)
    return(predict(lm1, dd2))
}

if (!predictTest) {
    # Have to change this. Leave-one-out cross-validation causes the test
    # set to miss some factors (though there should be some way of controlling
    # for that). A k-fold cross validation might be better, in any case.
    #folds <- createFolds(train$Type, 5) 
    # don't need the Type anymore    
    folds <- lapply(1:5, function(i) sample(nrow(train), nrow(train) * 0.25))
    res <- lapply(folds, function(i) model2(trainpca[-i, ], trainpca[i, ]))
    res <- sapply(1:length(res), function(i) rmse(apply(res[[i]], 1, mean), 
                                                      trainpca[folds[[i]], "revenue"]))
    print(mean(res))
    # Create regression
    res1 <- model2(trainpca, trainpca)
    res1 <- apply(res1, 1, mean)
    res2 <- model3(res1, trainpca$revenue, res1)
    print(rmse(res2, trainpca$revenue))
} else {
    # Write result to disk with real prediction

    cat("Predicting final test dataset.\n")
    pred <- model2(trainpca, testpca)
    pred <- apply(pred, 1, mean)
    # Compute transformation
    res1 <- model2(trainpca, trainpca)
    res1 <- apply(res1, 1, mean)
    pred <- model3(res1, train$revenue, pred)    
    res <- data.frame(Id = test$Id, Prediction = pred)
    
    resultfile <- sprintf("/tmp/restrevresult_%s.csv.gz", 
                          gsub(":", "", gsub(" ", "_", Sys.time())))
    gzresultfile <- gzfile(resultfile)
    write.csv(res, file = gzresultfile, quote = FALSE, row.names = FALSE)
}
