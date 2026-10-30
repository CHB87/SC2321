**************************************************************************
******* WORKSHOP 3: INTERACTION EFFECTS AND LOGISTIC REGRESSION **********
**************************************************************************


clear all 
/*clear data in memory, use if you want to open a new file but make 
sure to save the current one first*/

//For this part of the exercise we'll use one of Stata's practice data sets.

webuse nhanes2

****************************************************************************
************** PART 1: INTERACTION EFFECTS *********************************
****************************************************************************

/*
When analyzing interaction effects, we focus on two main questions:

	1. Does the interaction improve the model?

	2. What does the interaction look like?

How we answer these questions depends on the level of measurement
of the variables involved (continuous or categorical), as well as
the type of regression model (OLS or logistic regression).

We will use significance tests to assess whether the interaction
improves the model, and margins and marginsplot to examine and
visualize the conditional effects.
*/


* CONTINOUS x CATEGORICAL (bivariate) *

// Does sex and age have effects on systolic blood pressure?
reg bpsystol i.sex c.age

/*Yes! But does the potential of sex vary with age? 
We use the i. (categorical) and c. (continous) operators here to be able 
to use the margins commands later.*/
reg bpsystol i.sex##c.age

/*
What do we see? Adjusted R2 is slightly higher in the model
with the interaction term, suggesting an improvement in
explanatory power.

The significance of the interaction term indicates whether
there is statistical evidence of an interaction (NOTE: this
is ONLY true when there is a single interaction coefficient).
The significance of the interaction term indicates whether there is statistical 
evidence that the effect of sex varies with age. However, it does not tell us 
the magnitude or statistical significance of the effect of sex at specific 
values of age.

Therefore, we need to examine the conditional marginal effects
to assess both the statistical significance and substantive
importance of the interaction.

To this end we will use the very helpful and versatile margins and 
marginsplot commands. 
*/
 
help margins
help marginsplot

/* The Stata manual for marginsplot is very useful, there are endless
possibilities and I will only show you a few examples. */				 

* Conditional marginal effects of sex at different ages
margins, dydx(sex) at(age=(20(10)80))

* Plot marginal effects with 95% confidence intervals
marginsplot, yline(0)

/* In younger ages (until age 60 or so) being female has a negative effect
on bp (CIs do not overlap zero). In older ages CIs still do not overlap zero, 
but being a woman is associated with having  higher bp compared to men.*/


* CATEGORICAL (bivariate) x CATEGORICAL (bivariate or more categories) *

codebook agegrp
reg bpsystol i.sex##i.agegrp

/* Here, we get multiple interaction coefficients. Each
indicates whether the gender difference in blood pressure
in a particular age group differs significantly from the
gender difference in the reference group (20–29 years).

However, the individual interaction coefficients do not
tell us whether the gender differences within each age
group are statistically significant, or whether the gender
differences vary significantly across all age groups. */

/* We can use testparm to conduct a joint F-test of the
interaction terms. This tests whether the gender difference
in blood pressure is the same across all age groups.

A significant result provides evidence of an interaction,
but does not tell us which specific age groups differ. */

testparm i.sex#i.agegrp

/* To better understand the interaction, we can use margins
to estimate the gender difference in blood pressure within
each age group and assess whether these differences are
statistically significant.

Marginsplot allows us to visualize these conditional
effects and their confidence intervals. */

margins, dydx(sex) at(agegrp=(1 2 3 4 5 6))
marginsplot, yline(0)

* CONTINOUS x CONTINOUS *

reg bpsystol c.weight##c.age 
margins, dydx(weight) at(age=(20(1)74)) 
marginsplot, yline(0) 


/************************************************************************
* NOTE:
*
* It is perfectly possible to conduct interaction analyses with two
* qualitative variables that each have more than two categories. 
* However, this produces more interaction coefficients and possible group
* comparisons, making interpretation more complicated. Therefore,
* we will stick to these simpler examples for now. 
*
************************************************************************/



****************************************************************************
************** PART 2: LOGISTIC REGRESSION *********************************
****************************************************************************

clear
use "ESS_Practice dataset.dta"


///////////////////////////////////////
/// BINOMINAL LOGISTIC REGRESSION ////
/////////////////////////////////////

/* For the first example, we will examine determinants of union membership in 
Sweden. Our main focus is on the role of employment sector. To control for 
potentially confounding effects, we will also include gender and age */


** CHECK DATA AND MAKE NECESSARY RECODINGS **

* Examine the original variable (mbtru)
tab mbtru, missing
codebook mbtru

* Create a binary variable indicates whether a person was ever a union member
gen uni_mem = mbtru
recode uni_mem (1/2 = 1) (3 = 0) (else = .)

* Label the new variable
lab var uni_mem "Union membership"
lab def unionlbl 0 "Non-member" 1 "Union member"
lab val uni_mem unionlbl

* Check the recoding
tab uni_mem, missing

* Examine the original variable (tporgwk)
tab tporgwk, missing
codebook tporgwk

* Create a variable for employment sector
gen emp_sector = tporgwk
recode emp_sector (1/3 = 1) (4 = 2) (5 = 3) (else = .)

* Label the variable
lab var emp_sector "Employment sector"
lab def emplbl 1 "Public sector" 2 "Private sector" 3 "Self-employed"
lab val emp_sector emplbl

