SELECT VERSION();

CREATE DATABASE loan_db;
USE loan_db;

CREATE TABLE raw_customers (
  customer_id TEXT, age TEXT, employment_type TEXT, monthly_income TEXT,
  city TEXT, region TEXT, credit_score TEXT, kyc_status TEXT,
  acquisition_channel TEXT, onboarding_date TEXT
);

CREATE TABLE raw_loans (
  loan_id TEXT, customer_id TEXT, product TEXT, disbursal_date TEXT,
  loan_amount TEXT, tenure_months TEXT, interest_rate TEXT,
  emi_amount TEXT, loan_status TEXT
);

CREATE TABLE raw_repayments (
  repayment_id TEXT, loan_id TEXT, due_date TEXT, paid_date TEXT,
  emi_due TEXT, amount_paid TEXT, days_past_due TEXT, payment_status TEXT
);

SELECT COUNT(*) FROM raw_customers;
SELECT COUNT(*) FROM raw_loans;
SELECT COUNT(*) FROM raw_repayments;
SELECT * FROM raw_customers LIMIT 5;

SELECT COUNT(*) FROM raw_customers;
USE loan_db;
SHOW TABLES;
SELECT COUNT(*) FROM customers;

SET GLOBAL local_infile = 1;

LOAD DATA LOCAL INFILE 'C:/Users/YourName/loan-credit-risk-platform/data/raw/customers.csv'
INTO TABLE raw_customers
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;


SELECT DISTINCT acquisition_channel
FROM customers;

SELECT DISTINCT region
FROM customers;

SELECT *
FROM customers;

CREATE TABLE clean_customers AS
SELECT DISTINCT *
FROM customers;

SELECT COUNT(*) AS total_rows
FROM clean_customers;

UPDATE clean_customers
SET credit_score = NULL
WHERE credit_score = 999;

SELECT COUNT(*) AS count_999
FROM clean_customers
WHERE credit_score IS NULL;

UPDATE clean_customers
SET city = CASE
			WHEN city = 'Bangalore' THEN 'Bengaluru'
            WHEN city = 'Cochin' THEN 'Kochi'
            ELSE city 
END
WHERE city IN ('Bangalore', 'Cochin'); 

SELECT *
FROM clean_customers
WHERE city IN ('bangalore', 'Cochin')

SELECT
    customer_id,
    COUNT(*) AS times
FROM clean_customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

SELECT
    SUM(customer_id IS NULL OR TRIM(customer_id) = '') AS customer_id_missing,
    SUM(age IS NULL) AS age_missing,
    SUM(employment_type IS NULL OR TRIM(employment_type) = '') AS employment_missing,
    SUM(monthly_income IS NULL) AS income_missing,
    SUM(city IS NULL OR TRIM(city) = '') AS city_missing,
    SUM(region IS NULL OR TRIM(region) = '') AS region_missing,
    SUM(credit_score IS NULL) AS credit_score_missing,
    SUM(kyc_status IS NULL OR TRIM(kyc_status) = '') AS kyc_missing,
    SUM(acquisition_channel IS NULL OR TRIM(acquisition_channel) = '') AS acquisition_missing,
    SUM(onboarding_date IS NULL OR TRIM(onboarding_date) = '') AS onboarding_missing
FROM clean_customers;

SELECT
    MIN(credit_score) AS min_score,
    MAX(credit_score) AS max_score
FROM clean_customers;

SELECT *
FROM loans;

SELECT 
	loan_id,
    COUNT(*) AS count_duplicates
FROM loans
GROUP BY loan_id
HAVING COUNT(*) > 1;

DESCRIBE loans;

SELECT
    SUM(loan_id IS NULL OR TRIM(loan_id) = '') AS loan_id_missing,
    SUM(customer_id IS NULL OR TRIM(customer_id) = '') AS customer_id_missing,
    SUM(product IS NULL OR TRIM(product) = '') AS product_missing,
    SUM(disbursal_date IS NULL OR TRIM(disbursal_date) = '') AS disbursal_date_missing,
    SUM(loan_amount IS NULL) AS loan_amount_missing,
    SUM(tenure_months IS NULL) AS tenure_missing,
    SUM(interest_rate IS NULL) AS interest_rate_missing,
    SUM(emi_amount IS NULL) AS emi_missing,
    SUM(loan_status IS NULL OR TRIM(loan_status) = '') AS loan_status_missing
