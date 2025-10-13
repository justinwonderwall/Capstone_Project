# Harnessing Big Data to Improve Financial Integrity and Operational Efficiency Project

## Project Overview

The aim of this project is to perform a comprehensive ETL (Extract, Transform, Load) process on student course, tuition fee, and government funding data from the University of Western Australia (UWA). The final objective is to generate a clean, standardized dataset suitable for business intelligence analysis. This dataset will be imported into Power BI to build a data model and create visualization dashboards, providing insights into student enrollment, fee structures, and funding allocation.


## Project Structure

The project is organized into the following directory structure:

```
/Capstone_project
|-- /data
|   |-- /raw
|   |   |-- students.csv
|   |   |-- government.xlsx
|   |-- /processed
|       |-- ... (other processed data files)
|-- /document
|   |-- 2024 indexed rates.pdf
    |-- ... (other files)
|-- /notebook
|   |-- 1_ETL_Pipeline.ipynb
    |-- 2_Data_Warehouse.ipynb
    |-- 3_Data_Modelling.ipynb
|-- README.md
```

* **/data/raw**: Contains the original, unmodified data files.
* **/data/processed**: Contains the cleaned and transformed data (fact and dimension tables) ready for analysis.
* **/notebooks**: Contains the Jupyter Notebook with ETL, Date warehouse, data modeling code.
* **README.md**: This file, providing an overview of the project.

## Data Sources

The raw data for this project is located in the `/data/raw/` folder and includes the following files:

* `students.csv`: Contains basic student enrollment information, such as course IDs, unit IDs, etc.
* `government.xlsx`: Contains government funding standards and classification information for different fields of education.

The data presented in this report is exclusively for the purposes of this project and must not be used or referenced for any other project or application. 

## ETL Process Overview

All data processing and transformation logic is executed within the `/notebooks/1_ETL_Pipeline.ipynb` Jupyter Notebook. The main steps include:

1. **Extract**: Load data from various source files (CSV, Excel) into Pandas DataFrames.
2. **Transform**:
   * **Cleaning**: Handle missing values and duplicates values, standardize column names, and normalize column values.
   * **Split columns**: Derive new columns from existing ones, such as splitting `funding_group` into `funding_nationality` and `funding_type`, and calculating the core business metric `total_funding` using vectorized operations.
   * **Data Type Unification**: Ensure that ID and currency fields are converted to the correct `int` types.
   * **Integration**: Merge the cleaned student data with the government funding data.
   **Create Error Flag**
   * **FOE Error**: The FOE codes appear only in the student dataset.
   * **EFTSL Error**: Overloaded 1 if EFTSL > 3 else 0. 
3. **Load**: Merge data Based on FOE code, save as `.csv` files to the `/data/processed/` folder.

## Data Warehouse 

**Fact and Dimension Tables**
// **adjust based on design**
To enable efficient and flexible analysis in Power BI, the data is structured as a Star Schema, consisting of a central fact table and multiple dimension tables.

### Dimension Tables

Dimension tables provide the **context** for business events. They contain descriptive attributes used for filtering, grouping, and slicing the data.

The following dimension tables were created for this project:

* **`dim_course`**: **Course Dimension Table**
  * **Purpose**: Describes the detailed information for Course.
  * **Key Fields**: `course_id` (Primary Key), `couser_type_borad`.

* **`dim_fundingcluster`**: **Funding Dimension Table**
  * **Purpose**: Describes the detailed information for each funding cluster.
  * **Key Fields**: `cluster_code` (Primary Key), `funding_cluster`.

* **`dim_foe`**: **FOE Dimension Table**
  * **Purpose**: Describes FOE information.
  * **Key Fields**: `foe_code` (Primary Key), `FOE_name`.

### Fact Table

The fact table stores the **measures** of business events. It contains numeric data that can be aggregated.

* **`fact_table`**: **Student Enrollment Fact Table**
  * **Purpose**: Records the **quantifiable facts** of the core event of [need more infro] in a course unit.
  * **Key Fields**: `course_id`, (Foreign Key), `cluster_code` (Foreign Key), `foe_code`,(Foreign Key), `eftsl_2024` (Measure), `CSP_student_contribution`(Measure),
  `CSP_commonwealth_contribution`(Measure).

## Final Deliverables

The final output of the ETL process is a series of CSV files located in the `/data/processed/` folder. These files are clean, structured, and ready to be imported into Power BI for modeling and analysis.

* `dim_course.csv`
* `dim_.csv`
* `dim_foe.csv`
* `fact_table.csv`

## Data Modelling
Two Models are built for the data modelling part which are Logistic Regression, a simple linear model, provides clear interpretability and helps identify which features most strongly influence discrepancies. XGBoost, an advanced tree-based ensemble method, captures more complex and nonlinear relationships within the data. 

## Data Visualization
The data visualization was built by Power BI, which connects the PostgreSQL database automated.
Including：
**2024 EFTSL Overview:** Focuses on the total student Equivalent Full-Time Student Load (EFTSL) by key dimensions such as nationality, Degree Level, and Fee Type. This dashboard provides a comprehensive and interactive view of the EFTSL distribution. 
**2024 CSP Student Overview:** Focuses on students in Commonwealth Supported Place, visualizing Government Payment distribution by Course, unit, FOE, and Funding Cluster. This is primary     dashboard to identify key patterns and discrepancies between internal payment data and external data sources.   

## How to Use

1. Ensure you have a Python environment with the necessary libraries installed.
2. Place the raw data files in the `/data/raw/` directory.
3. Open and run all cells in the `/notebook/1._ETL_Pipeline.ipynb` notebook in sequential order.
4. The processed data will be automatically saved in the `/data/processed/` folder.
5. In Power BI, use "Get Data" -> "Text/CSV" to import these processed files and build the data model based on the fact and dimension table relationships.

