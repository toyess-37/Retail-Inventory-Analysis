USE inventory_project_sql;

-- Check the past 30 days movement trends
DROP VIEW IF EXISTS ViewStockMovementTrends;
CREATE VIEW ViewStockMovementTrends AS
SELECT
    StoreID,
    Region,
    ProductID,
    AVG(InventoryLevel) AS AvgStock30Days,
    MIN(InventoryLevel) AS MinStock30Days,
    MAX(InventoryLevel) AS MaxStock30Days,
    STDDEV(InventoryLevel) AS StockVolatility
FROM FactInventorySales
WHERE PDate >= (
    SELECT DATE_SUB(MAX(PDate), INTERVAL 30 DAY) -- replace MAX(PDate) with your desired date
    FROM FactInventorySales
)
GROUP BY ProductID, StoreID, Region
ORDER BY StoreID, Region, ProductID;
-- SELECT * FROM ViewStockMovementTrends LIMIT 1000; -- Check the movement trends

-- Daily sales of products
DROP VIEW IF EXISTS ViewProductDailySales;
CREATE VIEW ViewProductDailySales AS
SELECT
    PDate,
    ProductID,
    SUM(UnitsSold) AS DailySales,
    SUM(InventoryLevel) AS DailyInventory,
    SUM(DemandForecast) AS DailyForecast
FROM FactInventorySales
GROUP BY PDate, ProductID
ORDER BY ProductID, PDate;
-- SELECT * FROM ViewProductDailySales LIMIT 100; -- Check the Daily Sales of Products

-- Average Daily Sales
DROP VIEW IF EXISTS ViewProductAverageDailySales;
CREATE VIEW ViewProductAverageDailySales AS
SELECT
    ProductID,
    AVG(DailySales) AS AvgDailySales,
    AVG(DailyForecast) AS AvgDailyForecast,
    CASE WHEN AVG(DailyForecast) = 0 THEN NULL
    ELSE (AVG(DailySales) / AVG(DailyForecast)) END AS AvgForecastAccuracy
FROM ViewProductDailySales
GROUP BY ProductID
ORDER BY ProductID;
-- SELECT * FROM ViewProductAverageDailySales; -- Check the Average Daily Sales of Products





