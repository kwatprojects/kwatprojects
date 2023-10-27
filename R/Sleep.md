Exploring and Wrangling Fitbit data - Sleep
================
Katie Wat
2023-10-26

   

Here is a snippet of R codes that I compiled from answering some
exploratory questions from this Fitbit dataset.  
This dataset is available publicly on
[Kaggle](https://www.kaggle.com/datasets/arashnic/fitbit/data).

``` r
library(tidyverse)
library(RColorBrewer)

SleepDay <- read.csv("sleepDay_merged.csv", header = TRUE)
```

   

## Setting up the dataset

1.  Examine data struture
2.  Set ***Id*** as a factor

``` r
head(SleepDay) # examine data structure
```

    ##           Id SleepDay TotalSleepRecords TotalMinutesAsleep TotalTimeInBed
    ## 1 1503960366  4/12/16                 1                327            346
    ## 2 1503960366  4/13/16                 2                384            407
    ## 3 1503960366  4/15/16                 1                412            442
    ## 4 1503960366  4/16/16                 2                340            367
    ## 5 1503960366  4/17/16                 1                700            712
    ## 6 1503960366  4/19/16                 1                304            320

``` r
SleepDay$Id <- as.factor(SleepDay$Id) # set Id as factor
```

   

## Take a first look at the dataset

``` r
SleepDay %>% 
  summarize(n_ppt = n_distinct(Id))
```

    ##   n_ppt
    ## 1    24

There are **24** participants in this dataset.

### Add a new variable in the dataset

1.  Add a **new column** for the ***time spent in bed but not asleep***
    `TotalTimeNotSleep`.
2.  We can calcuate it by subtracting ***time asleep***
    `TotalMinutesAsleep` from ***total time in bed*** `TotalTimeInBed`.

``` r
SleepDay <- SleepDay %>% 
  mutate(TotalTimeNotSleep = TotalTimeInBed-TotalMinutesAsleep)

head(SleepDay)
```

    ##           Id SleepDay TotalSleepRecords TotalMinutesAsleep TotalTimeInBed
    ## 1 1503960366  4/12/16                 1                327            346
    ## 2 1503960366  4/13/16                 2                384            407
    ## 3 1503960366  4/15/16                 1                412            442
    ## 4 1503960366  4/16/16                 2                340            367
    ## 5 1503960366  4/17/16                 1                700            712
    ## 6 1503960366  4/19/16                 1                304            320
    ##   TotalTimeNotSleep
    ## 1                19
    ## 2                23
    ## 3                30
    ## 4                27
    ## 5                12
    ## 6                16

### Brief statistics on participants’ sleep habits

``` r
SleepStats <- SleepDay %>%
  summarize(n_ppt = n_distinct(Id),
            mean_sleep = round(mean(TotalMinutesAsleep),0), 
            mean_bed = round(mean(TotalTimeInBed),0), 
            mean_notsleep = round(mean(TotalTimeNotSleep),0))
```

- There were **24** participants in this dataset.
- Average total time spent in bed: **459** minutes, or **7.7** hours.
- Average time asleep: **419** minutes, or **7** hours.
- Average time in bed, but not asleep: **39** minutes.

     

## Categorize participants by hours of sleep

### How many participants reached at least 7 hours of sleep?

It is recommended to get 7-9 hours of sleep per day.

1.  Calculate average time asleep by participant.
2.  Create 3 categories: ***\<7 hours***, ***7 hours***, ***\>8 hours***
    of sleep.
3.  Reorder the factors so that they are presented in an ascending
    order.

``` r
SleepDay %>%
  group_by(Id) %>%
  summarize(sleep_days = n(),
            mean_sleep = mean(TotalMinutesAsleep), 
            mean_bed = mean(TotalTimeInBed), 
            mean_notsleep = mean(TotalTimeNotSleep)) %>%
  mutate(Hrs_of_Sleep = case_when(mean_sleep >= 60*8 ~ ">8"
                                  ,mean_sleep >= 60*7 ~ "7"
                                  ,TRUE ~ "<7")) %>%
  mutate(Hrs_of_Sleep = fct_relevel(Hrs_of_Sleep, c("<7", "7", ">8")) )%>%
  ungroup() %>%
  group_by(Hrs_of_Sleep) %>%
  summarize(N = n())
```

    ## # A tibble: 3 × 2
    ##   Hrs_of_Sleep     N
    ##   <fct>        <int>
    ## 1 <7              12
    ## 2 7               10
    ## 3 >8               2

- **Half** of the participants had less than 7 hours of sleep,
- **10** participants had 7-8 hours of sleep,
- **2** participants had more than 8 hours of sleep on average.
- We will include the `Hrs_of_Sleep` category in our plot next.

     

## Plotting participants sleep habits

### 1. Time spent sleeping

``` r
# [plot] Average hours of sleep
SleepDay %>%
  group_by(Id) %>%
  summarize(sleep_days = n(),
            mean_sleep = mean(TotalMinutesAsleep), 
            mean_bed = mean(TotalTimeInBed), 
            mean_notsleep = mean(TotalTimeNotSleep)) %>%
  mutate(Hrs_of_Sleep = case_when(mean_sleep >= 60*8 ~ ">8"
                                  ,mean_sleep >= 60*7 ~ "7"
                                  ,TRUE ~ "<7")) %>%
  mutate( Hrs_of_Sleep = fct_relevel(Hrs_of_Sleep, c("<7", "7", ">8")) )%>%
  ungroup()  %>%
  
  ggplot(aes(x = fct_reorder(Id, mean_sleep), y = mean_sleep))+
  geom_col(aes(fill = Hrs_of_Sleep))+
  geom_hline(yintercept = SleepStats$mean_sleep, linetype="dashed", color = "grey30")+
  scale_y_continuous("Average sleep per day (mins)", breaks = seq(0,720,60), limits = c(0,720))+
  scale_x_discrete("Participant")+
  labs(title = "Daily sleep duration by participant")+
  scale_fill_brewer(palette = "Blues", name = "Sleep hrs")+
  geom_text(aes(6, SleepStats$mean_sleep, 
                label = paste("mean = ", round(SleepStats$mean_sleep,0)), vjust = -0.5), 
            color = "grey30", size = 4)+
  theme_classic()+
  theme(axis.text.x = element_blank(),
        axis.title.x = element_text(size=12),
        axis.title.y = element_text(size = 12),
        title = element_text( size = 14))
```

![](Sleep_files/figure-gfm/%5Bplot%5D%20Average%20hours%20of%20sleep-1.png)<!-- -->

- **Half** of the participants reached at least 7 hours of sleep.
- but only **2** particiapnts reached at least 8 hours of sleep.

 

### 2. Time spent in bed but not sleeping

- Visualizing data with a boxplot allows us to see more details within
  each participant

``` r
# [plot] How much time did they spent in bed not sleeping? 
SleepDay %>%
  ggplot(aes(x = fct_reorder(Id, TotalTimeNotSleep), y = TotalTimeNotSleep))+
  geom_boxplot(fill = "coral3", alpha = 0.7)+
  scale_x_discrete("Participant")+
  scale_y_continuous("Time spent in bed but not asleep (mins)", breaks = seq(0,420,60), limits = c(0,420))+
  labs(title = "Time spent in bed but not asleep")+
  theme_classic()+
  theme(axis.text.x = element_blank(),
        axis.title.x = element_text(size=12),
        axis.title.y = element_text(size = 12),
        title = element_text( size = 14))
```

![](Sleep_files/figure-gfm/%5Bplot%5D%20not%20sleeping-1.png)<!-- -->

- Most participants spent **within 60 minutes** in bed not asleep.
- 2 of the participants spent **2 - 6 hours** in bed not asleep.

 

### 3. Is there any correlation between time spent sleeping and not sleeping?

``` r
SleepDay %>%
  ggplot(aes(x = TotalMinutesAsleep, y = TotalTimeNotSleep))+
  geom_point(color = "darkorchid", alpha = 0.7)+
  scale_x_continuous("Time spent sleeping (mins)", breaks = seq(0,840,60), limits = c(0,840))+
  scale_y_continuous("Time spent NOT sleeping (mins)", breaks = seq(0,420,60), limits = c(0,420))+
  labs(title = "Time spent sleeping verus not sleeping")+
  theme_classic()+
  theme(axis.title.x = element_text(size=12),
        axis.title.y = element_text(size = 12),
        title = element_text( size = 14))
```

![](Sleep_files/figure-gfm/%5Bplot%5D%20sleep%20vs%20not%20sleep-1.png)<!-- -->

- There’s **no clear pattern or correlation** between time spent
  sleeping and not sleeping.

     

## Next steps

- Dive deeper into sleep habits. For example:
- What time did they sleep/ wake up?
- What was the sleep quality in terms of continuous sleep?

     
