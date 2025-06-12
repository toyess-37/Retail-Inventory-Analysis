USE inventory_project_sql;

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