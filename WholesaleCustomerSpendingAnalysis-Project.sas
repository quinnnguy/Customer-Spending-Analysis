ods html close;
options nodate nonumber leftmargin=1in rightmargin=1in;
title;
ods escapechar="~";
ods graphics on / width=4in height=3in;

ods rtf file='/home/u64258575/sasuser.v94/STAT448-Final Project/Quinn-Nguyen-Final.rtf'
        nogtitle startpage=no;
ods noproctitle;

proc import datafile="/home/u64258575/sasuser.v94/STAT448-Final Project/Wholesale customers data.csv"
	out=work.wholesale
	dbms=CSV
	replace;
run;
data wholesale;
	set wholesale;
	if channel=1 then channelname='Horeca';
	if channel=2 then channelname='Retail';
	if region=1 then regionname='Lisbon';
	if region=2 then regionname='Oporto';
	if region=3 then regionname='Other';
	fresh = fresh/100;
	milk = milk/100;
	grocery =grocery/100;
	frozen=frozen/100;
	detergents_paper=detergents_paper/100;
	delicassen=delicassen/100;
run;
ods text= "~{style [fontsize=14pt]INTRODUCTION}";
ods text="The dataset used in this project is from the UCI Machine Learning Repository, which records annual spending by 440 business 
clients across six categories, which are Fresh, Milk, Grocery, Frozen, Detergents & Paper, and Delicassen, alongside Channel (Horeca vs. Retail) and Region (Lisbon, Oporto, Other). 
We explore five key questions: channel spending differences, channel prediction, regional separation, how Frozen spending is related to other product categories, and 
whether customer groupings align with channel or region. 
~n~n
Descriptive analysis shows Retail customers spend far more on Grocery, Milk, and Detergents ans Paper, whereas Horeca clients spend more in Fresh and Frozen. 
A stepwise logistic model retains only Grocery and Detergents_Paper as predictors of Retail. 
To test regional differentiation, we performed cross‐validated quadratic discriminant analysis and found overall accuracy is around 38 percent. 
Stepwise selection retained Fresh, Milk, Detergents_Paper, and Delicassen as the significant predictors in the final model for Frozen spending. 
Clustering produces three segments that perfectly map to Channel (one Retail, one Horeca, one mixed) but not to Region, 
underscoring that segmentation and strategy should be channel‐focused rather than region‐based."; 
/* TASK 1 */
ods text= "~{style [fontsize=14pt]Task 1}";
ods text="Retail customers (channel 2) spend substantially more on grocery (mean=163.23), milk (107.17), and detergents_paper (72.70), 
while Horeca customers (channel 1) spend more on fresh (134.76) and frozen (37.48) items. Fresh spending in the Horeca channel exhibits the greatest variability (SD=138.32), 
whereas in the retail channel, grocery spending shows the largest dispersion (SD=122.67). In most categories, the channel with the higher average spend also shows the most extreme outliers. 
For delicassen spending, the two channels have similar average levels, 
but Horeca shows the single largest outliers, indicating that some hotels, restaurants and cafes make occational very large specialty purchases. 
Shapiro-Wilk tests confirm strong right-skewness in every category (all p-values less than 0.0001), providing evidence that none of the spending 
variables are normally distributed (see A, Task 1 Appendix). Overall, these results underscore that retail outlets focus on packaged goods (high spending on grocery, milk, detergents), 
while HORECA businesses incur larger, more variable costs for fresh and frozen goods, with occasional large specialty orders in delicassen."; 
proc sort data=wholesale;
	by channel; 
	run;
proc means data=wholesale;  
	var fresh--delicassen;
	by channel;
run;
proc sgplot data=wholesale;
	vbox fresh / category=channel;
run;
proc sgplot data=wholesale;
	vbox milk / category=channel;
run;
proc sgplot data=wholesale;
	vbox grocery / category=channel;
run;
proc sgplot data=wholesale;
	vbox frozen / category=channel;
run;
proc sgplot data=wholesale;
	vbox detergents_paper / category=channel;
run;
proc sgplot data=wholesale;
	vbox delicassen / category=channel;
run;

/* TASK 2 */
ods text= "~{style [fontsize=14pt]Task 2}"; 
proc logistic data=wholesale desc plots=influence(unpack);
	class channel;
	model channel = fresh--delicassen / selection=stepwise lackfit;
	output out=diag cbar=cb; 
	ods select OddsRatios ParameterEstimates LackFitChiSq CBarPlot; * issue with lack of fit;
run;
ods text="First, we fitted a logistic regression. With stepwise selection, we find that Grocery and Detergents_Paper are the only 
significant predictors for whether a business is a Retail business. However, the Hosmer–Lemeshow p-value is below 0.05, meaning that there is a lack of fit. 
We should consider removing a high Cbar value and refit the model. ";
proc logistic data=diag desc plots=influence(unpack);
	class channel;
	model channel = Grocery Detergents_Paper/lackfit;
	where cb<0.3;
	output out=diag2 cbar=cb2;
	ods select OddsRatios ParameterEstimates LackFitChiSq CBarPlot; 