FROM loans;

SELECT
    MIN(loan_amount) AS min_loan_amount,
    MAX(loan_amount) AS max_loan_amount,
    MIN(tenure_months) AS min_tenure,
    MAX(tenure_months) AS max_tenure,
    MIN(interest_rate) AS min_interest_rate,
    MAX(interest_rate) AS max_interest_rate,
    MIN(emi_amount) AS min_emi,
    MAX(emi_amount) AS max_emi
FROM loans;

SELECT DISTINCT product
FROM loans
ORDER BY product;

SELECT DISTINCT loan_status
FROM loans
ORDER BY loan_status;

SELECT
    l.customer_id
FROM loans l
LEFT JOIN clean_customers c
    ON l.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT COUNT(*) AS orphan_loan_rows
FROM loans l
LEFT JOIN clean_customers c
    ON l.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT COUNT(DISTINCT l.customer_id) AS orphan_customers
FROM loans l
LEFT JOIN clean_customers c
    ON l.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT COUNT(DISTINCT l.customer_id) AS missing_from_raw_customers
FROM loans l
LEFT JOIN customers c
    ON l.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT 
    l.customer_id,
    COUNT(*) AS loan_count
FROM loans l
LEFT JOIN customers c
    ON l.customer_id = c.customer_id
WHERE c.customer_id IS NULL
GROUP BY l.customer_id
ORDER BY l.customer_id;

SELECT COUNT(DISTINCT l.customer_id) AS still_unmatched
FROM loans l
LEFT JOIN customers c
    ON TRIM(UPPER(l.customer_id)) = TRIM(UPPER(c.customer_id))
WHERE c.customer_id IS NULL;

SELECT
    MIN(disbursal_date) AS earliest_loan_date,
    MAX(disbursal_date) AS latest_loan_date,
    COUNT(*) AS unmatched_loan_rows
FROM loans l
LEFT JOIN customers c
    ON l.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT
    l.loan_status,
    COUNT(*) AS loan_count
FROM loans l
LEFT JOIN customers c
    ON l.customer_id = c.customer_id
WHERE c.customer_id IS NULL
GROUP BY l.loan_status
ORDER BY loan_count DESC;

SELECT
    l.product,
    COUNT(*) AS loan_count
FROM loans l
LEFT JOIN customers c
    ON l.customer_id = c.customer_id
WHERE c.customer_id IS NULL
GROUP BY l.product
ORDER BY loan_count DESC;

SELECT
    MIN(l.loan_amount) AS min_loan_amount,
    MAX(l.loan_amount) AS max_loan_amount,
    AVG(l.loan_amount) AS avg_loan_amount,
    SUM(l.loan_amount) AS total_loan_amount
FROM loans l
LEFT JOIN customers c
    ON l.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT
    MIN(l.tenure_months) AS min_tenure,
    MAX(l.tenure_months) AS max_tenure,
    MIN(l.interest_rate) AS min_interest_rate,
    MAX(l.interest_rate) AS max_interest_rate,
    AVG(l.interest_rate) AS avg_interest_rate
FROM loans l
LEFT JOIN customers c
    ON l.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT
    MIN(l.emi_amount) AS min_emi,
    MAX(l.emi_amount) AS max_emi,
    AVG(l.emi_amount) AS avg_emi
FROM loans l
LEFT JOIN customers c
    ON l.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT loan_id) AS unique_loan_ids
FROM loans;

CREATE TABLE clean_loans AS
SELECT DISTINCT *
FROM loans;

SELECT payment_status, COUNT(*) AS records
FROM repayments
GROUP BY payment_status
ORDER BY payment_status;

SELECT payment_status, COUNT(*) AS records,
       SUM(paid_date IS NULL OR TRIM(paid_date) = '') AS missing_paid_date
FROM repayments
GROUP BY payment_status
ORDER BY payment_status;

