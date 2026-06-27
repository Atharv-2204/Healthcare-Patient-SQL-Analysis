-- Rank medical conditions by total billing revenue within each hospital
SELECT hospital,
medical_condition,
total_bill_revenue
FROM (SELECT hospital,
             medical_condition,
             SUM(billing_amount) AS total_bill_revenue,
             RANK() OVER(PARTITION BY hospital
             ORDER BY SUM(billing_amount) DESC)
      FROM healthcare_dataset
      GROUP BY hospital, medical_condition
      ) ranked
WHERE rank = 1
ORDER BY hospital;

-- Month-over-month admission trend
WITH monthly_admission AS (
  SELECT DATE_TRUNC('month', date_of_admission) AS admission_month,
         COUNT(*) AS total_admissions
  FROM healthcare_dataset
  GROUP BY admission_month
),
with_lag AS (
  SELECT admission_month,
         total_admissions,
         LAG(total_admissions) OVER (ORDER BY admission_month) AS previous_admissions
  FROM monthly_admission
)
SELECT admission_month,
       total_admissions,
       previous_admissions,
       total_admissions - previous_admissions AS admission_change,
       CASE WHEN previous_admissions IS NULL THEN 'No previous month'
            WHEN total_admissions > previous_admissions THEN 'increasing'
            WHEN total_admissions < previous_admissions THEN 'decreasing'
            ELSE 'no change'
       END AS trend
FROM with_lag
ORDER BY admission_month;

-- Patients billed significantly above their condition's average
WITH condition_avg AS (
  SELECT
    medical_condition,
    ROUND(AVG(billing_amount), 2) AS avg_billing_for_condition
  FROM healthcare_dataset
  GROUP BY medical_condition
)
SELECT
  h.name,
  h.medical_condition,
  h.billing_amount,
  c.avg_billing_for_condition,
  ROUND(h.billing_amount - c.avg_billing_for_condition, 2) AS amount_above_avg
FROM healthcare_dataset h
JOIN condition_avg c ON h.medical_condition = c.medical_condition * 1.5
WHERE h.billing_amount > c.avg_billing_for_condition
ORDER BY amount_above_avg DESC
LIMIT 20;

-- Doctor's repeat patient rate (patients admitted more than once)
WITH patient_visits AS (
  SELECT
    doctor,
    name,
    COUNT(*) AS visit_count
  FROM healthcare_dataset
  GROUP BY doctor, name
),
doctor_summary AS (
  SELECT
    doctor,
    COUNT(*) AS total_unique_patients,
    SUM(CASE WHEN visit_count > 1 THEN 1 ELSE 0 END) AS repeat_patients
  FROM patient_visits
  GROUP BY doctor
)
SELECT
  doctor,
  total_unique_patients,
  repeat_patients,
  ROUND(repeat_patients * 100.0 / total_unique_patients, 1) AS repeat_rate_pct
FROM doctor_summary
WHERE total_unique_patients >= 10
ORDER BY repeat_rate_pct DESC
LIMIT 10;

-- Segment patients into High/Medium/Low cost using NTILE
WITH cost_segments AS (
  SELECT
    name,
    medical_condition,
    billing_amount,
    NTILE(4) OVER (ORDER BY billing_amount) AS quartile
  FROM healthcare_dataset
),
labeled AS (
  SELECT
    medical_condition,
    CASE
      WHEN quartile = 4 THEN 'High Cost'
      WHEN quartile IN (2,3) THEN 'Medium Cost'
      ELSE 'Low Cost'
    END AS cost_segment,
    CASE
      WHEN quartile = 4 THEN 1
      WHEN quartile IN (2,3) THEN 2
      ELSE 3
    END AS segment_order,
    billing_amount
  FROM cost_segments
)
SELECT
  medical_condition,
  cost_segment,
  COUNT(*) AS patient_count,
  ROUND(AVG(billing_amount), 2) AS avg_billing
FROM labeled
GROUP BY medical_condition, cost_segment, segment_order
ORDER BY medical_condition, segment_order;

-- Readmission Risk Score: Emergency + Abnormal result + above-average stay
WITH stay_avg AS (
  SELECT ROUND(AVG(discharge_date - date_of_admission), 1) AS avg_stay
  FROM healthcare_dataset
),
patient_risk AS (
  SELECT
    h.name,
    h.medical_condition,
    h.admission_type,
    h.test_results,
    (h.discharge_date - h.date_of_admission) AS stay_length,
    s.avg_stay,
    CASE
      WHEN h.admission_type = 'Emergency'
        AND h.test_results = 'Abnormal'
        AND (h.discharge_date - h.date_of_admission) > s.avg_stay
      THEN 'High Risk'
      WHEN h.admission_type = 'Emergency'
        AND h.test_results = 'Abnormal'
      THEN 'Medium Risk'
      ELSE 'Low Risk'
    END AS readmission_risk
  FROM healthcare_dataset h
  CROSS JOIN stay_avg s
)
SELECT
  readmission_risk,
  COUNT(*) AS patient_count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct_of_total
FROM patient_risk
GROUP BY readmission_risk
ORDER BY patient_count DESC;