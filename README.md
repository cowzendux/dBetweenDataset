# dBetweenDataset

SPSS Python Extension function that calculates between-groups d statistics and saves the results to an SPSS dataset

This is similar to the dBetween function, except that it can take multiple outcomes, multiple grouping variables, and can calculate the d statistics within multiple levels of a split variable. It will calculate the d for each combination of outcome, grouping variable, and level of the split variable, and then save the result to a dataset. The program will obtain the means of the two groups and calculate the d statistic, calculated as: (mean of first group - mean of second group)/pooled sd. The two means, the two standard deviations, the pooled sd, and the d statistic will be saved  to a new dataset. Each line will be indexed by the level of the Split File Variable, the Group Variable, and the Outcome Variable.

This and other SPSS Python Extension functions can be found at http://www.stat-help.com/python.html

## Usage
**dBetweenDataset(outcomeList, groupList, splitvar)**
* "outcomeList" is a list of continuous outcome variables that are being compared between the levels of the group variables. This argument is required.
* "groupList" is a list of categorical variables that define the two groups being compared. If any of the Group Variables have more than two levels, then the first two groups (alphabetically) will be used for the comparison.
* "splitvar" is an optional argument. If it is not provided, then the calculations will be made on the full data set. If it is provided, then the calculations will be separately performed on each level of the Split File Variable.
* The Outcomes and Group Variables must be contained in lists, even if you only want to consider a single outcome or a single group variable.

## Example 1
**dBetweenDataset(outcomeList = ["height", "weight", "age"],    
groupList = ["gender", "minority"],    
splitvar = "site")**
* This will calculate a six different d statistics for each level of site. 
* Within each site, it will calculate one d for each combination of the three outcome variables with the two group variables. 
* The sign of the coefficient will be positive if the first group has a higher mean and will be negative if the second group has a higher mean. If gender was coded 0 = female 1 = male, for example, then a positive d would indicate that females had a higher mean, and a negative d would indicate that men have a higher mean. 

## Example 2
**dBetweenDataset(outcomeList = ["height", "weight", "age"],    
groupList = ["gender"])**
* This demonstrates how you would use this procedure if you only were interested in using a single Group Variable. You can see that we make the group variables into a list by including brackets, even though there is only one group variable of interest. 
* The split file variable was excluded, so the analyses will be performed on the full data set.
