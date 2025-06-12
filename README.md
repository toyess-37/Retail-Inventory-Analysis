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
cd "C:\Users\bilas\OneDrive\Documents\GENAI\sql"

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

## Reports and Documentation

- **retail_inventory_analysis_report.pdf**: Comprehensive analysis report with insights and recommendations
- **Inventory_Optimization_Report.md**: Detailed optimization strategies and findings
- **Project_Approach_and_Impact.md**: Methodology and business impact analysis

## License

This project is licensed under the terms specified in the LICENSE file.

## Contributing

Feel free to fork this project and submit pull requests for improvements or additional analysis modules.

## Support

For questions or issues, please refer to the documentation files or create an issue in the project repository.
