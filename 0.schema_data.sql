DROP DATABASE IF EXISTS inventory_project_sql;
CREATE DATABASE IF NOT EXISTS inventory_project_sql;
USE inventory_project_sql;
SET GLOBAL local_infile = 1;

CREATE TABLE IF NOT EXISTS DimProduct 
(
  ProductID VARCHAR(255) NOT NULL PRIMARY KEY,
  Category VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS DimStore 
(
  StoreSK INTEGER PRIMARY KEY AUTO_INCREMENT, -- acts as the superkey
  StoreID VARCHAR(255) NOT NULL,
  Region VARCHAR(255),
  CONSTRAINT UNIQUE (StoreID, Region)
);

CREATE TABLE IF NOT EXISTS DimDate 
(
    DateKey INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    PDate DATE NOT NULL,
    PYear INT,
    PMonth INT,
    PDay INT,
    PDayOfWeek VARCHAR(10),
    Seasonality VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS FactInventorySales 
(
  FactID INT NOT NULL AUTO_INCREMENT,
  PDate DATE,
  StoreID VARCHAR(255),
  Region VARCHAR(255),
  ProductID VARCHAR(255),
  StoreSK INT,
  InventoryLevel INT,
  UnitsSold INT,
  UnitsOrdered INT,
  DemandForecast DECIMAL(10,2),
  Price DECIMAL(10,2),
  Discount DECIMAL(5,2),
  EffectivePrice DECIMAL(10,2),
  WeatherCondition VARCHAR(50),
  IsHolidayPromotion TINYINT(1),
  CompetitorPricing DECIMAL(10,2),
  PRIMARY KEY (FactID),
  FOREIGN KEY (StoreSK) REFERENCES DimStore(StoreSK),
  FOREIGN KEY (ProductID) REFERENCES DimProduct(ProductID)
);

-- Create a temporary table for loading data
CREATE TEMPORARY TABLE temp_inventory_data 
(
  PDate DATE,
  StoreID VARCHAR(255),
  ProductID VARCHAR(255),
  Category VARCHAR(255),
  Region VARCHAR(255),
  InventoryLevel INT,
  UnitsSold INT,
  UnitsOrdered INT,
  DemandForecast DECIMAL(10,2),
  Price DECIMAL(10,2),
  Discount DECIMAL(5,2),
  WeatherCondition VARCHAR(50),
  Holiday_Promotion TINYINT(1),
  CompetitorPricing DECIMAL(10,2),
  Seasonality VARCHAR(50)
);

-- Load data from CSV file into the temporary table
-- Make sure the file path is correct and accessible by the MySQL server
-- Adjust the file path as necessary for your environment
LOAD DATA LOCAL INFILE '/inventory_forecasting.csv'
INTO TABLE temp_inventory_data
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

INSERT INTO DimProduct (ProductID, Category)
SELECT TRIM(ProductID), TRIM(Category)
FROM temp_inventory_data
ON DUPLICATE KEY UPDATE Category = VALUES(Category);
-- SELECT * FROM DimProduct; -- Check the Products list

INSERT INTO DimStore (StoreID, Region)
SELECT TRIM(StoreID), TRIM(Region)
FROM temp_inventory_data
ON DUPLICATE KEY UPDATE Region = VALUES(Region);
-- SELECT * FROM DimStore ORDER BY StoreSK; -- Check the Stores list with their Superkey

INSERT INTO DimDate (PDate, PYear, PMonth, PDay, PDayOfWeek, Seasonality)
SELECT
    PDate,
    YEAR(PDate) AS PYear,
    MONTH(PDate) AS PMonth,
    DAY(PDate) AS PDay,
    DAYNAME(PDate) AS PDayOfWeek,
    Seasonality
FROM temp_inventory_data
ON DUPLICATE KEY UPDATE
    PYear = VALUES(PYear),
    PMonth = VALUES(PMonth),
    PDay = VALUES(PDay),
    PDayOfWeek = VALUES(PDayOfWeek),
    Seasonality = VALUES(Seasonality);
-- Don't check this table, have faith in yourself :)

INSERT INTO FactInventorySales (
    PDate, StoreID, Region, ProductID, StoreSK, InventoryLevel, UnitsSold, 
    UnitsOrdered, DemandForecast, Price, Discount, EffectivePrice,
    WeatherCondition, IsHolidayPromotion, CompetitorPricing
)
SELECT 
    TRIM(PDate),
    TRIM(temp_inventory_data.StoreID),
    TRIM(DimStore.Region),
    TRIM(ProductID),
    StoreSK,
    InventoryLevel,
    UnitsSold,
    UnitsOrdered,
    DemandForecast,
    Price,
    Discount,
    Price * (1 - Discount/100.0) AS EffectivePrice,
    TRIM(WeatherCondition),
    CASE WHEN Holiday_Promotion = 1 THEN TRUE ELSE FALSE END AS IsHolidayPromotion,
    CompetitorPricing
FROM temp_inventory_data JOIN DimStore ON TRIM(temp_inventory_data.StoreID) = TRIM(DimStore.StoreID) AND TRIM(temp_inventory_data.Region) = TRIM(DimStore.Region);
SELECT * FROM FactInventorySales ORDER BY FactID LIMIT 200; -- Check the Inventory details (relevant csv data)

DROP TEMPORARY TABLE IF EXISTS temp_inventory_data; -- Drop the temporary table