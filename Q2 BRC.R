library(tidyverse)
library(mosaic)
library(sjlabelled)
library(sjmisc)
library(sjstats)
library(ggeffects)
library(sjPlot)
library(caret)
library(e1071)
library(magrittr)
library(knitr)

# load packages for various functions (tab_model, confusionMatrix, factor, etc...)

brca = read.csv('C:/Users/Nyarlathotep/Documents/Econ - Data Mining/Excercise 2/brca.csv') #Import data

#2 - A Hospital Audit

#The following audit for the performance of various radiologists in our hospital seeks to 
#evaluate how accurately they are assessing patients' need to be recalled for additional 
#screenings based on mammograms and varous other factors.


#### 2.1 - Are some doctors more conservative when recalling patients?

#### 2.1.1 - Build a classification model that holds risk factors constant
# in assessing whether some radiologists are more conservative than other
# in recalling patients?

# let's model recall versus risk factors + radiologist
model_recall = glm(recall ~ . - cancer, data=brca, family=binomial)
#glm is a logistic regression, generalized to allow the dependent variable to be 
#non-normal.


# While it is the goal of the hospital to detect cancer and provide patients with necessary
# treatment, resource constraints for both the hospital and the patients prohibit 
# unnecessary recalls. Thus, it is incumbent upon us to improve the accuracy of our 
# cancer screenings.

#First, we will assess if any radiologists are more conservative when recalling patients,
# i.e. they are more likely to recall patients holding all risk factors equal.

# There are five randomly selected radiologists, identified by numbers: 13, 34, 66, 89, 
# 95. Below is a table of each one's performance. 


tab_model(model_recall)%>% 
    return() %$% 
    knitr %>% 
    asis_output()

#We will let radiologist13 be our baseline, i.e. the likelihood that any other radiologist recalls a patient is reported in relation to radiologist 13:
  
#  - radiologist34 has about exp(0.59) ??? 0.66 times the odds of recalling a patient, holding other risk factors constant.
#- radiologist66 has about exp(1.43) ??? 1.54 times the odds of recalling a patient, holding other risk factors constant.
#- radiologist89 has about exp(1.59) ??? 1.80 times the odds of recalling a patient, holding other risk factors constant.
#- radiologist95 has about exp(0.95) ??? 0.95 times the odds of recalling a patient,
#holding other risk factors constant.

#Ranking the radiologists in terms of increasing conservatism, we have: 34, 95, 13, 66, 89.

#Next, we will examine how accurately radiologists, as a whole, are weighing certain risk factors when making a decision to recall a patient.

#### 2.2 - When the radiologists at this hospital interpret a mammogram 
# to make a decision on whether to recall the patient, does the data suggest 
# that they should be weighing some clinical risk factors more heavily than 
# they currently are?

#Below is a confusion matrix captureing the number of true positives, true negatives, false positives, and false negatives for the recall decision.


#confusionMatrix(data = factor(brca$cancer), reference = factor(brca$recall), positive = "1", dnn = c("recalled", "cancer diagnosed"))

#Radiologists accurately predicted 866/897 correct outcomes (85.71% accuracy). Additionally, there were 15 false positives and 126 false negatives. The latter number is particularly concerning and suggests that improvements can be made.

#Consider a model that regresses cancer on a radiologist's decision to recall the patient (model A), and a model that regresses cancer on "recall" and a given risk factor (model B). There are five diferent model B's since we have five different risk factors examined in the data.

#If a given risk factor is weighed appropriately, there should be high colinearity between the recall and a given risk factor, and the risk factor variable should not be statistically significant.

#If the second model proves to be more accurate, it means that radiologists are not properly assessing the risk factors relative to other factors.


glm_modela = glm(cancer ~ recall, data = brca, family = binomial)
glm_modelb_hist = glm(cancer ~ recall + history, data = brca, family = binomial)
glm_modelb_age = glm(cancer ~ recall + age, data = brca, family = binomial)
glm_modelb_symp = glm(cancer ~ recall + symptoms, data = brca, family = binomial)
glm_modelb_meno = glm(cancer ~ recall + menopause, data = brca, family = binomial)
glm_modelb_den = glm(cancer ~ recall + density, data = brca, family = binomial)

# summary of Model A and Model B regressions.

tab_model(glm_modela, glm_modelb_age)%>% 
  return() %$% 
  knitr %>% 
  asis_output()
#We see that the coefficient on the age[70] level is statistically significant, meaning that the it was not fully accounted for in the radiologists decision to recall the patient, and it is positive, meaning that this risk factor was under estimated. We now compare model A against model B, looking at each other risk factor.

```{R echo = FALSE}
tab_model(glm_modela, glm_modelb_den)%>% 
  return() %$% 
  knitr %>% 
  asis_output()

# Density 4 is significant at the 14% level, but does not seem as important.

tab_model(glm_modela, glm_modelb_hist)%>% 
  return() %$% 
  knitr %>% 
  asis_output()

# Family history is not significant.

tab_model(glm_modela, glm_modelb_meno)%>% 
  return() %$% 
  knitr %>% 
  asis_output()

# Symptoms not significant. 

tab_model(glm_modela, glm_modelb_symp)%>% 
  return() %$% 
  knitr %>% 
  asis_output()

#Examing the tables above, we see which factors have no significant partial effects other than the decision to recall. In laymen's terms, there is little evidence that radiologists are inappropriately weighing certain risk factors (besides the fact that people are over 70). There may be an argument to be made that radiologists should also more heavily weigh having the densest category of breast tissue, as the p-value may not be too large (.137).

Let's test Model B for age and density. 

# Create vectors of predicted values.
pred_age = predict(glm_modelb_age, data = brca)
pred_den = predict(glm_modelb_den, data = brca)

# Convert predicted values into binary values

bin_age = pred_age >= -3.5 #based on coefficients of glm_modelb_age regression
bin_den = pred_den >= -3.3 #based on coefficients of glm_modelb_den regression
logical_index = brca$cancer
logical_index = brca$cancer == 1

#Confusion matrices
confusionMatrix(data = factor(logical_index), reference = factor(bin_age), positive = "TRUE", dnn = c("recalled", "cancer diagnosed"))
confusionMatrix(data = factor(logical_index), reference = factor(bin_den), positive = "TRUE", dnn = c("recalled", "cancer diagnosed"))
```
#Model B for both age and density do not improve on the radiologists decisions (model A). Perhaps there is a more sophisticated model that utilizes the risk factors in improve accurace using somethings besides a linear term.
