SELECT current_database();

---hr_employee
CREATE TABLE hr_employee (
    age INTEGER,
    attrition VARCHAR(10),
    business_travel VARCHAR(50),
    daily_rate INTEGER,
    department VARCHAR(100),
    distance_from_home INTEGER,
    education INTEGER,
    education_field VARCHAR(100),;

TRUNCATE TABLE hr_employee;

SELECT COUNT(*) AS total_employees
FROM hr_employee;

UPDATE hr_employee
SET role_progression_gap = years_at_company - years_in_current_role;

---Role Progression Band

UPDATE hr_employee
SET role_progression_band =
    CASE
        WHEN role_progression_gap <= 2 THEN '0–2 Years'
        WHEN role_progression_gap <= 5 THEN '3–5 Years'
        WHEN role_progression_gap <= 10 THEN '6–10 Years'
        ELSE '10+ Years'
    END;

SELECT role_progression_band, COUNT(*) AS employees
FROM hr_employee
GROUP BY role_progression_band
ORDER BY employees DESC;

---Promotion Delay Band

UPDATE hr_employee
SET promotion_delay_band =
    CASE
        WHEN years_since_last_promotion <= 2 THEN '0–2 Years'
        WHEN years_since_last_promotion <= 5 THEN '3–5 Years'
        WHEN years_since_last_promotion <= 10 THEN '6–10 Years'
        ELSE '10+ Years'
    END;

SELECT promotion_delay_band, COUNT(*) AS employees
FROM hr_employee
GROUP BY promotion_delay_band
ORDER BY employees DESC;

---overtime risk

UPDATE hr_employee
SET overtime_risk =
    CASE
        WHEN overtime = 'Yes' THEN 1
        ELSE 0
    END;

---Low Job Satisfaction Flag

UPDATE hr_employee
SET low_job_satisfaction =
    CASE
        WHEN job_satisfaction = 1 THEN 1
        ELSE 0
    END;

---Low Work-Life Balance Flag

UPDATE hr_employee
SET low_work_life_balance =
    CASE
        WHEN work_life_balance = 1 THEN 1
        ELSE 0
    END;

---Low Job Involvement Flag

UPDATE hr_employee
SET low_job_involvement =
    CASE
        WHEN job_involvement = 1 THEN 1
        ELSE 0
    END;

--Employee Risk Score

UPDATE hr_employee
SET employee_risk_score =
      overtime_risk
    + low_job_satisfaction
    + low_work_life_balance
    + low_job_involvement;
	
SELECT
    employee_risk_score,
    COUNT(*) AS employees
FROM hr_employee
GROUP BY employee_risk_score
ORDER BY employee_risk_score;

---Risk Segment

UPDATE hr_employee
SET risk_segment =
    CASE
        WHEN employee_risk_score = 0 THEN 'Low Risk'
        WHEN employee_risk_score = 1 THEN 'Moderate Risk'
        WHEN employee_risk_score = 2 THEN 'High Risk'
        ELSE 'Very High Risk'
    END;

SELECT
    risk_segment,
    COUNT(*) AS employees
FROM hr_employee
GROUP BY risk_segment
ORDER BY
    CASE risk_segment
        WHEN 'Low Risk' THEN 1
        WHEN 'Moderate Risk' THEN 2
        WHEN 'High Risk' THEN 3
        WHEN 'Very High Risk' THEN 4
    END;

--Attrition Binary

UPDATE hr_employee
SET attrition_binary =
    CASE
        WHEN attrition = 'Yes' THEN 1
        ELSE 0
    END;

SELECT
    attrition,
    attrition_binary,
    COUNT(*) AS employees
FROM hr_employee
GROUP BY attrition, attrition_binary
ORDER BY attrition;

---Basic Data Quality Check

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT employee_number) AS unique_employees,
    COUNT(*) - COUNT(DISTINCT employee_number) AS duplicate_employee_rows,
    COUNT(*) FILTER (WHERE attrition IS NULL) AS null_attrition,
    COUNT(*) FILTER (WHERE department IS NULL) AS null_department,
    COUNT(*) FILTER (WHERE monthly_income IS NULL) AS null_monthly_income
FROM hr_employee;

---Check Invalid / Unexpected Values

SELECT
    'Attrition' AS field,
    attrition AS value,
    COUNT(*) AS employees
