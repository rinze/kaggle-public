# RMSE function, used to evaluate the leaderboard
rmse <- function(x, y) {
    return(sqrt(mean((x - y) ^ 2)))
}

rforest1 <- function(dataset) {
    return(randomForest(revenue ~ lage + City.Group + P2, 
                        data = dataset,
                        ntrees = 500)
           )
}

# Does not work. At all.
nnet1 <- function(dataset) {
    return(nnet(revenue ~ lage + City.Group + P2, data = dataset, 
                size = 3,
                rang = 0.3,
                decay = 1e-1)) 
}

# Assign the predictive function here
predictor <- rforest1

# LOO-CV
loo <- function(dataset, predictor) {
    pred <- sapply(1:nrow(dataset), function(i) {
        train <- dataset[-i, ]
        test <- dataset[i, ]
        p1 <- predictor(train)
        return(predict(p1, test))
    })
    print(rmse(pred, dataset$revenue))
    invisible(pred)
}

# k-fold repeated cv
krepcv <- function(dataset, predictor, iterations = 100, p = 0.7) {
    samples <- createResample(1:nrow(dataset), iterations, p)
    err <- sapply(samples, function(s) {        
        p1 <- predictor(dataset[s, ])
        pred <- predict(p1, dataset[-s, ])
        return(rmse(pred, dataset[-s, ]$revenue))
    })
    return(mean(err))
}
