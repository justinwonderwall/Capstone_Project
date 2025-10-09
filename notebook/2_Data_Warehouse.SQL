
-- 1. clean setup)

DROP TABLE IF EXISTS fact_table CASCADE;
DROP TABLE IF EXISTS dim_foe CASCADE;
DROP TABLE IF EXISTS dim_fundingcluster CASCADE;
DROP TABLE IF EXISTS dim_course CASCADE;

-- 2. CREATE DIMENSION TABLES

-- FOE (Field of Education) Dimension Table
CREATE TABLE dim_foe (
    foe_code INTEGER PRIMARY KEY,
    foe_name VARCHAR(255) NOT NULL
);

-- Funding Cluster Dimension Table
CREATE TABLE dim_fundingcluster (
    cluster_code INTEGER PRIMARY KEY,
    funding_cluster VARCHAR(50) NOT NULL
);

-- Course Dimension Table
CREATE TABLE dim_course (
    course_id INTEGER PRIMARY KEY,
    course_type VARCHAR(100) NOT NULL
);

-- 3. CREATE FACT TABLE

-- CSP Student Funding Fact Table
CREATE TABLE fact_table (
    foe_code INTEGER NOT NULL,
    cluster_code INTEGER,
    course_id INTEGER,
    eftsl DECIMAL(10,4) NOT NULL,
    csp_student_contribution DECIMAL(12,2) DEFAULT 0.00,
    csp_commonwealth_contribution DECIMAL(12,2) DEFAULT 0.00,
    
    -- Foreign Key Constraints
    CONSTRAINT fk_fact_foe 
        FOREIGN KEY (foe_code) REFERENCES dim_foe(foe_code),
    CONSTRAINT fk_fact_cluster 
        FOREIGN KEY (cluster_code) REFERENCES dim_fundingcluster(cluster_code),
    CONSTRAINT fk_fact_course 
        FOREIGN KEY (course_id) REFERENCES dim_course(course_id)
);


-- 4. DATA IMPORT COMMANDS

-- Import Dimension Tables from CSV files
-- Note: Make sure CSV files are accessible to PostgreSQL server

-- Import FOE Dimension
COPY dim_foe
FROM '/Users/justin/Desktop/Workplace/Work/uwa/2025-s2/5553/Project/data test/data/processed/dim_foe.csv'
DELIMITER ','
CSV HEADER;

-- Import Funding Cluster Dimension
COPY dim_fundingcluster
FROM '/Users/justin/Desktop/Workplace/Work/uwa/2025-s2/5553/Project/data test/data/processed/dim_fundingcluster.csv'
DELIMITER ','
CSV HEADER;

-- Import Course Dimension
COPY dim_course
FROM '/Users/justin/Desktop/Workplace/Work/uwa/2025-s2/5553/Project/data test/data/processed/dim_course.csv'
DELIMITER ','
CSV HEADER;

-- Import Fact Table
COPY fact_table
FROM '/Users/justin/Desktop/Workplace/Work/uwa/2025-s2/5553/Project/data test/data/processed/fact_table.csv'
DELIMITER ','
CSV HEADER;

