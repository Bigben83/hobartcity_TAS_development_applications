require 'nokogiri'
require 'open-uri'
require 'sqlite3'
require 'logger'

# Initialize the logger
logger = Logger.new(STDOUT)

# Define the URL for the portal (PlanBuild TAS)
search_url = 'https://portal.planbuild.tas.gov.au/external/advertisement/search'

# Step 1: Fetch the page content using open-uri
begin
  logger.info("Fetching page content from: #{search_url}")
  page_html = open(search_url).read
  logger.info("Successfully fetched page content.")
rescue => e
  logger.error("Failed to fetch page content: #{e}")
  exit
end

# Step 2: Parse the page content using Nokogiri
doc = Nokogiri::HTML(page_html)

# Step 3: Initialize the SQLite database
db = SQLite3::Database.new "data.sqlite"

# Create a table to store the results
db.execute <<-SQL
  CREATE TABLE IF NOT EXISTS advertisement_data (
    id INTEGER PRIMARY KEY,
    address TEXT,
    council_reference TEXT
  );
SQL

# Step 4: Extract advertisement results
advertisement_results = doc.css('#advertisement-search-results .advertisement-result-row')

advertisement_results.each do |result|
  # Extract the address and council reference
  address = result.css('.col-xs-8').text.strip
  council_reference = result.css('.col-xs-4').text.strip

  # Insert the extracted data into the database
  db.execute("INSERT INTO advertisement_data (address, council_reference) VALUES (?, ?)",
             [address, council_reference])

  logger.info("Data for #{address} (Council Reference: #{council_reference}) saved to database.")
end

logger.info("Scraping completed and all data saved to data.sqlite.")
