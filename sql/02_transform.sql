DROP TABLE IF EXISTS clean_passengers;

CREATE TABLE clean_passengers AS
WITH age_filled AS (
    SELECT
        s.*,
        COALESCE(
            s.age,
            AVG(s.age) OVER (PARTITION BY s.passenger_class, s.sex)
        ) AS age_imputed
    FROM stg_titanic AS s
),
embarked_mode AS (
    SELECT embarked
    FROM stg_titanic
    WHERE embarked IS NOT NULL AND TRIM(embarked) <> ''
    GROUP BY embarked
    ORDER BY COUNT(*) DESC, embarked ASC
    LIMIT 1
),
base AS (
    SELECT
        a.survived,
        a.passenger_class,
        CASE WHEN a.sex = 'female' THEN 1 ELSE 0 END AS sex,
        a.age_imputed AS age,
        a.sibsp,
        a.parch,
        a.fare,
        COALESCE(NULLIF(a.embarked, ''), (SELECT embarked FROM embarked_mode)) AS embarked,
        a.who,
        a.adult_male,
        a.alive,
        a.load_timestamp,
        a.batch_id
    FROM age_filled AS a
)
SELECT
    survived,
    passenger_class,
    sex,
    age,
    sibsp,
    parch,
    fare,
    embarked,
    who,
    adult_male,
    alive,
    CASE
        WHEN age <= 12 THEN 'Child'
        WHEN age <= 19 THEN 'Teen'
        WHEN age <= 59 THEN 'Adult'
        ELSE 'Senior'
    END AS age_group,
    sibsp + parch + 1 AS family_size,
    CASE WHEN sibsp + parch = 0 THEN 1 ELSE 0 END AS is_alone,
    CASE
        WHEN fare_quartile = 1 THEN 'Low'
        WHEN fare_quartile = 2 THEN 'Medium'
        WHEN fare_quartile = 3 THEN 'High'
        ELSE 'Premium'
    END AS fare_category,
    load_timestamp,
    batch_id
FROM (
    SELECT
        b.*,
        NTILE(4) OVER (ORDER BY fare, passenger_class) AS fare_quartile
    FROM base AS b
) AS categorized;