FROM hr_employee
GROUP BY attrition

UNION ALL

SELECT
    'OverTime' AS field,
    overtime AS value,
    COUNT(*) AS employees
FROM hr_employee
GROUP BY overtime

UNION ALL

SELECT
    'Department' AS field,
    department AS value,
    COUNT(*) AS employees
FROM hr_employee
GROUP BY department

UNION ALL

SELECT
    'Gender' AS field,
    gender AS value,
    COUNT(*) AS employees
FROM hr_employee
GROUP BY gender

UNION ALL

SELECT
    'MaritalStatus' AS field,
    marital_status AS value,
    COUNT(*) AS employees
FROM hr_employee
GROUP BY marital_status;

---Numerical Data Range Validation

SELECT
    COUNT(*) FILTER (WHERE age < 18 OR age > 100) AS invalid_age,
    COUNT(*) FILTER (WHERE monthly_income <= 0) AS invalid_income,
    COUNT(*) FILTER (WHERE years_at_company < 0) AS invalid_company_years,
    COUNT(*) FILTER (WHERE years_in_current_role < 0) AS invalid_role_years,
    COUNT(*) FILTER (WHERE years_since_last_promotion < 0) AS invalid_promotion_years,
    COUNT(*) FILTER (WHERE years_with_curr_manager < 0) AS invalid_manager_years,
    COUNT(*) FILTER (WHERE total_working_years < 0) AS invalid_working_years,
    COUNT(*) FILTER (WHERE percent_salary_hike < 0 OR percent_salary_hike > 100) AS invalid_salary_hike
FROM hr_employee;

---Overall HR Workforce & Attrition Summary

SELECT
    COUNT(*) AS total_employees,
    COUNT(*) FILTER (WHERE attrition = 'No') AS active_employees,
    COUNT(*) FILTER (WHERE attrition = 'Yes') AS attrition_count,
    ROUND(
        COUNT(*) FILTER (WHERE attrition = 'Yes') * 100.0 / COUNT(*),
        2
    ) AS attrition_rate,
    ROUND(AVG(age), 2) AS avg_age,
    ROUND(AVG(years_at_company), 2) AS avg_tenure,
    ROUND(AVG(monthly_income), 2) AS avg_monthly_income
FROM hr_employee;

---Department-wise Attrition Analysis

SELECT
    department,
    COUNT(*) AS total_employees,
    COUNT(*) FILTER (WHERE attrition = 'Yes') AS attrition_count,
    ROUND(
        COUNT(*) FILTER (WHERE attrition = 'Yes') * 100.0 / COUNT(*),
        2
    ) AS attrition_rate,
    ROUND(AVG(monthly_income), 2) AS avg_monthly_income
FROM hr_employee
GROUP BY department
ORDER BY attrition_rate DESC;

---Job Role-wise Attrition Analysis

SELECT
    job_role,
    COUNT(*) AS total_employees,
    COUNT(*) FILTER (WHERE attrition = 'Yes') AS attrition_count,
    ROUND(
        COUNT(*) FILTER (WHERE attrition = 'Yes') * 100.0 / COUNT(*),
        2
    ) AS attrition_rate,
    ROUND(AVG(monthly_income), 2) AS avg_monthly_income
FROM hr_employee
GROUP BY job_role
ORDER BY attrition_rate DESC;

---Overtime-wise Attrition

SELECT
    overtime,
    COUNT(*) AS total_employees,
    COUNT(*) FILTER (WHERE attrition = 'Yes') AS attrition_count,
    ROUND(
        COUNT(*) FILTER (WHERE attrition = 'Yes') * 100.0 / COUNT(*),
        2
    ) AS attrition_rate
FROM hr_employee
GROUP BY overtime
ORDER BY attrition_rate DESC;

---Attrition by Job Satisfaction

SELECT
    job_satisfaction,
    COUNT(*) AS total_employees,
    COUNT(*) FILTER (WHERE attrition = 'Yes') AS attrition_count,
    ROUND(
        COUNT(*) FILTER (WHERE attrition = 'Yes') * 100.0 / COUNT(*),
        2
    ) AS attrition_rate
FROM hr_employee
GROUP BY job_satisfaction
ORDER BY job_satisfaction;

---Attrition by Work-Life Balance

