# Pizza-Delivery-Operations-Analysis-Revenue-Optimization
## 1. Background & Business Context
Pizza Runner is an emerging Uber-like food delivery startup. However, scaling operations requires solid data foundations. The raw data collected from the mobile app and dispatch system was highly unstructured and contained numerous anomalies. 

This project aims to clean and analyze the startup's multi-relational operational data. The primary focus is on tracking **service performance**, proactively identifying **operational gaps** in the preparation workflows, and generating **actionable insights** to optimize fleet logistics and net profitability.

## 2. Tech Stack & Techniques
* **Database:** PostgreSQL 
* **Core Techniques:** 
  * Data Cleansing & Transformation (Handling `'null'` text, formatting measurement units)
  * Array Manipulation (`string_to_array`, `unnest`)
  * Advanced SQL (Common Table Expressions - CTEs, Window Functions, Aggregate Functions, Cross Apply)
  * Database Schema Design & Scalability Assessment

## 3. Entity Relationship Diagram (ERD)
The database schema consists of 6 normalized tables handling runners, customer orders, runner dispatches, pizza names, recipes, and toppings.

![Pizza Runner ERD](https://github.com/PhanVuDucTrung/Pizza-Delivery-Operations-Analysis-Revenue-Optimization/blob/main/erd/Pizza_Shop_Database_ERD.png)


## 4. Data Quality Assessment & Cleansing
Before generating business reports, the raw dataset required rigorous cleansing to ensure readiness for statistical analysis:
* **Standardizing Null Values:** Addressed records where missing data was inputted as the text string `'null'` or empty strings (`''`) using `CASE WHEN` and `TRIM()`.
* **Unit Formatting:** Stripped inconsistent text characters like `km`, `mins`, and `minutes` from the `distance` and `duration` columns, casting them into `FLOAT` data types for accurate mathematical aggregations.
* **Array Conversions:** Transformed comma-separated strings in `exclusions` and `extras` columns into SQL arrays (`int[]`) using `string_to_array()` to enable advanced ingredient-level analysis.

## 5. Key Actionable Insights & Business Impact
Aligning with the core objectives of operations excellence, the SQL analysis generated the following insights:

### A. Service Performance & Fleet Logistics
* **Runner Speed Anomalies:** Tracked the moving speed of delivery partners. Discovered a critical safety anomaly where Runner 2 exceeded 90+ km/h (reaching 93.6 - 94 km/h) during late-night deliveries, highlighting an operational risk that requires immediate training.
* **Fulfillment Rates:** Calculated the exact successful delivery percentage for each runner (**Runner 1: 100%, Runner 2: 75%, Runner 3: 50%**) to evaluate fleet reliability.
* **Delivery Variance:** Evaluated delivery durations and distances, finding a significant **30-minute variance** between the longest and shortest delivery times.

### B. Operational Gaps & Process Enhancements
* **Preparation Bottlenecks:** Analyzed the relationship between order size and kitchen preparation time. Identified that while preparation time generally increases with the number of pizzas, the trend is inconsistent, indicating an **operational gap** in kitchen efficiency.
* **Automated Kitchen Display System (KDS):** Engineered a data-driven **process enhancement** by using SQL string aggregation (`STRING_AGG`) to translate complex customer exclusions and extras into human-readable KDS receipts (e.g., *"Meatlovers - Exclude Cheese - Extra Bacon"*). This automation minimizes human error in preparation workflows.

### C. Unit Economics & Revenue Optimization
* **Profitability Simulation:** Evaluated the baseline gross revenue (**$138**) and simulated a pricing strategy (adding a $1 surcharge for extra toppings), projecting an increase in total revenue to **$142**.
* **Logistics Costs Tracking:** Calculated the leftover net profit (**$73.38**) after deducting a **$0.30/km** compensation fee for runners, providing visibility into the actual unit economics of long-distance deliveries.
* **360-Degree Service View:** Designed and implemented a new relational schema (`runner_ratings`) to capture post-delivery customer feedback, consolidating it with operational metrics (speed, duration) to support continuous improvement.

## 📁 6. Repository Guide
* `sql`:
   > `database_setup.sql`: scripts to create the database schema and insert raw data
   
   > `data_cleaning.sql`: Scripts handling messy text formats, null handling, and array conversions
   
   > `Analysis.sql`: The core analytics script answering business questions logical
* `erd`: entities relationshop diagram
