

#Installing the Reguired Packages

install.packages(c("tidyverse", "arules", "arulesViz", "gridExtra", "ggthemes", "dplyr", "readxl", "plyr", "ggplot2", "knitr", "lubridate", "kableExtra", "RColorBrewer"))



#Loading the Libraries

library(tidyverse) # helpful in Data Cleaning and Manipulation
library(arules) # Mining Association Rules and Frequent Itemsets
library(arulesViz) # Visualizing Association Rules and Frequent Itemsets 
library(gridExtra) #  low-level functions to create graphical objects 
library(ggthemes) # For cool themes like fivethirtyEight
library(dplyr) # Data Manipulation
library(readxl)# Read Excel Files in R
library(plyr)# Tools for Splitting, Applying and Combining Data
library(ggplot2) # Create graphics and charts
library(knitr) # Dynamic Report generation in R
library(lubridate) # Easier to work with dates and times.
library(kableExtra) # construct complex tables and customize styles
library(RColorBrewer) # Color schemes for plotting

#Loading the Data Set

retail <- read_excel('C:/Users/NARSIMHA/OneDrive/Documents/5th Sem/DA(Data Analytics)/Online Retail.xlsx')


retail <- retail[complete.cases(retail), ] # will clean up the non missing values.

head(retail)

glimpse(retail)

#Data Cleaning

retail$Description <- as.factor(retail$Description)
retail$Country <- retail$Country
retail$Date <- as.Date(retail$InvoiceDate)
retail$InvoiceNo <- as.numeric(as.character(retail$InvoiceNo)) 
retail$Time <- format(retail$InvoiceDate,"%H:%M:%S")


#ddply(dataframe, variables_to_be_used_to_split_data_frame, function_to_be_applied)

transaction_data <- ddply(retail,c("InvoiceNo","Date"),
                          function(df1)paste(df1$Description,
                                             collapse = ","))

#Write CSV save the cleaned data as transaction as transaction_data

write.csv(transaction_data,'C:/Users/NARSIMHA/OneDrive/Documents/5th Sem/DA(Data Analytics)/market_basket_transactions.csv', quote = FALSE, row.names = TRUE)

#Transaction data file which is in basket format let’s convert it into an object of the transaction class.

tr <- read.transactions('C:/Users/NARSIMHA/OneDrive/Documents/5th Sem/DA(Data Analytics)/market_basket_transactions.csv', format = 'basket', sep=',')


#Summary

summary(tr)

#Frequency plot of top 10 Items
top_items<-retail %>%
  dplyr::group_by(Description) %>%
  dplyr::summarise(count=n()) %>%
  dplyr::arrange(desc(count))

summary(retail)

#12 Frequency plot of top 10 Items:

top_items<-head(top_items,10)

ggplot(top_items,aes(x=reorder(Description,count), y=count))+
  geom_bar(stat="identity",fill="cadetblue")+
  coord_flip()+
  scale_y_continuous(limits = c(0,3000))+
  ggtitle("Frequency plot of top 10 Items")+
  xlab("Description of item")+
  ylab("Count")+
  theme_fivethirtyeight()

#Lets Plot Item Frequency Bar Plot to view distribution.

itemFrequencyPlot(tr,topN=10,type="absolute",col=brewer.pal(8,'Pastel2'), main="Top 10 Absolute Item Frequency Plot", horiz = TRUE)


#Monthly Transactions
# Transactions per month
retail %>%
  mutate(Month=as.factor(month(Date))) %>%
  group_by(Month) %>%
  dplyr::summarize(Description=n_distinct(Description)) %>% 
  ggplot(aes(x=Month, y=Description)) +
  geom_bar(stat="identity", fill="#FF69B4", show.legend=FALSE) +
  geom_label(aes(label=Description, y= 1, fontface = 'bold')) +
  labs(title="Transactions per month") +
  theme_fivethirtyeight()+
  coord_flip()

# Description per weekday
retail %>%
  mutate(WeekDay=as.factor(weekdays(as.Date(Date)))) %>%
  group_by(WeekDay) %>%
  dplyr::summarize(Description=n_distinct(Description)) %>%
  ggplot(aes(x=WeekDay, y=Description)) +
  geom_bar(stat="identity", fill="dodgerblue", show.legend=FALSE) +
  geom_label(aes(label=Description, y =1, fontface = 'bold')) +
  labs(title=" Transacions per weekday") +
  scale_x_discrete(limits=c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")) +
  theme_fivethirtyeight()+
  coord_flip()

# Transactions per hour
parsed <- parse_date_time(retail$InvoiceDate, orders = "ymd HMS")
retail$date <- as.character(as_date(parsed))
retail$time <- format(parsed, "%H:%M:%S")

retail %>%
  mutate(Hour=as.factor(hour(hms(time)))) %>%
  group_by(Hour) %>%
  dplyr::summarize(Description=n_distinct(Description)) %>%
  ggplot(aes(x=Hour, y=Description)) +
  geom_bar(stat="identity", fill="steelblue1", show.legend=FALSE) +
  geom_label(aes(label=Description)) +
  labs(title="Transactions per hour across day") +
  theme_fivethirtyeight()

#Lets Plot Item Frequency Bar Plot to view distribution:

itemFrequencyPlot(tr,topN=10,type="absolute",col=brewer.pal(8,'Pastel2'), main="Top 10 Absolute Item Frequency Plot", horiz = TRUE)


#association Rules

association_rules <- apriori(tr, parameter = list(supp=0.001, conf=0.8,maxlen=10))

inspect(association_rules[1:10])

inspectDT(head(sort(association_rules, by = "confidence"), 3))

#shorter association Rules

shorter_association_rules <- apriori(tr, parameter = list(supp=0.001, conf=0.8,maxlen=3))

#Removing redundant rules
subset_rules <- which(colSums(is.subset(association_rules, association_rules)) > 1) # get subset rules in vector
length(subset_rules)
subset_rules

#For example, to find what customers buy before buying ‘METAL’. Lets look into tha
#Metal
metal.association.rules <- apriori(tr, parameter = list(supp=0.001, conf=0.8),appearance = list(default="lhs",rhs="METAL"))

inspectDT(head(metal.association.rules))
#Decoration
decoration.association.rules <- apriori(tr, parameter = list(supp=0.001, conf=0.8),appearance = list(default="lhs",rhs="DECORATION"))

inspectDT(head(decoration.association.rules))

#POSTAGE
postage.association.rules <- apriori(tr, parameter = list(supp=0.001, conf=0.4),appearance = list(default="lhs",rhs="POSTAGE"))

inspectDT(head(postage.association.rules))

#Visualization

# Filter rules with confidence greater than 0.4 or 40%
subRules<-association_rules[quality(association_rules)$confidence>0.4]

plotly_arules(subRules)

#10 rules from subRules having the highest confidence.
top10subRules <- head(subRules, n = 10, by = "confidence")
plot(top10subRules, method = "graph",  engine = "htmlwidget") #interactive plot engine=htmlwidget


