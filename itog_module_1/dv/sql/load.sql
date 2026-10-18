SET search_path = dv;
BEGIN;

CREATE TEMP TABLE raw (ship_mode TEXT, segment TEXT, country TEXT, city TEXT, state TEXT, postal_code TEXT,
  region TEXT, category TEXT, sub_category TEXT, sales NUMERIC, quantity INT, discount NUMERIC, profit NUMERIC)
  DISTRIBUTED RANDOMLY;
\copy raw FROM '/import/SampleSuperstore.csv' WITH (FORMAT csv, HEADER true)
INSERT INTO stg_superstore (sale_bk, ship_mode, segment, country, city, state, postal_code,
                            region, category, sub_category, sales, quantity, discount, profit)
SELECT h || '|' || row_number() OVER (PARTITION BY h)::text, ship_mode, segment, country, city, state, postal_code,
       region, category, sub_category, sales, quantity, discount, profit
FROM (SELECT *, md5(concat_ws('|', ship_mode, segment, country, city, state, postal_code, region,
                              category, sub_category, sales::numeric(12,4), quantity, discount::numeric(5,2),
                              profit::numeric(12,4))) AS h FROM raw) r;

CREATE TEMP VIEW stg_keys AS
SELECT *, md5(sale_bk) AS sale_hk, md5(ship_mode) AS ship_mode_hk, md5(segment) AS segment_hk,
       md5(concat_ws('|', country, state, city, postal_code)) AS location_hk,
       md5(concat_ws('|', category, sub_category)) AS product_hk
FROM stg_superstore;

INSERT INTO hub_ship_mode (ship_mode_hk, ship_mode, load_dts, record_source)
SELECT DISTINCT ship_mode_hk, ship_mode, now(), 'SampleSuperstore.csv' FROM stg_keys;

INSERT INTO hub_segment (segment_hk, segment, load_dts, record_source)
SELECT DISTINCT segment_hk, segment, now(), 'SampleSuperstore.csv' FROM stg_keys;

INSERT INTO hub_location (location_hk, country, state, city, postal_code, load_dts, record_source)
SELECT DISTINCT location_hk, country, state, city, postal_code, now(), 'SampleSuperstore.csv' FROM stg_keys;

INSERT INTO hub_product (product_hk, category, sub_category, load_dts, record_source)
SELECT DISTINCT product_hk, category, sub_category, now(), 'SampleSuperstore.csv' FROM stg_keys;

INSERT INTO hub_sale (sale_hk, sale_bk, load_dts, record_source)
SELECT sale_hk, sale_bk, now(), 'SampleSuperstore.csv' FROM stg_keys;

INSERT INTO lnk_sale (lnk_sale_hk, sale_hk, ship_mode_hk, segment_hk, location_hk, product_hk, load_dts, record_source)
SELECT md5(sale_hk || ship_mode_hk || segment_hk || location_hk || product_hk),
       sale_hk, ship_mode_hk, segment_hk, location_hk, product_hk, now(), 'SampleSuperstore.csv'
FROM stg_keys;

INSERT INTO sat_location_region (location_hk, load_dts, hash_diff, region, record_source)
SELECT DISTINCT location_hk, now(), md5(region), region, 'SampleSuperstore.csv' FROM stg_keys;

INSERT INTO sat_sale_metrics (sale_hk, load_dts, hash_diff, sales, quantity, discount, profit, record_source)
SELECT sale_hk, now(), md5(sales::text||'|'||quantity||'|'||discount||'|'||profit),
       sales, quantity, discount, profit, 'SampleSuperstore.csv'
FROM stg_keys;

COMMIT;