run; 
ods text="The Hosmer–Lemeshow p-value improved, but it is still below 0.05. We continue to remove another high Cbar value and refit the model again. "; 
proc logistic data=diag2 desc plots=influence(unpack);
	class channel;
	model channel = Grocery Detergents_Paper /lackfit;
	where cb2<0.3;
	output out=diag3 cbar=cb3;
	ods select OddsRatios ParameterEstimates LackFitChiSq CBarPlot; 
run;

ods text="Now, the results are very good. The Hosmer–Lemeshow p-value is greater than 0.05, indicating there is no lack of fit.  
The best model includes only Grocery and Detergents_Paper. Both Grocery and Detergents_Paper parameters are positive, suggesting that those who spend more in Grocery and Detergents_Paper have higher 
log odds of being a Retail channel. The odds ratios confirm this. Each additional unit of Grocery spending increases the odds of being Retail by 1.5 percent. 
Since the confidence interval (1.006, 1.025) does not include 1, this effect is statiscially significant. Also, for every one unit increase in Detergents_Paper, 
the odds of being a Retail channel are multiplied by around 1.104. The confident interval (1.077, 1.133) excludes 1, suggesting a significant effect. 
Althought there are some CBar values higher than the majority of values, none are extreme enough to raise concerns about undue influence. " ;

/* TASK 3 */
ods text= "~{style [fontsize=14pt]Task 3}";
ods text="The test of Homogeneity of Within Covariance Matrices was statistically significant, with p-value less than 0.0001, meaning that 
the assumption of equal covariances was violated. Not all p-values from the multivariate test of group mean differences was significant, except from Roy's test. 
This suggests that there is no strong evidence that the mean spending profiles differ across regions. The cross-validation results were not great. 
Customers from Lisbon were correctly classified 33.8 percent of the time, Oporto a mere 8.5 percent, and Other regions 56 percent. 
The overall cross-validation error rate was high, approximately 53 percent. This indicates that spending alone provide minimal discriminatory power across regions 
and strongly supports the distributor’s hypothesis that regions cannot be distinguished by purchase behavior. "; 
proc stepdisc data=wholesale sle=.05 sls=.05;
   	class region;
   	var fresh--delicassen;
run;

proc discrim data=wholesale method=normal manova crossvalidate pool=test;
   class region;
   var fresh--delicassen;
   priors proportional;
   ods select ChiSq MultStat ClassifiedCrossVal ErrorCrossVal;
run;

/* TASK 4 */
ods text= "~{style [fontsize=14pt]Task 4}";
proc genmod data=wholesale plots=(stdreschi stdresdev);
	model frozen = fresh--delicassen / dist=gamma 
		link=log type1 type3;
	output out=gammares pred=presp_n stdreschi=presids	
		stdresdev=dresids;
	ods select ModelFit ParameterEstimates Type1 Type3;
run;
proc genmod data=wholesale plots=cooksd;
	model frozen = fresh--delicassen / dist=gamma 
		link=log type1 type3;
	output out=diagnostics4 cooksd=cd4;
	ods select CooksDPlot;
run;
ods text="We modeled frozen food sales using Gamma GLM with a log link to accomodate its right-skewed distribution. The scaled deviance of 
1.1684 is not too far from 0, so we do not have to worry about overdispersion. In the parameter estimates, not all predictors are significant. 
Cook's distance plot suggests the presence of an unduly influential point violating the rule of thumb. We should remove this point and refit the model.";
proc genmod data=diagnostics4 plots=cooksd;
	model frozen = fresh milk grocery detergents_Paper delicassen/ dist=gamma 
		link=log type1 type3;
	where cd4<1;
	output out=diagnostics42 cooksd=cd42;
	ods select ModelFit ParameterEstimates Type1 Type3 CooksDPlot;
run; 

ods text="Grocery is the only insignificant predictor in the parameter estimates. We should exclude it from the final model. ";

proc genmod data=diagnostics42 plots=(stdreschi stdresdev);
	model frozen = fresh milk detergents_paper delicassen/ dist=gamma
		link=log type1 type3;
	output out=diagnostics43 cooksd=cd43;
	ods select ModelFit ParameterEstimates Type1 Type3 CooksDPlot;	
run;
proc genmod data=diagnostics43 plots=(stdreschi stdresdev);
	model frozen = fresh milk detergents_paper delicassen/ dist=gamma
		link=log type1 type3;
	output out=gammares pred=presp_n stdreschi=presids	
		stdresdev=dresids;
	ods select DiagnosticPlot;	
run;
proc sgscatter data=gammares;
	compare y= (presids dresids) x=presp_n;
	where presp_n<100;
run;