SELECT
    MIN(emi_due) AS min_emi_due,
    MAX(emi_due) AS max_emi_due,
    MIN(amount_paid) AS min_amount_paid,
    MAX(amount_paid) AS max_amount_paid,
    MIN(days_past_due) AS min_dpd,
    MAX(days_past_due) AS max_dpd
FROM repayments;



SHOW TABLES;
DESCRIBE clean_repayments

SELECT 'clean_customers' AS table_name, COUNT(*) AS row_count
FROM clean_customers
UNION ALL
SELECT 'clean_loans', COUNT(*) FROM clean_loans
UNION ALL
SELECT 'clean_repayments', COUNT(*) FROM clean_repayments;

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_customers,
    SUM(customer_id IS NULL) AS null_customer_ids
FROM clean_customers;

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT loan_id) AS unique_loans,
    SUM(loan_id IS NULL) AS null_loan_ids
FROM clean_loans;

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT repayment_id) AS unique_repayments,
    SUM(repayment_id IS NULL) AS null_repayment_ids
FROM clean_repayments;

SELECT COUNT(*) AS loans_without_matching_customer
FROM clean_loans l
LEFT JOIN clean_customers c
    ON l.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT COUNT(*) AS repayments_without_matching_loan
FROM clean_repayments r
LEFT JOIN clean_loans l
    ON r.loan_id = l.loan_id
WHERE l.loan_id IS NULL;

SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'loan_db'
ORDER BY table_name, ordinal_position;

SELECT * FROM clean_loans LIMIT 5;
SELECT DISTINCT loan_status FROM clean_loans;

SELECT
  COUNT(*)                                                AS total_loans,
  SUM(loan_amount)                                        AS total_loan_amount,
  ROUND(AVG(loan_amount),1)                               AS avg_loan_amount,
  ROUND(100*SUM(loan_status='Defaulted')/COUNT(*),2)      AS defaulted_rate_pct,
  ROUND(100*SUM(loan_status='Written Off')/COUNT(*),2)    AS written_off_rate_pct
FROM clean_loans;

SELECT ROUND(100*SUM(payment_status='On Time')/COUNT(*),2) AS on_time_rate_pct
FROM clean_repayments;

SELECT 'product' col, product val FROM clean_loans GROUP BY product
UNION ALL SELECT 'region', region FROM clean_customers GROUP BY region
UNION ALL SELECT 'employment_type', employment_type FROM clean_customers GROUP BY employment_type;

CREATE USER 'chatbot_ro'@'localhost' IDENTIFIED BY 'choose_a_strong_password';
GRANT SELECT ON loan_db.clean_customers TO 'chatbot_ro'@'localhost';
GRANT SELECT ON loan_db.clean_loans TO 'chatbot_ro'@'localhost';
GRANT SELECT ON loan_db.clean_repayments TO 'chatbot_ro'@'localhost';
FLUSH PRIVILEGES;

SELECT due_date, paid_date FROM clean_repayments LIMIT 5;

SELECT ROUND(100*SUM(payment_status='On Time')/COUNT(*),2) AS on_time_repayment_rate_pct
FROM clean_repayments;

SELECT *
FROM clean_customers
WHERE city IN ('New Delhi')

UPDATE clean_customers
SET city = 'Delhi'
WHERE city = 'New Delhi' 

SELECT city, COUNT(*) FROM clean_customers WHERE city LIKE '%Delhi%' GROUP BY city;
CREATE TABLE clean_customers_backup AS SELECT * FROM clean_customers;

SET SQL_SAFE_UPDATES = 0;
UPDATE clean_customers SET city = 'Delhi' WHERE city = 'New Delhi';
SET SQL_SAFE_UPDATES = 1;


