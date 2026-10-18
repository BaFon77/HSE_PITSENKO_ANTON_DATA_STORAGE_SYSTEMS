DROP SCHEMA IF EXISTS dv CASCADE;
CREATE SCHEMA dv;
SET search_path = dv;

-- В датасете нет ни одного id, поэтому бизнес-ключи собираем из самих данных.
-- sale_bk = md5(вся строка) + '|' + номер повтора: 17 строк в файле полностью
-- одинаковые, без номера они бы слились в одну и мы потеряли продажи
CREATE TABLE stg_superstore (
    sale_bk      VARCHAR(40),
    ship_mode    TEXT,
    segment      TEXT,
    country      TEXT,
    city         TEXT,
    state        TEXT,
    postal_code  TEXT,
    region       TEXT,
    category     TEXT,
    sub_category TEXT,
    sales        NUMERIC(12,4),
    quantity     INT,
    discount     NUMERIC(5,2),
    profit       NUMERIC(12,4)
) DISTRIBUTED BY (sale_bk);

CREATE TABLE hub_ship_mode (
    ship_mode_hk CHAR(32) PRIMARY KEY,
    ship_mode    VARCHAR(30) NOT NULL,
    load_dts     TIMESTAMP   NOT NULL DEFAULT now(),
    record_source VARCHAR(50) NOT NULL
) DISTRIBUTED BY (ship_mode_hk);

CREATE TABLE hub_segment (
    segment_hk   CHAR(32) PRIMARY KEY,
    segment      VARCHAR(30) NOT NULL,
    load_dts     TIMESTAMP   NOT NULL DEFAULT now(),
    record_source VARCHAR(50) NOT NULL
) DISTRIBUTED BY (segment_hk);

-- У локации нет id, ключом служат страна + штат + город + индекс
CREATE TABLE hub_location (
    location_hk  CHAR(32) PRIMARY KEY,
    country      VARCHAR(50)  NOT NULL,
    state        VARCHAR(50)  NOT NULL,
    city         VARCHAR(100) NOT NULL,
    postal_code  VARCHAR(10)  NOT NULL,
    load_dts     TIMESTAMP    NOT NULL DEFAULT now(),
    record_source VARCHAR(50) NOT NULL
) DISTRIBUTED BY (location_hk);

-- Конкретных товаров в данных нет, поэтому продукт = категория + подкатегория
CREATE TABLE hub_product (
    product_hk   CHAR(32) PRIMARY KEY,
    category     VARCHAR(50) NOT NULL,
    sub_category VARCHAR(50) NOT NULL,
    load_dts     TIMESTAMP   NOT NULL DEFAULT now(),
    record_source VARCHAR(50) NOT NULL
) DISTRIBUTED BY (product_hk);

CREATE TABLE hub_sale (
    sale_hk      CHAR(32) PRIMARY KEY,
    sale_bk      VARCHAR(40) NOT NULL,   -- 32 символа md5 + '|' + номер повтора
    load_dts     TIMESTAMP   NOT NULL DEFAULT now(),
    record_source VARCHAR(50) NOT NULL
) DISTRIBUTED BY (sale_hk);

CREATE TABLE lnk_sale (
    lnk_sale_hk  CHAR(32) PRIMARY KEY,
    sale_hk      CHAR(32) NOT NULL,
    ship_mode_hk CHAR(32) NOT NULL,
    segment_hk   CHAR(32) NOT NULL,
    location_hk  CHAR(32) NOT NULL,
    product_hk   CHAR(32) NOT NULL,
    load_dts     TIMESTAMP   NOT NULL DEFAULT now(),
    record_source VARCHAR(50) NOT NULL,
    CONSTRAINT fk_lnk_sale_sale     FOREIGN KEY (sale_hk)      REFERENCES hub_sale (sale_hk),
    CONSTRAINT fk_lnk_sale_shipmode FOREIGN KEY (ship_mode_hk) REFERENCES hub_ship_mode (ship_mode_hk),
    CONSTRAINT fk_lnk_sale_segment  FOREIGN KEY (segment_hk)   REFERENCES hub_segment (segment_hk),
    CONSTRAINT fk_lnk_sale_location FOREIGN KEY (location_hk)  REFERENCES hub_location (location_hk),
    CONSTRAINT fk_lnk_sale_product  FOREIGN KEY (product_hk)   REFERENCES hub_product (product_hk)
) DISTRIBUTED BY (lnk_sale_hk);

-- Регион определяется штатом, а не продажей, поэтому это спутник локации.
CREATE TABLE sat_location_region (
    location_hk  CHAR(32)    NOT NULL,
    load_dts     TIMESTAMP   NOT NULL,
    hash_diff    CHAR(32)    NOT NULL,
    region       VARCHAR(20) NOT NULL,
    record_source VARCHAR(50) NOT NULL,
    PRIMARY KEY (location_hk, load_dts),
    CONSTRAINT fk_sat_location_hub FOREIGN KEY (location_hk) REFERENCES hub_location (location_hk)
) DISTRIBUTED BY (location_hk);

-- Меры описывают конкретную продажу и могут уточняться, поэтому лежат в спутнике
CREATE TABLE sat_sale_metrics (
    sale_hk      CHAR(32)    NOT NULL,
    load_dts     TIMESTAMP   NOT NULL,
    hash_diff    CHAR(32)    NOT NULL,
    sales        NUMERIC(12,4) NOT NULL,
    quantity     INT           NOT NULL,
    discount     NUMERIC(5,2)  NOT NULL,
    profit       NUMERIC(12,4) NOT NULL,
    record_source VARCHAR(50)  NOT NULL,
    PRIMARY KEY (sale_hk, load_dts),
    CONSTRAINT fk_sat_sale_hub FOREIGN KEY (sale_hk) REFERENCES hub_sale (sale_hk)
) DISTRIBUTED BY (sale_hk);
