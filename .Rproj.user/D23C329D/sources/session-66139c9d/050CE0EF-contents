# Start with the Plumber image
FROM rstudio/plumber:latest

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev

# Install R Big Data libraries
RUN R -e "install.packages(c('duckdb', 'dplyr', 'dbplyr'))"

# Create App Directory
WORKDIR /app

# Copy Data and Code
# (In production, you'd mount data as a volume, but for this portfolio copy it in)
COPY data /app/data
COPY script.R /app/script.R
COPY main.R /app/main.R
COPY static /app/static

EXPOSE 8000

CMD ["Rscript", "main.R"]