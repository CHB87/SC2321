**************************************************************************
********************* WORKSHOP 1: STATA PRIMER ***************************
**************************************************************************


/*Always use do-files to make sure that you don't loose your work!

Heads-up: If you drop variables or observations in STATA, they're gone forever -
there is no "undo" command. Thus, if you want to make more substantial changes 
to a dataset, always save the original and work with a copy.
 
Green text = Put an asterix or // before the text if you want to make notes and
Stata won't read it as commands. */


************************************************************
************************ SETUP DATA ************************
************************************************************

clear all 
/*clear data in memory, use if you want to open a new file but make 
sure to save the current one first*/

cd "/Users/xhasca/Library/CloudStorage/OneDrive-UniversityofGothenburg/SC2321/" 
// set directory to where your dta file is located

use "ESS_Practice dataset.dta" //open data file
cls //clears the results window, OBS cannot be undone.

save "ESS_Practice dataset" 
/* Saves the dataset as "ESS_Practice dataset.dta". 
If a file with the same name already exists, Stata will return an error.*/

save "ESS_Practice dataset", replace  
/*Saves the dataset as "ESS_Practice dataset.dta". The replace option overwrites 
the existing file if a file with the same name already exists. 
OBS cannot be undone.*/


***************************************************************
************** PART 1: EXPLORING DATA *************************
***************************************************************

/*Stata syntax is quite straight forward: 

		command _varlist, options

The help command is very helpful, e.g.*/

help browse // allows us inspect the data matrix (as a whole or parts of it) 
help codebook // describe data contents, e.g., how a variable is coded 
help order // order variables in the variables window
help sort // arrange observations of the current data into ascending order
help sum // gives you summary statistics (mean, sd etc.), cont. variables only
help tab // tabulate data (mainly for categorical data)
help table //useful for summary statistics 
help misstable //tabulates missing values

//Let's try them out!*/

browse idno cntry gndr age
codebook gndr
misstable sum gndr
codebook cntry, tab(40) // Stata will by default only print 9 values
order gndr, before(cntry)
sort age

sum age

tab gndr //frequency table
tab1 gndr age // more than one frequency tables
tab polintr gndr, col //contingency table w. column percentage 

table cntry, stat(mean age) stat(sd age)
// descriptive statistics (mean/sd) for the variable age 
table cntry gndr, stat(mean age) 
//descriptive statistics (mean/sd) for the variable age, by gender 

collect style cell result[mean], nformat(%9.1f) 
// Formats the mean values in the table to display one decimal place.
collect export "table.docx", replace 
/*Exports the table to a Word document
the replace option overwrites an existing file with the same name.*/


***** CONDITIONAL STATEMENTS AND LOGICAL OPERATORS ******

/* It is important to understand and be able to work with logical operators.
The command is only executed for the subset of observations that fulfill the
specified condition. The "if qualifier" is specified before the comma, while
command options are specified after the comma.*/


* Equal to (==)
tab gndr if cntry == "SE" //(Sweden)

* Not equal to (!=)
tab gndr if cntry != "SE"

* Greather than (>) and less than (<)
sum  eduyrs if age > 40
sum  eduyrs if age < 40 

* Greather or equal and less or equal
sum  eduyrs if age >= 40
sum  eduyrs if age <= 40 

//You can also specify multiple conditions that must be fulfilled

* & ("and") requires both conditions to be fulfilled:
tab gndr if marital == 1 & age > 40 // "All married people 40+"

* | ("or") requires either, or both, conditions to be fulfilled 
tab gndr if cntry == "SE" | age > 40 // "People who are Swedish and/or 40+"


**************************************************************************
************** PART 2: CHANGE AND GENERATE DATA **************************
**************************************************************************


***** KEEP AND DROP OBSERVAATIONS OR VARIABLES ******

* We can reduce the data sets to only the variables that we are interested in

keep _varlist //keeps all variables in the varlist
drop _varlist //drops all variables in the varlist

preserve //temporarily saves the current state of the dataset in memory

* Drop variable
drop age

