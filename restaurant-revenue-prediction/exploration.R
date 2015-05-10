# Data exploration algorithm. Generates figures / statistics. Stores figures
# to /tmp/restrev

source('preproc.R')

TARGETDIR <- "/tmp/restrev"
if(!file.exists(TARGETDIR)) dir.create(TARGETDIR)

# Use the best predictor and study the residuals, see if there is some
# relationship between varibles that we might have missed.
rf1 <- predictor(train)
pred <- predict(rf1, train)
train$residuals <- train$revenue - pred

# Operate the P variables together and see if there is any relationship at all
# with the residuals. Do it in sets of two at the beginning.
pvars <- grep("P", names(train))
multiset <- expand.grid(pvars, pvars)
pvals <- sapply(1:nrow(multiset), function(i) {
    m <- as.numeric(multiset[i, ])
    val <- sqrt(train[, m[1]]) * log1p(train[, m[2]])
    #d <- data.frame(value = val, residuals = train$residuals)
    #lm1 <- lm(residuals ~ val, d)
    #s1 <- summary(lm1)
    #return(s1$coefficients[2, 4])
    c1 <- cor.test(val, train$revenue, exact = FALSE, method = "spearman")
    return(c1$p.value)
})
pvals <- p.adjust(pvals, method = "fdr")
multiset$p <- pvals
plot(sort(pvals))
print(min(pvals))
print(multiset[which(pvals < 0.05), ])

# Plot the "P" variables against revenue
pvars <- grep("P", names(train))
n <- names(train)
for (i in pvars) {
    d <- data.frame(residuals = train$residuals,
                    var = train[, i])
    names(d) <- c("residuals", "var")
    varname <- n[i]
    p1 <- ggplot(d) + geom_point(aes(x = var, y = residuals,
                                     color = train$City.Group), size = 5) +
          ggtitle(varname)
    #ggsave(plot = p1, filename = file.path(TARGETDIR, 
    #                                       sprintf("%s.png", varname)))
    print(p1)
}

# Plot the "P" variables against lage
for (i in pvars) {
    d <- data.frame(lage = train$lage,
                    var = train[, i])
    names(d) <- c("lage", "var")
    varname <- n[i]
    p1 <- ggplot(d) + geom_point(aes(x = lage, y = var,
                                     color = train$City.Group), size = 5) +
        ggtitle(varname)
    #ggsave(plot = p1, filename = file.path(TARGETDIR, 
    #                                       sprintf("%s.png", varname)))
    print(p1)
}