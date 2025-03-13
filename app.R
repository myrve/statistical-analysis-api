library(shiny)
library(httr)
library(jsonlite)
library(shinythemes)
library(shinyjs)

# User Interface (UI)
ui <- fluidPage(
  theme = shinytheme("cosmo"),
  useShinyjs(),
  tags$head(
    tags$style(HTML("
      body {
        background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
        font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
      }
      .title-panel {
        background-color: #3f51b5;
        color: white;
        padding: 20px;
        margin-bottom: 30px;
        border-radius: 8px;
        box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        text-align: center;
      }
      .btn-primary {
        background-color: #3f51b5;
        border-color: #303f9f;
        width: 100%;
        margin-top: 15px;
        transition: all 0.3s ease;
      }
      .btn-primary:hover {
        background-color: #303f9f;
        transform: translateY(-2px);
        box-shadow: 0 4px 8px rgba(0,0,0,0.2);
      }
      .btn-info {
        background-color: #00bcd4;
        border-color: #00acc1;
        width: 100%;
        margin-top: 10px;
        transition: all 0.3s ease;
      }
      .btn-info:hover {
        background-color: #00acc1;
        transform: translateY(-2px);
        box-shadow: 0 4px 8px rgba(0,0,0,0.2);
      }
      .well {
        background-color: white;
        border-radius: 8px;
        border: none;
        box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        padding: 20px;
      }
      h3, h4 {
        color: #3f51b5;
        border-bottom: 2px solid #3f51b5;
        padding-bottom: 10px;
        font-weight: bold;
      }
      #apiResponse {
        background-color: #f8f9fa;
        border-radius: 8px;
        padding: 15px;
        border-left: 4px solid #3f51b5;
        font-family: 'Courier New', monospace;
        white-space: pre-wrap;
        max-height: 600px;
        overflow-y: auto;
        box-shadow: inset 0 2px 4px rgba(0,0,0,0.05);
      }
      .shiny-input-container {
        margin-bottom: 15px;
      }
      .selectize-input {
        border-radius: 8px;
        border: 1px solid #e0e0e0;
      }
      .form-control {
        border-radius: 8px;
        border: 1px solid #e0e0e0;
      }
      .endpoint-icon {
        margin-right: 10px;
        color: #3f51b5;
      }
      .api-badge {
        background-color: #ff4081;
        color: white;
        padding: 3px 8px;
        border-radius: 12px;
        font-size: 0.8em;
        margin-left: 10px;
      }
      .loading-indicator {
        text-align: center;
        color: #3f51b5;
        margin: 20px 0;
      }
    "))
  ),
  div(class = "title-panel",
      h1("Statistical Analysis API", style = "font-weight: 700; margin-bottom: 5px;"),
      p("Powerful data analysis through simple API calls", style = "opacity: 0.8;")
  ),
  
  sidebarLayout(
    sidebarPanel(
      style = "background-color: white; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.1);",
      h4(tags$i(class = "fa fa-exchange-alt endpoint-icon"), "Select Endpoint", tags$span("v1", class = "api-badge")),
      selectInput("endpoint", "", 
                  choices = c("Descriptive Statistics" = "descriptive-stats",
                              "Normality Test" = "normality-test",
                              "T-Test" = "t-test",
                              "Pairwise T-Test" = "pairwise-test",
                              "ANOVA" = "anova",
                              "Comprehensive Analysis" = "analyze-dataset")),
      
      h4(tags$i(class = "fa fa-code endpoint-icon"), "JSON Data"),
      textAreaInput("jsonInput", "", 
                    height = "200px",
                    placeholder = 'Example: {"data": [23.4, 26.7, 22.1, 25.8, 24.3], "group": ["A", "A", "A", "B", "B"]}'),
      
      actionButton("sendBtn", "Send Request", icon = icon("paper-plane"), class = "btn-primary"),
      
      hr(),
      
      h4(tags$i(class = "fa fa-server endpoint-icon"), "Connection Settings"),
      textInput("apiUrl", "API URL:", value = "http://localhost:8000"),
      
      actionButton("loadExample", "Load Example", icon = icon("file-code"), class = "btn-info")
    ),
    
    mainPanel(
      style = "background-color: white; border-radius: 8px; padding: 20px; box-shadow: 0 4px 6px rgba(0,0,0,0.1);",
      h3(tags$i(class = "fa fa-chart-bar"), "API Response"),
      div(id = "loadingIndicator", class = "loading-indicator", style = "display: none;",
          tags$i(class = "fa fa-spinner fa-spin fa-3x"),
          p("Processing request...")),
      verbatimTextOutput("apiResponse")
    )
  )
)

# Server
server <- function(input, output, session) {
  # Load example data
  observeEvent(input$loadExample, {
    # Button animation
    runjs("$('#loadExample').addClass('animated pulse');")
    delay(1000, runjs("$('#loadExample').removeClass('animated pulse');"))
    
    selected_endpoint <- input$endpoint
    
    example_data <- switch(selected_endpoint,
                           "descriptive-stats" = '{"data": [23.4, 26.7, 22.1, 25.8, 24.3, 27.9, 23.5, 26.2, 24.8, 25.1], "group": ["A", "A", "A", "A", "A", "B", "B", "B", "B", "B"]}',
                           "normality-test" = '{"data": [23.4, 26.7, 22.1, 25.8, 24.3, 27.9, 23.5, 26.2, 24.8, 25.1], "group": ["A", "A", "A", "A", "A", "B", "B", "B", "B", "B"], "test": "shapiro"}',
                           "t-test" = '{"group1": [23.4, 26.7, 22.1, 25.8, 24.3], "group2": [27.9, 23.5, 26.2, 24.8, 25.1], "paired": false, "var.equal": true}',
                           "pairwise-test" = '{"data": [23.4, 26.7, 22.1, 25.8, 24.3, 27.9, 23.5, 26.2, 24.8, 25.1, 28.3, 22.8, 25.4, 24.9, 26.5], "group": ["A", "A", "A", "A", "A", "B", "B", "B", "B", "B", "C", "C", "C", "C", "C"], "p.adjust.method": "bonferroni"}',
                           "anova" = '{"dependent": [23.4, 26.7, 22.1, 25.8, 24.3, 27.9, 23.5, 26.2, 24.8, 25.1, 28.3, 22.8, 25.4, 24.9, 26.5], "factors": {"treatment": ["A", "A", "A", "A", "A", "B", "B", "B", "B", "B", "C", "C", "C", "C", "C"], "gender": ["M", "F", "M", "F", "M", "F", "M", "F", "M", "F", "M", "F", "M", "F", "M"]}}',
                           "analyze-dataset" = '{"measurements": [23.4, 26.7, 22.1, 25.8, 24.3, 27.9, 23.5, 26.2, 24.8, 25.1], "treatment": ["A", "A", "A", "A", "A", "B", "B", "B", "B", "B"], "subject_id": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], "timepoint": ["pre", "post", "pre", "post", "pre", "post", "pre", "post", "pre", "post"], "filter": {"treatment": ["A", "B"], "timepoint": ["post"]}}'
    )
    
    updateTextAreaInput(session, "jsonInput", value = example_data)
  })
  
  # Send API request
  observeEvent(input$sendBtn, {
    req(input$jsonInput)
    
    # Button animation
    runjs("$('#sendBtn').addClass('animated pulse');")
    delay(1000, runjs("$('#sendBtn').removeClass('animated pulse');"))
    
    # Show loading indicator
    shinyjs::show("loadingIndicator")
    
    tryCatch({
      # Parse JSON data
      json_data <- input$jsonInput
      
      # Create API URL
      api_url <- paste0(input$apiUrl, "/v1/", input$endpoint)
      
      # Send API request
      response <- POST(
        url = api_url,
        body = json_data,
        content_type("application/json")
      )
      
      # Process response
      if (status_code(response) == 200) {
        result <- content(response, "text", encoding = "UTF-8")
        # Format JSON nicely
        parsed <- fromJSON(result)
        formatted_json <- toJSON(parsed, pretty = TRUE, auto_unbox = TRUE)
        output$apiResponse <- renderText({
          formatted_json
        })
      } else {
        output$apiResponse <- renderText({
          paste("Error:", status_code(response), content(response, "text"))
        })
      }
    }, error = function(e) {
      output$apiResponse <- renderText({
        paste("Error:", e$message)
      })
    })
    
    # Hide loading indicator after a short delay
    shinyjs::delay(1000, shinyjs::hide("loadingIndicator"))
  })
}

# Run the application
shinyApp(ui = ui, server = server)
