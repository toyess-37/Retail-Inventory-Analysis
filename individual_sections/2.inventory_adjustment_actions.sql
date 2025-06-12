USE inventory_project_sql;

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