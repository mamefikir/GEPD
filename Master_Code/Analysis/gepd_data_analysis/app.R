#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(shinyjs)
library(tidyverse)
library(plotly)
library(glue)
library(DT)
library(rvg)
library(officer)
library(kableExtra)
library(ggcorrplot)
library(stargazer)
library(sandwich)
library(Cairo)
library(scales)
library(ggpmisc)

#setwd(dirname(rstudioapi::getSourceEditorContext()$path))


# Define UI for application that examines GEPD data
ui <- fluidPage(

    # Application title
    titlePanel("GEPD Data Explorer"),

    # Sidebar with an input for the specific indicator 
    sidebarLayout(
        sidebarPanel(
            selectizeInput("indicators",
                        "Indicator Name:",
                        choices=NULL),
            selectizeInput("subgroup", "Subgroup:",
                        choices=NULL),

            h2("Scoring Metadata on Indicator"),
            htmlOutput('metadata' )


        ),

        # Show a plot of the generated distribution

        mainPanel(
          h2(textOutput('var_name')),
            # Output: Tabset w/ plot, summary, and table ----
            tabsetPanel(type = "tabs",
                        id='tabset',
                        tabPanel("Histogram Plot", value=1, plotOutput("distPlot", height=600)),
                        tabPanel("BoxPlot", value=2, plotOutput("boxPlot", height=600)),
                        tabPanel("Summary", value=3, DT::dataTableOutput("tableset") ),
                        tabPanel("Correlations", value=4, plotlyOutput("corrPlot", height=1000)),
                        tabPanel("Regression Analysis", value=5, 
                                 selectizeInput("reg_choices", "Choose Outcome Variable for Regressions: (Default: 4th Grade Learning)", 
                                                choices=NULL)   ,
                                 plotOutput("regplot", height=600)
                                 ),
                        tabPanel("Sub-Indicator Regression Analysis", value=6,
                                 selectizeInput("sub_reg_choices", "Choose Outcome Variable for Regressions: (Default: 4th Grade Learning)", 
                                                choices=NULL)   ,
                                 htmlOutput('scoring')
                                 )
            )        )
    )
)

