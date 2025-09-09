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
|   |   |-- ... (other raw data files)
|   |-- /processed
|       |-- dim_funding.csv
|       |-- dim_unit.csv
|       |-- ... (other processed data files)
|-- /document
|   |-- 2024 indexed rates.pdf
    |-- ... (other files)
|-- /notebook
|   |-- data_test.ipynb
    |-- ... (other files)
|-- README.md
```

* **/data/raw**: Contains the original, unmodified data files.
* **/data/processed**: Contains the cleaned and transformed data (fact and dimension tables) ready for analysis.
* **/notebooks**: Contains the Jupyter Notebook with all the ETL code.
* **README.md**: This file, providing an overview of the project.

## Data Sources

The raw data for this project is located in the `/data/raw/` folder and includes the following files:

* `students.csv`: Contains basic student enrollment information, such as course IDs, unit IDs, etc.
* `government.xlsx`: Contains government funding standards and classification information for different fields of education.
* *(Other potential data sources)*

## ETL Process Overview

All data processing and transformation logic is executed within the `/notebooks/1_ETL_Pipeline.ipynb` Jupyter Notebook. The main steps include:

1. **Extract**: Load data from various source files (CSV, Excel) into Pandas DataFrames.
2. **Transform**:
   * **Cleaning**: Handle missing values and duplicates values, standardize column names, Normalnize column values.
   * **Split columns**: Derive new columns from existing ones, such as splitting `funding_group` into `funding_nationality` and `funding_type`, and calculating the core business metric `total_funding` using vectorized operations.
   * **Data Type Unification**: Ensure that ID and currency fields are converted to the correct `int` types.
   * **Integration**: Merge the cleaned student data with the government funding data.
3. **Load**: Based on the Star Schema design principle, create fact and dimension tables and export them as `.csv` files to the `/data/processed/` folder.

## Data Model: Fact and Dimension Tables

To enable efficient and flexible analysis in Power BI, the data is structured as a Star Schema, consisting of a central fact table and multiple dimension tables.

### Dimension Tables

Dimension tables provide the **context** for business events. They contain descriptive attributes used for filtering, grouping, and slicing the data.

The following dimension tables were created for this project:

* **`dim_course`**: **Course Dimension Table**
  * **Purpose**: Describes the detailed information for Course.
  * **Key Fields**: `course_info_id` (Primary Key), `couser_type_borad`, `unit_id`, `unit_level_code`, `unit_level_name`.


* **`dim_funding`**: **Funding Dimension Table**
  * **Purpose**: Describes the detailed information for each Field of Course.
  * **Key Fields**: `funding_id` (Primary Key), `funding_cluster`, `funding_nation`, `funding_type`.

* **`dim_foe`**: **FOE Dimension Table**
  * **Purpose**: Describes FOE information.
  * **Key Fields**: `foe_id` (Primary Key), `foe_detailed`, `foe_narrow`, `foe_broad`,`is_funding_cluster_variable`,`special_course_code`,`max_contrib_indicator`.
  * **Notion:** these data from government dataset, as it has more complete information



### Fact Table

The fact table stores the **measures** of business events. It contains numeric data that can be aggregated.

* **`fact_table`**: **Student Enrollment Fact Table**
  * **Purpose**: Records the **quantifiable facts** of the core event of [need more infro] in a course unit.
  * **Key Fields**: `course_id`,`course_info_id` (Foreign Key), `funding_id` (Foreign Key), `foe_code`,`foe_id` (Foreign Key), `eftsl_2024` (Measure), `max_student_contrib_2024`(Measure),
  `commonwealth_contrib_2024`(Measure), `max_student_contrib_gf_2024`(Measure),
  `commonwealth_contrib_gf_2024`(Measure), `stud_payment` (Measure),`gov_payment` (Measure),`total_payment` (Measure).

## Final Deliverables

The final output of the ETL process is a series of CSV files located in the `/data/processed/` folder. These files are clean, structured, and ready to be imported into Power BI for modeling and analysis.

* `dim_course.csv`
* `dim_funding.csv`
* `dim_foe.csv`
* `fact_table.csv`

## How to Use

1. Ensure you have a Python environment with the necessary libraries installed (Pandas, Numpy).
2. Place the raw data files in the `/data/raw/` directory.
3. Open and run all cells in the `/notebooks/data_test.ipynb` notebook in sequential order.
4. The processed data will be automatically saved in the `/data/processed/` folder.
5. In Power BI, use "Get Data" -> "Text/CSV" to import these processed files and build the data model based on the fact and dimension table relationships.
"""


