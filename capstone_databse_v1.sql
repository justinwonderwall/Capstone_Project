-- alter dim fee-- 
ALTER TABLE fact.enrolment_2024
DROP CONSTRAINT IF EXISTS fk_enrolment_fee;

--drop dim fee---
DROP TABLE IF EXISTS dim.fees CASCADE;



--alter dim funding cluster --
ALTER TABLE dim.funding_cluster
DROP COLUMN IF EXISTS year;

COPY dim.funding_cluster (cluster_code, cluster_name)
FROM '/tmp/dimfundingcluster.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');


--drop ref.for_cluster --
DROP TABLE IF EXISTS ref.foe_cluster CASCADE;

---alter fact table ---
ALTER TABLE fact.enrolment_2024
DROP COLUMN IF EXISTS fee_code,
DROP COLUMN IF EXISTS student_type,
DROP COLUMN IF EXISTS delivery_mode,
DROP COLUMN IF EXISTS scholarship_amount;

--- alter reference key ---
ALTER TABLE fact.enrolment_2024
DROP CONSTRAINT fk_enrolment_foe;

--- only keep csp table ---
DROP TABLE IF EXISTS raw.international_fee_schedule_2024;
DROP TABLE IF EXISTS raw.domestic_feepaying_price_2024;

--- drop agreement table ---
DROP TABLE IF EXISTS raw.funding_agreement_2024 CASCADE;

---alter table csp_allocation_2024 ---
ALTER TABLE raw.csp_allocation_2024
DROP COLUMN IF EXISTS grandfathered_max_student_contribution,
DROP COLUMN IF EXISTS grandfathered_commonwealth_contribution,
DROP COLUMN IF EXISTS special_course_typepcode,
DROP COLUMN IF EXISTS maximum_student_contribution_indicator;


select * from raw.csp_allocation_2024;
select * from enrolment_2024;

--- checking the missing special case---

SELECT r.*
FROM raw.student_enrolments_2024 r
LEFT JOIN dim.foe d ON r.unit_primary_foe_code = d.foe_code
WHERE d.foe_code IS NULL;


