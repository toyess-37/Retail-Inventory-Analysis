USE inventory_project_sql;

-- ======================================
-- ABC ANALYSIS VIEW
-- ======================================

-- ABC Analysis according to revenue
-- ABC Classification of Products
/*
  Categorizes products based on their contribution to total revenue
  according to each store (storeID, region)
    A items: Top 80% of revenue (most important to that store)
    B items: Next 15% of revenue (moderately important to that store)
    C items: Bottom 5% of revenue (least important to that store)
*/

DROP VIEW IF EXISTS ViewABCAnalysis;
CREATE VIEW ViewABCAnalysis AS
SELECT
    abc.StoreID,
    abc.Region,
    abc.ProductID,
    abc.ABCCategory,
    abc.TotalRevenue,
    abc.CumulativePercentage,
	COALESCE(SUM(fis.UnitsSold), 0) AS TotalUnitsSold,
    COALESCE(AVG(fis.InventoryLevel), 0) AS AverageInventoryLevel,
    CASE
        WHEN COALESCE(AVG(fis.InventoryLevel), 0) = 0 THEN NULL
        ELSE COALESCE(SUM(fis.UnitsSold), 0) / COALESCE(AVG(fis.InventoryLevel), 1)
    END AS InventoryTurnoverRate
FROM 
(
    SELECT 
        StoreID,
        Region,
        ProductID,
        TotalRevenue,
        (CumulativeRevenue / GrandTotalRevenue) * 100 AS CumulativePercentage,
        CASE
            WHEN (CumulativeRevenue / GrandTotalRevenue) * 100 <= 80 THEN 'A'
            WHEN (CumulativeRevenue / GrandTotalRevenue) * 100 > 80 AND (CumulativeRevenue / GrandTotalRevenue) * 100 <= 95 THEN 'B'
            ELSE 'C'
        END AS ABCCategory -- Assigning ABC Categories based on cumulative percentage across each store
    FROM 
	(
        SELECT
            StoreID,
            Region,
            ProductID,
            TotalRevenue,
            SUM(TotalRevenue) OVER (PARTITION BY StoreID, Region ORDER BY TotalRevenue DESC) AS CumulativeRevenue,
            SUM(TotalRevenue) OVER (PARTITION BY StoreID, Region) AS GrandTotalRevenue
        FROM 
		(
            SELECT
                StoreID,
                Region, 
                ProductID,
                SUM(UnitsSold * EffectivePrice) AS TotalRevenue
            FROM FactInventorySales
            GROUP BY StoreID, Region, ProductID
        ) AS ProductRevenue -- Calculating Total Revenue for each Product across each store
    ) AS CumulativeRevenues -- Calculating Cumulative Revenue and Grand Total Revenue for each store
) AS abc JOIN FactInventorySales fis ON abc.ProductID = fis.ProductID AND abc.StoreID = fis.StoreID AND abc.Region = fis.Region
WHERE fis.PDate >= DATE_SUB('2023-12-31', INTERVAL 30 DAY) 
-- '2023-12-31' is a placeholder date, change as needed
-- if you want to check the net categorization replace DATE_SUB('2023-12-31', INTERVAL 30 DAY) with '2022-01-01'
GROUP BY abc.StoreID, abc.Region, abc.ProductID, abc.TotalRevenue, abc.CumulativePercentage, abc.ABCCategory
ORDER BY abc.StoreID, abc.Region, abc.ABCCategory, abc.CumulativePercentage, abc.TotalRevenue, abc.ProductID DESC;
-- SELECT * FROM ViewABCAnalysis; -- Check the ABC Analysis results

-- ======================================
-- INVENTORY TURNOVER METRICS
-- ======================================

