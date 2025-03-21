-- What is the average BMI of patients grouped by gender?
SELECT p.gender, ROUND(AVG(h.bmi),2) AS avg_bmi
FROM Hospital_Records h
JOIN Patients p ON h.patient_id = p.patient_id
GROUP BY p.gender;

-- What are the top 5 most common reasons for outpatient visits?
SELECT reason_for_visit, COUNT(*) AS visit_count
FROM Outpatient_Visits
GROUP BY reason_for_visit
ORDER BY visit_count DESC
LIMIT 5;

-- How many patients have a family history of hypertension?
SELECT family_history_of_hypertension, COUNT(*) AS patient_count
FROM Hospital_Records
GROUP BY family_history_of_hypertension;

-- What is the average hospital stay duration for each department?
SELECT department_name, ROUND(AVG(Days_in_the_hospital),1) AS avg_stay
FROM Hospital_Records
GROUP BY department_name;

-- What is the percentage of smokers among all patients?
SELECT 
    (SUM(CASE WHEN smoker_status = 'Y' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS smoker_percentage
FROM Outpatient_Visits;

-- What is the total number of appointments per department?
SELECT department_name, COUNT(*) AS total_appointments
FROM Appointments
GROUP BY department_name;

-- What is the busiest date for appointments (most scheduled visits)?
SELECT appointment_date, COUNT(*) AS appointment_count
FROM Appointments
GROUP BY appointment_date
ORDER BY appointment_count DESC
LIMIT 1;

-- How many patients have visited the hospital more than 3 times?
SELECT patient_id, COUNT(*) AS visit_count
FROM Outpatient_Visits
GROUP BY patient_id
HAVING visit_count > 3
ORDER BY visit_count DESC;

-- What are the top 3 most frequently prescribed medications?
SELECT medication_prescribed, COUNT(*) AS prescription_count
FROM Outpatient_Visits
WHERE medication_prescribed IS NOT NULL
GROUP BY medication_prescribed
ORDER BY prescription_count DESC
LIMIT 3;

-- What is the average age of patients diagnosed with hypertension?
SELECT ROUND(AVG(YEAR(CURDATE()) - YEAR(date_of_birth)),1) AS avg_age
FROM Patients p
JOIN Outpatient_Visits v ON p.patient_id = v.patient_id
WHERE v.diagnosis LIKE '%hypertension%';

-- Which department has the highest percentage of senior patients (65+ years old)?
WITH age_group AS (
    SELECT p.patient_id, department_name,
           CASE WHEN YEAR(CURDATE()) - YEAR(date_of_birth) >= 65 THEN 'Senior'
           ELSE 'Non-Senior' END AS age_category
    FROM Patients p
    JOIN Hospital_Records h ON p.patient_id = h.patient_id
)
SELECT department_name, 
       (SUM(CASE WHEN age_category = 'Senior' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS senior_percentage
FROM age_group
GROUP BY department_name
ORDER BY senior_percentage DESC
LIMIT 1;

-- Which diagnosis has the longest average hospital stay?
SELECT diagnosis, ROUND(AVG(Days_in_the_hospital),2) AS avg_days
FROM Hospital_Records h
JOIN Outpatient_Visits v ON h.patient_id = v.patient_id
GROUP BY diagnosis
ORDER BY avg_days DESC
LIMIT 1;

-- What is the correlation between BMI and hypertension?
SELECT 
    CASE 
        WHEN bmi < 18.5 THEN 'Underweight'
        WHEN bmi BETWEEN 18.5 AND 24.9 THEN 'Normal'
        WHEN bmi BETWEEN 25 AND 29.9 THEN 'Overweight'
        ELSE 'Obese'
    END AS bmi_category,
    COUNT(*) AS total_patients,
    SUM(CASE WHEN family_history_of_hypertension = 'Yes' THEN 1 ELSE 0 END) AS hypertension_cases,
    (SUM(CASE WHEN family_history_of_hypertension = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS hypertension_percentage
FROM Hospital_Records
GROUP BY bmi_category;

--  How many patients missed their scheduled appointment time by more than 30 minutes?
SELECT COUNT(*) AS missed_appointments
FROM Appointments
WHERE TIMEDIFF(admission_time, appointment_time) > '00:30:00';

-- What is the most common diagnosis among patients with a family history of hypertension?
SELECT v.diagnosis, COUNT(*) AS diagnosis_count
FROM Outpatient_Visits v
JOIN Hospital_Records h ON v.patient_id = h.patient_id
WHERE h.family_history_of_hypertension = 'Yes'
AND v.diagnosis IS NOT NULL
GROUP BY v.diagnosis
ORDER BY diagnosis_count DESC
LIMIT 1;

-- What is the average wait time between arrival and admission for each department?
SELECT department_name, 
       ROUND(AVG(TIMESTAMPDIFF(MINUTE, arrival_time, admission_time)),2) AS avg_wait_time
FROM Appointments
GROUP BY department_name
ORDER BY avg_wait_time DESC;

-- Which day of the week has the highest no-show rate (patients who never got admitted)?
SELECT DAYNAME(appointment_date) AS weekday, 
       COUNT(*) AS total_appointments,
       SUM(CASE WHEN admission_time IS NULL THEN 1 ELSE 0 END) AS no_show_count,
       (SUM(CASE WHEN admission_time IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS no_show_rate
FROM Appointments
GROUP BY weekday
ORDER BY no_show_rate DESC
LIMIT 3;

-- What is the readmission rate for patients within 30 days of their last visit?
WITH readmissions AS (
    SELECT patient_id, visit_date,
           LAG(visit_date) OVER (PARTITION BY patient_id ORDER BY visit_date) AS prev_visit_date
    FROM Outpatient_Visits
)
SELECT COUNT(*) AS readmission_count, 
       (COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Outpatient_Visits)) AS readmission_rate
FROM readmissions
WHERE DATEDIFF(visit_date, prev_visit_date) <= 30;

-- Which diagnosis has the highest re-occurrence rate within 6 months?
WITH diagnosis_reoccurrence AS (
    SELECT 
        patient_id, 
        diagnosis, 
        visit_date,
        COALESCE(LAG(visit_date) OVER (PARTITION BY patient_id, diagnosis ORDER BY visit_date), visit_date) AS last_diagnosis_date
    FROM Outpatient_Visits
)
SELECT 
    diagnosis, 
    COUNT(*) AS recurrence_count
FROM diagnosis_reoccurrence
WHERE DATEDIFF(visit_date, last_diagnosis_date) <= 180
AND diagnosis IS NOT NULL  -- Ensuring only valid diagnoses
GROUP BY diagnosis
ORDER BY recurrence_count DESC
LIMIT 1;

-- What percentage of patients have at least one chronic disease (hypertension, diabetes, heart disease)?
SELECT 
    (COUNT(DISTINCT patient_id) * 100.0 / (SELECT COUNT(*) FROM Patients)) AS chronic_disease_percentage
FROM Outpatient_Visits
WHERE diagnosis LIKE '%hypertension%' 
   OR diagnosis LIKE '%diabetes%' 
   OR diagnosis LIKE '%heart disease%';
   









