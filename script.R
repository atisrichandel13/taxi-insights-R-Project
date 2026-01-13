# script.R
library(plumber)
library(duckdb)
library(dplyr)

# --- DATABASE SETUP ---
print("🚀 Starting NYC Taxi Analytics Engine...")
con <- dbConnect(duckdb::duckdb())
parquet_file <- "data/taxi.parquet"
dbExecute(con, paste0("CREATE VIEW taxi AS SELECT * FROM '", parquet_file, "'"))
tbl_taxi <- tbl(con, "taxi")
print("✅ Ready.")

# --- API CONFIGURATION ---

#* @apiTitle NYC Taxi Analytics Engine

#* Enable CORS
#* @filter cors
function(res) {
  res$setHeader("Access-Control-Allow-Origin", "*")
  res$setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
  plumber::forward()
}

#* Serve the Static UI
#* @assets ./static /
list()

#* Log requests
#* @filter logger
function(req){
  cat(as.character(Sys.time()), "-", req$REQUEST_METHOD, req$PATH_INFO, "\n")
  plumber::forward()
}

# --- ENDPOINTS ---

#* Get Average Fare stats
#* @param count:int
#* @get /stats/fare
function(count = 1) {
  p_count <- as.numeric(count)
  cat(paste0("🔍 Analyzing trips with ", p_count, " passengers...\n"))
  
  result <- tbl_taxi %>%
    filter(passenger_count == p_count) %>%
    summarise(
      total_trips = n(),
      avg_tip = mean(tip_amount, na.rm = TRUE),
      avg_fare = mean(fare_amount, na.rm = TRUE)
    ) %>%
    collect()
  
  print(result)
  return(result)
}

#* Build a Linear Model (Tip ~ Distance)
#* @get /stats/model
function() {
  cat("📉 Training Linear Regression Model on sample data...\n")
  
  # 1. Filter for VALID data
  # payment_type = 1 (Credit Card only - Cash tips are not recorded!)
  # trip_distance > 0 (Remove cancelled trips)
  # trip_distance < 50 (Remove outliers/GPS errors)
  sample_data <- tbl_taxi %>%
    filter(sql("random() < 0.01")) %>% 
    filter(payment_type == 1, trip_distance > 0, trip_distance < 50) %>%
    select(trip_distance, tip_amount) %>%
    collect()
  
  # 2. Run Regression
  model <- lm(tip_amount ~ trip_distance, data = sample_data)
  
  # 3. Format the Output
  slope <- coef(model)[2]
  r2 <- summary(model)$r.squared
  
  print(summary(model))
  
  list(
    intercept = round(coef(model)[1], 4),
    slope = round(slope, 4),
    r_squared = round(r2, 4),
    # improved message logic
    message = paste0("For every extra mile, the tip increases by $", 
                     round(slope, 2))
  )
}