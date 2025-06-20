# Retail Inventory Analysis Project

A comprehensive MySQL-based retail inventory analysis system that provides insights into inventory optimization, sales patterns, and product performance across multiple stores and regions.

## Project Overview

This project implements a data warehouse solution for retail inventory management and analysis. It provides various analytical views and reports to help retailers make informed decisions about inventory management, product categorization, and sales optimization.

### Key Features

- **ABC Analysis**: Categorizes products based on revenue contribution (80/15/5 rule)
- **Inventory Turnover Analysis**: Calculates turnover rates and identifies slow/fast-moving products
- **Seasonal Analysis**: Analyzes sales patterns across different seasons
- **Movement Trends**: Tracks product movement patterns over time
- **Competitor Pricing Analysis**: Compares pricing strategies
- **Inventory Adjustment Recommendations**: Provides actionable insights for inventory optimization

## Project Structure

```
├── 0.schema_data.sql                    # Database schema and table creation
├── 1.analysis_compiled.sql              # Main analysis views and queries
├── inventory_forecasting.csv            # Sample forecasting data
├── Inventory_Optimization_Report.md     # Detailed optimization report
├── Project_Approach_and_Impact.md       # Project methodology and impact analysis
├── retail_inventory_analysis_report.pdf # Comprehensive analysis report
├── LICENSE                              # License file
├── README.md                           # This file
└── individual_sections/                # Modular analysis components
    ├── 2.inventory_adjustment_actions.sql   # Inventory adjustment recommendations
    ├── 3.movement_trends.sql               # Product movement trend analysis
    ├── 4.abc_classification.sql            # ABC classification analysis
    ├── 5.turnover_details.sql             # Detailed turnover calculations
    ├── 6.seasonal_analysis.sql            # Seasonal pattern analysis
    └── 7.competitor_pricing.sql           # Competitor pricing comparison
```

## Detailed File Descriptions

### Core Files

#### `0.schema_data.sql` - Database Foundation
**What it contains:** Complete database schema definition including all tables, relationships, and initial setup

**What it does:** 
- Creates the `inventory_project_sql` database
- Defines dimension tables (DimProduct, DimStore, DimDate)
- Creates the main fact table (FactInventorySales)
- Sets up foreign key relationships and constraints

**How to run:** `SOURCE 0.schema_data.sql;` (run first, before any other scripts)

**Contribution:** Essential foundation - all other analysis depends on this schema

#### `1.analysis_compiled.sql` - Complete Analysis Suite
**What it contains:** All analytical views and stored procedures combined in one comprehensive file

**What it does:**
- Creates all analytical views (ABC Analysis, Inventory Turnover, Seasonal Analysis, etc.)
- Combines functionality from all individual section files
- Provides complete end-to-end analysis framework
**How to run:** `SOURCE 1.analysis_compiled.sql;` (run after schema creation)

**Contribution:** One-stop solution for all inventory analysis needs

### Individual Analysis Modules

#### `2.inventory_adjustment_actions.sql` - Smart Inventory Management
**What it contains:** Inventory optimization and reordering logic

**What it does:**
- Classifies products as Fast/Medium/Slow movers
- Calculates reorder points using lead time and safety stock
- Generates specific inventory adjustment recommendations (URGENT REORDER, INCREASE, REDUCE, MAINTAIN)
- Analyzes last 30 days of data for current stock decisions
**How to run:** `SOURCE individual_sections/2.inventory_adjustment_actions.sql;`

**Contribution:** Provides actionable inventory management decisions to prevent stockouts and reduce overstock

#### `3.movement_trends.sql` - Product Movement Analytics
**What it contains:** Stock movement pattern analysis and daily sales tracking

**What it does:**
- Tracks 30-day stock movement trends (min, max, average, volatility)
- Calculates daily sales patterns by product
- Monitors average daily sales and forecast accuracy
- Identifies products with high inventory volatility
**How to run:** `SOURCE individual_sections/3.movement_trends.sql;`

**Contribution:** Helps understand product demand patterns and inventory stability over time

#### `4.abc_classification.sql` - Revenue-Based Product Categorization
**What it contains:** ABC analysis implementation using Pareto principle (80/15/5 rule)

**What it does:**
- Categorizes products by revenue contribution per store
- A items: Top 80% of revenue (high priority)
- B items: Next 15% of revenue (medium priority) 
- C items: Bottom 5% of revenue (low priority)
- Calculates inventory turnover rates by category
**How to run:** `SOURCE individual_sections/4.abc_classification.sql;`

**Contribution:** Enables focused inventory management by identifying most valuable products per location

