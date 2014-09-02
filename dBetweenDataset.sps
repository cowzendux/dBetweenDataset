* Calculate between-groups d statistic
* Analyses by Jamie DeCoster

* Usage: dBetween(List of Outcomes, List of Group Variables, [Split file variable])
* List of Outcomes is a list of continuous outcome variables that are 
being compared between the levels of the group variables
* List of Group Variable is a list of categorical variables that define 
the two groups being compared. If any of the Group Variables have more than two 
levels, then the first two groups (alphabetically) will be used for the comparison.
* Split File Variable is an optional argument. If it is not provided, then the
calculations will be made on the full data set. If it is provided, then the calculations
will be separately performed on each level of the Split File Variable.
* The Outcomes and Group Variables must be contained in lists, even if
you only want to consider a single outcome or a single group variable.
* The program will obtain the means of the two groups and calculate the
d statistic, calculated as:
(mean of first group - mean of second group)/pooled sd
* The two means, the two standard deviations, the pooled sd, and the d statistic 
will be outputted to a new dataset. Each line will be indexed by the level of the
Split File Variable, the Group Variable, and the Outcome Variable.

* EXAMPLE 1: dBetweenDataset(["height", "weight", "age"], ["gender", "minority"],
"site")
This will calculate a six different d statistics for each level of site. Within each 
site, it will calculate one d for each combination of the three outcome variables 
with the two group variables. The sign of the coefficient will be positive if the 
first group has a higher mean and will be negative if the second group has a 
higher mean. If gender was coded 0 = female 1 = male, for example, 
then a positive d would indicate that females had a higher mean, and a negative 
d would indicate that men have a higher mean. 

* EXAMPLE 2: dBetweenDataset(["height", "weight", "age"], ["gender"])
This demonstrates how you would use this procedure if you only were interested
in using a single Group Variable. You can see that we make the group variables
into a list by including brackets, even though there is only one group variable
of interest. The split file variable was excluded, so the analyses will be performed
on the full data set.

*******
* Version History
*******
* 2013-04-04 Created
* 2013-04-05 Finished making the program work with lists
* 2013-04-05a Added the optional split variable
* 2013-04-07 Made the program work even if there are empty cells
* 2013-04-08 Added overall effect sizes to table of effect sizes by split variable
* 2013-04-08a Performed additional correction to make function work with
    empty cells
* 2013-04-26 Added Ns to final table

set printback=off.
begin program python.
import spss, spssaux, spssdata, math

def getVariableIndex(variable):
   	for t in range(spss.GetVariableCount()):
      if (variable.upper() == spss.GetVariableName(t).upper()):
         return(t)

def descriptive(variable, stat):
# Valid values for stat are MEAN STDDEV MINIMUM MAXIMUM
# SEMEAN VARIANCE SKEWNESS SESKEW RANGE
# MODE KURTOSIS SEKURT MEDIAN SUM VALID MISSING
# VALID returns the number of cases with valid values, and MISSING returns
# the number of cases with missing values

 if (stat.upper() == "VALID"):
   cmd = "FREQUENCIES VARIABLES="+variable+"\n\
  /FORMAT=NOTABLE\n\
  /ORDER=ANALYSIS."
	  handle,failcode=spssaux.CreateXMLOutput(
		cmd,
		omsid="Frequencies",
		subtype="Statistics",
		visible=False)
	  result=spssaux.GetValuesFromXMLWorkspace(
		handle,
		tableSubtype="Statistics",
		cellAttrib="text")
   return (result[0])
 elif (stat.upper() == "MISSING"):
   cmd = "FREQUENCIES VARIABLES="+variable+"\n\
  /FORMAT=NOTABLE\n\
  /ORDER=ANALYSIS."
	  handle,failcode=spssaux.CreateXMLOutput(
		cmd,
		omsid="Frequencies",
		subtype="Statistics",
		visible=False)
	  result=spssaux.GetValuesFromXMLWorkspace(
		handle,
		tableSubtype="Statistics",
		cellAttrib="text")
   return (result[1])
 else:
  	cmd = "FREQUENCIES VARIABLES="+variable+"\n\
  /FORMAT=NOTABLE\n\
  /STATISTICS="+stat+"\n\
  /ORDER=ANALYSIS."
	  handle,failcode=spssaux.CreateXMLOutput(
		cmd,
		omsid="Frequencies",
		subtype="Statistics",
		visible=False)
	  result=spssaux.GetValuesFromXMLWorkspace(
		handle,
		tableSubtype="Statistics",
		cellAttrib="text")
   if (float(result[0]) <> 0 and len(result) > 2):
    return (result[2])