SELECT
    work_life_balance,
    COUNT(*) AS total_employees,
    COUNT(*) FILTER (WHERE attrition = 'Yes') AS attrition_count,
    ROUND(
        COUNT(*) FILTER (WHERE attrition = 'Yes') * 100.0 / COUNT(*),
        2
    ) AS attrition_rate
FROM hr_employee
GROUP BY work_life_balance
ORDER BY work_life_balance;

---Attrition by Age Band

SELECT
    CASE
        WHEN age < 25 THEN 'Under 25'
        WHEN age BETWEEN 25 AND 34 THEN '25–34'
        WHEN age BETWEEN 35 AND 44 THEN '35–44'
        WHEN age BETWEEN 45 AND 54 THEN '45–54'
        ELSE '55+'
    END AS age_band,
    COUNT(*) AS total_employees,
    COUNT(*) FILTER (WHERE attrition = 'Yes') AS attrition_count,
    ROUND(
        COUNT(*) FILTER (WHERE attrition = 'Yes') * 100.0 / COUNT(*),
        2
    ) AS attrition_rate
FROM hr_employee
GROUP BY
    CASE
        WHEN age < 25 THEN 'Under 25'
        WHEN age BETWEEN 25 AND 34 THEN '25–34'
        WHEN age BETWEEN 35 AND 44 THEN '35–44'
        WHEN age BETWEEN 45 AND 54 THEN '45–54'
        ELSE '55+'
    END
ORDER BY
    MIN(age);

---Attrition by Salary Band

SELECT
    CASE
        WHEN monthly_income < 3000 THEN 'Under 3K'
        WHEN monthly_income BETWEEN 3000 AND 5999 THEN '3K–5.9K'
        WHEN monthly_income BETWEEN 6000 AND 9999 THEN '6K–9.9K'
        WHEN monthly_income BETWEEN 10000 AND 14999 THEN '10K–14.9K'
        ELSE '15K+'
    END AS salary_band,
    COUNT(*) AS total_employees,
    COUNT(*) FILTER (WHERE attrition = 'Yes') AS attrition_count,
    ROUND(
        COUNT(*) FILTER (WHERE attrition = 'Yes') * 100.0 / COUNT(*),
        2
    ) AS attrition_rate
FROM hr_employee
GROUP BY
    CASE
        WHEN monthly_income < 3000 THEN 'Under 3K'
        WHEN monthly_income BETWEEN 3000 AND 5999 THEN '3K–5.9K'
        WHEN monthly_income BETWEEN 6000 AND 9999 THEN '6K–9.9K'
        WHEN monthly_income BETWEEN 10000 AND 14999 THEN '10K–14.9K'
        ELSE '15K+'
    END
ORDER BY MIN(monthly_income);

---Attrition by Tenure Band

SELECT
    CASE
        WHEN years_at_company <= 2 THEN '0–2 Years'
        WHEN years_at_company <= 5 THEN '3–5 Years'
        WHEN years_at_company <= 10 THEN '6–10 Years'
        ELSE '10+ Years'
    END AS tenure_band,
    COUNT(*) AS total_employees,
    COUNT(*) FILTER (WHERE attrition = 'Yes') AS attrition_count,
    ROUND(
        COUNT(*) FILTER (WHERE attrition = 'Yes') * 100.0 / COUNT(*),
        2
    ) AS attrition_rate
FROM hr_employee
GROUP BY
    CASE
        WHEN years_at_company <= 2 THEN '0–2 Years'
        WHEN years_at_company <= 5 THEN '3–5 Years'
        WHEN years_at_company <= 10 THEN '6–10 Years'
        ELSE '10+ Years'
    END
ORDER BY MIN(years_at_company);

---Risk Segment-wise Attrition Analysis (CTE)

WITH risk_summary AS (
    SELECT
        risk_segment,
        COUNT(*) AS total_employees,
        COUNT(*) FILTER (WHERE attrition = 'Yes') AS attrition_count
    FROM hr_employee
    GROUP BY risk_segment
)
SELECT
    risk_segment,
    total_employees,
    attrition_count,
    ROUND(
        attrition_count * 100.0 / total_employees,
        2
    ) AS attrition_rate
