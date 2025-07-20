source("openAIAPIKey.R")
Sys.setenv(OPENAI_API_KEY = openAiAPIKey)

library(httr)
library(jsonlite)

# There's no wrapper for the OpenAI API suitable for using the deep research models, so we directly send the request.

buildGptApiRequest <- function(llmSystemPrompt, llmUserPrompt)
{
  # Build input payload
  payload <- list(
    model = "o4-mini-2025-04-16",
    input = list(
      list(
        role = "developer",
        content = list(
          list(
            type = "input_text",  
            text = llmSystemPrompt
          )
        )
      ),
      list(
        role = "user",
        content = list(
          list(
            type = "input_text",  
            text = llmUserPrompt
          )
        )
      )
    ),
    tools = list(
      list(type = "web_search_preview")
    ),
    reasoning = list(
      summary = "auto"
    ),
    background=TRUE
  )
  
  json_payload <- toJSON(payload, auto_unbox = TRUE, pretty = TRUE)
  
  # Make request
  res <- POST(
    url = "https://api.openai.com/v1/responses",
    add_headers(
      Authorization = paste("Bearer", Sys.getenv("OPENAI_API_KEY")),
      `Content-Type` = "application/json"
    ),
    body = json_payload,
    encode = "json"
  )
  return(res)
}


sendGptApiRequest <- function(llmSystemPrompt, llmUserPrompt)
{

  res <- buildGptApiRequest(llmSystemPrompt, llmUserPrompt)
  stop_for_status(res)
  job <- content(res, as = "parsed")
  job_id <- job$id
  
  repeat {
    Sys.sleep(5)
    
    poll <- GET(
      paste0("https://api.openai.com/v1/responses/", job_id),
      add_headers(Authorization = paste("Bearer", Sys.getenv("OPENAI_API_KEY")))
    )
  
    stop_for_status(poll)
    data <- content(poll, as = "parsed")
    cat("Status:", data$status, "\n")
    
    if (data$status == "completed") {
      message_output <- data$output[sapply(data$output, function(x) x$type == "message")][[1]]$content[[1]]$text
      
      if (length(message_output) > 0) {
        cat(message_output)
      } else {
        cat("No message output found.\n")
      }
      break
    } else if (data$status == "failed") {
      cat("Job failed.\n")
      if (!is.null(data$error)) {
        cat("Error message: ", data$error$message, "\n")
     
      }
      stop()
    }
  }
}
