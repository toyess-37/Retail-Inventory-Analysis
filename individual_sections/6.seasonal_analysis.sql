USE inventory_project_sql;

-- Create view for monthly statistics
DROP VIEW IF EXISTS monthly_stats;
CREATE VIEW monthly_stats AS
SELECT
    StoreID,
    Region,
    ProductID,
    MONTH(PDate) AS MonthNo,
    MONTHNAME(PDate) AS MonthName,
    WeatherCondition AS Weather,
    AVG(UnitsSold) AS AvgMonthlySales,
    AVG(DemandForecast) AS AvgMonthlyForecast
FROM FactInventorySales
GROUP BY ProductID, StoreID, Region, MonthNo, MonthName, WeatherCondition;

-- Overall statistics
DROP VIEW IF EXISTS overall_stats;
CREATE VIEW overall_stats AS
SELECT
    StoreID,
    Region,
    ProductID,
    AVG(AvgMonthlySales) AS OverallAvgSales
FROM monthly_stats
GROUP BY ProductID, StoreID, Region;

DROP VIEW IF EXISTS ViewSeasonalDemandAnalysis;
CREATE VIEW ViewSeasonalDemandAnalysis AS
SELECT 
    m.StoreID,
    m.Region,
    m.ProductID,
    m.MonthName,
    m.Weather,
    m.AvgMonthlySales,
    o.OverallAvgSales,
    -- WeatherCondition index
    CASE 
        WHEN o.OverallAvgSales > 0 
        THEN m.AvgMonthlySales / o.OverallAvgSales 
        ELSE 1 
    END AS WeatherConditionIndex,
    -- Demand pattern classification
    CASE 
        WHEN m.AvgMonthlySales > o.OverallAvgSales * 1.2 THEN 'High Season'
        WHEN m.AvgMonthlySales < o.OverallAvgSales * 0.8 THEN 'Low Season'
        ELSE 'Regular Season'
    END AS SeasonalPattern
FROM monthly_stats m JOIN overall_stats o ON m.StoreID = o.StoreID AND m.Region = o.Region AND m.ProductID = o.ProductID
ORDER BY m.StoreID, m.Region, m.ProductID, m.MonthNo;
-- SELECT * FROM ViewSeasonalDemandAnalysis WHERE StoreID LIKE 'S001' AND Region LIKE 'North';

-- Only Season-wise stats
DROP VIEW IF EXISTS weather_stats;
CREATE VIEW weather_stats AS
SELECT
    StoreID,
    Region,
    ProductID,
    WeatherCondition,
    ROUND(AVG(UnitsSold), 2) AS AvgSeasonalSales,
    ROUND(AVG(DemandForecast), 2) AS AvgSeasonalDemand,
    SUM(UnitsSold * EffectivePrice) AS Turnover
FROM FactInventorySales
GROUP BY ProductID, StoreID, Region, WeatherCondition
ORDER BY Turnover DESC, AvgSeasonalSales DESC, AvgSeasonalDemand DESC;
-- SELECT * FROM weather_stats WHERE StoreID LIKE 'S001' AND Region LIKE 'North';