-- View the Inventory Turnover
DROP VIEW IF EXISTS ViewInventoryTurnover;
CREATE VIEW ViewInventoryTurnover AS
SELECT 
    ProductID,
    StoreID,
    Region,

    -- Total units sold in the period
    SUM(UnitsSold) AS TotalUnitsSold,

    -- Average inventory level
    AVG(InventoryLevel) AS AvgInventoryLevel,

    -- Inventory turnover ratio
    CASE 
        WHEN AVG(InventoryLevel) > 0 
        THEN SUM(UnitsSold) / AVG(InventoryLevel)
        ELSE 0 
    END AS InventoryTurnoverRatio,

    -- Days in inventory (365 / turnover ratio)
    CASE 
        WHEN AVG(InventoryLevel) > 0 AND SUM(UnitsSold) > 0
        THEN 365 / (SUM(UnitsSold) / AVG(InventoryLevel))
        ELSE NULL 
    END AS DaysInInventory,

    -- Total revenue
    SUM(UnitsSold * EffectivePrice) AS TotalRevenue,

    -- Average selling price
    AVG(EffectivePrice) AS AvgSellingPrice
FROM FactInventorySales
GROUP BY ProductID, StoreID, Region
HAVING AVG(InventoryLevel) > 0
ORDER BY InventoryTurnoverRatio DESC;
-- SELECT * FROM ViewInventoryTurnover WHERE StoreID LIKE 'S001' AND Region LIKE 'North' LIMIT 5; -- The inventory turnover details

-- ======================================
-- INVENTORY STOCK ACTIONS & REORDERING
-- ======================================

-- in this section, replace '2023-12-31' with your desired date

-- Important Inventory Actions and Recommendations
/*
    We'll see a list of inventory actions on the products.
    - First we classify products as Slow, Medium and Fast movers.
    - Then we use the Reorder Points to estimate the quantity changes required in the stocks
    - We analyze and compare the data of the last 30 days starting from a given date (default value: '2023-12-31').
*/

-- Current Stock Levels of products
DROP VIEW IF EXISTS ViewCurrentStockLevels;
CREATE VIEW ViewCurrentStockLevels AS
SELECT 
    ProductID,
    StoreID,
    Region,
    InventoryLevel AS CurrentStockLevel,
    PDate AS LastRecordedDate
FROM (
    SELECT 
        ProductID,
        StoreID,
        Region,
        InventoryLevel,
        PDate,
        ROW_NUMBER() OVER (
            PARTITION BY ProductID, StoreID, Region 
            ORDER BY PDate DESC
        ) as rn
    FROM FactInventorySales
) ranked
WHERE rn = DATEDIFF((SELECT MAX(PDate) FROM FactInventorySales),'2023-12-31')+1 -- Change the '2023-12-31' here to your desired date
ORDER BY ProductID, StoreID, Region;
-- SELECT * FROM ViewCurrentStockLevels WHERE StoreID LIKE 'S001' AND Region LIKE 'North'; -- Check the latest stock levels

-- Reorder points using Lead time demand
-- lead time is assumed to be 1 day (adjust accordingly)
DROP VIEW IF EXISTS ViewReorderPoints;
CREATE VIEW ViewReorderPoints AS
SELECT 
    ProductID,
    StoreID,
    Region,

    AVG(UnitsSold) AS AvgDailyDemand,
    STDDEV(UnitsSold) AS DemandStdDev,
    1 AS LeadTimeDays,

    -- Safety stock (1.65 * std dev for 95% service level)
    CEIL(COALESCE(1.65 * STDDEV(UnitsSold), 0)) AS SafetyStock,

    -- Reorder Point = (Avg Daily Demand * Lead Time) + Safety Stock
    FLOOR((AVG(UnitsSold) * 1) + COALESCE(1.65 * STDDEV(UnitsSold), 0)) AS ReorderPoint -- Replace the 1 here with your lead time
FROM FactInventorySales
WHERE PDate >= DATE_SUB('2023-12-31', INTERVAL 30 DAY) -- Change '2023-12-31' as changed above
GROUP BY ProductID, StoreID, Region
ORDER BY ProductID, StoreID, Region;
-- SELECT * FROM ViewReorderPoints LIMIT 100;