* Keep/drop observations
drop if cntry == "SE" //Drops all Swedes
keep if cntry == "NO" //Keeps Norwegians only
drop if eduyrs == . //Drops all observations where data on education is missing

restore //returns the dataset to the state it was in when preserve was executed

***** RENAME VARIABLES ******

preserve
rename gndr myvariable
restore 

***** RECODE VARIABLE ******

/*A variable has five categories, ranging from "Not important at all" to 
"Very important". Let's combine these into three broader categories*/

tab ipjbhin // Inspect the distribution of the original variable
codebook ipjbhin // Check the coding of the original variable
gen high_inc = ipjbhin // Create a copy of the original variable
recode high_inc (1/2=1) (3=2) (4/5=3) // Recode into three categories
lab var high_inc "Importance of high income when choosing a job"
lab def high_inc 1"Not important" 2"Neither important nor unimportant" 3"Important"
lab val high_inc high_inc // Attach value labels to the variable values 
tab high_income // Final check!


***** GENERATE NEW VARIABLE ******

/*Let's create a variable that identifies people with high subjective 
well-being, defined here as being both happy AND satisfied with their life. */

codebook happy stflife // Check the variables that I plan to use
gen high_wellbeing = 0 // All observations will initially be 0

replace high_wellbeing = 1 if happy >= 8 & stflife >= 8 
// People scoring 8 or higher on BOTH measures will get value 1
replace high_wellbeing = . if happy == . | stflife == . 
// Exclude people who have missing values on either variable

tab high_wellbeing // Final check!

***** Transforming string variables ******
codebook cntry 
encode cntry, gen(country_num)
lab var country_num country_num 
codebook country_num, tab(40)


***************************************************************************
************ PART 3: DATA VISUALISATION AND BASIC ANALYSES ****************
***************************************************************************


***** GRAPHICS ******

/*Plotting data is often very informative for understanding the data generating
process. It is also a nice way to present data to your readers/audience. 
There are several plot types and endless possibilities to modify them in Stata, 
here are some very basic examples*/

help hist
help graph

histogram age // Distribution of a continuous variable

graph bar, over(gndr) 
// Distribution of a categorical variable
graph pie, over(emplrel) 
// Proportions of a categorical variable with few categories
graph hbar (mean) hwwkhs, over(gndr) 
// Compare group means
graph box hwwkhs, over(gndr) 
// Compare distributions across groups

twoway (scatter eduyrs age) (lfit eduyrs age) 
// Illustrate elationship between two continuous variables

preserve // Very important step since we'll now chnage the dataset!
collapse (mean) happy, by(age) 
// Reduces the dataset to mean happiness for each age
twoway line happy age 
// Plots mean happiness by age.
restore 
// Restores the original individual-level dataset.


***** SOME BASIC BIVARIATE ANALYSES ***** 

/*Before any bivariate analyses are conducted, always make sure to inspect the 
variables that you plan to use - are all values that should be coded as missing 
really coded as misisng? Are there any outliers etc. that could potentially 
affect your analyses? 

All tests also come with a number of assumptions thart must be met. 
We won't have time to go through all of them here, but always consult your
textbook before conducting a test and make sure that all relevant assumptions 
are tested and met before you go any further*/ 

** Testing the equality of means in two groups **

help ttest 

/* Is there a significant difference in years of schooling between men and 
women? Let's do a t-test! In reality we would have to check that a number of 
test assumptions are met but let's assume that they are. */

graph box eduyrs, over(gndr) 
// Compare the distribution of years of education between men and women
ttest eduyrs, by(gndr) unequal 
/* Testing wheter ther is a sig. diffrence in means using Welch's t-test
(does not assume equal variances)*/

** CHI2 - Testing associations between 2 categorical variables **

/*Is there a significant association between gender and importance assigned 
to job security (jbscr)? After checking the variables that I plan to use:*/

tab jbscr gndr, chi col

** Pearson's r - Testing associations between 2 continous variables **

help pwcorr

// Is there a significant association between age and years of schooling?

pwcorr age hwwkhs eduyrs, star(.05) 
/*Displays Pearson's correlation coefficients with stars indicating statistical 
significance (p<0.05).*/