* Check the recoding
tab emp_sector, missing

logit uni_mem i.emp_sector i.gndr c.age if cntry == "SE"
/* The model has a McFadden's Pseudo R-squared of 0.1143, indicating
an improvement in model fit compared to the null model. Higher values generally 
indicate better model fit, but Pseudo R-squared cannot be interpreted as the 
proportion of explained variation (cf. OLS).

Individuals working in the private sector have 0.988 lower log-odds 
of ever having been a union member compared to those in the public sector, 
holding other variables constant. Not very intutive... let's try odds ratios!*/ 

logit uni_mem i.emp_sector i.gndr c.age if cntry == "SE", or 
/* Individuals working in the private sector have 62.8% lower odds of ever
having been a union member compared to those in the public sector, holding 
other variables constant (OR = 0.372, p < 0.001).

Maybe a bit more intutive (and commonly reported), but let's switch to
probabilities instead! We'll use the margins command*/


* AVERAGE MARGINAL EFFECTS (AME's) *

/* Gives us differences in probability for all x's.*/

margins, dydx(*) 
/* People in the private sector are 5.06 percentage points less likely
to have ever been union members than those in the public sector (p = 0.025).

Each additional year of age is associated with a 0.75 percentage
point increase in probability of ever having been a union member (p < 0.001).

While AMEs show differences in predicted probabilities, they do not
show the actual probability levels. We may therefore also want to
examine predicted probabilities for each employment sector.*/

* PREDICTED PROBABILITIES *

margins emp_sector
marginsplot, recast(scatter) ///
    title("Predicted Probability of Union Membership") ///
    xtitle("Employment Sector") ///
    ytitle("Predicted Probability")
	
/* The predicted probability of ever having been a union member is
81.8% in the public sector, adjusting for other variables.*/

* COMPARE MODELS *

/* Pseudo R-squared describes overall model fit. The LR-test examines whether 
adding variables significantly improves model fit and is generally more useful 
for comparing nested models.*/

/*When comparing models, we want to ensure that both models are estimated
using the same observations. We therefore use the nestreg command.*/

nestreg, lr: logit uni_mem (i.emp_sector i.gndr c.age) ///
    (i.emp_sector#i.gndr) if cntry == "SE"

/* The lrtest is non-signifikant (p =  0.289), which suggests that the 
interaction does not improve model fit.*/

margins emp_sector, dydx(gndr)
marginsplot, recast(scatter) ///
    title("Union Membership") ///
    xtitle("Employment Sector") ///
    ytitle("Gender Difference in Probability") ///
    yline(0)
	
/* The confidence intervals for the gender differences include zero
in all three sectors, indicating that none of the gender differences
are statistically significant at the 5% level. */


* EXAMPLES OF MODEL DIAGNOSTICS FOR LOGIT *

* 1. Linktest: Checks for potential model specification errors.

qui logit uni_mem i.emp_sector i.gndr c.age if cntry=="SE"
linktest, nolog // A significant _hatsq suggests that the model may be misspecified.

* 2. VIF: Checks for multicollinearity among explanatory variables.

qui logit uni_mem i.emp_sector i.gndr c.age if cntry=="SE"
vif // High VIF values (e.g., above 5 or 10) may indicate a problem.

* 3. DBETA: Identifies potentially influential observations.

qui logit uni_mem i.emp_sector i.gndr c.age if cntry=="SE"
predict p, pr
predict db, dbeta //Large values indicate obs. that may strongly affect model estimates.

scatter db p, ///
    title("Influential Observations") ///
    xtitle("Predicted Probability") ///
    ytitle("DBETA") 

* Inspect observations with the largest DBETA values
gsort -db //Sort observations by DBETA in descending order (highest first).
list uni_mem emp_sector gndr age db in 1/10

/*High DBETA values indicate potentially influential observations.
These should be examined for errors or unusual characteristics,
but not automatically excluded. The observations with the highest DBETA
values are young women in the private sector who have never been union members.
--> Fall within the target population, no reason to exclude!*/


/////////////////////////////////////
/// ORDINAL LOGISTIC REGRESSION ////
////////////////////////////////////

/* For this example, we will examine perceptions of how wrong it is to buy
something that might be stolen. Our main focus is on the roles of gender 
and age.*/

ologit bystlwr i.gndr c.age, or 

/* Women have approximately 31% higher odds than men of reporting
a higher level of perceived wrongfulness, controlling for age
(OR = 1.310, p < 0.001). 

Each additional year of age is associated with approximately 2.1%
higher odds of reporting a higher level of perceived wrongfulness,
controlling for gender (OR = 1.021, p < 0.001). 

The cutpoints define the thresholds between the ordered categories
and are generally not interpreted.

We can also use margins to get probabilities of interest: */

margins gndr, predict(outcome(4))

/*The predicted probability of considering buying something that might
be stolen "seriously wrong" is 45.1% for men and 51.5% for women,
adjusting for age.*/

margins, predict(outcome(4)) at(age=(20(10)80))
marginsplot


* TEST THE PROPORTIONAL ODDS ASSUMPTION  *

estat parallel 

/* The proportional odds assumption means that the odds ratios between
groups are the same across all thresholds of the ordered outcome. The Brant
test examines whether this assumption holds.
	 p < 0.05: Evidence that the assumption is violated.
	 p >= 0.05: No significant evidence of a violation.*/

