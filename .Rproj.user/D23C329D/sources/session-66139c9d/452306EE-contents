library(plumber)

# Create the router
r <- pr("script.R")

# Get the PORT from the cloud environment (Render sets this automatically).
# If it's missing (like on your laptop), default to 8000.
port <- as.numeric(Sys.getenv("PORT", "8000"))

print(paste("Server starting on port", port))

# Run
r$run(host = "0.0.0.0", port = port)