# Define server logic required to produce output
server <- function(input, output, session) {

    #Load the GEPD indicator data
    load(paste("school_indicators_data.RData", sep="/"))
    load(paste("public_officials_indicators_data.RData", sep="/"))
    
    
    
    
    load(paste("school_sample_2019_07_22.RData"))
    
    

    
    names(indicators)<-make.names(names(indicators), unique=TRUE)
  
    
    #Create list of key indicators
    ind_list<-c('student_knowledge', 'math_student_knowledge', 'literacy_student_knowledge',
                'student_attendance',
                'absence_rate', 'school_absence_rate', 
                'content_knowledge', 'math_content_knowledge', 'literacy_content_knowledge',
                'ecd_student_knowledge', 'ecd_math_student_knowledge', 'ecd_literacy_student_knowledge', 'ecd_exec_student_knowledge', 'ecd_soc_student_knowledge',
                'inputs', 'blackboard_functional', 'pens_etc', 'share_desk', 'used_ict', 'access_ict',
                'infrastructure','drinking_water', 'functioning_toilet', 'visibility', 'class_electricity','disability_accessibility','disab_road_access', 'disab_school_ramp', 'disab_school_entr', 'disab_class_ramp', 'disab_class_entr', 'disab_screening',
                'operational_management', 'vignette_1', 'vignette_1_resp', 'vignette_1_finance', 'vignette_1_address', 'vignette_2', 'vignette_2_resp', 'vignette_2_finance', 'vignette_2_address', 
                'intrinsic_motivation', 'm3scq1_tinm','m3scq2_tinm', 'm3scq3_tinm', 'm3scq4_tinm', 'm3scq5_tinm', 'm3scq6_tinm', 'm3scq7_tinm', 'm3scq10_tinm', 'm3scq11_tinm', 'm3scq14_tinm',
                'instructional_leadership', 'classroom_observed', 'classroom_observed_recent', 'discussed_observation', 'feedback_observation', 'lesson_plan_w_feedback',
                'principal_management', 'school_goals_exist','school_goals_clear','school_goals_relevant','school_goals_measured',
                'teacher_attraction', 'teacher_satisfied_job', 'teacher_satisfied_status', 'better_teachers_promoted' ,'teacher_bonus',
                'teacher_selection_deployment', 'teacher_selection','teacher_deployment',
                'teacher_support', 'pre_training_exists','pre_training_practicum','pre_training_practicum_lngth','in_service_exists','in_servce_lngth','in_service_classroom',
                'teaching_evaluation', 'formally_evaluated','evaluation_knowledge_skill','negative_consequences','positive_consequences',
                'teacher_monitoring','attendance_evaluated' , 'attendance_rewarded' , 'attendence_sanctions',
                'school_monitoring', 'standards_monitoring','monitoring_inputs','monitoring_infrastructure','parents_involved',
                'school_management_attraction', 'principal_satisfaction',
                'school_selection_deployment', 
                'school_support', 'prinicipal_trained','principal_training','principal_used_skills','principal_offered',
                'principal_evaluation', 'principal_formally_evaluated','principal_evaluation_multiple','principal_negative_consequences','principal_positive_consequences',
                "national_learning_goals",
                "mandates_accountability",
                "quality_bureaucracy",
                "impartial_decision_making"
    )
    
    indicator_labels<-c("4th Grade Student Knowledge", "4th Grade Math Knowledge", "4th Grade Literacy Knowledge",
                        "Student Attendance Rate",
                        "Teacher Classroom Absence Rate", "Teacher School Absence Rate", 
                        "Teacher Content Knowledge", "Teacher Math Content Knowledge", "Teacher Literacy Content Knowledge",
                        "1st Grade Assessment Score", "1st Grade Numeracy Score", "1st Grade Literacy Score", "1st Grade Executive Functioning Score", "1st Grade Socio-Emotional Score",
                        "Inputs", "Functioning Blackboard", "Classroom Materials", "Desks", "ICT Usage", "ICT Access",
                        "Infrastructure", "Clean Drinking Water", "Functioning/Accessible Toilets", "Classroom Visibility", "Electricity", "Disability Accessibility", "Disability Road Access", "School Ramps", "Disability School Entrance", "Classroom Ramps", "Disability Classroom Entrance", "Disability Screening",
                        "Operational Management", "Operational Management - Vignette 1", 'vignette_1_resp', 'vignette_1_finance', 'vignette_1_address', "Operational Management - Vignette 2",'vignette_2_resp', 'vignette_2_finance', 'vignette_2_address', 
                        "Teacher Intrinsic Motivation", 'm3scq1_tinm','m3scq2_tinm', 'm3scq3_tinm', 'm3scq4_tinm', 'm3scq5_tinm', 'm3scq6_tinm', 'm3scq7_tinm', 'm3scq10_tinm', 'm3scq11_tinm', 'm3scq14_tinm',
                        "Instructional Leadership", 'classroom_observed', 'classroom_observed_recent', 'discussed_observation', 'feedback_observation', 'lesson_plan_w_feedback',
                        'Principal Management Skills', 'school_goals_exist','school_goals_clear','school_goals_relevant','school_goals_measured',
                        'Teacher Attraction (De Facto)', 'teacher_satisfied_job', 'teacher_satisfied_status', 'better_teachers_promoted' ,'teacher_bonus',
                        'Teacher Selection & Deployment (De Facto)', 'teacher_selection','teacher_deployment',
                        'Teacher Support (De Facto)', 'pre_training_exists','pre_training_practicum','pre_training_practicum_lngth','in_service_exists','in_servce_lngth','in_service_classroom',
                        'Teacher Evaluation (De Facto)', 'formally_evaluated','evaluation_knowledge_skill','negative_consequences','positive_consequences',
                        'Teacher Monitoring & Accountability (De Facto)', 'attendance_evaluated' , 'attendance_rewarded' , 'attendence_sanctions',
                        "Inputs and Infrastructure Monitoring", 'standards_monitoring','monitoring_inputs','monitoring_infrastructure','parents_involved',
                        "School Management Attraction", 'principal_satisfaction',
                        "School Management Selection & Deployment",
                        "School Management Support", 'prinicipal_trained','principal_training','principal_used_skills','principal_offered',
                        "School Management Evaluation", 'principal_formally_evaluated','principal_evaluation_multiple','principal_negative_consequences','principal_positive_consequences',
                        "National Learning Goals",
                        "Mandates and Accountability",
                        "Quality of Bureaucracy",
                        "Impartial Decision Making"
                        )
  
    #create subset with just main indicators
    main_indicator_labels<-c("4th Grade Student Knowledge", 
                        "Student Attendance Rate",
                        "Teacher Classroom Absence Rate", 
                        "Teacher Content Knowledge", 
                        "1st Grade Assessment Score", 
                        "Inputs", 
                        "Infrastructure", 
                        "Operational Management", 
                        "Teacher Intrinsic Motivation", 
                        "Instructional Leadership", 
                        'Principal Management Skills', 
                        'Teacher Attraction (De Facto)',
                        'Teacher Selection & Deployment (De Facto)',
                        'Teacher Support (De Facto)', 
                        'Teacher Evaluation (De Facto)', 
                        'Teacher Monitoring & Accountability (De Facto)', 
                        "Inputs and Infrastructure Monitoring", 
                        "School Management Attraction", 
                        "School Management Selection & Deployment",
                        "School Management Support", 
                        "School Management Evaluation", 
                        "National Learning Goals",
                        "Mandates and Accountability",
                        "Quality of Bureaucracy",
                        "Impartial Decision Making"
    )  
      
    labels_df<-data.frame(indicators=as.character(ind_list),
                          indicator_labels=as.character(indicator_labels))
    
    indicators<- indicators %>%
        filter(indicator_tag!="PROE" & indicator_tag!="PROP" & indicator_tag!="TENR" & 
                 indicator_tag!="BIMP" & indicator_tag!="BMAC" & indicator_tag!="BNLG" & indicator_tag!="BFIN") %>%
#keep just one Bureaucracy indicator, because all with show in one
      mutate(indicator_tag=case_when(
        indicator_tag=='BQBR' ~ "QB",
        TRUE ~ indicator_tag)) %>%
      mutate(Indicator.Name=if_else(indicator_tag=="QB", 'Politics and Bureaucratic Capacity', Indicator.Name))
        
       #fix a few issues with Survey of Public Officials naming
    
    #update indicator choices for session and for regression tables
    updateSelectizeInput(session, 'indicators', choices = indicators$Indicator.Name, server = TRUE)
    
    updateSelectizeInput(session, 'reg_choices', choices = indicator_labels, server = TRUE)
    
    updateSelectizeInput(session, 'sub_reg_choices', choices = main_indicator_labels, server = TRUE)
    

    get_tag <- reactive({
    
    get_tag_df<-indicators %>%
        filter(Indicator.Name==input$indicators)
    
    
    get_tag_df[,'indicator_tag']
    
    })
    

    
    observe({ 
      if (!(str_sub(get_tag()[1],1,2) %in% c('QB', 'ID', 'AC', 'NL'))) {
        
        updateSelectizeInput(session, 'subgroup', choices = c('All', 'Urban', 'Rural'))
        
      } else if ((str_sub(get_tag()[1],1,2) %in% c('QB', 'ID', 'AC', 'NL'))) {
        
        choice<-unique(as.character(public_officials_dta_clean$govt_tier))
        choice<-append('All',choice)
        
        updateSelectizeInput(session, 'subgroup', choices = choice)
        
        
      }
      
    })  
      
    ##########################
    #Produce dataset based on indicator selected
    ##########################
    dat <- reactive({
      if (!(str_sub(get_tag()[1],1,2) %in% c('QB', 'ID', 'AC', 'NL'))) {
        df<-get(paste("final_indicator_data_",get_tag()[1], sep=""))
        
        

        df<- df %>%
          mutate(codigo.modular=as.numeric(school_code)) %>%
          left_join(data_set_updated)

        
       if (input$subgroup=="Rural") {
          df<- df %>%
            filter(rural==TRUE)
        } else if (input$subgroup=="Urban") {
          df<- df %>%
            filter(rural==FALSE)  
        }
        } else if ((str_sub(get_tag()[1],1,2) %in% c('QB', 'ID', 'AC', 'NL'))) {
          
          df<-public_officials_dta_clean 
          
          
          if (input$subgroup!="All") {
            df<- df %>%
              filter(govt_tier==input$subgroup)
          }
          
        }
        df
        
        

    })
    
    
    
    # #Update list of subindicators
    # 
    # subind_dat <- reactive({
    #   if (!(str_sub(get_tag()[1],1,2) %in% c('QB', 'ID', 'AC', 'NL'))) {
    #     df_subindicators<-get(paste("final_indicator_data_",get_tag()[1], sep=""))
    #     } else if ((str_sub(get_tag()[1],1,2) %in% c('QB', 'ID', 'AC', 'NL'))) {
    #     
    #     df_subindicators<-public_officials_dta_clean 
    # 
    #     }
    #   
    #   df_subindicators<- df_subindicators %>%
    #     select(one_of(ind_list))  
    #   
    #   df_subindicators
    #   
    #   
    #   
    # })
    #   
    # 
    # updateVarSelectInput(session, 'subindicators', data = subind_dat() , server = TRUE)
    # 
    #   

    
    

    
    ##########################
    #Diplay name of variable
    ##########################
    output$var_name<-renderText({paste(input$indicators, input$subgroup, sep=" - ")})

    
    ##########################
    #Diplay metadata of variable
    ##########################
    
    #Get metadata from github
    indicator_choices<-read_delim('indicators_choices.md', delim="|", trim_ws=TRUE)
    
    #Display metadata for indicator
    indicator_choices <- indicator_choices %>%
      dplyr::select(-X1, -X6) %>%
      dplyr::filter(Series!="---") 
    
    names(indicator_choices)<-make.names(names(indicator_choices), unique=TRUE)
    
    
    get_meta <- reactive({
      
      get_meta_df<-indicator_choices %>%
        dplyr::filter(Indicator.Name==input$indicators) 
      
      
      get_meta_df[,'How.is.the.indicator.scored.']
      
    })
    
    output$metadata<-renderUI({
      
    HTML(paste(get_meta()[1]))
      
    })
    

        
    ###################################
    #Output histogram of key indicators
    ##################################
    output$distPlot<-renderPlot({
        
        df_plot <- dat() %>%
            select(one_of(ind_list)) %>%
            rowid_to_column("ID") %>%
            pivot_longer(cols=one_of(ind_list),
                         names_to='indicators', values_to='values') %>%
            left_join(labels_df)
        
        

        p<- ggplot(data=na.omit(df_plot), aes(x=values, group=indicator_labels, colour=indicator_labels)) +
          geom_histogram() +
          facet_wrap(indicator_labels ~ ., scales='free_x' , labeller=labeller(indicator_labels=label_wrap_gen(10))) +
          theme_classic() + 
          theme(
            text = element_text(size = 16),
            
          ) +
          ggtitle("Histograms of Dashboard Indicators") +
          labs(colour = "Indicator")
        
        
        
        p
   
    })
    ###################################
    #Output boxplot of key indicators
    ##################################
    output$boxPlot<-renderPlot({
      
      df_plot <- dat() %>%
        select(one_of(ind_list)) %>%
        rowid_to_column("ID") %>%
        pivot_longer(cols=one_of(ind_list),
                     names_to='indicators', values_to='values') %>%
        left_join(labels_df)
      
      
        q<- ggplot(data=na.omit(df_plot), aes(y=values, x=indicator_labels)) +
          geom_boxplot(fill="gold1", line='goldernrod2') +
          theme_classic() + 
          theme(
            text = element_text(size = 16),
          ) +
          ggtitle("Boxplot of Dashboard Indicators")+
          xlab("Indicator")
        
        q
    })
    
    ##########################
    #summary statistics table
    #########################
    output$tableset <- DT::renderDataTable({

      if (!(str_sub(get_tag()[1],1,2) %in% c('QB', 'ID', 'AC', 'NL'))) {
        sum_items<-colnames(dat()[,grep(x=colnames(dat()), pattern="m1s?q?|m2s?q?|m3s?q?|m4s?q?|m5s?q?|m6s?q?|m7s?q?|m8s?q?")])
        metadata<-metadta
      } else if ((str_sub(get_tag()[1],1,2) %in% c('QB', 'ID', 'AC', 'NL'))) {
        sum_items<-colnames(dat()[,grep(x=colnames(dat()), pattern="gender|DEM|NLG|ACM|QB|ORG")])
        metadata<-public_officials_metadata
      }
        sumstats <- dat() %>%
          select(one_of(ind_list), one_of(sum_items) ) 
        
        #impute missing weights with median
        school_dta_short <- school_dta_short %>%
          mutate(school_ipw=if_else(is.na(school_ipw), median(school_ipw, na.rm=T), school_ipw))
        
        school_ipw<-school_dta_short$school_ipw 
        
        
        #add function to produce weighted summary stats
        my_skim <- skim_with( numeric = sfl( mean = ~ weighted.mean(.,  w=school_ipw, na.rm=TRUE),
                                             sd = ~ sqrt(wtd.var(.,  weights=school_ipw, na.rm=TRUE)),
                                             p25 = ~ (wtd.quantile(., probs=c(0.25),  weights=school_ipw, na.rm=TRUE)),
                                             p50 = ~ (wtd.quantile(., probs=c(0.5), weights=school_ipw, na.rm=TRUE)),
                                             p75 = ~ (wtd.quantile(., probs=c(0.75), weights=school_ipw, na.rm=TRUE)),
                                             complete_count= ~ sum(!is.na(.))))
        
        
        
        sumstats_df<-my_skim(sumstats) %>%
          select(-skim_type) %>%
          rename(variable=skim_variable) %>%
          select(variable, numeric.mean, numeric.sd, numeric.p0, numeric.p25, numeric.p50, numeric.p75, numeric.p100, numeric.complete_count, n_missing, numeric.hist)
        

        #add variable label
        sumstats_df <- sumstats_df %>%
            mutate(name=variable,
                   indicators=variable) %>%
            left_join(metadata) %>%
            left_join(labels_df) %>%
            mutate(varlabel=if_else(is.na(varlabel),as.character(indicator_labels),as.character(varlabel))) %>%
            select(variable, varlabel, numeric.mean, numeric.sd, numeric.p0, numeric.p25, numeric.p50, numeric.p75, numeric.p100, numeric.complete_count, n_missing, numeric.hist)

        DT::datatable(sumstats_df, caption="Summary Statistics of Key Indicator Variables and Components of Indicator",
                      colnames=c("Indicator", "Label", "Mean", "Std Dev","Min", "25th Percentile", "Median", "75th Percentile", "Max", "# Complete Cases", "# Missing Cases", "Histogram"),
                      extensions = 'Buttons', options=list(
                          dom = 'Bfrtip',
                          buttons = c('copy', 'csv', 'excel', 'pdf', 'print'),
                          pageLength = 60)) %>%
          formatRound(columns = c('numeric.mean', 'numeric.sd', 'numeric.p0', 
                                  'numeric.p25', 'numeric.p50', 'numeric.p75', 'numeric.p100'),
                      digits=2)

        
    })
  
    #####################################
    #Correlation Plot of key indicators
    ####################################
    output$corrPlot<-renderPlotly({
        
        #drop non-numeric elements
        
        corr_items<-colnames(dat()[,grep(x=colnames(dat()), pattern="m2s?q?|m3s?q?|m4s?q?|m5s?q?|m6s?q?|m7s?q?|m8s?q?")])
        
        df_corr_plot <- dat() %>%
            select(one_of(ind_list), one_of(corr_items) ) %>%
            select_if(is.numeric)
        
        df_corr_plot <-    round(cor(df_corr_plot, use="complete.obs"), 2)
        
        
        pcorr<- ggcorrplot(df_corr_plot,
                           outline.color = "white",
                           ggtheme = theme_bw(),
                           colors = c("#F8696B", "#FFEB84", "#63BE7B"),
                           legend.title = "Correlation",
                           title = "Correlation Between Questionnaire Items") + 
            theme(
                text = element_text(size = 16),
            )
        
        
        ggplotly(pcorr)
    })
    
    
    
    #############################
    # Create database with just learning outcomes for regressions
    ##############################
    
    
    get_tag_reg <- reactive({
      
      get_tag_reg_df<-labels_df %>%
        filter(indicator_labels==input$reg_choices)
      
      
      get_tag_reg_df[,'indicators']
      
    })
    
    
    dat_reg <- reactive({
      #create database with just learning outcomes
      df_reg<-school_dta_short
      
      df_reg<- df_reg %>%
        mutate(codigo.modular=as.numeric(school_code)) %>%
        left_join(data_set_updated)
      
      
      if (input$subgroup=="Rural") {
        df_reg<- df_reg %>%
          filter(rural==TRUE)
      } else if (input$subgroup=="Urban") {
        df_reg<- df_reg %>%
          filter(rural==FALSE)  
      }
      
      #keep just school code and learning outcome
      df_reg %>%
        select(school_code, as.character(get_tag_reg()[1]), weights ) %>%
        rename(y=2) %>%
        mutate(school_ipw=if_else(is.na(weights), median(weights, na.rm=T), weights))
    })
    
    ########################################
    #Regression Analysis of key indicators
    #########################################
    output$regplot<-renderPlot({
      
      

      df_reg_plot <- dat() %>%
        select(one_of(ind_list), school_code) %>%
        rowid_to_column("ID") %>%
        pivot_longer(cols=one_of(ind_list),
                     names_to='indicators', values_to='values') %>%
        left_join(dat_reg()) %>%
        left_join(labels_df) 
        
      
      regplots<- ggplot(data=na.omit(df_reg_plot), aes(x=values, y=y, group=indicator_labels, colour=indicator_labels)) +
        geom_point() +
        geom_smooth(method='lm', mapping = aes(weight = school_ipw)) +
        facet_wrap(indicator_labels ~ ., scales='free_x' , labeller=labeller(indicator_labels=label_wrap_gen(10)), nrow = 3) +
        theme_classic() + 
        theme(
          text = element_text(size = 16),
          
        ) +
        ggtitle(paste0("Linear Regression of Dashboard Indicators on Subindicators for ", input$reg_choices)) +
        labs(colour = "Indicator") +
        ylab(input$reg_choices) +
        stat_poly_eq(aes(label = paste(..eq.label.., ..rr.label.., sep = "~~~")), 
                     label.x.npc = "right", label.y.npc = 0.15,
                     formula = 'y~x', parse = TRUE, size = 5)
      
      
      regplots
    })  
    
    
    

    #Create list of key sub-indicators

    
    
    sub_ind_list<-c( 'math_student_knowledge', 'literacy_student_knowledge',
                'math_content_knowledge', 'literacy_content_knowledge',
                 'ecd_math_student_knowledge', 'ecd_literacy_student_knowledge', 'ecd_exec_student_knowledge', 'ecd_soc_student_knowledge',
                'blackboard_functional', 'pens_etc', 'share_desk', 'used_ict', 'access_ict',
                'drinking_water', 'functioning_toilet', 'visibility', 'class_electricity','disability_accessibility','disab_road_access', 'disab_school_ramp', 'disab_school_entr', 'disab_class_ramp', 'disab_class_entr', 'disab_screening',
                 'vignette_1', 'vignette_1_resp', 'vignette_1_finance', 'vignette_1_address', 'vignette_2', 'vignette_2_resp', 'vignette_2_finance', 'vignette_2_address', 
                 'm3scq1_tinm','m3scq2_tinm', 'm3scq3_tinm', 'm3scq4_tinm', 'm3scq5_tinm', 'm3scq6_tinm', 'm3scq7_tinm', 'm3scq10_tinm', 'm3scq11_tinm', 'm3scq14_tinm',
                 'classroom_observed', 'classroom_observed_recent', 'discussed_observation', 'feedback_observation', 'lesson_plan_w_feedback',
                 'school_goals_exist','school_goals_clear','school_goals_relevant','school_goals_measured',
                 'teacher_satisfied_job', 'teacher_satisfied_status', 'better_teachers_promoted' ,'teacher_bonus',
                'teacher_selection','teacher_deployment',
                 'pre_training_exists','pre_training_practicum','pre_training_practicum_lngth','in_service_exists','in_servce_lngth','in_service_classroom',
                 'formally_evaluated','evaluation_knowledge_skill','negative_consequences','positive_consequences',
                'attendance_evaluated' , 'attendance_rewarded' , 'attendence_sanctions',
                 'standards_monitoring','monitoring_inputs','monitoring_infrastructure','parents_involved',
                'principal_satisfaction',
                 'prinicipal_trained','principal_training','principal_used_skills','principal_offered',
                 'principal_formally_evaluated','principal_evaluation_multiple','principal_negative_consequences','principal_positive_consequences'
    )

########################################
#Sub-indicator Regressions
#########################################
    
    get_tag_sub_reg <- reactive({
      
      get_tag_sub_reg_df<-labels_df %>%
        filter(indicator_labels==input$sub_reg_choices)
      
      
      get_tag_sub_reg_df[,'indicators']
      
    })
    
    
    dat_sub_reg <- reactive({
      #create database with just learning outcomes
      df_sub_reg<-school_dta_short
      
      df_sub_reg<- df_sub_reg %>%
        mutate(codigo.modular=as.numeric(school_code)) %>%
        left_join(data_set_updated)
      
      
      if (input$subgroup=="Rural") {
        df_sub_reg<- df_sub_reg %>%
          filter(rural==TRUE)
      } else if (input$subgroup=="Urban") {
        df_sub_reg<- df_sub_reg %>%
          filter(rural==FALSE)  
      }
      
      #keep just school code and learning outcome
      df_sub_reg %>%
        select(school_code, as.character(get_tag_sub_reg()[1]), weights ) %>%
        rename(y=2) %>%
        mutate(school_ipw=if_else(is.na(weights), median(weights, na.rm=T), weights))
    })
    
    
output$scoring<-renderUI({
  
  
  
  df_scoring_reg <- dat() %>%
    select(one_of(sub_ind_list), school_code) %>%
    left_join(dat_sub_reg()) %>%
    select(-school_code,-weights, -school_ipw)
  
  scoring_reg<-lm(y~., df_scoring_reg, weights = dat()$school_ipw)
  
# Adjust standard errors
cov1         <- vcovHC(scoring_reg, type = "HC1")
robust_se    <- sqrt(diag(cov1))



HTML(paste(
  stargazer( scoring_reg, type = "html",
          se        = list(robust_se),
          title = "Regressions of Indicator variables on Set of Sub-Indicators",
          column.labels = input$sub_reg_choices
          )
))      
  

})  


}





# Run the application 
shinyApp(ui = ui, server = server)
