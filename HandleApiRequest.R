Sys.setenv(OPENAI_API_KEY = "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")

library(httr)
library(jsonlite)

sendGptApiRequest <- function(llmSystemPrompt, llmUserPrompt)
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
      message_output <- data$output[sapply(data$output, function(x) x$type == "message")]$content[[1]]$text
      
      if (length(message_output) > 0) {
        cat(message_output[[1]]$text)
      } else {
        cat("No message output found.\n")
      }
      break
    } else if (data$status == "failed") {
      cat("Job failed.\n")
      if (!is.null(data$error)) {
        cat("🔍 Error message: ", data$error$message, "\n")
        cat("🔢 Error type: ", data$error$type, "\n")
      } else {
        cat("⚠️ No detailed error info provided.\n")
      }
      stop("Deep Research failed.")
    }
  }
}