def getLevels(variable):
    submitstring = """use all.
execute.
SET Tnumbers=values.
OMS SELECT TABLES
/IF COMMANDs=['Frequencies'] SUBTYPES=['Frequencies']
/DESTINATION FORMAT=OXML XMLWORKSPACE='freq_table'.
    FREQUENCIES VARIABLES=%s.
    OMSEND.
SET Tnumbers=Labels.""" %(variable)
    spss.Submit(submitstring)
 
    handle='freq_table'
    context="/outputTree"
#get rows that are totals by looking for varName attribute
#use the group element to skip split file category text attributes
    xpath="//group/category[@varName]/@text"
    values=spss.EvaluateXPath(handle,context,xpath)

# If the original variable was numeric, convert the list to numbers

    varnum=getVariableIndex(variable)
    values2 = []
    if (spss.GetVariableType(varnum) == 0):
      for t in range(len(values)):
         values2.append(int(float(values[t])))
    else:
      for t in range(len(values)):
         values2.append("'" + values[t] + "'")
    spss.DeleteXPathHandle(handle)
    return values2

def dBetweenDataset(outcomeList, groupList, splitvar="None"):
    if splitvar == "None":
        dt = []
        for group in groupList:
            glevels = getLevels(group)
            for outcome in outcomeList:
                meanlist = []
                sdlist = []
                nlist = []
                namelist = []
                wlist = []
                for level in glevels[:2]:
                    submitstring = """USE ALL.
COMPUTE filter_$=(%s=%s).
FILTER BY filter_$.
EXECUTE.""" %(group, level)
                    spss.Submit(submitstring)

                    namelist.append(str(level))
                    if (descriptive(outcome, "MEAN") == None):
                       m = None
                    else:
                       m = float(descriptive(outcome, "MEAN"))
                    meanlist.append(m)
                    if (descriptive(outcome, "STDDEV") == None):
                       s = None
                    else:
                       s = float(descriptive(outcome, "STDDEV"))
                    sdlist.append(s)
                    if (descriptive(outcome, "VALID") == None):
                       n = None
                    else:
                       n = float(descriptive(outcome, "VALID"))
                    nlist.append(n)
                    if (n == None or s == None):
                       w = None
                    else:
                       w = w + ((n-1)*(s**2))
                    wlist.append(w)

                if (wlist[0] == None or wlist[1] == None):
                   sp = None
                else:
                   sp = math.sqrt((wlist[0]+wlist[1])/(nlist[0]+nlist[1]))
                if (sp == None or meanlist[0] == None or meanlist[1] == None):
                   d = None
                else:
                   d = (meanlist[0] - meanlist[1]) / sp
                dt.append([group, outcome, namelist[0], namelist[1], nlist[0], nlist[1],
                    meanlist[0], meanlist[1], sdlist[0], sdlist[1], sp, d])

        spss.Submit("use all.")
    
