# Gerekli Paketleri Dahil Et
library(plumber)
library(dplyr)
library(tidyr)
library(jsonlite)
library(car)
library(nortest)

# API tanımlaması - bu dosyayı api.R olarak kaydedin
#* @apiTitle Statistical Analysis API
#* @apiDescription API for performing various statistical analyses

#* Descriptive Statistics Endpoint
#* @param req The request object
#* @post /v1/descriptive-stats
#* @serializer unboxedJSON
function(req) {
  data <- fromJSON(req$postBody)
  
  # Veriyi data frame'e dönüştür
  df <- data.frame(value = data$data, group = data$group)
  
  # Tüm veri için açıklayıcı istatistikler
  all_stats <- data.frame(
    mean = mean(df$value, na.rm = TRUE),
    median = median(df$value, na.rm = TRUE),
    sd = sd(df$value, na.rm = TRUE),
    min = min(df$value, na.rm = TRUE),
    max = max(df$value, na.rm = TRUE),
    q1 = quantile(df$value, 0.25, na.rm = TRUE),
    q3 = quantile(df$value, 0.75, na.rm = TRUE)
  )
  
  # Grup bazında açıklayıcı istatistikler
  group_stats <- df %>%
    group_by(group) %>%
    summarise(
      mean = mean(value, na.rm = TRUE),
      median = median(value, na.rm = TRUE),
      sd = sd(value, na.rm = TRUE),
      min = min(value, na.rm = TRUE),
      max = max(value, na.rm = TRUE),
      q1 = quantile(value, 0.25, na.rm = TRUE),
      q3 = quantile(value, 0.75, na.rm = TRUE)
    )
  
  # Sonuçları yapılandır
  response <- list(
    status = "success",
    timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ"),
    results = list(
      all = all_stats,
      by_group = group_stats
    )
  )
  
  return(response)
}

#* Normality Test Endpoint
#* @param req The request object
#* @post /v1/normality-test
#* @serializer unboxedJSON
function(req) {
  data <- fromJSON(req$postBody)
  
  # Veriyi data frame'e dönüştür
  df <- data.frame(value = data$data, group = data$group)
  
  # Test tipini belirle
  test_type <- if(!is.null(data$test)) data$test else "shapiro"
  
  # Normality test fonksiyonu
  run_normality_test <- function(values, test_type) {
    if(test_type == "shapiro") {
      test_result <- shapiro.test(values)
      return(list(
        test = "Shapiro-Wilk",
        statistic = test_result$statistic,
        p_value = test_result$p.value
      ))
    } else if(test_type == "anderson-darling") {
      test_result <- ad.test(values)
      return(list(
        test = "Anderson-Darling",
        statistic = test_result$statistic,
        p_value = test_result$p.value
      ))
    } else if(test_type == "kolmogorov-smirnov") {
      test_result <- lillie.test(values)
      return(list(
        test = "Kolmogorov-Smirnov",
        statistic = test_result$statistic,
        p_value = test_result$p.value
      ))
    }
  }
  
  # Tüm veri için normallik testi
  all_normality <- run_normality_test(df$value, test_type)
  
  # Grup bazında normallik testi
  group_normality <- df %>%
    group_by(group) %>%
    do({
      test_result <- run_normality_test(.$value, test_type)
      data.frame(
        group = unique(.$group),
        test = test_result$test,
        statistic = test_result$statistic,
        p_value = test_result$p_value
      )
    })
  
  # Sonuçları yapılandır
  response <- list(
    status = "success",
    timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ"),
    results = list(
      all = all_normality,
      by_group = group_normality
    )
  )
  
  return(response)
}

