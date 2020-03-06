### import the model online_news
# look at the data and examine it.
online_news = read.csv('C:/Users/swate/Google Drive/MA Econ/spring 2020 classes/data mining/hw 2/question 3/online_news.csv')
View(online_news)

### first "regression and threshold"

# note that shares is hugely skewed
# probably want a log transformation here
hist(online_news$shares)

# much nicer :-)
hist(log(online_news$shares))

#### lasso (glmnet does L1-L2, gamlr does L0-L1) 
# I want to fit a lasso regression and do cross validation of K=10 folds 
# inorder to automate finiding independent variables and training & testing my data multiple times.
# cv.gamlr command in the gamlr does it for me.
# download gamlr library
library(gamlr) 

# i create a matrix of all my independent varaibles except for url from online_news data to make it easily readable for gamlr commands.
# the sparse.model.matrix function.
x = sparse.model.matrix(log(shares) ~ . - url, data=online_news)[,-1] # do -1 to drop intercep

y = log(online_news$shares) # pull out `y' too just for convenience and do log(shares)- dependent variable

# Here I fit my lasso regression to the data and do my cross validation of k=10 n folds
# the cv.gamlr command does both things at once.
#(verb just prints progress)
cvl = cv.gamlr(x, y, nfold=10, verb=TRUE)

# plot the out-of-sample deviance as a function of log lambda
plot(cvl, bty="n")

## CV min deviance selection
b.min = coef(cvl, select="min")
log(cvl$lambda.min) # this gives the value of lamda
sum(b.min!=0) # this gives the coefficent not 0

#######

# predict number of shares
lhat_shares = predict(cvl, x) # log value of shares
hat_shares = exp(lhat_shares) # predicted values of shares
head (hat_shares, 50)

# change predicted number of shares into viral prediction(t_viral)
threshold_viral = ifelse(hat_shares > 1400, 1, 0)
head(threshold_viral, 50)

# create new variable "viral"
viral = ifelse(online_news$shares > 1400, 1, 0)
head(viral, 20)

# create confusion matrix
confusion_1= table(y = viral, yhat = threshold_viral)
print(confusion_1)
sum(diag(confusion_1))/sum(confusion_1) # gives the sample accuracy for model 1

##### model 2

# create logistic lasso regression and cross validate with viral as the dependent variable
# add family = "binomial" to code to do a logistic regression instead of normal regression
#(verb just prints progress)
viral_cvl = cv.gamlr(x, viral, nfold=10, family="binomial", verb=TRUE)

# plot the out-of-sample deviance as a function of log lambda
plot(viral_cvl, bty="n")

## CV min deviance selection
b.min = coef(viral_cvl, select="min")
log(viral_cvl$lambda.min)
sum(b.min!=0) # note: this is random!  because of the CV randomness

# predict number of viral
hat_viral = predict(viral_cvl, x)
head (hat_viral, 50)

# change hat_viral to true/false prediction
b_hat_viral = ifelse(hat_viral > 0, 1, 0)
head(b_hat_viral, 50)

# create confusion matirx
confusion_2= table(y = viral, yhat = b_hat_viral)
print(confusion_2)
sum(diag(confusion_2))/sum(confusion_2) # gives the sample accuracy of model 2


#### comaprison of models

table(viral) # gives the actual number of viral or not viral articles
20082/39644  # 50.66 percent of articles were not viral---null hypothesis

print(confusion_1)
sum(diag(confusion_1))/sum(confusion_1) # gives the sample accuracy for model 1 = 56.8 percent
# so my model 1 is (56.8-50.66) = aboput 6 percent improvement to null model
17458/(17458+5058) # True positive rate of model 1 is 77.54 percent
15024/(5058+15024) # Fasle positive rate of model 1 is 74.81 percent
15024/(15024+17458)# False dicovery rate of model 1 is 46.25 percent

print(confusion_2)
sum(diag(confusion_2))/sum(confusion_2) # gives the sample accuracy of model 2 = 63 percent
# so model 2 is 12.5 percent improvement to null model and about 6.2 percent improvement to model 1.
12704/(12705+6857) # the true positive rate is 64.95 percent which is worst than model 1
7811/(7811+12271) # false positive rate is 38.9 percent which is better than model 1 because lower is better here.
7811/(7811+12705) # false discovery rate is 38.07 percent which is better than model 1 because lower is better.

# based TPR, FPR, FDR, and general acuracy model 2 does better than model 1.
