--1
SELECT 
        channel_id, 
        prod_id, 
        SUM(amount_sold) AS total_sales
    FROM 
        sales 
    GROUP BY 
        channel_id, 
        prod_id
    ORDER BY 
        channel_id, 
        prod_id;

--2
CREATE MATERIALIZED VIEW SALES_CHAN_PROD_MV
ENABLE QUERY REWRITE AS
SELECT 
    channel_id, 
    prod_id, 
    SUM(amount_sold) AS total_sales
FROM 
    sales 
GROUP BY 
    channel_id, 
    prod_id;

SELECT 
    channel_id, 
    prod_id, 
    total_sales
FROM 
    SALES_CHAN_PROD_MV
WHERE 
    channel_id = 'some_channel';

--3
SELECT 
        CHANNEL_DESC, 
        prod_id, 
        SUM(amount_sold) AS total_sales
    FROM 
        CHANNELS, sales
    GROUP BY 
        channel_desc, 
        prod_id
    ORDER BY 
        channel_desc, 
        prod_id;

--4


--5
--DROP TABLE DIM_CHANNEL;
--DROP TABLE DIM_PRODUCT;

--CREATE TABLE DIM_CHANNEL (
--    channel_id       NUMBER(6) PRIMARY KEY NOT NULL,
--    channel_desc     VARCHAR2(20) NOT NULL,
--    channel_class    VARCHAR2(20) NOT NULL,
--    channel_class_id NUMBER(6) NOT NULL,
--    channel_total    VARCHAR2(13) NOT NULL,
--    channel_total_id NUMBER(6) NOT NULL
--);
--
--CREATE TABLE DIM_PRODUCT (
--    prod_id                  NUMBER(6) PRIMARY KEY NOT NULL,
--    prod_name                VARCHAR2(50) NOT NULL,
--    prod_desc                VARCHAR2(4000) NOT NULL,
--    prod_subcategory         VARCHAR2(50) NOT NULL,
--    prod_subcategory_id      NUMBER NOT NULL,
--    prod_subcategory_desc    VARCHAR2(2000) NOT NULL,
--    prod_category            VARCHAR2(50) NOT NULL,
--    prod_category_id         NUMBER NOT NULL,
--    prod_category_desc       VARCHAR2(2000) NOT NULL,
--    prod_weight_class        NUMBER(3) NOT NULL,
--    prod_unit_of_measure     VARCHAR2(20),
--    prod_pack_size           VARCHAR2(30) NOT NULL,
--    supplier_id              NUMBER(6) NOT NULL,
--    prod_status              VARCHAR2(20) NOT NULL,
--    prod_list_price          NUMBER(8,2) NOT NULL,
--    prod_min_price           NUMBER(8,2) NOT NULL,
--    prod_total               VARCHAR2(13) NOT NULL,
--    prod_total_id            NUMBER NOT NULL,
--    prod_src_id              NUMBER,
--    prod_eff_from            DATE,
--    prod_eff_to              DATE,
--    prod_valid               VARCHAR2(1)
--);

SELECT 
    c.channel_desc,
    p.prod_name,
    s.total_sales
FROM 
    SALES_CHAN_PROD_MV s 
JOIN 
    DIM_CHANNEL c ON s.channel_id = c.channel_id  
JOIN 
    DIM_PRODUCT p ON s.prod_id = p.prod_id  
WHERE 
    c.channel_desc = 'SomeChannelName';





--6
--select * from channels;

SELECT 
    c.channel_name,
    p.product_name,
    s.total_sales
FROM 
    SALES_CHAN_PROD_MV s
JOIN 
    DIM_CHANNEL c ON s.channel_id = c.channel_id
JOIN 
    DIM_PRODUCT p ON s.prod_id = p.prod_id
WHERE 
    c.channel_name = 'SomeChannelName';
--    
--SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);    
--
SELECT /*+ FULL(s) FULL(c) FULL(p) */
c.channel_name,
p.product_name,
s.total_sales
FROM
SALES_CHAN_PROD_MV s
JOIN
DIM_CHANNEL c ON s.channel_id = c.channel_id
JOIN
DIM_PRODUCT p ON s.prod_id = p.prod_id
WHERE
c.channel_name = 'SomeChannelName';















--
--drop table Dim_channel;
--
--CREATE TABLE DIM_COUNTRY (
--    country_id            NUMBER(6) PRIMARY KEY NOT NULL,
--    country_iso_code      CHAR(2) NOT NULL,
--    country_name          VARCHAR2(100) NOT NULL,
--    country_code          VARCHAR2(3),
--    country_subregion     VARCHAR2(30) NOT NULL,
--    country_subregion_id  NUMBER NOT NULL,
--    country_region        VARCHAR2(50) NOT NULL,
--    country_region_id     NUMBER NOT NULL,
--    country_total         VARCHAR2(11) NOT NULL,
--    country_total_id      NUMBER NOT NULL,
--    country_name_hist     VARCHAR2(40)
--);


--select * from shcountries;

--------------------------------------not using decode

--SELECT 
--    c.channel_desc AS channel_description,
--    p.prod_category,
--    co.country_name,
--    SUM(s.amount_sold) AS total_sales
--FROM
--    sales s
--JOIN DIM_CHANNEL c ON s.channel_id = c.channel_id
--JOIN DIM_PRODUCT p ON s.prod_id = p.prod_id
--JOIN shcountries co ON s.country_id = co.country_id
--WHERE
--    p.prod_category NOT IN ('Peripherals and Accessories', 'Hardware', 'Photo')
--    AND co.country_name IN ('France', 'Italy')
--GROUP BY ROLLUP(
--    c.channel_desc,
--    p.prod_category,
--    co.country_name
--)
--ORDER BY 
--    channel_description,
--    p.prod_category,
--    co.country_name;


---------------------------------------------------------------------------------------------------------------------

WITH TotalSales AS (
    SELECT
        ch.channel_desc,
        pr.prod_category,
        DECODE(co.country_name, 'France', 'Totals in France', 'Italy', 'Total in Italy', 'Totals in France and Italy') AS decoded_country,
        SUM(sa.amount_sold) AS total_sales
    FROM
        sales sa
        JOIN channels ch ON sa.channel_id = ch.channel_id
        JOIN products pr ON sa.prod_id = pr.prod_id
        JOIN customers cu ON sa.cust_id = cu.cust_id
        JOIN shcountries co ON cu.country_id = co.country_id
    WHERE
        pr.prod_category NOT IN ('Peripherals and Accessories', 'Hardware', 'Photo')
        AND co.country_name IN ('France', 'Italy')
    GROUP BY
        GROUPING SETS (
            (ch.channel_desc, pr.prod_category, co.country_name),
            (ch.channel_desc, pr.prod_category)
        )
),
SalesReport AS (
    SELECT
        DECODE(channel_desc, NULL, 'All Channels', channel_desc) AS channel_desc,
        DECODE(prod_category, NULL, 'Category All Categories', 'Category ' || prod_category) AS prod_category,
        DECODE(decoded_country, NULL, 'Totals in France and Italy', decoded_country) AS decoded_country,
        '€ ' || SUM(total_sales)  AS total_sales
    FROM
        TotalSales
    GROUP BY
        GROUPING SETS (
            (channel_desc, prod_category, decoded_country),
            (channel_desc, 'All Categories', 'Totals in France and Italy'),
            ('All Channels', 'All Categories', 'Totals in France and Italy')
        )
)
SELECT
    *
FROM
    SalesReport
ORDER BY
    channel_desc, prod_category, decoded_country, total_sales DESC;