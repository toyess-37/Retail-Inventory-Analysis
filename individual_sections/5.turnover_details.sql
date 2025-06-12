USE inventory_project_sql;

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
-- SELECT * FROM ViewInventoryTurnover; -- The inventory turnover details
