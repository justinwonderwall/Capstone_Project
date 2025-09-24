-- step1：create SCHEMA
CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS stg;
CREATE SCHEMA IF NOT EXISTS dim;
CREATE SCHEMA IF NOT EXISTS ref;
CREATE SCHEMA IF NOT EXISTS fact;

ALTER DATABASE "UWA_fees" SET search_path = public, raw, stg, dim, ref, fact;

--2.1 Create the 5 RAW tables
CREATE TABLE IF NOT EXISTS raw.student_enrolments_2024 (
  row_id                  bigserial PRIMARY KEY,
  course_type_broad_name  text,
  funding_group_name      text,
  unit_id                 text,
  unit_level              text,
  unit_primary_foe_code   text,
  unit_primary_foe_detailed_name text,
  unit_primary_foe_narrow_name   text,
  unit_primary_foe_broad_name    text,
  eftsl_2024              numeric(6,3)
);

-- RAW table for the CSP allocation (export the target sheet to CSV first)
CREATE TABLE IF NOT EXISTS raw.csp_allocation_2024 (
  row_id                                   bigserial PRIMARY KEY,
  broad_discipline_foe                      text,
  narrow_discipline_foe                     text,
  detailed_discipline_foe                   text,
  funding_cluster                           text,
  max_student_contribution_2024             text,
  commonwealth_contribution_2024            text,
  Special_Course_TypePCode                  text,  -- clinical psychology flag
  Maximum_student_contribution_indicator    text,  -- contribution indicator (7/8/9)
  grandfathered_max_student_contribution    text,
  grandfathered_commonwealth_contribution   text
);
COMMENT ON TABLE raw.csp_allocation_2024 IS 'Raw CSP allocation (2024), as published by government';

-- RAW table for Funding Agreement
CREATE TABLE IF NOT EXISTS raw.funding_agreement_2024 (
  id            bigserial PRIMARY KEY,
  funding_type  text,     -- e.g. RTP Stipend / RTP Fees Offset / CGS Grant
  year          smallint,
  amount_text   text,
  notes         text
);
COMMENT ON TABLE raw.funding_agreement_2024 IS 'Raw funding agreement summary (2024), manual entries from PDF';

---International fees---
CREATE TABLE raw.international_fee_schedule_2024 (
  row_id              bigserial PRIMARY KEY,
  category_id         varchar(5),      -- '1','2','3','4','E1','E2','E3'
  delivery_mode       text,            -- On Campus / External
  fee_basis           text,            -- Annual / Weekly
  total_without_capital numeric(12,2),
  total_with_capital    numeric(12,2),
  currency            varchar(3),
  year                smallint,
  notes               text             -- free text: description like "Law/Econ/Business..."
);

---Domestic fee-paying fees---
CREATE TABLE raw.domestic_feepaying_price_2024 (
  row_id              bigserial PRIMARY KEY,
  foe_detailed_code   varchar(10),     -- align with FOE codes if possible
  description         text,           
  price_basis         text,            -- Annual / EFTSL
  annual_price        numeric(12,2),
  year                smallint
);

----dim table----
DROP TABLE IF EXISTS dim.fees CASCADE;

CREATE TABLE dim.fees (
  fee_code     varchar(40),    -- CSP / FeePaying / RTP
  student_type varchar(30),    -- Domestic / International
  year         smallint,
  PRIMARY KEY (fee_code, student_type, year) 
);

DROP TABLE IF EXISTS dim.foe CASCADE;

CREATE TABLE dim.foe (
  foe_code varchar(10) PRIMARY KEY,
  foe_name text
);
COMMENT ON TABLE dim.foe IS 'Field of Education (Detailed level only, from UnitPrimaryFOECode & Name)';

DROP TABLE IF EXISTS dim.funding_cluster CASCADE;
CREATE TABLE IF NOT EXISTS dim.funding_cluster (
  cluster_code varchar(20) PRIMARY KEY,       -- e.g. 'Funding Cluster 1'
  cluster_name text,                           -- ：Law, Accounting...
  year smallint
);


DROP TABLE IF EXISTS ref.foe_cluster;

CREATE TABLE ref.foe_cluster (
    foe_code varchar(10),          
    funding_cluster varchar(50),
    e312_rule text,
    e392_rule text,
    year smallint,
    PRIMARY KEY (foe_code, funding_cluster, year)
);


---fact table---

DROP TABLE IF EXISTS fact.enrolment_2024 CASCADE;

CREATE TABLE fact.enrolment_2024 (
  enrol_id              bigserial PRIMARY KEY,
  unit_id               varchar(20),
  foe_code              varchar(10) REFERENCES dim.foe(foe_code),
  fee_code              varchar(40),
  student_type          varchar(30),
  acad_year             smallint,
  delivery_mode         varchar(20),

  -- Measures
  eftsl                 numeric(6,3),          
  student_contribution  numeric(12,2),
  commonwealth_contribution numeric(12,2),
  tuition_amount        numeric(12,2),
  scholarship_amount    numeric(12,2),
  enrol_unit            int,

  FOREIGN KEY (fee_code, student_type, acad_year)
    REFERENCES dim.fees(fee_code, student_type, year)
);

--- import csp student data ----
COPY raw.student_enrolments_2024(
  course_type_broad_name,
  funding_group_name,
  unit_id,
  unit_level,
  unit_primary_foe_code,
  unit_primary_foe_detailed_name,
  unit_primary_foe_narrow_name,
  unit_primary_foe_broad_name,
  eftsl_2024
)
FROM '/tmp/student_enrolments_domestic_csp.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

---import csp_allocation---