-- Product Movement classification (Fast, Slow and Medium)

-- stats of the movements of last 30 days starting from current date (default: '2023-12-31')
DROP VIEW IF EXISTS ViewProductStats;
CREATE VIEW ViewProductStats AS
SELECT 
    ProductID,
    StoreID,
    Region,
    SUM(UnitsSold) AS TotalSold,
    AVG(InventoryLevel) AS AvgInventory,
    SUM(UnitsSold * EffectivePrice) AS TotalRevenue
FROM FactInventorySales
WHERE PDate >= DATE_SUB('2023-12-31', INTERVAL 30 DAY) -- change '2023-12-31' as changed above
GROUP BY StoreID, Region, ProductID;

-- Movement Classification as fast, slow and medium
DROP VIEW IF EXISTS ViewProductMovementClassification;
CREATE VIEW ViewProductMovementClassification AS
SELECT
    ProductID,
    StoreID,
    Region,

    -- Fast, Slow and Medium mover
    CASE 
        WHEN NTILE(5) OVER (ORDER BY TotalSold DESC) = 1 THEN 'Fast-moving'
        WHEN NTILE(5) OVER (ORDER BY TotalSold DESC) = 5 THEN 'Slow-moving'
        ELSE 'Medium-moving'
    END AS MovementCategory
FROM ViewProductStats;
-- SELECT * FROM ViewProductMovementClassification WHERE StoreID LIKE 'S001' AND Region LIKE 'North'; -- Example usage

-- Inventory Adjustment Recommendations
DROP VIEW IF EXISTS ViewInventoryActions;
CREATE VIEW ViewInventoryActions AS
SELECT 
    c.StoreID,
    c.Region,

    c.ProductID,
    c.CurrentStockLevel,

    r.ReorderPoint,
    r.AvgDailyDemand,

    -- Recommended adjustment
    CASE 
        WHEN c.CurrentStockLevel <= r.ReorderPoint
            THEN CONCAT('URGENT REORDER around: ', CAST(CEIL((r.ReorderPoint * 2 - c.CurrentStockLevel)/10)*10 AS CHAR), ' units')

        WHEN ((c.CurrentStockLevel > r.ReorderPoint AND c.CurrentStockLevel < r.ReorderPoint * 1.2) 
                AND pm.MovementCategory LIKE 'Fast-moving')
            THEN CONCAT('INCREASE by around: ', CAST(CEIL((r.ReorderPoint * 1.5 - c.CurrentStockLevel)/10)*10 AS CHAR), ' units')

        WHEN (c.CurrentStockLevel > r.ReorderPoint * 1.2 AND pm.MovementCategory LIKE 'Slow-moving') 
            THEN CONCAT('REDUCE by ', CAST(CEIL((c.CurrentStockLevel - r.ReorderPoint)/10)*10 AS CHAR), ' units')
    
        ELSE 'MAINTAIN current level'
    END AS RecommendedAction,
    
    pm.MovementCategory,

    CASE 
        WHEN c.CurrentStockLevel <= r.ReorderPoint THEN 'LOW'
        WHEN c.CurrentStockLevel <= (r.ReorderPoint * 1.2) THEN 'NOT LOW'
        ELSE 'ADEQUATE'
    END AS InventoryStatus,

    -- Days of stock remaining
    CASE 
        WHEN r.AvgDailyDemand > 0 
        THEN ROUND(c.CurrentStockLevel / r.AvgDailyDemand, 2)
        ELSE NULL 
    END AS DaysOfStockRemaining
