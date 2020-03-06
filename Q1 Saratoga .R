library(tidyverse)
library(mosaic)
data(SaratogaHouses)
summary(SaratogaHouses)

SaratogaHouses$new <- ifelse(SaratogaHouses$age == 0, 1,0)
SaratogaHouses$new

housevalue <- SaratogaHouses$price - SaratogaHouses$landValue
head(housevalue)
heating_electric <- SaratogaHouses[grep("electric", SaratogaHouses$heating), ]
head(heating_electric)
heating_steam <- SaratogaHouses[grep("hot water/steam", SaratogaHouses$heating), ]
head(heating_steam)
heating_hotair <- SaratogaHouses[grep("hot air", SaratogaHouses$heating), ]
head(heating_hotair)

fuel_oil <- SaratogaHouses[grep("oil", SaratogaHouses$fuel), ]
head(fuel_oil)
fuel_gas <- SaratogaHouses[grep("gas", SaratogaHouses$fuel), ]
head(fuel_gas)
fuel_electric <- SaratogaHouses[grep("electric", SaratogaHouses$fuel), ]
head(fuel_electric)

#Defining the models 
#Base model
lm_base = lm(price ~ lotSize + age + livingArea + pctCollege + bedrooms + fireplaces +
           heating + bathrooms + rooms + fuel + centralAir + new, data = SaratogaHouses)
#Hand-built Model
lm_own = lm(price ~ lotSize + pctCollege  + heating + bathrooms + bedrooms 
         + rooms + fuel + centralAir + new + landValue + new*lotSize
         + centralAir*heating + pctCollege*age + landValue*fuel + heating*bedrooms
         , data = SaratogaHouses)

#Define only the numerics of the train-test data sets 
N = nrow(SaratogaHouses)
train = round(0.8*N)
test = (N-train)
#Define the fution
rmse = function(y, yhat) {
  sqrt( mean( (y - yhat)^2 ) )
}

#Rmse iterations
rmse1 <- NULL
rmse2 <- NULL

for (i in seq(1:200)){
  #Picking data up for training and testing
  train_cases = sample.int(N, train, replace=FALSE)
  test_cases = setdiff(1:N, train_cases)
  
  #Define the train-test data sets (for all X's and Y)
  saratoga_train = SaratogaHouses[train_cases,]
  saratoga_test = SaratogaHouses[test_cases,]
  
#Training
#Base model
lm1 = lm(price ~ lotSize + age + livingArea + pctCollege + bedrooms + fireplaces +
           heating + bathrooms + rooms + fuel + centralAir + new , data=saratoga_train)
#Hand-built Model
lm2 = lm(price ~ lotSize + pctCollege  + heating  + bathrooms + bedrooms 
         + rooms + fuel + centralAir + new + landValue + new*lotSize
         + centralAir*heating + pctCollege*age + landValue*fuel + heating*bedrooms
         , data=saratoga_train)

#Testing 
yhat_test1 = predict(lm1, saratoga_test)
yhat_test2 = predict(lm2, saratoga_test)

#Run it on the actual and the predicted values
rmse1[i]= rmse(saratoga_test$price, yhat_test1)
rmse2[i]= rmse(saratoga_test$price, yhat_test2)
}

 mean(rmse1)
 mean(rmse2)
 
 
#KNN (Non-parametric model)
#Defining train-test sets for the hand-built regression model
 knn_model = do(100)*{
   N = nrow(SaratogaHouses)
   train = round(0.8*N)
   test = (N-train)
   
   train_cases = sample.int(N, train, replace=FALSE)
   test_cases = setdiff(1:N, train_cases)
   
   saratoga_train = SaratogaHouses[train_cases,]
   saratoga_test = SaratogaHouses[test_cases,]
   
   Xtrain = model.matrix(~ lotSize + pctCollege  + heating  + bathrooms + bedrooms 
                         + rooms + fuel + centralAir + new + landValue - 1, data=saratoga_train)
   Xtest = model.matrix(~ lotSize + pctCollege  + heating  + bathrooms + bedrooms 
                        + rooms + fuel + centralAir + new + landValue - 1, data=saratoga_test)
   Ytrain = saratoga_train$price
   Ytest = saratoga_test$price
   
   #Scaling the features (Standardization)
   scale_train = apply(Xtrain, 2, sd) 
   Xtilde_train = scale(Xtrain, scale = scale_train)
   Xtilde_test = scale(Xtest, scale = scale_train) 
   
   #The for loop 
   library(foreach)
   k_grid = seq(2,100)
   rmse_grid = foreach(K = k_grid, .combine='c') %do% {
     knn_model = knn.reg(Xtilde_train, Xtilde_test, Ytrain, k=K)
     rmse(Ytest, knn_model$pred)
   }
 }
 knn_model_mean = colMeans(knn_model)
 
#Plotting 
plot(k_grid, knn_model_mean)
abline(h=rmse(Ytest, yhat_test2)) 

#I found that variables telling the same thing could be eliminated. 
#For example, if you just want to know if the house is new or not then just knowing the age is sufficient
#and makes the binary variable 'new' unecessary to know. Having said this I couldn't eliminate rooms because it seems like bathrooms and bedrooms
#are not the only type of rooms looked out for when deciding the former's number in a house.
#I found that newer houses are bigger and increase pricing. Heating in terms of hot air affects the central air. 
#It looks like age of the house is correlated with the percentage of college graduates 
#residing in the neighbourhood and the higher either of those numbers, the higher would the 
#price be. The fuel availability is correlated with the land value and that in turn affects the price as well.
save.image("/Users/msimran28/Q1 Saratoga.R")