#* T-Test Analysis Endpoint
#* @param req The request object
#* @post /v1/t-test
#* @serializer unboxedJSON
function(req) {
  tryCatch({
    data <- fromJSON(req$postBody)
    
    # Veri doğrulama
    if(is.null(data$group1) || is.null(data$group2)) {
      return(list(
        status = "error",
        timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ"),
        message = "Both group1 and group2 are required"
      ))
    }
    
    if(!is.numeric(data$group1) || !is.numeric(data$group2)) {
      return(list(
        status = "error",
        timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ"),
        message = "Both groups must contain numeric values"
      ))
    }
    
    # Parametreleri al
    group1 <- data$group1
    group2 <- data$group2
    paired <- if(!is.null(data$paired)) data$paired else FALSE
    var_equal <- if(!is.null(data$var.equal)) data$var.equal else FALSE
    
    # T-test uygula
    t_test_result <- t.test(group1, group2, paired = paired, var.equal = var_equal)
    
    # Sonuçları yapılandır
    response <- list(
      status = "success",
      timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ"),
      results = list(
        test = "t-test",
        statistic = t_test_result$statistic,
        p_value = t_test_result$p.value,
        parameter = t_test_result$parameter,
        conf_int = t_test_result$conf.int,
        estimate = t_test_result$estimate,
        method = t_test_result$method,
        alternative = t_test_result$alternative
      )
    )
    
    return(response)
  }, error = function(e) {
    return(list(
      status = "error",
      timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ"),
      message = paste("Error in t-test analysis:", e$message)
    ))
  })
}

#* Pairwise T-Test Endpoint
#* @param req The request object
#* @post /v1/pairwise-test
#* @serializer unboxedJSON
function(req) {
  tryCatch({
    data <- fromJSON(req$postBody)
    
    # Veri doğrulama
    if(is.null(data$data) || is.null(data$group)) {
      return(list(
        status = "error",
        timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ"),
        message = "Both data and group are required"
      ))
    }
    
    if(length(data$data) != length(data$group)) {
      return(list(
        status = "error",
        timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ"),
        message = "Data and group must have the same length"
      ))
    }
    
    # Veriyi data frame'e dönüştür
    df <- data.frame(value = data$data, group = factor(data$group))
    
    # p-değeri düzeltme yöntemi
    p_adjust_method <- if(!is.null(data$p.adjust.method)) data$p.adjust.method else "bonferroni"
    
    # Pairwise t-test uygula
    pairwise_result <- pairwise.t.test(df$value, df$group, p.adjust.method = p_adjust_method)
    
    # Sonuçları yapılandır
    response <- list(
      status = "success",
      timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ"),
      results = list(
        method = pairwise_result$method,
        p_adjust_method = pairwise_result$p.adjust.method,
        p_values = pairwise_result$p.value
      )
    )
    
    return(response)
  }, error = function(e) {
    return(list(
      status = "error",
      timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ"),
      message = paste("Error in pairwise t-test:", e$message)
    ))
  })
}

#* ANOVA Analysis Endpoint
#* @param req The request object
#* @post /v1/anova
#* @serializer unboxedJSON
function(req) {
  tryCatch({
    data <- fromJSON(req$postBody)
    
    # Veri doğrulama
    if(is.null(data$dependent) || is.null(data$factors)) {
      return(list(
        status = "error",
        timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ"),
        message = "Both dependent variable and factors are required"
      ))
    }
    
    # Veriyi data frame'e dönüştür
    df <- data.frame(dependent = data$dependent)
    
    # Faktörleri ekle
    for(factor_name in names(data$factors)) {
      df[[factor_name]] <- factor(data$factors[[factor_name]])
    }
    
    # ANOVA formülünü oluştur
    formula_str <- paste("dependent ~", paste(names(data$factors), collapse = " * "))
    formula_obj <- as.formula(formula_str)
    
    # ANOVA uygula
    anova_result <- aov(formula_obj, data = df)
    anova_summary <- summary(anova_result)[[1]]
    
    # Sonuçları yapılandır
    response <- list(
      status = "success",
      timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ"),
      results = list(
        model = formula_str,
        df = anova_summary$Df,
        sum_sq = anova_summary$`Sum Sq`,
        mean_sq = anova_summary$`Mean Sq`,
        f_value = anova_summary$`F value`,
        p_value = anova_summary$`Pr(>F)`
      )
    )
    
    return(response)
  }, error = function(e) {
    return(list(
      status = "error",
      timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ"),
      message = paste("Error in ANOVA analysis:", e$message)
    ))
  })
}

