# Preprocessing script: feature selection, mostly.
library(ggplot2)
library(randomForest)
library(caret)
library(nnet)
library(e1071)

load("~/Dropbox/kaggle/restrev/restrevData.Rda")

set.seed(1) # make results reproducible

source("functions.R")

#### NEW VARIABLES ####
# Compute today's date and use thata to calculate the age of each store, will
# be more informative than the Open.Date variable.
today <- Sys.Date()

train$age <- as.numeric(today - train$Open.Date) / 365
test$age <- as.numeric(today - test$Open.Date) / 365

train$lage <- log1p(train$age)
test$lage <- log1p(test$age)

# Remove the single DT Type case from the training dataset
#train <- train[train$Type != "DT", ]

train <- train[train$revenue < 1.2e7, ]

# Remove unused variables
train$age <- NULL
train$Open.Date <- NULL
train$Id <- NULL

test$age <- NULL
test$Open.Date <- NULL
test$Id <- factor(test$Id)

# Try the Istambul division
train$City.Group2 <- as.character(train$City.Group)
train[train$City == "İstanbul", "City.Group2"] <- "Istam"
train$City.Group2 <- factor(train$City.Group2)

test$City.Group2 <- as.character(test$City.Group)
test[test$City == "İstanbul", "City.Group2"] <- "Istam"
test$City.Group2 <- factor(test$City.Group2)

# Build PCA vectors
pctokeep <- 3
pc1 <- princomp(train[, c(4:40)])
varexp <- cumsum(pc1$sdev^2) / sum(pc1$sdev^2)

trainpca <- pc1$scores[, 1:pctokeep]
trainpca <- data.frame(trainpca)
trainpca$revenue <- train$revenue
trainpca$lage <- train$lage
trainpca$City.Group2 <- train$City.Group2

testpca <- predict(pc1, test[, c(5:41)])
testpca <- testpca[, 1:pctokeep]
testpca <- data.frame(testpca)
testpca$lage <- test$lage
testpca$City.Group2 <- test$City.Group2

# Scale numerical features
# ridx <- names(test) == "revenue"
# fidx <- sapply(test, class) == "factor"
# test[, !fidx] <- scale(test[, !fidx])
# ridx <- names(train) == "revenue"
# fidx <- sapply(train, class) == "factor"
# fidx[ridx] <- TRUE
# train[, !fidx] <- scale(train[, !fidx])

# Engineered features
#train$EF1 <- with(train, P11 + sqrt(P30))
#test$EF1 <- with(test, P11 + sqrt(P30))

#### FEATURE SELECTION ####

# feat1 <- sbf(revenue ~ ., data = train,
#              size = 1:12,
#              sbfControl = sbfControl(functions = treebagSBF,
#                                      method = "repeatedcv",
#                                      number = 5,
#                                      repeats = 30000,
#                                      verbose = FALSE
#             )
# )
# 
# print(feat1)

# Relevant variables after this: City.Group, P2, lage. P28 and P6 with very
# low probabilities. Do not run again unless strictly necessary (takes a long
# time).

trainpca$City.Group <- train$City.Group
ggplot(trainpca) + geom_point(aes(x = Comp.1, y = Comp.2, color = revenue, 
                                  shape = City.Group), alpha = 0.5, size = 6) + 
    scale_colour_gradientn(colours = c("black", "blue", "red", "yellow"), 
                           name = "Revenue")
trainpca$City.Group <- NULL