ods text="Our final model includes Fresh, Milk, Detergents_Paper, and Delicassen as predictors of Frozen food sales. 
Parameter estimates show that all predictors are highly significant with p-values less than 0.05. 
Type 3 analysis confirms this, while type 1 disagrees, showing that Milk is not significant. But AIC has decreased, which is a good sign. 
Cook's distance plot also shows no concerning influential point. The plots for standardized Pearson and deviance residuals versus 
predicted values seem fine and do not appear to have any trend, meaning that the final model fits the data well. The coefficients for 
Fresh, Milk, Detergents_Paper, and Delicassen are exp(0.0023)=1.0023, exp(0.0024)=1.0024, exp(-0.0076)=0.9924, and exp(0.0116)= =1.0117 
respectively. The model tells us that:
~n
- For each additional 100 units spent on Fresh, expected Frozen spending increases by 0.23 percent.
~n
- For each additional 100 units spent on Milk, expected Frozen spending increases by 0.24 percent.
~n 
- Each extra 100 units on Detergents and Paper lower the expected spending on Frozen by 0.76 percent. 
~n 
- And each extra 100 units on Delicassen increase the the expected spending on Frozen by 1.17 percent.
 ";

/* TASK 5 */
ods text= "~{style [fontsize=14pt]Task 5}";
ods text="Based on the correlation-based principal component analysis, we keep 2 components. 
For component 1, all coefficients are positive, but largest values are in Milk, Grocery, and Detergents_Paper, which are what Retail customers usually spend more on. 
For component 2, there is a contrast of spending from Retail customers and Horeca customers (see A, Task 5 Appendix)."; 
proc princomp data=wholesale plots=score(ellipse ncomp=2) out=pcoutCorr noprint;
    var fresh--delicassen;
    ods select Eigenvalues Eigenvectors Screeplot;
run;
ods text="In terms of clusters, we see that the CCC values are negative at the first 15 components, and the pseudo F statistic 
is relatively high at 3 clusters. Also, the pseudo t-squared shows a large jump from 3 to 2 cluster. So, 3 is our best choice for number of clusters.";
proc cluster data=pcoutCorr method=average outtree=sale_avg std pseudo ccc print=15;
   var fresh--delicassen;
   copy channel region Prin:;
   ods select CccPsfAndPsTSqPlot;
run;

proc tree data=sale_avg out=clusters n=3 noprint; *choose 3 clusters;
   copy channel region Prin: fresh--delicassen;
run;
proc sort data=clusters;
	by cluster;
run;
ods text="Here we can do a simple comparation. We see that component 1 is highest in cluster 2 and pretty high in cluster 3. 
In general, those two clusters spend heavily on Milk, Grocery, and Detergents_Paper. 
Cluster 1 has a slight negative average component 1. In contrast, component 2 is highest in cluster 3 and negative in other clusters. 
~n~n
We say that cluster 1 exihits moderate spending across all goods. Cluster 2 is a packaged-goods-heavy segment, with exceptionally high Grocery, 
Milk, and Detergents_Paper spend, but low Fresh and Frozen purchases. Finally, cluster 3 includes a single extreme outlier, who is a large Horeca customer. 
They spend much more money than everyone else on Fresh, Frozen, and Delicassen. ";
proc means data=clusters;
	var Prin1 Prin2;
	by cluster;
run;
ods text="Looking at the table of cluster by Channel, cluster 2 seem to be 100 percent Retail, cluster 3 100 percent Horeca, while cluster 1 
a mix of both (68 percent Horeca and 32 Retail). On the other hand, the table of cluster by Region does not show much relation. Each cluster 
was dominated by Other region, with only minimal representation from Lisbon or Oporto in any group.
~n~n
These results confirm that spending‐based segmentation aligns strongly with channel rather than region. Retail customers custer together 
through their heavy purchases of packaged goods (Milk, Grocery, and Detergents_Paper), while Horeca clients from their own group driven by 
Fresh and Frozen goods. Also, the majority of businesses fall into a moderate cluster (cluster 1).";
proc freq data=clusters;
  tables cluster*channel/ norow nocol;
run;
proc freq data=clusters;
  tables cluster*region/ norow nocol;
run;

ods text= "~{style [fontsize=14pt]CONCLUSION}";
ods text="In summary, Retail customers focus on packaged goods, which are Grocery and Detergents_Paper, the only significant predictors in our logistic model, 
while Horeca clients lead in Fresh and Frozen foods. Regional classification fails (overall cross-validation error rate was high, around 53 percent) so geography offers no spend-based segmentation. 
Frozen sales are driven by Fresh, Milk, Detergents_Paper, and Delicassen, revealing cross-category demand patterns. 
Finally, business spending clearly segments by channel, not by region. The distributor might want to tailor marketing strategies by channel rather than region-based approaches.  ";

/* Appendix */
ods text= "~{style [fontsize=14pt]APPENDIX}";
ods text= "~{style [fontsize=14pt]Task 1}";
ods text="A";
proc univariate data=wholesale normal; *Normality tests; 
	class channel;
	var fresh--delicassen;
	histogram fresh--delicassen/ normal;
	ods select TestsForNormality; 
run;
ods text= "~{style [fontsize=14pt]Task 5}";
ods text="A";
proc princomp data=wholesale plots=score(ellipse ncomp=2) out=pcoutCorr; *pick 2 principal components;
    var fresh--delicassen;
    ods select Eigenvalues Eigenvectors Screeplot;
run;









ods rtf close;