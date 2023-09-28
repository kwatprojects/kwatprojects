Exploring and Wrangling Fitbit data
================
Katie Wat
2023-09-27

   

This dataset is available publicly on
[Kaggle](https://www.kaggle.com/datasets/arashnic/fitbit/data).

``` r
library(tidyverse)
library(RColorBrewer)

dailyActivity <- read.csv("dailyActivity_merged.csv")
```

   

## Setting up the dataset

1.  Examine data struture
2.  Set ***Id*** as a factor

``` r
glimpse(dailyActivity) # examine data structure
```

    ## Rows: 940
    ## Columns: 15
    ## $ Id                       <dbl> 1503960366, 1503960366, 1503960366, 150396036…
    ## $ ActivityDate             <chr> "4/12/2016", "4/13/2016", "4/14/2016", "4/15/…
    ## $ TotalSteps               <int> 13162, 10735, 10460, 9762, 12669, 9705, 13019…
    ## $ TotalDistance            <dbl> 8.50, 6.97, 6.74, 6.28, 8.16, 6.48, 8.59, 9.8…
    ## $ TrackerDistance          <dbl> 8.50, 6.97, 6.74, 6.28, 8.16, 6.48, 8.59, 9.8…
    ## $ LoggedActivitiesDistance <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, …
    ## $ VeryActiveDistance       <dbl> 1.88, 1.57, 2.44, 2.14, 2.71, 3.19, 3.25, 3.5…
    ## $ ModeratelyActiveDistance <dbl> 0.55, 0.69, 0.40, 1.26, 0.41, 0.78, 0.64, 1.3…
    ## $ LightActiveDistance      <dbl> 6.06, 4.71, 3.91, 2.83, 5.04, 2.51, 4.71, 5.0…
    ## $ SedentaryActiveDistance  <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, …
    ## $ VeryActiveMinutes        <int> 25, 21, 30, 29, 36, 38, 42, 50, 28, 19, 66, 4…
    ## $ FairlyActiveMinutes      <int> 13, 19, 11, 34, 10, 20, 16, 31, 12, 8, 27, 21…
    ## $ LightlyActiveMinutes     <int> 328, 217, 181, 209, 221, 164, 233, 264, 205, …
    ## $ SedentaryMinutes         <int> 728, 776, 1218, 726, 773, 539, 1149, 775, 818…
    ## $ Calories                 <int> 1985, 1797, 1776, 1745, 1863, 1728, 1921, 203…

``` r
dailyActivity$Id <- as.factor(dailyActivity$Id) # set Id as factor
```

   

## Take a first look at the dataset

``` r
# How many participant were there? 
n_ppt <- dailyActivity %>% 
  summarize(n_ppt = n_distinct(Id))

# How many days did participants logged their data? 
Range <- dailyActivity %>% 
  group_by(Id) %>%
  summarize(n_days = n_distinct(ActivityDate)) %>%
  summarize(min_days = min(n_days), max_days = max(n_days), med_days = median(n_days))
```

- There are **33** in this study.
- Participants recorded between **4** and **31** days, with a median of
  **31** days.

     

## How much time did participants spent being active daily?

### 1. Prepare dataframes

1.  Transform dataframe from wide to narrow, bringing all ***Activity
    Intensity*** in first column, and its respective minutes
    ***ActivityMinutes*** in the second column.
2.  Set ***Activity Intensity*** as a factor.
3.  Rename levels within ***Activity Intensity***.

``` r
# reshape dataframe from wide to narrow, displaying activity intensity and their respective minutes
# set activity intensity as factor, and change levels names
ActivityMinutes <- dailyActivity %>%
  pivot_longer(cols = 11:14, names_to = "ActivityIntensity", values_to = "ActivityMinutes") %>%
  mutate(ActivityIntensity =  factor(ActivityIntensity, levels = c(unique(ActivityIntensity))), 
         ActivityIntensity = fct_recode(ActivityIntensity, Sedentary = "SedentaryMinutes", 
                                        LightlyActive = "LightlyActiveMinutes",
                                        FairlyActive = "FairlyActiveMinutes",
                                        VeryActive = "VeryActiveMinutes"))
```

   

4.  Filter out ***Sedentary*** activity, so we don’t include any minutes
    that were sedentary.
5.  Find total activity minutes by participant and date, which is the
    sum of ***LightlyActive***, ***FairlyActive*** and ***VeryActive***
    minutes.
6.  Calculate **summary statistics** on the duration of activity as a
    whole.

``` r
# How many minutes of activity did participants logged?   
Act_stats<- ActivityMinutes %>%
  filter(ActivityIntensity != "Sedentary") %>%
  group_by(Id, ActivityDate) %>%
  summarize(Total_Act_min = sum(ActivityMinutes), cnt = n_distinct(ActivityMinutes)) %>%
  ungroup() %>%
  summarize(Min_Act_min = min(Total_Act_min), Med_Act_min = median(Total_Act_min), 
            Avg_Act_min = round(mean(Total_Act_min),0), Max_Act_min = max(Total_Act_min))
```

#### Summary statistics on duration of activities (minutes)

- Minimum: 0
- Median: 247
- Maximum: 552
- Mean: 228

We will use the mean value for the plot below to see how each
participant compares to the average time spent being active.

   

### 2. Make some plots

#### 1. Histogram of average daily activity duration

``` r
# [plot] histogram of activity duration
ActivityMinutes %>%
  filter(ActivityIntensity != "Sedentary") %>%
  group_by(Id, ActivityDate) %>%
  summarize(total_act_mins = sum(ActivityMinutes)) %>%
  ungroup() %>%
  group_by(Id) %>%
  summarize(avg_act_mins = round(mean(total_act_mins), 1)) %>%
  
  ggplot(aes(x = avg_act_mins))+ 
  geom_histogram(binwidth = 60, color = "grey30", fill = "gold2", alpha = 0.8)+
  scale_x_continuous("Average active minutes per day", breaks = seq(0,360,60), limits = c(0,360))+
  scale_y_continuous("Number of participants", breaks = seq(0,12,2), limits = c(0,12))+
  labs(title = "Distribution of daily activity duration")+
  theme_classic()+
  theme(axis.title.x = element_text(size=12),
        axis.title.y = element_text(size = 12),
        title = element_text( size = 14))
```

![](DailyActivity_files/figure-gfm/%5Bplot%5D%20Histogram%20ActivityMinutes-1.png)<!-- -->
 

- On average, participants spent between 60 to 360 minutes (1-6 hours)
  being active daily.
- Most participants spent more than 240 minute (\>4 hours) being active
  daily.

 

#### 2. Average daily activity duration by each participant, sorted by the activity duration

``` r
# [plot] Average active minutes per day by participant
ActivityMinutes %>%
  filter(ActivityIntensity != "Sedentary") %>%
  group_by(Id, ActivityIntensity) %>%
  summarize(avg_act_mins = mean(ActivityMinutes)) %>% # avg active minutes by activity intensity and person across days
  
  ggplot(aes(x = fct_reorder(Id, avg_act_mins, .fun=sum), y = avg_act_mins))+
  geom_col(aes(fill = ActivityIntensity), alpha = 0.8)+
  geom_hline(yintercept = Act_stats$Avg_Act_min, linetype="dashed", color = "grey30")+
  scale_y_continuous("Average active minutes per day", breaks = seq(0,360,60), limits = c(0,360))+
  scale_x_discrete("Participant")+
  labs(title = "Daily activity duration by participant")+
  scale_fill_brewer(palette = "YlOrRd", direction = -1)+
  geom_text(aes(6, Act_stats$Avg_Act_min, label = paste("mean = ", Act_stats$Avg_Act_min), vjust = -0.5), color = "grey30", size = 4)+
  theme_classic()+
  theme(axis.text.x = element_blank(),
        axis.title.x = element_text(size=12),
        axis.title.y = element_text(size = 12),
        title = element_text( size = 14))
```

![](DailyActivity_files/figure-gfm/%5Bplot%5D%20ActivityMinutes-1.png)<!-- -->

 

- A large proportion of their daily activity was in **light intensity**.

   

## Next Steps

- Explore more on activity data, discover any daily/ weekly activity
  patterns.
- Explore from other data tables, including **Sleep Hours** and **Step
  Count**.

   