#* Comprehensive Data Analysis Endpoint
#* @param req The request object
#* @post /v1/analyze-dataset
#* @serializer unboxedJSON
function(req) {
  tryCatch({
    data <- fromJSON(req$postBody)
    
    # Veri doğrulama
    required_fields <- c("measurements", "treatment", "subject_id", "timepoint")
    for(field in required_fields) {
      if(is.null(data[[field]])) {
        return(list(
          status = "error",
          timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ"),
          message = paste("Missing required field:", field)
        ))
      }
    }
    
    # Veriyi data frame'e dönüştür
    df <- data.frame(
      measurements = data$measurements,
      treatment = data$treatment,
      subject_id = data$subject_id,
      timepoint = data$timepoint
    )
    
    # Filtreleri uygula
    if(!is.null(data$filter)) {
      for(filter_name in names(data$filter)) {
        if(filter_name %in% colnames(df)) {
          df <- df[df[[filter_name]] %in% data$filter[[filter_name]], ]
        }
      }
    }
    
    # Veri boş mu kontrol et
    if(nrow(df) == 0) {
      return(list(
        status = "error",
        timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ"),
        message = "No data remains after applying filters"
      ))
    }
    
    # Açıklayıcı istatistikler
    descriptives <- df %>%
      group_by(treatment, timepoint) %>%
      summarise(
        n = n(),
        mean = mean(measurements, na.rm = TRUE),
        median = median(measurements, na.rm = TRUE),
        sd = sd(measurements, na.rm = TRUE),
        min = min(measurements, na.rm = TRUE),
        max = max(measurements, na.rm = TRUE)
      )
    
    # Normallik testi
    normality_results <- df %>%
      group_by(treatment, timepoint) %>%
      do({
        if(length(unique(.$measurements)) > 2) {
          test_result <- shapiro.test(.$measurements)
          data.frame(
            statistic = test_result$statistic,
            p_value = test_result$p.value,
            is_normal = test_result$p.value > 0.05
          )
        } else {
          data.frame(
            statistic = NA,
            p_value = NA,
            is_normal = NA
          )
        }
      })
    
    # Uygun istatistiksel testleri seç ve uygula
    is_normal <- all(normality_results$is_normal, na.rm = TRUE)
    
    test_results <- list()
    
    if(is_normal) {
      # Parametrik testler
      if(length(unique(df$treatment)) == 2 && length(unique(df$timepoint)) == 1) {
        # İki grup için t-test
        group1 <- df$measurements[df$treatment == unique(df$treatment)[1]]
        group2 <- df$measurements[df$treatment == unique(df$treatment)[2]]
        test_result <- t.test(group1, group2, var.equal = TRUE)
        test_results$type <- "t-test"
        test_results$result <- list(
          statistic = test_result$statistic,
          p_value = test_result$p.value,
          df = test_result$parameter,
          conf_int = test_result$conf.int
        )
      } else if(length(unique(df$treatment)) > 2 && length(unique(df$timepoint)) == 1) {
        # Çoklu grup için ANOVA
        formula_obj <- as.formula("measurements ~ treatment")
        test_result <- aov(formula_obj, data = df)
        anova_summary <- summary(test_result)[[1]]
        test_results$type <- "ANOVA"
        test_results$result <- list(
          df = anova_summary$Df,
          f_value = anova_summary$`F value`,
          p_value = anova_summary$`Pr(>F)`
        )
      } else if(length(unique(df$timepoint)) == 2) {
        # Zaman noktaları için paired t-test
        wide_df <- reshape(df, idvar = "subject_id", timevar = "timepoint", 
                           direction = "wide")
        time_points <- unique(df$timepoint)
        test_result <- t.test(wide_df[[paste0("measurements.", time_points[1])]], 
                              wide_df[[paste0("measurements.", time_points[2])]], 
                              paired = TRUE)
        test_results$type <- "paired t-test"
        test_results$result <- list(
          statistic = test_result$statistic,
          p_value = test_result$p.value,
          df = test_result$parameter,
          conf_int = test_result$conf.int
        )
      }
    } else {
      # Non-parametrik testler
      if(length(unique(df$treatment)) == 2 && length(unique(df$timepoint)) == 1) {
        # İki grup için Wilcoxon test
        group1 <- df$measurements[df$treatment == unique(df$treatment)[1]]
        group2 <- df$measurements[df$treatment == unique(df$treatment)[2]]
        test_result <- wilcox.test(group1, group2)
        test_results$type <- "Wilcoxon rank sum test"
        test_results$result <- list(
          statistic = test_result$statistic,
          p_value = test_result$p.value
        )
      }
    }
    
    # Sonuçları yapılandır
    response <- list(
      status = "success",
      timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ"),
      results = list(
        descriptives = descriptives,
        normality = normality_results,
        tests = test_results
      )
    )
    
    return(response)
  }, error = function(e) {
    return(list(
      status = "error",
      timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ"),
      message = paste("Error in dataset analysis:", e$message)
    ))
  })
}