SElect count(*)
FROM clean_customers
    ROUND(
        SUM(
            CASE
                WHEN l.loan_status = 'Defaulted' THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS default_rate_pct

FROM clean_loans l
JOIN clean_customers c
    ON l.customer_id = c.customer_id

GROUP BY credit_score_band
ORDER BY default_rate_pct DESC;
    
    
    SELECT
    c.employment_type,
    COUNT(*) AS total_loans,

    SUM(
        CASE
            WHEN l.loan_status = 'Defaulted' THEN 1
            ELSE 0
        END
    ) AS defaulted_loans,

    ROUND(
        SUM(
            CASE
                WHEN l.loan_status = 'Defaulted' THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS default_rate_pct

FROM clean_loans l
JOIN clean_customers c
    ON l.customer_id = c.customer_id

GROUP BY c.employment_type
ORDER BY default_rate_pct DESC;


SELECT
    c.region,
    COUNT(*) AS total_loans,

    SUM(
        CASE
            WHEN l.loan_status = 'Defaulted' THEN 1
            ELSE 0
        END
    ) AS defaulted_loans,

    ROUND(
        SUM(
            CASE
                WHEN l.loan_status = 'Defaulted' THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS default_rate_pct

FROM clean_loans l
JOIN clean_customers c
    ON l.customer_id = c.customer_id

GROUP BY c.region
ORDER BY default_rate_pct DESC;
    
-- Within each loan product, do customers with lower credit scores have higher observed default rates?
SELECT 
	l.product, 
    CASE 
    WHEN c.credit_score IS NULL THEN 'Unknown'
    WHEN c.credit_score < 580 THEN 'Low'
    WHEN c.credit_score < 670 THEN 'Fair'
    WHEN c.credit_score < 740 THEN 'Good'
    ELSE 'Very Good'
    END AS credit_score_band,
	COUNT(*) AS count_times,
    SUM(
	CASE WHEN l.loan_status='Defaulted' THEN 1
         ELSE 0
	END) AS defaulted_count,
    ROUND(
		SUM(
			CASE WHEN l.loan_status='Defaulted' THEN 1
             ELSE 0 
             END) *100.0/ COUNT(*),2) AS defaulted_rate_pct
	FROM clean_loans l
    JOIN clean_customers c 
    ON l.customer_id = c.customer_id
    GROUP BY l.product, credit_score_band
    ORDER BY l.product, defaulted_rate_pct DESC
    

    
SELECT
    l.product,
    r.payment_status,
    COUNT(*) AS repayment_count,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (PARTITION BY l.product),
        2
    ) AS percentage_within_product

FROM clean_loans l
JOIN clean_repayments r
    ON l.loan_id = r.loan_id

GROUP BY
    l.product,
    r.payment_status

ORDER BY
    l.product,
    percentage_within_product DESC;
    
    
SELECT
    l.product,

    COUNT(*) AS total_repayment_records,

    SUM(
        CASE
            WHEN r.days_past_due >= 30 THEN 1
            ELSE 0
        END
    ) AS records_30plus_dpd,

    ROUND(
        SUM(
            CASE
                WHEN r.days_past_due >= 30 THEN r.emi_due
                ELSE 0
            END
        ),
        2
    ) AS emi_due_30plus,

    ROUND(
        SUM(
            CASE
                WHEN r.days_past_due >= 30 THEN r.emi_due
                ELSE 0
            END
        ) * 100.0 / SUM(r.emi_due),
        2
    ) AS overdue_exposure_proxy_pct

FROM clean_loans l
JOIN clean_repayments r
    ON l.loan_id = r.loan_id

GROUP BY l.product

ORDER BY overdue_exposure_proxy_pct DESC;

SELECT
    COUNT(*) AS total_loans,

    COUNT(DISTINCT customer_id) AS distinct_customers_with_loans,

    SUM(loan_amount) AS total_loan_amount,

    ROUND(AVG(loan_amount), 2) AS average_loan_amount,

    SUM(
        CASE
            WHEN loan_status = 'Defaulted' THEN 1
            ELSE 0
        END
    ) AS defaulted_loans,

    ROUND(
        SUM(
            CASE
                WHEN loan_status = 'Defaulted' THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS default_rate_pct,

    SUM(
        CASE
            WHEN loan_status = 'Written Off' THEN 1
            ELSE 0
        END
    ) AS written_off_loans,

    ROUND(
        SUM(
            CASE
                WHEN loan_status = 'Written Off' THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS write_off_rate_pct

FROM clean_loans;

SELECT
    COUNT(*) AS total_loans,

    SUM(
        CASE
            WHEN c.customer_id IS NOT NULL THEN 1
            ELSE 0
        END
    ) AS matched_loans,

    SUM(
        CASE
            WHEN c.customer_id IS NULL THEN 1
            ELSE 0
        END
    ) AS unmatched_loans

FROM clean_loans l
LEFT JOIN clean_customers c
    ON l.customer_id = c.customer_id;
    
    
    
SELECT
    COUNT(*) AS unmatched_loan_records,
    COUNT(DISTINCT l.customer_id) AS unmatched_customer_ids,
    SUM(
        CASE
            WHEN r.customer_id IS NOT NULL THEN 1
            ELSE 0
        END
    ) AS found_in_raw_customers,
    SUM(
        CASE
            WHEN r.customer_id IS NULL THEN 1
            ELSE 0
        END
    ) AS not_found_in_raw_customers
FROM clean_loans l
LEFT JOIN clean_customers c
    ON l.customer_id = c.customer_id
LEFT JOIN raw_customers r
    ON l.customer_id = r.customer_id
WHERE c.customer_id IS NULL;


SELECT
    COUNT(*) AS unmatched_loan_count,
    SUM(l.loan_amount) AS unmatched_loan_value,
    ROUND(
        100.0 * COUNT(*) /
        (SELECT COUNT(*) FROM clean_loans),
        2
    ) AS percentage_of_loan_count,
    ROUND(
        100.0 * SUM(l.loan_amount) /
        (SELECT SUM(loan_amount) FROM clean_loans),
        2
    ) AS percentage_of_loan_value
FROM clean_loans l
LEFT JOIN clean_customers c
    ON l.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


SELECT
    loan_status,
    COUNT(*) AS loan_count,
    SUM(loan_amount) AS total_loan_value
FROM clean_loans
GROUP BY loan_status
ORDER BY loan_count DESC;


SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT loan_id) AS unique_loan_ids,
    COUNT(*) - COUNT(DISTINCT loan_id) AS duplicate_rows
FROM clean_loans;


SELECT
    COUNT(*) AS total_loans,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END)
        AS missing_customer_id,
    SUM(CASE WHEN loan_amount IS NULL THEN 1 ELSE 0 END)
        AS missing_loan_amount,
    SUM(CASE WHEN interest_rate IS NULL THEN 1 ELSE 0 END)
        AS missing_interest_rate,
    SUM(CASE WHEN tenure_months IS NULL THEN 1 ELSE 0 END)
        AS missing_tenure,
    SUM(CASE WHEN loan_status IS NULL THEN 1 ELSE 0 END)
        AS missing_loan_status
FROM clean_loans;


SELECT
    SUM(CASE WHEN loan_amount <= 0 THEN 1 ELSE 0 END)
        AS invalid_loan_amounts,
    SUM(CASE WHEN interest_rate <= 0 THEN 1 ELSE 0 END)
        AS invalid_interest_rates,
    SUM(CASE WHEN tenure_months <= 0 THEN 1 ELSE 0 END)
        AS invalid_tenures
FROM clean_loans;


SELECT
    COUNT(*) AS total_repayments,
    COUNT(DISTINCT repayment_id) AS unique_repayment_ids,
    COUNT(*) - COUNT(DISTINCT repayment_id) AS duplicate_rows,
    SUM(
        CASE
            WHEN l.loan_id IS NULL THEN 1
            ELSE 0
        END
    ) AS unmatched_repayments
FROM clean_repayments r
LEFT JOIN clean_loans l
    ON r.loan_id = l.loan_id;
    
    
SELECT
    COUNT(*) AS total_repayments,
    SUM(CASE WHEN loan_id IS NULL THEN 1 ELSE 0 END)
        AS missing_loan_id,
    SUM(CASE WHEN due_date IS NULL THEN 1 ELSE 0 END)
        AS missing_due_date,
    SUM(CASE WHEN repayment_amount IS NULL THEN 1 ELSE 0 END)
        AS missing_repayment_amount,
    SUM(CASE WHEN payment_status IS NULL THEN 1 ELSE 0 END)
        AS missing_payment_status,
    SUM(CASE WHEN repayment_amount < 0 THEN 1 ELSE 0 END)
        AS negative_repayment_amounts
FROM clean_repayments;

DESCRIBE clean_repayments;


SELECT
    COUNT(*) AS total_repayments,
    SUM(CASE WHEN loan_id IS NULL THEN 1 ELSE 0 END)
        AS missing_loan_id,
    SUM(CASE WHEN due_date IS NULL THEN 1 ELSE 0 END)
        AS missing_due_date,
    SUM(CASE WHEN emi_due IS NULL THEN 1 ELSE 0 END)
        AS missing_emi_due,
    SUM(CASE WHEN amount_paid IS NULL THEN 1 ELSE 0 END)
        AS missing_amount_paid,
    SUM(CASE WHEN payment_status IS NULL THEN 1 ELSE 0 END)
        AS missing_payment_status,
    SUM(CASE WHEN emi_due < 0 THEN 1 ELSE 0 END)
        AS negative_emi_due,
    SUM(CASE WHEN amount_paid < 0 THEN 1 ELSE 0 END)
        AS negative_amount_paid
FROM clean_repayments;


SELECT
    payment_status,
    COUNT(*) AS total_records,
    SUM(
        CASE
            WHEN paid_date IS NULL THEN 1
            ELSE 0
        END
    ) AS missing_paid_date,
    SUM(
        CASE
            WHEN paid_date IS NOT NULL THEN 1
            ELSE 0
        END
    ) AS has_paid_date
FROM clean_repayments
GROUP BY payment_status
ORDER BY total_records DESC;


SELECT
    payment_status,
    COUNT(*) AS total_records,
    SUM(
        CASE
            WHEN paid_date IS NULL
                 OR TRIM(paid_date) = ''
            THEN 1
            ELSE 0
        END
    ) AS missing_or_blank_paid_date,
    SUM(
        CASE
            WHEN paid_date IS NOT NULL
                 AND TRIM(paid_date) <> ''
            THEN 1
            ELSE 0
        END
    ) AS nonblank_paid_date
FROM clean_repayments
GROUP BY payment_status
ORDER BY total_records DESC;

SELECT
    payment_status,
    COUNT(*) AS total_records,
    MIN(days_past_due) AS minimum_dpd,
    MAX(days_past_due) AS maximum_dpd,
    ROUND(AVG(days_past_due), 2) AS average_dpd,
    SUM(
        CASE WHEN days_past_due < 0 THEN 1 ELSE 0 END
    ) AS negative_dpd_records,
    SUM(
        CASE WHEN days_past_due > 365 THEN 1 ELSE 0 END
    ) AS over_365_days
FROM clean_repayments
GROUP BY payment_status
ORDER BY total_records DESC;


SELECT
    payment_status,
    COUNT(*) AS comparable_records,
    SUM(
        CASE
            WHEN days_past_due <>
                 GREATEST(
                     DATEDIFF(
                         STR_TO_DATE(paid_date, '%Y-%m-%d'),
                         STR_TO_DATE(due_date, '%Y-%m-%d')
                     ),
                     0
                 )
            THEN 1
            ELSE 0
        END
    ) AS dpd_mismatches
FROM clean_repayments
WHERE paid_date IS NOT NULL
  AND TRIM(paid_date) <> ''
  AND STR_TO_DATE(paid_date, '%Y-%m-%d') IS NOT NULL
  AND STR_TO_DATE(due_date, '%Y-%m-%d') IS NOT NULL
GROUP BY payment_status
ORDER BY payment_status;


SELECT
    repayment_id,
    loan_id,
    payment_status,
    due_date,
    paid_date,
    days_past_due,
    DATEDIFF(
        STR_TO_DATE(paid_date, '%Y-%m-%d'),
        STR_TO_DATE(due_date, '%Y-%m-%d')
    ) AS date_difference
FROM clean_repayments
WHERE payment_status IN ('Late', 'Partial')
  AND paid_date IS NOT NULL
  AND TRIM(paid_date) <> ''
  AND STR_TO_DATE(paid_date, '%Y-%m-%d') IS NOT NULL
  AND STR_TO_DATE(due_date, '%Y-%m-%d') IS NOT NULL
  AND days_past_due <> GREATEST(
      DATEDIFF(
          STR_TO_DATE(paid_date, '%Y-%m-%d'),
          STR_TO_DATE(due_date, '%Y-%m-%d')
      ),
      0
  )
ORDER BY payment_status, days_past_due DESC
LIMIT 10;


SELECT
    days_past_due,
    COUNT(*) AS record_count
FROM clean_repayments
WHERE payment_status = 'Late'
GROUP BY days_past_due
ORDER BY record_count DESC, days_past_due DESC
LIMIT 15;


SELECT
    payment_status,
    COUNT(*) AS total_records,
    SUM(
        CASE
            WHEN days_past_due <>
                 GREATEST(
                     DATEDIFF(
                         STR_TO_DATE(paid_date, '%Y-%m-%d'),
                         STR_TO_DATE(due_date, '%Y-%m-%d')
                     ),
                     0
                 )
            THEN 1 ELSE 0
        END
    ) AS mismatch_records,
    ROUND(
        AVG(
            ABS(
                days_past_due -
                GREATEST(
                    DATEDIFF(
                        STR_TO_DATE(paid_date, '%Y-%m-%d'),
                        STR_TO_DATE(due_date, '%Y-%m-%d')
                    ),
                    0
                )
            )
        ), 2
    ) AS average_absolute_difference
FROM clean_repayments
WHERE payment_status IN ('Late', 'Partial')
  AND paid_date IS NOT NULL
  AND TRIM(paid_date) <> ''
  AND STR_TO_DATE(paid_date, '%Y-%m-%d') IS NOT NULL
  AND STR_TO_DATE(due_date, '%Y-%m-%d') IS NOT NULL
GROUP BY payment_status;


SELECT
    repayment_id,
    loan_id,
    due_date,
    paid_date,
    emi_due,
    amount_paid,
    days_past_due,
    DATEDIFF(
        STR_TO_DATE(paid_date, '%Y-%m-%d'),
        STR_TO_DATE(due_date, '%Y-%m-%d')
    ) AS date_difference
FROM clean_repayments
WHERE payment_status = 'Partial'
ORDER BY days_past_due DESC
LIMIT 10;

SELECT
    COUNT(*) AS partial_records,
    MIN(days_past_due) AS minimum_stored_dpd,
    MAX(days_past_due) AS maximum_stored_dpd,
    MIN(
        DATEDIFF(
            STR_TO_DATE(paid_date, '%Y-%m-%d'),
            STR_TO_DATE(due_date, '%Y-%m-%d')
        )
    ) AS minimum_date_difference,
    MAX(
        DATEDIFF(
            STR_TO_DATE(paid_date, '%Y-%m-%d'),
            STR_TO_DATE(due_date, '%Y-%m-%d')
        )
    ) AS maximum_date_difference,
    SUM(
        CASE
            WHEN days_past_due >
                 DATEDIFF(
                     STR_TO_DATE(paid_date, '%Y-%m-%d'),
                     STR_TO_DATE(due_date, '%Y-%m-%d')
                 )
            THEN 1 ELSE 0
        END
    ) AS stored_dpd_greater_than_date_difference
FROM clean_repayments
WHERE payment_status = 'Partial'
  AND paid_date IS NOT NULL
  AND TRIM(paid_date) <> ''
  AND STR_TO_DATE(paid_date, '%Y-%m-%d') IS NOT NULL
  AND STR_TO_DATE(due_date, '%Y-%m-%d') IS NOT NULL;
  
  
SELECT
    COUNT(*) AS total_customer_rows,
    COUNT(DISTINCT customer_id) AS unique_customer_ids,
    COUNT(*) - COUNT(DISTINCT customer_id) AS duplicate_customer_rows
FROM clean_customers;

SELECT 'clean_customers' AS table_name, COUNT(*) AS total_rows
FROM clean_customers

UNION ALL

SELECT 'clean_loans', COUNT(*)
FROM clean_loans

UNION ALL

SELECT 'clean_repayments', COUNT(*)
FROM clean_repayments;

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT repayment_id) AS unique_repayment_ids
FROM clean_repayments;

SELECT
    SUM(repayment_id IS NULL OR TRIM(repayment_id) = '') AS repayment_id_missing,
    SUM(loan_id IS NULL OR TRIM(loan_id) = '') AS loan_id_missing,
    SUM(due_date IS NULL OR TRIM(due_date) = '') AS due_date_missing,
    SUM(paid_date IS NULL OR TRIM(paid_date) = '') AS paid_date_missing,
    SUM(emi_due IS NULL) AS emi_due_missing,
    SUM(amount_paid IS NULL) AS amount_paid_missing,
    SUM(days_past_due IS NULL) AS days_past_due_missing,
    SUM(payment_status IS NULL OR TRIM(payment_status) = '') AS payment_status_missing
FROM clean_repayments;

SELECT COUNT(*) AS unmatched_repayment_rows
FROM clean_repayments r
LEFT JOIN clean_loans l
    ON r.loan_id = l.loan_id
WHERE l.loan_id IS NULL;

SELECT
    payment_status,
    COUNT(*) AS records,
    SUM(amount_paid = 0) AS zero_paid,
    SUM(amount_paid < emi_due) AS less_than_due,
    SUM(amount_paid = emi_due) AS exactly_due,
    SUM(amount_paid > emi_due) AS greater_than_due
FROM repayments
GROUP BY payment_status
ORDER BY payment_status;

SELECT
    loan_status,
    COUNT(*) AS loan_count,
    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM clean_loans),
        2
    ) AS percentage
FROM clean_loans
GROUP BY loan_status
ORDER BY loan_count DESC;

SELECT
    loan_status,
    COUNT(*) AS loan_count,
    SUM(loan_amount) AS total_loan_amount,
    ROUND(AVG(loan_amount), 2) AS average_loan_amount
FROM clean_loans
GROUP BY loan_status
ORDER BY total_loan_amount DESC;

SELECT
    loan_status,
    COUNT(*) AS loan_count,
    SUM(loan_amount) AS total_loan_amount,
    ROUND(
        SUM(loan_amount) * 100.0 /
        (SELECT SUM(loan_amount) FROM clean_loans),
        2
    ) AS amount_percentage
FROM clean_loans
GROUP BY loan_status
ORDER BY total_loan_amount DESC;

SELECT
    payment_status,
    COUNT(*) AS repayment_count,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM clean_repayments),
        2
    ) AS percentage
FROM clean_repayments
GROUP BY payment_status
ORDER BY repayment_count DESC;

SELECT
    payment_status,
    COUNT(*) AS repayment_count,
    ROUND(AVG(days_past_due), 2) AS avg_dpd,
    MIN(days_past_due) AS min_dpd,
    MAX(days_past_due) AS max_dpd
FROM clean_repayments
GROUP BY payment_status
ORDER BY avg_dpd DESC;


SELECT
    l.loan_status,
    r.payment_status,
    COUNT(*) AS repayment_count,
    ROUND(AVG(r.days_past_due), 2) AS avg_dpd
FROM clean_loans l
JOIN clean_repayments r
    ON l.loan_id = r.loan_id
GROUP BY
    l.loan_status,
    r.payment_status
ORDER BY
    l.loan_status,
    repayment_count DESC;
    
    SELECT
    product,
    loan_status,
    COUNT(*) AS loan_count,
    SUM(loan_amount) AS total_loan_amount,
    ROUND(AVG(loan_amount), 2) AS avg_loan_amount
FROM clean_loans
WHERE loan_status IN ('Written off', 'defaulted')
GROUP BY
    product,
    loan_status
ORDER BY
    product,
    loan_count DESC;
    
    SELECT
    product,
    COUNT(*) AS total_loans,

    SUM(CASE
        WHEN loan_status = 'Defaulted' THEN 1
        ELSE 0
    END) AS defaulted_loans,

    ROUND(
        SUM(CASE
            WHEN loan_status = 'Defaulted' THEN 1
            ELSE 0
        END) * 100.0 / COUNT(*),
        2
    ) AS default_rate_pct,

    SUM(CASE
        WHEN loan_status = 'Written Off' THEN 1
        ELSE 0
    END) AS written_off_loans,

    ROUND(
        SUM(CASE
            WHEN loan_status = 'Written Off' THEN 1
            ELSE 0
        END) * 100.0 / COUNT(*),
        2
    ) AS write_off_rate_pct

FROM clean_loans
GROUP BY product
ORDER BY default_rate_pct DESC;