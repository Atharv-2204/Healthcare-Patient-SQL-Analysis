-- Total patients and average billing amount
SELECT COUNT(*) AS total_patients, ROUND(AVG(billing_amount), 2) AS avg_billing_amt
FROM healthcare_dataset;

--Distribution of patients by gender and blood type
SELECT gender, blood_type, COUNT(*) AS no_of_patients
FROM healthcare_dataset
GROUP BY gender, blood_type
ORDER BY no_of_patients DESC;

--Most frequently apperaring top 5 medical conditions
SELECT medical_condition, COUNT(*) AS no_of_patients
FROM healthcare_dataset
GROUP BY medical_condition
ORDER BY no_of_patients DESC
LIMIT 5;

--Most pateients handler insurance_provider and average billing amount of patients
SELECT insurance_provider, COUNT(*) AS no_of_patients, ROUND(AVG(billing_amount),2) AS avg_bill_amt
FROM healthcare_dataset
GROUP BY insurance_provider
ORDER BY no_of_patients DESC;

--Total patients by admission type
SELECT admission_type, COUNT(*) AS no_of_patients
FROM healthcare_dataset
GROUP BY admission_type
ORDER BY no_of_patients DESC;