COPY raw.csp_allocation_2024(
  broad_discipline_foe,
  narrow_discipline_foe,
  detailed_discipline_foe,
  funding_cluster,
  max_student_contribution_2024,
  commonwealth_contribution_2024,
  Special_Course_TypePCode,
  Maximum_student_contribution_indicator,
  grandfathered_max_student_contribution,
  grandfathered_commonwealth_contribution
)
FROM '/tmp/csp_allocation_2024.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

-- import dim.fees
COPY dim.fees (fee_code, student_type, year)
FROM '/tmp/dim_fees.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

-- import dim.foe
COPY dim.foe (foe_code, foe_name)
FROM '/tmp/dimFOE.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

ALTER TABLE ref.foe_cluster DROP CONSTRAINT foe_cluster_pkey;

ALTER TABLE ref.foe_cluster ADD COLUMN id bigserial PRIMARY KEY;


-- import ref.foe_cluster
BEGIN;

ALTER TABLE ref.foe_cluster DROP CONSTRAINT IF EXISTS foe_cluster_pkey;

ALTER TABLE ref.foe_cluster ADD COLUMN IF NOT EXISTS id bigserial PRIMARY KEY;

CREATE UNIQUE INDEX IF NOT EXISTS uq_foe_cluster_full
  ON ref.foe_cluster(foe_code, funding_cluster, e312_rule, e392_rule, year);

COMMIT;

TRUNCATE ref.foe_cluster;

COPY ref.foe_cluster(foe_code, funding_cluster, e312_rule, e392_rule, year)
FROM '/tmp/reffoe_cluster.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

SELECT foe_code, funding_cluster, e312_rule, e392_rule, year, COUNT(*)
FROM ref.foe_cluster
GROUP BY 1,2,3,4,5
HAVING COUNT(*) > 1;


--- data fact table---
--student_contribution  = se.eftsl_2024 * ca.max_student_contribution_2024
--commonwealth_contribution = se.eftsl_2024 * ca.commonwealth_contribution_2024
--tuition_amount        = student_contribution + commonwealth_contribution
--enrol_unit            = ROUND(se.eftsl_2024 / 0.125)

TRUNCATE TABLE fact.enrolment_2024 RESTART IDENTITY CASCADE;


ALTER TABLE ref.foe_cluster
ADD CONSTRAINT fk_fc_foe FOREIGN KEY (foe_code)
REFERENCES dim.foe(foe_code);

-- fact.enrolment_2024 → dim.foe
ALTER TABLE fact.enrolment_2024
ADD CONSTRAINT fk_enrolment_foe
FOREIGN KEY (foe_code)
REFERENCES dim.foe(foe_code);

-- fact.enrolment_2024 → dim.fees
ALTER TABLE fact.enrolment_2024
ADD CONSTRAINT fk_enrolment_fee
FOREIGN KEY (fee_code, student_type, acad_year)
REFERENCES dim.fees(fee_code, student_type, year);

-- ref.foe_cluster → dim.foe
ALTER TABLE ref.foe_cluster
ADD CONSTRAINT fk_fc_foe
FOREIGN KEY (foe_code)
REFERENCES dim.foe(foe_code);

-- fact.enrolment_2024  foe_code  6 
UPDATE fact.enrolment_2024
SET foe_code = lpad(trim(foe_code), 6, '0');

--  student_enrolments  FOE code  6 
UPDATE raw.student_enrolments_2024
SET unit_primary_foe_code = lpad(trim(unit_primary_foe_code), 6, '0');

--  CSP allocation foe_code  6 
UPDATE raw.csp_allocation_2024
SET foe_code = lpad(trim(foe_code), 6, '0');

-- 
UPDATE dim.foe
SET foe_code = lpad(trim(foe_code), 6, '0');







INSERT INTO fact.enrolment_2024 (
  foe_code,
  fee_code,
  student_type,
  delivery_mode,
  eftsl,
  student_contribution,
  commonwealth_contribution,
  tuition_amount,
  scholarship_amount,
  enrol_unit
)
SELECT
  se.unit_primary_foe_code AS foe_code,
  'CSP' AS fee_code,
  'Domestic' AS student_type,
  'OnCampus' AS delivery_mode,
  se.eftsl_2024 AS eftsl,
  (regexp_replace(ca.max_student_contribution_2024, '[^0-9\.]', '', 'g')::numeric * se.eftsl_2024) AS student_contribution,
  (regexp_replace(ca.commonwealth_contribution_2024, '[^0-9\.]', '', 'g')::numeric * se.eftsl_2024) AS commonwealth_contribution,
  ((regexp_replace(ca.max_student_contribution_2024, '[^0-9\.]', '', 'g')::numeric
   + regexp_replace(ca.commonwealth_contribution_2024, '[^0-9\.]', '', 'g')::numeric) * se.eftsl_2024) AS tuition_amount,
  0.00 AS scholarship_amount,
  ROUND(se.eftsl_2024 / 0.125)::int AS enrol_unit
FROM raw.student_enrolments_2024 se
JOIN raw.csp_allocation_2024 ca
  ON se.unit_primary_foe_code = ca.foe_code
JOIN dim.foe f
  ON se.unit_primary_foe_code = f.foe_code
JOIN dim.fees df
  ON df.fee_code = 'CSP'
 AND df.student_type = 'Domestic'
WHERE se.funding_group_name LIKE 'Domestic%';


ALTER TABLE fact.enrolment_2024
DROP COLUMN acad_year;

select * from fact.enrolment_2024;

SELECT COUNT(*) AS row_count
FROM fact.enrolment_2024
WHERE eftsl > 1;

SELECT COUNT(*) AS row_count,
       SUM(commonwealth_contribution) AS total_commonwealth_contribution
FROM fact.enrolment_2024
WHERE eftsl > 3;


