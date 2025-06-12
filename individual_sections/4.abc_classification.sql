USE inventory_project_sql;

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
GROUP BY abc.StoreID, abc.Region, abc.ProductID, abc.TotalRevenue, abc.CumulativePercentage, abc.ABCCategory
ORDER BY abc.StoreID, abc.Region, abc.ABCCategory, abc.CumulativePercentage, abc.TotalRevenue, abc.ProductID DESC;
-- SELECT * FROM ViewABCAnalysis; -- Check the ABC Analysis results