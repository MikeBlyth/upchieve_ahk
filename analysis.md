# Scan Log Analysis Toolkit

This document provides a summary of the scripts used to analyze the `scan.log` file. The toolkit is designed to parse the raw log data, store it in a structured format, and then generate a statistical report.

## Components

The toolkit consists of two main Ruby scripts and one SQLite database file.

### 1. `create_database.rb`

*   **Purpose**: This script is responsible for reading the raw `scan.log` file, cleaning and structuring the data, and loading it into an SQLite database (`scan_analysis.db`). It serves as the data processing and import tool.

*   **Technique**:
    *   **Log Parsing**: The script reads `scan.log` line by line and uses regular expressions to identify three types of entries: the start of a monitoring period, the end of a monitoring period, and a student help request.
    *   **Format Handling**: It is designed to handle two different log formats for student requests: one with a `|` separator and no waiting time, and another with a comma-separated waiting time.
    *   **Burst Filtering**: To handle scenarios where a class might test the system simultaneously, the script includes a "burst detection" feature. It ignores all requests for a specific topic if 4 or more requests for that same topic occur within a 90-second window. Once a burst is detected for a topic, no more requests are recorded for that topic until a 4-minute quiet period has passed.
    *   **Database Storage**: The processed data is stored in two tables within the `scan_analysis.db` database:
        *   `monitoring_periods`: Stores the start and end times of each monitoring session.
        *   `student_requests`: Stores details for each valid student request, including timestamp, name, subject, and waiting time.

### 2. `analyze_scan_log.rb`

*   **Purpose**: This script connects to the `scan_analysis.db` database to perform several analyses and prints a summary report to the console.

*   **Technique**:
    *   The script executes a series of SQL queries against the database to calculate the following metrics:
        *   **Requests per Hour**: Total number of requests for each hour of the day.
        *   **Requests per Day**: Total number of requests for each day of the week.
        *   **Normalized Requests per Day**: The number of requests on a given day of the week, normalized per 12 hours of scan time.
        *   **Average Waiting Time**: The average waiting time in seconds, grouped by subject.
        *   **Median Waiting Time by Subject**: The median waiting time in seconds, grouped by subject.
        *   **Median Waiting Time by Hour**: The median waiting time in seconds, grouped by hour of the day.
        *   **Hourly Request Density**: The number of requests per hour, normalized by the total time the system was being monitored during that hour. This provides a more accurate measure of request density.

### 3. `scan_analysis.db`

*   **Purpose**: This is the SQLite database file that stores the structured data from the log file. By having the data in a database, it can be easily queried for ad-hoc analysis using any standard SQLite tool, without needing to re-parse the raw log file each time.

## Usage

1.  **Create/Update the Database**: To process the `scan.log` file and populate the database, run the following command:
    ```sh
    ruby create_database.rb
    ```
2.  **Generate Analysis Report**: To view the statistical report, run the following command:
    ```sh
    ruby analyze_scan_log.rb
    ```
