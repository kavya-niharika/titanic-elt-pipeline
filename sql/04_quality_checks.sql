CREATE TABLE IF NOT EXISTS dq_results (
    check_name VARCHAR(100) NOT NULL,
    status VARCHAR(10) NOT NULL,
    checked_at DATETIME NOT NULL
);

DELETE FROM dq_results;

INSERT INTO dq_results (check_name, status, checked_at)
SELECT 'raw_count_equals_clean_count',
       IF((SELECT COUNT(*) FROM raw_titanic) = (SELECT COUNT(*) FROM clean_passengers), 'PASS', 'FAIL'),
       NOW();

INSERT INTO dq_results (check_name, status, checked_at)
SELECT 'no_null_age',
       IF((SELECT COUNT(*) FROM clean_passengers WHERE age IS NULL) = 0, 'PASS', 'FAIL'),
       NOW();

INSERT INTO dq_results (check_name, status, checked_at)
SELECT 'no_null_embarked',
       IF((SELECT COUNT(*) FROM clean_passengers WHERE embarked IS NULL OR TRIM(embarked) = '') = 0, 'PASS', 'FAIL'),
       NOW();

-- The seaborn Titanic data has no passenger identifier. Here, a duplicate means
-- two rows identical across the passenger attributes retained in clean_passengers.
INSERT INTO dq_results (check_name, status, checked_at)
SELECT 'no_duplicate_passengers',
       IF(
           (SELECT COUNT(*) FROM (
               SELECT passenger_class, sex, age, sibsp, parch, fare, embarked, survived, COUNT(*) AS n
               FROM clean_passengers
               GROUP BY passenger_class, sex, age, sibsp, parch, fare, embarked, survived
               HAVING COUNT(*) > 1
           ) AS duplicates_found) = 0,
           'PASS', 'FAIL'
       ),
       NOW();

INSERT INTO dq_results (check_name, status, checked_at)
SELECT 'age_between_0_and_100',
       IF((SELECT COUNT(*) FROM clean_passengers WHERE age < 0 OR age > 100 OR age IS NULL) = 0, 'PASS', 'FAIL'),
       NOW();

INSERT INTO dq_results (check_name, status, checked_at)
SELECT 'sex_only_0_or_1',
       IF((SELECT COUNT(*) FROM clean_passengers WHERE sex NOT IN (0, 1) OR sex IS NULL) = 0, 'PASS', 'FAIL'),
       NOW();

SELECT check_name, status, checked_at
FROM dq_results
ORDER BY check_name;
