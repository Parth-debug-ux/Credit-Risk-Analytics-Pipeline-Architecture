

-- 1. Creating the Credit Risk Database
CREATE DATABASE CreditRiskDB;


USE CreditRiskDB;


-- 2. Creating Staging Table (For initial raw CSV import)
CREATE TABLE Staging_Bank_Loans (
    person_age INT,
    person_income INT,
    person_home_ownership VARCHAR(50),
    person_emp_length FLOAT,
    loan_intent VARCHAR(100),
    loan_grade VARCHAR(5),
    loan_amnt INT,
    loan_int_rate FLOAT,
    loan_status INT,
    loan_percent_income FLOAT,
    cb_person_default_on_file VARCHAR(5),
    cb_person_cred_hist_length INT
);

drop table Staging_Bank_Loans;


-- 3. Creating Dimension Tables
CREATE TABLE Dim_Borrower_Demographics (
    Demographic_ID INT IDENTITY(1,1) PRIMARY KEY,
    Age_Bracket VARCHAR(20) NOT NULL,
    Income_Bracket VARCHAR(20) NOT NULL,
    Home_Ownership VARCHAR(50) NOT NULL
);

CREATE TABLE Dim_Loan_Intent (
    Intent_ID INT IDENTITY(1,1) PRIMARY KEY,
    Loan_Intent VARCHAR(100) NOT NULL
);

CREATE TABLE Dim_Credit_History (
    Credit_Hist_ID INT IDENTITY(1,1) PRIMARY KEY,
    Historical_Default_File CHAR(1) NOT NULL,
    Credit_History_Length_Years INT NOT NULL
);


-- 4. Create Fact Table
CREATE TABLE Fact_Loan_Details (
    Loan_ID INT IDENTITY(1,1) PRIMARY KEY,
    Demographic_ID INT FOREIGN KEY REFERENCES Dim_Borrower_Demographics(Demographic_ID),
    Intent_ID INT FOREIGN KEY REFERENCES Dim_Loan_Intent(Intent_ID),
    Credit_Hist_ID INT FOREIGN KEY REFERENCES Dim_Credit_History(Credit_Hist_ID),
    Person_Age INT NOT NULL,
    Person_Income INT NOT NULL,
    Person_Emp_Length INT NULL,
    Loan_Grade CHAR(1) NOT NULL,
    Loan_Amount INT NOT NULL,
    Loan_Interest_Rate DECIMAL(5,2) NULL,
    Loan_Percent_Income DECIMAL(4,2) NOT NULL,
    Loan_Status_Default INT NOT NULL
);


-- This should return the total number of rows in the dataset (around 32,581 rows)
SELECT COUNT(*) AS Total_Imported_Rows FROM Staging_Bank_Loans;

-- This will show  the top 5 rows to ensure columns aligned correctly
SELECT TOP 5 * FROM Staging_Bank_Loans;


-- 5. Impute missing Employment Lengths with a logical median value (4 years)
UPDATE Staging_Bank_Loans
SET person_emp_length = 4
WHERE person_emp_length IS NULL;

-- 6. Impute missing Interest Rates using the average rate of their specific Loan Grade
WITH GradeAverages AS (
    SELECT loan_grade, AVG(loan_int_rate) as avg_rate
    FROM Staging_Bank_Loans
    WHERE loan_int_rate IS NOT NULL
    GROUP BY loan_grade
)
UPDATE s
SET s.loan_int_rate = g.avg_rate
FROM Staging_Bank_Loans s
JOIN GradeAverages g ON s.loan_grade = g.loan_grade
WHERE s.loan_int_rate IS NULL;


-- 7. Populate Demographics Dimension
INSERT INTO Dim_Borrower_Demographics (Age_Bracket, Income_Bracket, Home_Ownership)
SELECT DISTINCT 
    CASE 
        WHEN person_age < 25 THEN 'Young Adult (<25)'
        WHEN person_age BETWEEN 25 AND 40 THEN 'Adult (25-40)'
        WHEN person_age BETWEEN 41 AND 60 THEN 'Mid-Age (41-60)'
        ELSE 'Senior (60+)'
    END,
    CASE 
        WHEN person_income < 35000 THEN 'Low Income'
        WHEN person_income BETWEEN 35000 AND 85000 THEN 'Medium Income'
        ELSE 'High Income'
    END,
    person_home_ownership
FROM Staging_Bank_Loans;

-- 8. Populate Loan Intent Dimension
INSERT INTO Dim_Loan_Intent (Loan_Intent)
SELECT DISTINCT loan_intent FROM Staging_Bank_Loans;