########
# Saving data set
########

        spss.StartDataStep()
        datasetObj = spss.Dataset(name=None)
        dsetname = datasetObj.name
        datasetObj.varlist.append('GroupVar',25)
        datasetObj.varlist.append('Outcome',25)
        datasetObj.varlist.append('Label1',25)
        datasetObj.varlist.append('Label2',25)
        datasetObj.varlist.append('N1',0)
        datasetObj.varlist.append('N2',0)
        datasetObj.varlist.append('Mean1',0)
        datasetObj.varlist.append('Mean2',0)
        datasetObj.varlist.append('S1',0)
        datasetObj.varlist.append('S2',0)
        datasetObj.varlist.append('Spooled',0)
        datasetObj.varlist.append('d',0)

        for line in dt:
           datasetObj.cases.append(line)
        spss.EndDataStep()

        submitstring = """dataset activate %s.
dataset name dBetween.""" %(dsetname)
        spss.Submit(submitstring)

    else: # is a split variable
        dt = []
        slevels = getLevels(splitvar)
        for sl in slevels:
            for group in groupList:
                glevels = getLevels(group)
                for outcome in outcomeList:
                    meanlist = []
                    sdlist = []
                    nlist = []
                    namelist = []
                    wlist = []
                    for level in glevels[:2]:
                        submitstring = """USE ALL.
COMPUTE filter_$=(%s=%s and %s=%s).
FILTER BY filter_$.
EXECUTE.""" %(splitvar, sl, group, level)
                        spss.Submit(submitstring)

                        namelist.append(str(level))
                        if (descriptive(outcome, "MEAN") == None):
                            m = None
                        else:
                            m = float(descriptive(outcome, "MEAN"))
                        meanlist.append(m)
                        if (descriptive(outcome, "STDDEV") == None):
                            s = None
                        else:
                            s = float(descriptive(outcome, "STDDEV"))
                        sdlist.append(s)
                        if (descriptive(outcome, "VALID") == None):
                            n = None
                        else:
                            n = float(descriptive(outcome, "VALID"))
                        nlist.append(n)
                        if (n == None or s == None):
                            w = None
                        else:
                            w = ((n-1)*(s**2))
                        wlist.append(w)

                    if (wlist[0] == None or wlist[1] == None):
                        sp = None
                    else:
                        sp = math.sqrt((wlist[0] + wlist[1])/(nlist[0]+nlist[1]))
                    if (sp == None or meanlist[0] == None or meanlist[1] == None):
                        d = None
                    else:
                        d = (meanlist[0] - meanlist[1]) / sp
                    dt.append([str(sl), group, outcome, namelist[0], namelist[1],
                    nlist[0], nlist[1],
                    meanlist[0], meanlist[1], sdlist[0], sdlist[1], sp, d])

        spss.Submit("use all.")

# Add overall statistics

        for group in groupList:
            glevels = getLevels(group)
            for outcome in outcomeList:
                meanlist = []
                sdlist = []
                nlist = []
                namelist = []
                wlist = []
                for level in glevels[:2]:
                    submitstring = """USE ALL.
COMPUTE filter_$=(%s=%s).
FILTER BY filter_$.
EXECUTE.""" %(group, level)
                    spss.Submit(submitstring)

                    namelist.append(str(level))
                    if (descriptive(outcome, "MEAN") == None):
                       m = None
                    else:
                       m = float(descriptive(outcome, "MEAN"))
                    meanlist.append(m)
                    if (descriptive(outcome, "STDDEV") == None):
                       s = None
                    else:
                       s = float(descriptive(outcome, "STDDEV"))
                    sdlist.append(s)
                    if (descriptive(outcome, "VALID") == None):
                       n = None
                    else:
                       n = float(descriptive(outcome, "VALID"))
                    nlist.append(n)
                    if (n == None or s == None):
                       w = None
                    else:
                       w = ((n-1)*(s**2))
                    wlist.append(w)

                if (wlist[0] == None or wlist[1] == None):
                   sp = None
                else:
                   sp = math.sqrt((wlist[0] + wlist[1])/(nlist[0]+nlist[1]))
                if (sp == None or meanlist[0] == None or meanlist[1] == None):
                   d = None
                else:
                   d = (meanlist[0] - meanlist[1]) / sp
                dt.append(["Overall", group, outcome, namelist[0], namelist[1], 
                    nlist[0], nlist[1],
                    meanlist[0], meanlist[1], sdlist[0], sdlist[1], sp, d])

        spss.Submit("use all.")
    
########
# Saving data set
########

        spss.StartDataStep()
        datasetObj = spss.Dataset(name=None)
        dsetname = datasetObj.name
        datasetObj.varlist.append(splitvar, 25)
        datasetObj.varlist.append('GroupVar',25)
        datasetObj.varlist.append('Outcome',25)
        datasetObj.varlist.append('Label1',25)
        datasetObj.varlist.append('Label2',25)
        datasetObj.varlist.append('N1',0)
        datasetObj.varlist.append('N2',0)
        datasetObj.varlist.append('Mean1',0)
        datasetObj.varlist.append('Mean2',0)
        datasetObj.varlist.append('S1',0)
        datasetObj.varlist.append('S2',0)
        datasetObj.varlist.append('Spooled',0)
        datasetObj.varlist.append('d',0)

        for line in dt:
           datasetObj.cases.append(line)
        spss.EndDataStep()

        submitstring = """dataset activate %s.
dataset name dBetween.""" %(dsetname)
        spss.Submit(submitstring)

end program python.
set printback=on.

