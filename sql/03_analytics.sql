CREATE OR REPLACE VIEW vw_survival_by_class_sex AS
SELECT
    passenger_class,
    sex,
    COUNT(*) AS passenger_count,
    SUM(survived) AS survivors,
    ROUND(100.0 * AVG(survived), 2) AS survival_rate_pct
FROM clean_passengers
GROUP BY passenger_class, sex;

CREATE OR REPLACE VIEW vw_survival_by_age_group AS
SELECT
    age_group,
    COUNT(*) AS passenger_count,
    SUM(survived) AS survivors,
    ROUND(100.0 * AVG(survived), 2) AS survival_rate_pct
FROM clean_passengers
GROUP BY age_group;

CREATE OR REPLACE VIEW vw_top3_fares_each_class AS
SELECT
    passenger_class,
    fare,
    sex,
    age,
    survived,
    fare_rank
FROM (
    SELECT
        passenger_class,
        fare,
        sex,
        age,
        survived,
        RANK() OVER (
            PARTITION BY passenger_class
            ORDER BY fare DESC
        ) AS fare_rank
    FROM clean_passengers
) AS ranked
WHERE fare_rank <= 3;
