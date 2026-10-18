SET search_path = dv;
SELECT 'hub_ship_mode' t, count(*) FROM hub_ship_mode UNION ALL SELECT 'hub_segment',count(*) FROM hub_segment
UNION ALL SELECT 'hub_location',count(*) FROM hub_location UNION ALL SELECT 'hub_product',count(*) FROM hub_product
UNION ALL SELECT 'hub_sale',count(*) FROM hub_sale UNION ALL SELECT 'lnk_sale',count(*) FROM lnk_sale
UNION ALL SELECT 'sat_location_region',count(*) FROM sat_location_region UNION ALL SELECT 'sat_sale_metrics',count(*) FROM sat_sale_metrics;
-- целостность связей: должно быть 0
SELECT count(*) AS orphan_links FROM lnk_sale l LEFT JOIN hub_location h USING(location_hk) WHERE h.location_hk IS NULL;
-- сверка с источником
SELECT round(sum(sales),2) dv_sales, (SELECT round(sum(sales),2) FROM stg_superstore) stg_sales FROM sat_sale_metrics;
-- пример запроса через DV
SELECT p.category, sum(m.sales)::numeric(12,2) sales, sum(m.profit)::numeric(12,2) profit
FROM lnk_sale l JOIN hub_product p USING(product_hk) JOIN sat_sale_metrics m USING(sale_hk) GROUP BY 1 ORDER BY 2 DESC;
