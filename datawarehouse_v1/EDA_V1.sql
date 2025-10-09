---EDA---
select * from fact.enrolment_2024; 
select * from raw.csp_allocation_2024;
select * from dim.funding_cluster;
select * from dim.foe;
select * from raw.student_enrolments_2024;
---
SELECT
  COALESCE(ca.funding_cluster, 'All Clusters') AS funding_cluster,
  COUNT(*)                             AS count,
  SUM(e.eftsl)                         AS total_eftsl,
  SUM(e.student_contribution)          AS sum_student_contribution,
  SUM(e.commonwealth_contribution)     AS sum_gov_contribution,
  SUM(e.tuition_amount)                AS total_tuition
FROM fact.enrolment_2024 e
LEFT JOIN raw.csp_allocation_2024 ca
  ON ca.foe_code = e.foe_code
GROUP BY ROLLUP(ca.funding_cluster)
ORDER BY funding_cluster;

--- checking the missing special case---

SELECT r.*
FROM raw.student_enrolments_2024 r
LEFT JOIN dim.foe d ON r.unit_primary_foe_code = d.foe_code
WHERE d.foe_code IS NULL;

--checking the missing special case with total eftsl --
SELECT 
    COUNT(*) AS n_rows,
    SUM(r.eftsl_2024) AS total_eftsl
FROM raw.student_enrolments_2024 r
LEFT JOIN dim.foe d 
    ON r.unit_primary_foe_code = d.foe_code
WHERE d.foe_code IS NULL;


---checking the overload student ---
SELECT
  COUNT(*) AS student_count_over3,
  SUM(e.commonwealth_contribution) AS total_csp_government_over3
FROM fact.enrolment_2024 e
WHERE e.eftsl > 3;

SELECT
  COUNT(*) AS student_count_over3,
  SUM(e.commonwealth_contribution) AS total_csp_government_over3
FROM fact.enrolment_2024 e
WHERE e.eftsl < 3;

--histogram--
SELECT eftsl, COUNT(*) FROM fact.enrolment_2024 GROUP BY eftsl ORDER BY eftsl;

--
SELECT foe_code, 
       COUNT(*) AS student_count,
       SUM(eftsl) AS total_eftsl,
       SUM(student_contribution) AS total_student_contribution,
       SUM(commonwealth_contribution) AS total_gov_contribution
FROM fact.enrolment_2024
GROUP BY foe_code
ORDER BY total_student_contribution DESC;

--- check the percentage ---

WITH base AS (
  SELECT enrol_id, foe_code, eftsl, enrol_unit,
         commonwealth_contribution AS gov,
         student_contribution     AS stu,
         (commonwealth_contribution + student_contribution) AS total_csp,
         CASE WHEN eftsl > 3 OR enrol_unit > 24 THEN 1 ELSE 0 END AS is_outlier
  FROM fact.enrolment_2024
)
SELECT
  COUNT(*)                                  AS rows_all,
  SUM(total_csp)                            AS csp_all,
  COUNT(*) FILTER (WHERE is_outlier=1)      AS rows_outlier,
  SUM(total_csp) FILTER (WHERE is_outlier=1)        AS csp_outlier,
  ROUND(100.0 * SUM(total_csp) FILTER (WHERE is_outlier=1) / NULLIF(SUM(total_csp),0), 2) AS outlier_share_pct
FROM base;

---
WITH b AS (
  SELECT enrol_id,
         (commonwealth_contribution + student_contribution) AS total_csp
  FROM fact.enrolment_2024
),
r AS (
  SELECT *,
         SUM(total_csp) OVER ()                              AS grand_total,
         SUM(total_csp) OVER (ORDER BY total_csp DESC)       AS running_total,
         ROW_NUMBER() OVER (ORDER BY total_csp DESC)         AS rn
  FROM b
)
SELECT rn AS min_rows_for_60pct
FROM r
WHERE running_total >= 0.60 * grand_total
ORDER BY rn
LIMIT 1;


--- check the outliner FOE --

--
WITH base AS (
    SELECT e.foe_code,
           e.commonwealth_contribution AS gov_csp,
           e.eftsl
    FROM fact.enrolment_2024 e
    WHERE e.eftsl > 3
)
SELECT b.foe_code,
       d.foe_name,
       c.funding_cluster,
       COUNT(*) AS n_rows,
       SUM(b.gov_csp) AS total_gov_csp,
       AVG(b.gov_csp) AS avg_gov_csp_per_student,
       AVG(b.eftsl) AS avg_eftsl
FROM base b
LEFT JOIN dim.foe d ON b.foe_code = d.foe_code
LEFT JOIN raw.csp_allocation_2024 c ON b.foe_code = c.foe_code
GROUP BY b.foe_code, d.foe_name, c.funding_cluster
ORDER BY total_gov_csp DESC
LIMIT 10;


