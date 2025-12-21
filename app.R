library(shiny)
library(shinythemes)
library(shinyjs)
library(shinyalert)

throw_velocity_ranges <- c("All" ,"85+", "70-85", "<70")

exit_velocity_choices <- c("All", "Hard", "Soft")

ui <- fluidPage(
  # Changes theme to dark blue
  theme = shinytheme("superhero"),
  
  # To use javascript editing in server code
  useShinyjs(),
  
  # To name the title displayed on the browser tab
  tags$head(
    tags$title("Cu7 Off Comm4and: A Pitcher Positioning Tool")
  ),
  
  tags$div(
    # Rescales to fit more devices
    style = "transform: scale(.67); transform-origin: top left;",
    
    # Website title text
    absolutePanel(
      titlePanel(h1("Cu7 Off Comm4nd", align = "center")),
      left = 731,
    ),

    # Frontend for image of field on the left
    absolutePanel(
      imageOutput("field"),
      left = 73,
      top = 64,
    ),
    
    # Frontend for heatmaps that eventually pop up on the right
    absolutePanel(
      imageOutput("plot"),
      top = 62,
      left = 1036,
    ),
  
    #HTML to more precisely customize visual features
    tags$head(
      tags$style(HTML("
        #exit_velo label {
          font-size: 15px;
        }
        .go-btn {
          background-color: #2b3e50;
          color: white;
          border: 3px solid black;
        }
        .base-btn {
          background-color: white;
          border: 4px solid black;
          width: 45px;
          height: 45px;
        }
        .base-btn:focus {
          outline: none;
          border: 4px solid black;
        }
        .fielder-btn img {
          width: 56px;
          height: 56px;
        }
        .fielder-btn {
          background: transparent;
          border: none;
          padding: 0;
        }
        .fielder-btn:focus {
          background: transparent;
          outline: none;
          box-shadow: none;
        }
        .summary-panel {
          font-size: 22px;
          letter-spacing: 1px;
          line-height: 1.3;
        }
      "))
    ),
    
    # Frontend for exit velo multiple choice
    absolutePanel(
      radioButtons("exit_velo", "Exit Velocity", exit_velocity_choices, selected = "All"),
      top = 72, left = 40
    ),
    
    # Frontend for throw velo dropdown
    absolutePanel(
      selectInput("throw_velo", "Outfielder Throw Velo Range (MPH)", throw_velocity_ranges, selected = "All", width = '194px'),
      top = 430, left = 338
    ),
    
    # Frontend for "Go" button
    absolutePanel(
      actionButton("go", "Go!", class = 'go-btn'),
      top = 715, left = 405,
    ),
    
    # Frontend for first base toggle button
    absolutePanel(
      actionButton("first_base", NULL, class = "base-btn", style = "transform: rotate(43deg);"),
      top = 448, left = 628
      ),
    
    # Frontend for second base toggle button
    absolutePanel(
      actionButton("second_base", NULL, class = "base-btn", style = "transform: rotate(45deg);"),
      top = 210, left = 413
    ),
    
    # Frontend for third base toggle button
    absolutePanel(
      actionButton("third_base", NULL, class = "base-btn", style = "transform: rotate(46deg);"),
      top = 448, left = 200
    ),
    
    # Frontend for center field icon
    absolutePanel(
      actionButton("Center", tags$img(src = "glove_off.png"), class = "fielder-btn"),
      top = 80, left = 407
    ),
    
    # Frontend for left field icon
    absolutePanel(
      actionButton("Left", tags$img(src = "glove_off.png"), class = "fielder-btn"),
      top = 205, left = 174
    ),
    
    # Frontend for right field icon
    absolutePanel(
      actionButton("Right", tags$img(src = "glove_off.png"), class = "fielder-btn"),
      top = 205, left = 648
    ),
    
  
    # Frontend to display all variable states
    absolutePanel(
      top = 569, left = 132, width = 300,
      class = "summary-panel",
      h2("Inputs:", align = "left"),
      textOutput("selected_bases"),
      textOutput("selected_outfielder"),
      textOutput("selected_exit_velo"),
      textOutput("selected_throw_velo")
    ),
    
    # Frontend for the density legend
    absolutePanel(
      imageOutput("density_legend"),
      top = 289,
      left = 871,
    )
  )
)
  

server <- function(input, output, session) {
  
  # Renders image of baseball diamond
  output$field <- renderImage({
    list(
      src = ("www/baseball_field.png"),
      contentType = "image/png",
      width = 730,
      height = 730
      )
  }, deleteFile = FALSE)
  
  # Sets base states to reactive value = 0
  first_base_state <- reactiveVal(0)
  second_base_state <- reactiveVal(0)
  third_base_state <- reactiveVal(0)
  
  # Sets CF state to reactive value = "none"
  fielder_state <- reactiveVal("None")
  
  # Function occurs every time a base is clicked
  toggle_base <- function(id, state) {
    observeEvent(input[[id]], {
      
      # Change value of base state when toggled
      new_state <- if(state() == 0) {
        1 
      } else {
        0
      }
      state(new_state)
      
      # Change base color when toggled
      color <- if(state() == 0) {
        "white"
      } else {
        "yellow"
      }
      runjs(sprintf("$('#%s').css('background-color', '%s');", id, color))
    })
  }
  
  toggle_base("first_base", first_base_state)
  toggle_base("second_base", second_base_state)
  toggle_base("third_base", third_base_state)
  
  
  # Function occurs every time an outfielder icon is clicked
  fielder_click <- function(id) {
    observeEvent(input[[id]], {
      positions <- c("Center", "Left", "Right")
      
      # Update current state of fielder variable
      state <- if (fielder_state() == id){
        "None"
      } else {
        id
      }
      fielder_state(state)
      
      # Update all fielder icons
      for (position in positions) {
        image <- if (state == position) {
          "glove_on.png"
        } else {
          "glove_off.png"
        }
        runjs(sprintf("$('#%s img').attr('src', '%s');", position, image))
      }
    })
  }
  
  fielder_click("Center")
  fielder_click("Left")
  fielder_click("Right")
  
  # Function occurs every time an outfielder icon is clicked
  go_click <- function() {
    observeEvent(input$go, {
      
      # Update current state of fielder variable
      if (fielder_state() == "None") {
        shinyalert("You must select an outfielder", 
                   type = "error",
                   closeOnEsc = TRUE,
                   closeOnClickOutside = TRUE,
                   confirmButtonCol = "#2b3e50")
      } else {
        # File names can't have "<" character so this avoids that
        throw_velo_for_file <- if (input$throw_velo == "<70") {
          "LessThan70"
        } else {
          input$throw_velo
        }

        # Creates file name string based on all inputs
        file_name <- reactiveVal("")
        new_file_name <- sprintf("www/%d%d%d_%s_%s_%s.png", 
                             first_base_state(),
                             second_base_state(),
                             third_base_state(),
                             fielder_state(),
                             input$exit_velo,
                             throw_velo_for_file
                            )
        file_name(new_file_name)
        
        # Displays warning message if we don't have the data for this combination
        if (!file.exists(file_name())) {
          shinyalert("This combination of inputs doesn't yield enough data for us to give you a result", 
                     type = "warning",
                     closeOnEsc = TRUE,
                     closeOnClickOutside = TRUE,
                     confirmButtonCol = "#2b3e50")
          # Hide previous heatmap + legend
          output$plot <- renderImage(req(FALSE))
          output$density_legend <- renderImage(req(FALSE))
        } else {
          # Render heatmap
          output$plot <- renderImage({
            list(
              src = (file_name()),
              contentType = "image/png",
              width = 850,
              height = 830
            )
          }, deleteFile = FALSE)
          # Render density legend
          output$density_legend <- renderImage({
            list(
              src = ("www/density.png"),
              contentType = "image/png",
              width = 182,
              height = 323
            )
          }, deleteFile = FALSE)
        }
      }
    })
  }
  
  go_click()
  
  # Displays states of input variables
  output$selected_bases <- renderText({
    sprintf("Bases: %s %s %s",
          if (first_base_state() == 1) {
            "1B"
          } else {
            ""
          },
          if (second_base_state() == 1) {
            "2B"
          } else {
            ""
          },
          if (third_base_state() == 1) {
            "3B"
          } else {
            ""
          })
  })
  output$selected_outfielder <- renderText({
    paste0("Outfielder: ", fielder_state())
  })
  output$selected_exit_velo <- renderText({
    sprintf("Exit Velo: %s", input$exit_velo)
  })
  output$selected_throw_velo <- renderText({
    sprintf("Throw Velo: %s", input$throw_velo)
  })
}

shinyApp(ui, server)