FROM ViewCurrentStockLevels c
JOIN ViewReorderPoints r ON c.ProductID = r.ProductID AND c.StoreID = r.StoreID AND c.Region = r.Region
JOIN ViewProductMovementClassification pm ON c.ProductID = pm.ProductID AND c.StoreID = pm.StoreID AND c.Region = pm.Region
ORDER BY 
    CASE 
        WHEN c.CurrentStockLevel <= r.ReorderPoint THEN 1
        WHEN (c.CurrentStockLevel >= r.ReorderPoint) AND (c.CurrentStockLevel <= r.ReorderPoint * 1.2) THEN 2
        ELSE 3
    END,
    DaysOfStockRemaining ASC,
    pm.MovementCategory;
-- SELECT * FROM ViewInventoryActions WHERE StoreID LIKE 'S001' AND Region LIKE 'North'; -- Example usage

-- ======================================
-- MOVEMENT TRENDS & DAILY SALES
-- ======================================

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

-- ======================================
-- COMPETITOR PRICING ANALYSIS
-- ======================================

-- Competitor Pricing impact
DROP VIEW IF EXISTS ViewCompetitorPricingImpact;
CREATE VIEW ViewCompetitorPricingImpact AS
SELECT 
    StoreID,
    Region,
    ProductID,

    -- Price comparison metrics
    AVG(Price) AS Avg_OurPrice,
    AVG(CompetitorPricing) AS Avg_CompetitorPrice,
    CONCAT(CAST(ROUND((AVG(Price - CompetitorPricing) / AVG(CompetitorPricing)) * 100, 2) AS CHAR), '%') AS DifferencePercent,
    
    -- Sales impact analysis
    AVG(CASE WHEN Price > CompetitorPricing THEN UnitsSold ELSE NULL END) AS AvgSalesWhenPricedHigher,
    AVG(CASE WHEN Price <= CompetitorPricing THEN UnitsSold ELSE NULL END) AS AvgSalesWhenPricedLower,
    
    -- Revenue impact
    SUM(CASE WHEN Price > CompetitorPricing THEN UnitsSold * Price * (1 - Discount/100) ELSE 0 END) AS RevenueWhenPricedHigher,
    SUM(CASE WHEN Price <= CompetitorPricing THEN UnitsSold * Price * (1 - Discount/100) ELSE 0 END) AS RevenueWhenPricedLower,
    
    -- Recommendation
    CASE 
        WHEN AVG(CASE WHEN Price > CompetitorPricing THEN UnitsSold ELSE NULL END) < 
             AVG(CASE WHEN Price <= CompetitorPricing THEN UnitsSold ELSE NULL END) * 0.8
             AND AVG(Price - CompetitorPricing) > 0
        THEN 'Reduce Price'

        WHEN AVG(CASE WHEN Price <= CompetitorPricing THEN UnitsSold ELSE NULL END) > 
             AVG(CASE WHEN Price > CompetitorPricing THEN UnitsSold ELSE NULL END) * 1.2
        THEN 'Maintain Competitive Pricing'

        ELSE 'Monitor Competitor Response'
    END AS PricingRecommendation
FROM FactInventorySales
WHERE CompetitorPricing IS NOT NULL AND CompetitorPricing > 0
GROUP BY ProductID, StoreID, Region
ORDER BY DifferencePercent DESC;
-- SELECT * FROM ViewCompetitorPricingImpact WHERE PricingRecommendation LIKE 'Reduce Price'; -- Example usage

-- ======================================
-- SEASONAL DEMAND ANALYSIS
-- ======================================

-- View for monthly statistics
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

-- Number of Necessary Actions
/* SELECT 'IMMEDIATE REORDERS' AS ActionType, COUNT(*) AS Count
FROM ViewInventoryActions
WHERE RecommendedAction LIKE 'URGENT%'
UNION ALL
SELECT 'STOCK REDUCTIONS' AS ActionType, COUNT(*) AS Count
FROM ViewInventoryActions 
WHERE RecommendedAction LIKE 'REDUCE%'
UNION ALL
SELECT 'PRICING REVIEWS' AS ActionType, COUNT(*) AS Count
FROM ViewCompetitorPricingImpact 
WHERE PricingRecommendation = 'Reduce Price'; */