FROM risk_summary
ORDER BY
    CASE risk_segment
        WHEN 'Low Risk' THEN 1
        WHEN 'Moderate Risk' THEN 2
        WHEN 'High Risk' THEN 3
        WHEN 'Very High Risk' THEN 4
    END;

---Job Role Attrition Ranking with Window Function

WITH role_attrition AS (
    SELECT
        job_role,
        COUNT(*) AS total_employees,
        COUNT(*) FILTER (WHERE attrition = 'Yes') AS attrition_count,
        ROUND(
            COUNT(*) FILTER (WHERE attrition = 'Yes') * 100.0 / COUNT(*),
            2
        ) AS attrition_rate
    FROM hr_employee
    GROUP BY job_role
)
SELECT
    job_role,
    total_employees,
    attrition_count,
    attrition_rate,
    RANK() OVER (ORDER BY attrition_rate DESC) AS attrition_rank
FROM role_attrition
ORDER BY attrition_rank;

---Department Benchmarking with Window Functions

WITH department_metrics AS (
    SELECT
        department,
        COUNT(*) AS total_employees,
        ROUND(AVG(monthly_income), 2) AS avg_monthly_income,
        ROUND(
            COUNT(*) FILTER (WHERE attrition = 'Yes') * 100.0 / COUNT(*),
            2
        ) AS attrition_rate
    FROM hr_employee
    GROUP BY department
)
SELECT
    department,
    total_employees,
    avg_monthly_income,
    attrition_rate,
    ROUND(
        AVG(avg_monthly_income) OVER (),
        2
    ) AS overall_avg_department_salary,
    ROUND(
        avg_monthly_income - AVG(avg_monthly_income) OVER (),
        2
    ) AS salary_difference_from_average
FROM department_metrics
ORDER BY attrition_rate DESC;

---Department + Overtime Attrition Segmentation

SELECT
    department,
    overtime,
    COUNT(*) AS total_employees,
    COUNT(*) FILTER (WHERE attrition = 'Yes') AS attrition_count,
    ROUND(
        COUNT(*) FILTER (WHERE attrition = 'Yes') * 100.0 / COUNT(*),
        2
    ) AS attrition_rate,
    ROUND(AVG(monthly_income), 2) AS avg_monthly_income
FROM hr_employee
GROUP BY department, overtime
ORDER BY department, attrition_rate DESC;

---Job Role + Risk Segment Analysis

SELECT
    job_role,
    risk_segment,
    COUNT(*) AS total_employees,
    COUNT(*) FILTER (WHERE attrition = 'Yes') AS attrition_count,
    ROUND(
        COUNT(*) FILTER (WHERE attrition = 'Yes') * 100.0 / COUNT(*),
        2
    ) AS attrition_rate
FROM hr_employee
GROUP BY job_role, risk_segment
HAVING COUNT(*) >= 5
ORDER BY attrition_rate DESC;

---Promotion Delay + Attrition Analysis

SELECT
    promotion_delay_band,
    COUNT(*) AS total_employees,
    COUNT(*) FILTER (WHERE attrition = 'Yes') AS attrition_count,
    ROUND(
        COUNT(*) FILTER (WHERE attrition = 'Yes') * 100.0 / COUNT(*),
        2
    ) AS attrition_rate,
    ROUND(AVG(years_at_company), 2) AS avg_years_at_company,
    ROUND(AVG(years_in_current_role), 2) AS avg_years_in_current_role
FROM hr_employee
GROUP BY promotion_delay_band
ORDER BY
    CASE promotion_delay_band
        WHEN '0–2 Years' THEN 1
        WHEN '3–5 Years' THEN 2
        WHEN '6–10 Years' THEN 3
        WHEN '10+ Years' THEN 4
    END;

---Multi-Factor Employee Risk Analysis

SELECT
    overtime,
    low_job_satisfaction,
    low_work_life_balance,
    COUNT(*) AS total_employees,
    COUNT(*) FILTER (WHERE attrition = 'Yes') AS attrition_count,
    ROUND(
        COUNT(*) FILTER (WHERE attrition = 'Yes') * 100.0 / COUNT(*),
        2
    ) AS attrition_rate
FROM hr_employee
GROUP BY
    overtime,
    low_job_satisfaction,
    low_work_life_balance
HAVING COUNT(*) >= 10
ORDER BY attrition_rate DESC;

---

















