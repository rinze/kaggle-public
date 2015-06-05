# Kaggle Galaxy Zoo R script

#### Libraries and constants ####
library(nnet)

# Set random seed for reproducibility
set.seed(1)

# Constants

SAMPLE <- 0.1

#### Functions ####
rmse <- function(a, b) {
    d <- dim(a)
    n <- d[1] * d[2]
    return(sqrt(sum((a - b)^2) / n))
}

rmsev <- function(a, b) {
    n <- length(a)
    return(sqrt(sum((a-b)^2) / n))
}

#### Load data ####

# Training data
trainingData <- read.csv("C:/temp/kaggle/galaxyzoo/training_data_newmeasure.csv")
nTrain <- nrow(trainingData)

fullIndex <- 1:nTrain
nTrain <- length(fullIndex)
trainingIndex <- sample(fullIndex, floor(nTrain * SAMPLE))
validationIndex <- fullIndex[-trainingIndex]

# Test data
testData <- read.csv("C:/temp/kaggle/galaxyzoo/test_data_newmeasure.csv")
nTest <- nrow(testData)
testIndex <- 1:nTest + max(fullIndex)

# Training results
trainingResults <- read.csv("C:/temp/kaggle/galaxyzoo/training_solutions.csv")

# Bind all together and remove intermediate datasets
gzoo <- rbind(trainingData, testData)
rm(list = c("trainingData", "testData"))

# Remove uncomplete or constant variables
gzoo <- gzoo[, !apply(gzoo, 2, function(x) any(is.na(x)))]
gzoo <- gzoo[, !apply(gzoo, 2, function(x) all(x == x[1]))]

#### Generate new variables and remove useless ones ####

# gzoo <- gzoo[, !(names(gzoo) %in% c("Min", "Max", "Mode", "X", "Y",
#                                     "XM", "YM", "BX", "BY", "Width", "Height",
#                                     "IntDen", "Median", "RawIntDen", "Angle"))]

#gzoo <- gzoo[, !(names(gzoo) %in% c("IntDen", "RawIntDen", "Width"))]
                                    #"XM", "YM", "BX", "BY", "Height",
                                    #, "Angle", "Min", 
                                    #"Max", "Mode", "FeretX", "FeretY", 
                                    #"FeretAngle"))]

# nc <- ncol(gzoo)
# for (i in 2:nc) {
#     print(i)
#     gzoo <- cbind(gzoo, gzoo[, i] * gzoo[, i:nc])
# }

gzoo$test1 <- gzoo$Circ. / gzoo$Perim.
gzoo$test2 <- gzoo$Solidity / gzoo$Feret

# a <- read.table("C:/temp/kaggle_results/extra1/training.txt")
# b <- read.table("C:/temp/kaggle_results/extra1/test.txt")
# gzoo$extra1 <- c(a$V1, b$V1)

gzoo[, -1] <- scale(gzoo[, -1])

#### Neural network ####
set.seed(1) # For reproducibility
nnet1 <- nnet(x = gzoo[trainingIndex, -1], 
              y = trainingResults[trainingIndex, -1], 
              size = ncol(gzoo) - 1, 
              rang = 0.5, 
              decay = 1e-4, 
              entropy = TRUE, 
              skip = FALSE,
              maxit = 200, 
              MaxNWts = 500000,
              trace = TRUE
              )

# This only makes sense if using trainingIndex to train
solution <- predict(nnet1, gzoo[validationIndex, -1])
print(rmse(solution, trainingResults[validationIndex, -1]))

# Create solution and assign column names
solution <- predict(nnet1, gzoo[testIndex, -1])
res <- data.frame(GalaxyID = gzoo[testIndex, 1], solution)
names(res) <- names(trainingResults)
