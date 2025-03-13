# Statistical Analysis API

# Introduction

This project implements a statistical analysis microservice using R and Shiny. It processes JSON data via HTTP requests and returns structured JSON responses with various statistical analyses.

**Features**
- Descriptive Statistics Endpoint

- Normality Test Endpoint

- T-Test Analysis Endpoint

- Pairwise T-Test Endpoint

- ANOVA Analysis Endpoint

- Comprehensive Data Analysis Endpoint

- User-friendly testing interface

**Installation**

To run this project, you need R (version 4.4.2 or higher) and the following packages:
```
install.packages(c('dplyr', 'tidyr', 'shiny', 'jsonlite', 'plumber', 'car', 'nortest', 'shinyjs', 'shinythemes'))
```
**Project Structure**

- api.R: Contains the API implementation with all endpoints

- run_api.R: Script to run the API server

- app.R: User interface for testing the API

**API Endpoints**

***1. Descriptive Statistics Endpoint***

**Endpoint:** /v1/descriptive-stats

**Method:** POST

**Request Body:**
```
{
  "data": [23.4, 26.7, 22.1, 25.8, 24.3, 27.9, 23.5, 26.2, 24.8, 25.1],
  "group": ["A", "A", "A", "A", "A", "B", "B", "B", "B", "B"]
}
```
**Response:** Returns basic descriptive statistics (mean, median, standard deviation, min, max, quartiles) for the entire dataset and for each group.

***2. Normality Test Endpoint***
   
**Endpoint:** /v1/normality-test

**Method:** POST

**Request Body:**
```
{
  "data": [23.4, 26.7, 22.1, 25.8, 24.3, 27.9, 23.5, 26.2, 24.8, 25.1],
  "group": ["A", "A", "A", "A", "A", "B", "B", "B", "B", "B"],
  "test": "shapiro"
}
```
**Response:** Returns test statistics and p-values for normality tests (Shapiro-Wilk, Anderson-Darling, or Kolmogorov-Smirnov).

***3. T-Test Analysis Endpoint***
   
**Endpoint:** /v1/t-test

**Method:** POST

**Request Body:**
```
{
  "group1": [23.4, 26.7, 22.1, 25.8, 24.3],
  "group2": [27.9, 23.5, 26.2, 24.8, 25.1],
  "paired": false,
  "var.equal": true
}
```
**Response:** Returns t-test results including test statistic, p-value, degrees of freedom, and confidence interval.

***4. Pairwise T-Test Endpoint***
   
**Endpoint:** /v1/pairwise-test

**Method:** POST

**Request Body:**
```
{
  "data": [23.4, 26.7, 22.1, 25.8, 24.3, 27.9, 23.5, 26.2, 24.8, 25.1, 28.3, 22.8, 25.4, 24.9, 26.5],
  "group": ["A", "A", "A", "A", "A", "B", "B", "B", "B", "B", "C", "C", "C", "C", "C"],
  "p.adjust.method": "bonferroni"
}
```
**Response:** Returns a matrix of p-values from pairwise t-tests between all groups.

***5. ANOVA Analysis Endpoint***
   
**Endpoint:** /v1/anova

**Method:** POST

**Request Body:**
```
{
  "dependent": [23.4, 26.7, 22.1, 25.8, 24.3, 27.9, 23.5, 26.2, 24.8, 25.1, 28.3, 22.8, 25.4, 24.9, 26.5],
  "factors": {
    "treatment": ["A", "A", "A", "A", "A", "B", "B", "B", "B", "B", "C", "C", "C", "C", "C"],
    "gender": ["M", "F", "M", "F", "M", "F", "M", "F", "M", "F", "M", "F", "M", "F", "M"]
  }
}
```
**Response:** Returns F-statistics, p-values, and degrees of freedom for each factor and their interactions.

***6. Comprehensive Data Analysis Endpoint***
   
**Endpoint:**/v1/analyze-dataset

**Method:** POST

**Request Body:**
```
{
  "measurements": [23.4, 26.7, 22.1, 25.8, 24.3, 27.9, 23.5, 26.2, 24.8, 25.1],
  "treatment": ["A", "A", "A", "A", "A", "B", "B", "B", "B", "B"],
  "subject_id": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
  "timepoint": ["pre", "post", "pre", "post", "pre", "post", "pre", "post", "pre", "post"],
  "filter": {
    "treatment": ["A", "B"],
    "timepoint": ["post"]
  }
}
```
**Response: **Returns comprehensive results including descriptive statistics and appropriate statistical tests based on data normality.

***Testing Interface***

The project includes a user-friendly Shiny interface for testing the API. The interface allows you to:

- Select an endpoint from a dropdown menu

- Enter JSON data or load example data

- Send requests to the API

- View formatted API responses

***Implementation Details***

- Proper error handling for all endpoints

- Input data validation

- Structured JSON responses with nested objects

- Standard response format with status, timestamp, and results

- Appropriate HTTP status codes

***Example cURL Commands***

**Descriptive Statistics**
```
curl -X POST http://localhost:8000/v1/descriptive-stats \
  -H "Content-Type: application/json" \
  -d '{"data": [23.4, 26.7, 22.1, 25.8, 24.3, 27.9, 23.5, 26.2, 24.8, 25.1], "group": ["A", "A", "A", "A", "A", "B", "B", "B", "B", "B"]}'
```
**Normality Test**
```
curl -X POST http://localhost:8000/v1/normality-test \
  -H "Content-Type: application/json" \
  -d '{"data": [23.4, 26.7, 22.1, 25.8, 24.3, 27.9, 23.5, 26.2, 24.8, 25.1], "group": ["A", "A", "A", "A", "A", "B", "B", "B", "B", "B"], "test": "shapiro"}'
```
***Artificial Intelligence Tools Used***

Perplexity AI: Used for generating code structure and documentation

Gemini: Used for code completion and debugging suggestions

ChatGPT: Used for explaining statistical concepts and API design patterns

**How to Run**

1. Start the API server in the background:
   - In RStudio, go to "Tools" > "Background Jobs" > "Start Job"
   - Select "run_api.R" file
   - Click "Start"
2. In the main R session, run the testing interface:
```
shiny::runApp("app.R")
```
3. Access the testing interface in your browser and start sending requests to the API.
