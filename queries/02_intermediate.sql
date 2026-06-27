-- Average length of stay by medical condition
WITH hospital_stay AS (
  SELECT medical_condition, (discharge_date - date_of_admission) AS stay
  FROM healthcare_dataset
)
SELECT medical_condition, ROUND(AVG(stay), 1) AS avg_stay_len
FROM hospital_stay
GROUP BY medical_condition
ORDER BY avg_stay_len DESC;

-- Patient count and average billing by age bracket
SELECT
  CASE WHEN age BETWEEN 0 AND 18 THEN '0-18'
       WHEN age BETWEEN 19 AND 35 THEN '19-35'
       WHEN age BETWEEN 36 AND 50 THEN '36-50'
       WHEN age BETWEEN 51 AND 65 THEN '51-65'
       ELSE '65+'
  END AS age_group,
  COUNT(*) AS no_of_patient,
  ROUND(AVG(billing_amount), 2) AS avg_bill_amt
FROM healthcare_dataset
GROUP BY age_group
ORDER BY no_of_patient DESC;

-- Top 10 doctors by patient count and average billing
SELECT 
  doctor, COUNT(*) AS no_of_patients, 
  ROUND(AVG(billing_amount), 2) AS avg_bill_amount
FROM healthcare_dataset
GROUP BY doctor
ORDER BY no_of_patients DESC
LIMIT 10;

-- Percentage breakdown of test results by medical condition
SELECT 
  medical_condition,
  test_results,
  COUNT(*) AS total_results,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY medical_condition), 2) AS percentage
FROM healthcare_dataset
GROUP BY medical_condition, test_results
ORDER BY medical_condition, percentage DESC;

-- Hospital with highest total billing revenue and unique doctor count
SELECT
  hospital,
  SUM(billing_amount) AS highest_total_bill,
  COUNT(DISTINCT doctor) AS no_of_unique_doctors
FROM healthcare_dataset
GROUP BY hospital
ORDER BY highest_total_bill DESC
LIMIT 1;