-- 9. Populate Credit History Dimension
INSERT INTO Dim_Credit_History (Historical_Default_File, Credit_History_Length_Years)
SELECT DISTINCT cb_person_default_on_file, cb_person_cred_hist_length FROM Staging_Bank_Loans;



USE CreditRiskDB;
GO

INSERT INTO Fact_Loan_Details (
    Demographic_ID, 
    Intent_ID, 
    Credit_Hist_ID, 
    Person_Age, 
    Person_Income, 
    Person_Emp_Length, 
    Loan_Grade, 
    Loan_Amount, 
    Loan_Interest_Rate, 
    Loan_Percent_Income, 
    Loan_Status_Default
)
SELECT 
    d.Demographic_ID,   -- These aliases are perfectly fine here in the SELECT
    i.Intent_ID,
    c.Credit_Hist_ID,
    s.person_age,
    s.person_income,
    CAST(s.person_emp_length AS INT),
    s.loan_grade,
    s.loan_amnt,
    CAST(s.loan_int_rate AS DECIMAL(5,2)),
    CAST(s.loan_percent_income AS DECIMAL(4,2)),
    s.loan_status
FROM Staging_Bank_Loans s

-- Fast Join for Demographics
LEFT JOIN Dim_Borrower_Demographics d 
    ON d.Home_Ownership = s.person_home_ownership
   AND d.Age_Bracket = (
        CASE 
            WHEN s.person_age < 24 THEN 'Young Adult (<25)' 
            WHEN s.person_age BETWEEN 24 AND 40 THEN 'Adult (25-40)'
            WHEN s.person_age BETWEEN 41 AND 60 THEN 'Mid-Age (41-60)'
            ELSE 'Senior (60+)'
        END
   )
   AND d.Income_Bracket = (
        CASE 
            WHEN s.person_income < 35000 THEN 'Low Income'
            WHEN s.person_income BETWEEN 35000 AND 85000 THEN 'Medium Income'
            ELSE 'High Income'
        END
   )

-- Fast Join for Loan Intent
LEFT JOIN Dim_Loan_Intent i 
    ON i.Loan_Intent = s.loan_intent

-- Fast Join for Credit History
LEFT JOIN Dim_Credit_History c 
    ON c.Historical_Default_File = s.cb_person_default_on_file 
   AND c.Credit_History_Length_Years = s.cb_person_cred_hist_length;



CREATE VIEW v_Analytics_Credit_Risk AS
SELECT 
    f.Loan_ID,
    d.Age_Bracket,
    d.Income_Bracket,
    d.Home_Ownership,
    i.Loan_Intent,
    c.Historical_Default_File,
    c.Credit_History_Length_Years,
    f.Person_Age,
    f.Person_Income,
    f.Person_Emp_Length,
    f.Loan_Grade,
    f.Loan_Amount,
    f.Loan_Interest_Rate,
    f.Loan_Percent_Income,
    f.Loan_Status_Default
FROM Fact_Loan_Details f
JOIN Dim_Borrower_Demographics d ON f.Demographic_ID = d.Demographic_ID
JOIN Dim_Loan_Intent i ON f.Intent_ID = i.Intent_ID
JOIN Dim_Credit_History c ON f.Credit_Hist_ID = c.Credit_Hist_ID;

SELECT 
    (SELECT COUNT(*) FROM Staging_Bank_Loans) AS Staging_Rows,
    (SELECT COUNT(*) FROM Fact_Loan_Details) AS Fact_Table_Rows;

    -- Run this to update Power BI view
ALTER VIEW v_Analytics_Credit_Risk AS
SELECT 
    f.Loan_ID,
    d.Age_Bracket,
    d.Income_Bracket,
    d.Home_Ownership,
    i.Loan_Intent,
    c.Historical_Default_File,
    c.Credit_History_Length_Years,
    f.Person_Age,
    f.Person_Income,
    f.Person_Emp_Length,
    f.Loan_Grade,
    f.Loan_Amount,
    f.Loan_Interest_Rate,
    f.Loan_Percent_Income,
    f.Loan_Status_Default,
    p.Probability_of_Default,
    p.Risk_Tier
FROM Fact_Loan_Details f
JOIN Dim_Borrower_Demographics d ON f.Demographic_ID = d.Demographic_ID
JOIN Dim_Loan_Intent i ON f.Intent_ID = i.Intent_ID
JOIN Dim_Credit_History c ON f.Credit_Hist_ID = c.Credit_Hist_ID
JOIN Fact_Loan_Predictions p ON f.Loan_ID = p.Loan_ID;