#### `5.turnover_details.sql` - Inventory Efficiency Metrics
**What it contains:** Detailed inventory turnover calculations and performance metrics

**What it does:**
- Calculates inventory turnover ratios (sales/average inventory)
- Determines days in inventory (how long stock sits)
- Computes total revenue and average selling prices
- Ranks products by turnover efficiency
**How to run:** `SOURCE individual_sections/5.turnover_details.sql;`

**Contribution:** Measures inventory efficiency and identifies slow-moving stock requiring attention

#### `6.seasonal_analysis.sql` - Demand Pattern Recognition
**What it contains:** Seasonal and weather-based demand analysis

**What it does:**
- Analyzes monthly sales patterns and weather impact
- Creates seasonal demand indices
- Classifies periods as High/Regular/Low season
- Compares actual vs forecasted seasonal demand
- Links weather conditions to sales performance
**How to run:** `SOURCE individual_sections/6.seasonal_analysis.sql;`

**Contribution:** Enables seasonal inventory planning and weather-responsive stocking strategies

#### `7.competitor_pricing.sql` - Competitive Pricing Intelligence
**What it contains:** Competitor price analysis and pricing recommendations

**What it does:**
- Compares your prices vs competitor prices
- Analyzes sales impact when priced higher/lower than competitors
- Calculates revenue impact of pricing strategies
- Provides pricing recommendations (Reduce Price, Maintain, Monitor)
- Measures price sensitivity effects on sales volume
**How to run:** `SOURCE individual_sections/7.competitor_pricing.sql;`

**Contribution:** Optimizes pricing strategy based on competitive analysis and sales impact

### Supporting Files

#### `inventory_forecasting.csv` - Sample Data
**What it contains:** Sample forecasting data for testing and demonstration

**How to use:** Import into database tables for testing the analysis scripts

**Contribution:** Provides realistic data for system validation

#### `retail_inventory_analysis_report.pdf` - Comprehensive analysis insights

## Database Schema

The project uses a star schema design with the following tables:

- **DimProduct**: Product dimension (ProductID, Category)
- **DimStore**: Store dimension (StoreID, Region, StoreSK)
- **DimDate**: Date dimension with seasonality information
- **FactInventorySales**: Main fact table containing sales, inventory, and pricing data

## How to Run the Program

### Prerequisites

- MySQL Server (5.7 or higher)
- MySQL Workbench or command-line client
- Administrative privileges to create databases

### Installation Steps

1. **Clone or download the project files** to your local directory

2. **Start MySQL Server** and connect using your preferred client

3. **Execute the schema creation script**:
   ```sql
   SOURCE path/to/0.schema_data.sql;
   ```
   This will:
   - Create the `inventory_project_sql` database
   - Create all necessary tables (DimProduct, DimStore, DimDate, FactInventorySales)
   - Set up the basic schema structure

4. **Load your data** into the fact and dimension tables (data loading scripts not included - adapt based on your data source)

5. **Execute the main analysis script**:
   ```sql
   SOURCE path/to/1.analysis_compiled.sql;
   ```
   This creates all analytical views and stored procedures

6. **Run individual analysis modules** (optional):
   ```sql
   -- For specific analysis components
   SOURCE path/to/individual_sections/2.inventory_adjustment_actions.sql;
   SOURCE path/to/individual_sections/3.movement_trends.sql;
   -- ... and so on for other modules
   ```

### Using PowerShell (Windows)

```powershell
# Navigate to project directory
cd "path/to/your/project/directory"

# Connect to MySQL and run scripts
mysql -u your_username -p < 0.schema_data.sql
mysql -u your_username -p < 1.analysis_compiled.sql
```

### Key Views and Outputs

After running the scripts, you'll have access to several analytical views:

- `ViewABCAnalysis`: ABC classification of products by store
- `ViewCurrentStockLevels`: Current inventory levels
- `ViewInventoryTurnover`: Turnover rates and movement categories
- `ViewSeasonalAnalysis`: Seasonal sales patterns
- `ViewCompetitorPricing`: Pricing comparison analysis

### Sample Queries

```sql
-- View ABC classification for all products
SELECT * FROM ViewABCAnalysis ORDER BY StoreID, ABCCategory, TotalRevenue DESC;

-- Check inventory adjustment recommendations
SELECT * FROM ViewInventoryAdjustments WHERE ActionRequired != 'Maintain';

-- Analyze seasonal trends
SELECT * FROM ViewSeasonalAnalysis WHERE Seasonality = 'Winter';
```

## License

This project is licensed under the terms specified in the LICENSE file.
