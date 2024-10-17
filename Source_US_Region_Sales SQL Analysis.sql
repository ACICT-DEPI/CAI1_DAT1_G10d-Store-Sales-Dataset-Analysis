--US_Regional_sales_Analysis

--Sales Performance Analysis--
--(1)Total Sales and Profit (What are the total sales over time?)
WITH Total_Sales_and_Profit AS (
    SELECT
        Order_Quantity, 
		OrderNumber,
        Unit_Price, 
        Unit_Cost,
		Discount_Applied,
        (Order_Quantity * Unit_Price) AS Sales
    FROM 
        orders
)
-- Total sales and Total profit(
SELECT COUNT( OrderNumber) AS total_order, sum(Unit_Cost) AS total_Cost,
sum(Sales* (1 - Discount_Applied)) as Total_Sales,
SUM(Order_Quantity * (Unit_Price - Unit_Cost) * (1 - discount_applied)) as Total_Profit
FROM Total_Sales_and_Profit;

--(2)Sales across channels (How do sales vary across different sales channels (e.g., online vs. offline)?)
SELECT 
    Sales_Channel,
    SUM(Order_Quantity * Unit_Price) AS Total_Sales_per_channel
FROM 
    orders
GROUP BY 
    Sales_Channel;

--(3) Average sales per each region and store (What is the average order value (AOV) across different stores or regions?)
WITH Store_Revenue AS (
    SELECT 
        sl.StoreID,
        r.Region,
        SUM(o.Order_Quantity * o.Unit_Price * (1 - o.Discount_Applied)) AS Total_Revenue,
        COUNT(DISTINCT o.OrderNumber) AS Total_Orders
    FROM orders o
    JOIN [Store_Locations] sl ON sl.StoreID = o.StoreID
    JOIN Regions r ON r.StateCode = sl.StateCode
    GROUP BY sl.StoreID, r.Region),
Region_Revenue AS (
    SELECT 
        r.Region,
        SUM(o.Order_Quantity * o.Unit_Price * (1 - o.Discount_Applied)) AS Total_Revenue,
        COUNT(DISTINCT o.OrderNumber) AS Total_Orders
    FROM orders o
    JOIN [Store_Locations] sl ON sl.StoreID = o.StoreID
    JOIN Regions r ON r.StateCode = sl.StateCode
    GROUP BY r.Region)
SELECT 
    'Store' AS Level,
    sl.StoreID AS Store_ID,
    sl.City_Name AS City_store,
    r.Region,
    ROUND(sr.Total_Revenue / sr.Total_Orders, 2) AS AOV
FROM Store_Revenue sr
JOIN [Store_Locations] sl ON sl.StoreID = sr.StoreID
JOIN Regions r ON r.StateCode = sl.StateCode

UNION ALL

SELECT 
    'Region' AS Level,
    NULL AS Level_ID,   -- No StoreID for region-level aggregation
    r.Region AS Level_Name,
    r.Region,
    ROUND(rr.Total_Revenue / rr.Total_Orders, 2) AS AOV
FROM Region_Revenue rr
JOIN Regions r ON r.Region = rr.Region;

--(4)highest products revenue (Which products generate the most revenue or profit?)
SELECT 
    p.ProductID,
    p.Product_Name,
    SUM(o.Order_Quantity * o.Unit_Price * (1 - o.Discount_Applied)) AS Total_Sales,
    SUM(o.Order_Quantity * (o.Unit_Price - o.Unit_Cost) * (1 - o.Discount_Applied)) AS Total_Profit
FROM orders o
JOIN Products p ON p.ProductID = o.ProductID
GROUP BY 
    p.ProductID, p.Product_Name
ORDER BY 
    Total_Sales DESC, Total_Profit DESC;

--(5) product Profit Margin(What is the profit margin across various products and regions?)
SELECT 
    p.ProductID,
    p.Product_Name,
    r.Region,
    SUM(o.Order_Quantity * o.Unit_Price * (1 - o.Discount_Applied)) AS Total_Revenue,
    SUM(o.Order_Quantity * (o.Unit_Price - o.Unit_Cost) * (1 - o.Discount_Applied)) AS Total_Profit,
    ROUND((SUM(o.Order_Quantity * (o.Unit_Price - o.Unit_Cost) * (1 - o.Discount_Applied)) /
          SUM(o.Order_Quantity * o.Unit_Price * (1 - o.Discount_Applied))) * 100, 2) AS Profit_Margin
FROM orders o
JOIN Products p ON p.ProductID = o.ProductID
JOIN [Store_Locations] sl ON sl.StoreID = o.StoreID
JOIN Regions r ON r.StateCode = sl.StateCode
GROUP BY 
    p.ProductID, p.Product_Name, r.Region
ORDER BY 
    Profit_Margin DESC;
	select * from  [Store_Locations]

--(6) (What is the impact of discounts on sales and profitability?)
SELECT 
    SUM(o.Order_Quantity * o.Unit_Price) AS Total_Revenue_Without_Discount,
    SUM(o.Order_Quantity * o.Unit_Price * (1 - o.Discount_Applied)) AS Total_Sales_With_Discount,
    SUM(o.Order_Quantity * (o.Unit_Price - o.Unit_Cost)) AS Total_Profit_Without_Discount,
    SUM(o.Order_Quantity * (o.Unit_Price - o.Unit_Cost) * (1 - o.Discount_Applied)) AS Total_Profit_With_Discount,
    ROUND((SUM(o.Order_Quantity * (o.Unit_Price - o.Unit_Cost)) /
           SUM(o.Order_Quantity * o.Unit_Price)) * 100, 2) AS Profit_Margin_Without_Discount,
    ROUND((SUM(o.Order_Quantity * (o.Unit_Price - o.Unit_Cost) * (1 - o.Discount_Applied)) /
           SUM(o.Order_Quantity * o.Unit_Price * (1 - o.Discount_Applied))) * 100, 2) AS Profit_Margin_With_Discount
FROM orders o;

--(7) (What is the trend of sales over specific time periods (daily, monthly, quarterly, annually)?)
--Daily Sales Trend:
SELECT 
    CONVERT(DATE, OrderDate) AS Sales_Date,
    SUM(Order_Quantity * Unit_Price) AS Total_Sales
FROM orders
GROUP BY 
    CONVERT(DATE, OrderDate)
ORDER BY 
    Sales_Date;
-- Monthly Sales Trend:
SELECT 
    YEAR(OrderDate) AS Year, 
    MONTH(OrderDate) AS Month,
    SUM(Order_Quantity * Unit_Price) AS Total_Sales
FROM orders
GROUP BY 
    YEAR(OrderDate), MONTH(OrderDate)
ORDER BY 
    Year, Month;
--Quarterly Sales Trend:
SELECT 
    YEAR(OrderDate) AS Year, 
    CEILING(MONTH(OrderDate) / 3.0) AS Quarter,
    SUM(Order_Quantity * Unit_Price) AS Total_Sales
FROM orders
GROUP BY 
    YEAR(OrderDate), CEILING(MONTH(OrderDate) / 3.0)
ORDER BY 
    Year, Quarter;
--Annual Sales Trend:
SELECT 
    YEAR(OrderDate) AS Year, 
    SUM(Order_Quantity * Unit_Price) AS Total_Sales
FROM orders
GROUP BY 
    YEAR(OrderDate)
ORDER BY 
    Year;

--(8) (How do shipping and delivery dates affect the profitability or customer satisfaction?)
--average delay between order date and delivery date:
SELECT 
    AVG(DATEDIFF(day, OrderDate, DeliveryDate)) AS Avg_Delivery_Delay
FROM orders;
--percentage of orders are delivered on time or late:
SELECT
    COUNT(CASE WHEN DATEDIFF(day, OrderDate, DeliveryDate) <= 5 THEN 1 END) * 100.0 / COUNT(*) AS On_Time_Percentage,
    COUNT(CASE WHEN DATEDIFF(day, OrderDate, DeliveryDate) > 5 THEN 1 END) * 100.0 / COUNT(*) AS Late_Percentage
FROM orders;
-- ORder deliverd (ontime/late)
SELECT 
    CASE 
        WHEN DATEDIFF(day, OrderDate, DeliveryDate) <= 5 THEN 'On_Time'
        ELSE 'Late'
    END AS Delivery_Status,
    SUM(Order_Quantity * (Unit_Price - Unit_Cost)) AS Profit
FROM orders
GROUP BY 
    CASE 
        WHEN DATEDIFF(day, OrderDate, DeliveryDate) <= 5 THEN 'On_Time'
        ELSE 'Late'
    END;
--Does faster shipping increase customer satisfaction or profit?
SELECT 
    CASE 
        WHEN DATEDIFF(day, OrderDate, DeliveryDate) <= 3 THEN 'Fast_Delivery'
        WHEN DATEDIFF(day, OrderDate, DeliveryDate) BETWEEN 4 AND 5 THEN 'Moderate_Delivery'
        ELSE 'Slow_Delivery'
    END AS Delivery_Speed,
    SUM(Order_Quantity * (Unit_Price - Unit_Cost)) AS Profit,
    COUNT(OrderNumber) AS Orders_Count
FROM orders
GROUP BY 
    CASE 
        WHEN DATEDIFF(day, OrderDate, DeliveryDate) <= 3 THEN 'Fast_Delivery'
        WHEN DATEDIFF(day, OrderDate, DeliveryDate) BETWEEN 4 AND 5 THEN 'Moderate_Delivery'
        ELSE 'Slow_Delivery'
    END;

--Product Analysis--

--(9) (Which products have the highest demand (based on order quantity)?)
SELECT 
    p.Product_Name,
    SUM(o.Order_Quantity) AS Total_Demand
FROM orders o
JOIN products p ON o.ProductID = p.ProductID
GROUP BY 
    p.Product_Name
ORDER BY 
    Total_Demand DESC;

--(10) (Which products offer the highest profit margins?)
SELECT 
    p.Product_Name,
    SUM(o.Order_Quantity * o.Unit_Price) AS Total_Sales,
    SUM(o.Order_Quantity * o.Unit_Cost) AS Total_Cost,
    (SUM(o.Order_Quantity * o.Unit_Price) - SUM(o.Order_Quantity * o.Unit_Cost)) AS Total_Profit,
    ROUND(( (SUM(o.Order_Quantity * o.Unit_Price) - SUM(o.Order_Quantity * o.Unit_Cost)) / SUM(o.Order_Quantity * o.Unit_Price)) * 100, 2) AS Profit_Margin_Percentage
FROM orders o
JOIN products p ON o.ProductID = p.ProductID
GROUP BY 
    p.Product_Name
ORDER BY 
    Profit_Margin_Percentage DESC;

--(11) (What is the average price and cost for each product category?)
SELECT 
    p.Product_Name,
    ROUND(AVG(o.Unit_Price), 2) AS Average_Price,
    ROUND(AVG(o.Unit_Cost), 2) AS Average_Cost
FROM orders o
JOIN products p ON o.ProductID = p.ProductID
GROUP BY 
    p.Product_Name
ORDER BY 
    Average_Price DESC;

--(12) (Are there specific products that are consistently discounted, and what is their impact on profit?)
WITH Discounted_Products AS (
    SELECT 
        p.Product_Name,
        COUNT(*) AS Total_Orders,
        SUM(CASE WHEN o.Discount_Applied > 0 THEN 1 ELSE 0 END) AS Discounted_Orders,
        ROUND(100.0 * SUM(CASE WHEN o.Discount_Applied > 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS Discount_Percentage,
        SUM(o.Order_Quantity * o.Unit_Price * (1 - o.Discount_Applied)) AS Total_Revenue_With_Discount,
        SUM(o.Order_Quantity * o.Unit_Price) AS Total_Revenue_Without_Discount,
        SUM(o.Order_Quantity * o.Unit_Cost) AS Total_Cost
    FROM orders o
    JOIN products p ON o.ProductID = p.ProductID
    GROUP BY 
        p.Product_Name)
SELECT 
    Product_Name,
    Discount_Percentage,
    ROUND((Total_Revenue_With_Discount - Total_Cost), 2) AS Profit_With_Discount,
    ROUND((Total_Revenue_Without_Discount - Total_Cost), 2) AS Profit_Without_Discount,
    ROUND((Total_Revenue_Without_Discount - Total_Revenue_With_Discount), 2) AS Discount_Impact_On_Profit
FROM Discounted_Products
ORDER BY 
    Discount_Percentage DESC;

--(13) (How does product performance vary across different regions or sales channels?)
WITH Product_Performance AS (
    SELECT 
        p.Product_Name,
        r.Region,
        o.Sales_Channel,
        SUM(o.Order_Quantity * o.Unit_Price * (1 - o.Discount_Applied)) AS Total_Revenue,
        SUM(o.Order_Quantity * (o.Unit_Price - o.Unit_Cost) * (1 - o.Discount_Applied)) AS Total_Profit,
        SUM(o.Order_Quantity) AS Total_Orders
    FROM orders o
    JOIN products p ON o.ProductID = p.ProductID
    JOIN [Store_Locations] sl ON o.StoreID = sl.StoreID
    JOIN Regions r ON sl.StateCode = r.StateCode
    GROUP BY 
        p.Product_Name, r.Region, o.Sales_Channel)
SELECT 
    Product_Name,
    Region,
    Sales_Channel,
    ROUND(Total_Revenue, 2) AS Total_Revenue,
    ROUND(Total_Profit, 2) AS Total_Profit,
    Total_Orders
FROM Product_Performance
ORDER BY 
    Region, Sales_Channel, Total_Revenue DESC;

--Customer Analysis--
--(14) (Which customers contribute the most to sales and profitability?)
WITH Customer_Contribution AS (
    SELECT 
        c.Customer_Names,
        SUM(o.Order_Quantity * o.Unit_Price * (1 - o.Discount_Applied)) AS Total_Revenue,
        SUM(o.Order_Quantity * (o.Unit_Price - o.Unit_Cost) * (1 - o.Discount_Applied)) AS Total_Profit,
        SUM(o.Order_Quantity) AS Total_Orders
    FROM orders o
    JOIN customers c ON o.CustomerID = c.CustomerID
    GROUP BY 
        c.Customer_Names)
SELECT 
    Customer_Names,
    ROUND(Total_Revenue, 2) AS Total_Revenue,
    ROUND(Total_Profit, 2) AS Total_Profit,
    Total_Orders
FROM Customer_Contribution
ORDER BY 
    Total_Revenue DESC;

--(14) (What is the repeat customer rate?)
WITH Customer_Order_Count AS (
    SELECT 
        CustomerID,
        COUNT(OrderNumber) AS Order_Count
    FROM orders
    GROUP BY 
        CustomerID),
Customer_Stats AS (
    SELECT 
        COUNT(DISTINCT CustomerID) AS Total_Customers,
        COUNT(DISTINCT CASE WHEN Order_Count > 1 THEN CustomerID END) AS Repeat_Customers
    FROM Customer_Order_Count)
SELECT 
    ROUND((Repeat_Customers * 1.0 / Total_Customers) * 100, 2) AS Repeat_Customer_Rate
FROM Customer_Stats;

--(15) (What is the average order quantity or value per customer?)
WITH Customer_Summary AS (
    SELECT 
        CustomerID,
        SUM(Order_Quantity) AS Total_Quantity,
        SUM(Order_Quantity * Unit_Price) AS Total_Value
    FROM orders
    GROUP BY 
        CustomerID),
Overall_Averages AS (
    SELECT 
        COUNT(DISTINCT CustomerID) AS Total_Customers,
        SUM(Total_Quantity) AS Grand_Total_Quantity,
        SUM(Total_Value) AS Grand_Total_Value
    FROM Customer_Summary)
SELECT 
    ROUND(Grand_Total_Quantity * 1.0 / Total_Customers, 2) AS Average_Order_Quantity,
    ROUND(Grand_Total_Value * 1.0 / Total_Customers, 2) AS Average_Order_Value
FROM Overall_Averages;

--(16) (Are there any trends in customer behavior based on geographic location (city, county, or state)?)
SELECT 
    sl.State,
    COUNT(DISTINCT o.CustomerID) AS Total_Customers,
    SUM(o.Order_Quantity) AS Total_Quantity,
    SUM(o.Order_Quantity * o.Unit_Price) AS Total_Sales,
    ROUND(AVG(o.Order_Quantity * o.Unit_Price), 2) AS Average_Order_Value,
    COUNT(o.OrderNumber) AS Total_Orders
FROM orders o
JOIN [Store_Locations] sl ON o.StoreID = sl.StoreID
GROUP BY 
    sl.State
ORDER BY Total_Sales DESC;

--(17) (How does household income, median income, or population affect customer purchasing behavior?)
WITH Income_Purchase AS (
    SELECT 
        sl.Household_Income,
        SUM(o.Order_Quantity * o.Unit_Price) AS Total_Sales,
        COUNT(o.OrderNumber) AS Total_Orders,
        ROUND(AVG(o.Order_Quantity * o.Unit_Price), 2) AS Average_Order_Value
    FROM orders o
    JOIN [Store_Locations] sl ON o.StoreID = sl.StoreID
    GROUP BY 
        sl.Household_Income)
SELECT 
    Household_Income,
    Total_Sales,
    Total_Orders,
    Average_Order_Value
FROM Income_Purchase
ORDER BY Total_Sales DESC;

--(18) (How do time zones influence customer buying patterns?)
WITH Time_Zone_Sales AS (
    SELECT 
        sl.Time_Zone,
        COUNT(o.OrderNumber) AS Total_Orders,
        SUM(o.Order_Quantity * o.Unit_Price) AS Total_Sales,
        ROUND(AVG(o.Order_Quantity * o.Unit_Price), 2) AS Average_Order_Value
    FROM orders o
    JOIN [Store_Locations] sl ON o.StoreID = sl.StoreID
    GROUP BY 
        sl.Time_Zone)
SELECT 
    Time_Zone,
    Total_Orders,
    Total_Sales,
    Average_Order_Value
FROM Time_Zone_Sales
ORDER BY Total_Sales DESC;

--(19) (Which store locations generate the highest sales or profit?)
WITH Store_Sales_Profit AS (
    SELECT 
        sl.StoreID,
        sl.City_Name,
        sl.County,
        sl.State,
        SUM(o.Order_Quantity * o.Unit_Price * (1 - o.Discount_Applied)) AS Total_Sales,
        SUM(o.Order_Quantity * (o.Unit_Price - o.Unit_Cost) * (1 - o.Discount_Applied)) AS Total_Profit
    FROM orders o
    JOIN [Store_Locations] sl ON o.StoreID = sl.StoreID
    GROUP BY 
        sl.StoreID, sl.City_Name, sl.County, sl.State)
SELECT 
    StoreID,
    City_Name,
    County,
    State,
    Total_Sales,
    Total_Profit
FROM Store_Sales_Profit
ORDER BY Total_Sales DESC; 

--Regional and Store Analysis--
--(20) (How do sales vary by city, county, or state?)
-- Total sales by City
SELECT 
    sl.City_Name,
    SUM(o.Order_Quantity * o.Unit_Price * (1 - o.Discount_Applied)) AS Total_Sales
FROM orders o
JOIN [Store_Locations] sl ON o.StoreID = sl.StoreID
GROUP BY sl.City_Name
ORDER BY Total_Sales DESC;
-- Total sales by County
SELECT 
    sl.County,
    SUM(o.Order_Quantity * o.Unit_Price * (1 - o.Discount_Applied)) AS Total_Sales
FROM orders o
JOIN [Store_Locations] sl ON o.StoreID = sl.StoreID
GROUP BY sl.County
ORDER BY Total_Sales DESC;

-- Total sales by State
SELECT 
    sl.State,
    SUM(o.Order_Quantity * o.Unit_Price * (1 - o.Discount_Applied)) AS Total_Sales
FROM orders o
JOIN [Store_Locations] sl ON o.StoreID = sl.StoreID
GROUP BY sl.State
ORDER BY Total_Sales DESC;

--(21) (How does region (e.g., West, East, etc.) affect sales performance?)
SELECT 
    r.Region,
    COUNT(DISTINCT o.OrderNumber) AS Total_Orders,
    SUM(o.Order_Quantity * o.Unit_Price * (1 - o.Discount_Applied)) AS Total_Sales,
    ROUND(AVG(o.Order_Quantity * o.Unit_Price * (1 - o.Discount_Applied)), 2) AS Avg_Order_Value
FROM orders o
JOIN [Sales_Teams] r ON  r.SalesTeamID = o.SalesTeamID
GROUP BY r.Region
ORDER BY Total_Sales DESC;

--(22) (How does population density or household income affect sales at a store level?)
SELECT 
    sl.StoreID,
    sl.City_Name,
    sl.Population,
    sl.Household_Income,
    SUM(o.Order_Quantity * o.Unit_Price * (1 - o.Discount_Applied)) AS Total_Sales,
    ROUND(AVG(o.Order_Quantity * o.Unit_Price * (1 - o.Discount_Applied)), 2) AS Avg_Order_Value,
    ROUND(SUM(o.Order_Quantity * o.Unit_Price * (1 - o.Discount_Applied)) / NULLIF(sl.Population, 0), 2) AS Sales_Per_Capita
FROM orders o
JOIN [Store_Locations] sl ON o.StoreID = sl.StoreID
GROUP BY 
    sl.StoreID, sl.City_Name, sl.Population, sl.Household_Income
ORDER BY 
    Total_Sales DESC;

--(23) (What is the relationship between store location (latitude/longitude) and sales volume?)
SELECT 
    sl.StoreID,
    sl.Latitude,
    sl.Longitude,
    SUM(o.Order_Quantity * o.Unit_Price * (1 - o.Discount_Applied)) AS Total_Sales_Volume
FROM orders o
JOIN [Store_Locations] sl ON o.StoreID = sl.StoreID
GROUP BY sl.StoreID, sl.Latitude, sl.Longitude
ORDER BY Total_Sales_Volume DESC;

--(24) (How does the time between order date and delivery date affect sales performance?) 
WITH DeliveryTimeAnalysis AS (
    SELECT 
        OrderDate,
        DeliveryDate,
        DATEDIFF(DAY, OrderDate, DeliveryDate) AS Delivery_Time_Days,
        Order_Quantity,
        Unit_Price,
        Discount_Applied,
        (Order_Quantity * Unit_Price * (1 - Discount_Applied)) AS Total_Sales
    FROM orders)
SELECT 
    Delivery_Time_Days,
    COUNT(*) AS Total_Orders,
    SUM(Total_Sales) AS Total_Sales_Volume,
    AVG(Order_Quantity) AS Average_Order_Quantity
FROM DeliveryTimeAnalysis
GROUP BY Delivery_Time_Days
ORDER BY Delivery_Time_Days;

	--Time and Delivery Analysis--
--(25) (Are there patterns or trends in sales based on the delivery date (e.g., holiday seasons)?)
WITH SalesData AS (
    SELECT 
        DeliveryDate,
        Order_Quantity,
        Unit_Price,
        Discount_Applied,
        (Order_Quantity * Unit_Price * (1 - Discount_Applied)) AS Total_Sales,
        YEAR(DeliveryDate) AS Year,
        MONTH(DeliveryDate) AS Month,
        DATENAME(WEEKDAY, DeliveryDate) AS Day_Of_Week
    FROM orders)
SELECT 
    Year,
    Month,
    SUM(Total_Sales) AS Total_Sales_Volume,
    SUM(Order_Quantity) AS Total_Orders,
    AVG(Order_Quantity) AS Average_Order_Quantity
FROM SalesData
GROUP BY Year, Month
ORDER BY Year, Month;

--(26) (How efficient are warehouses in fulfilling orders, based on ship and delivery times?
WITH ShippingData AS (
    SELECT 
        WarehouseCode,
        Order_Quantity,
        ShipDate,
        DeliveryDate,
        DATEDIFF(DAY, ShipDate, DeliveryDate) AS Shipping_Time, -- Calculate shipping time in days
        (Order_Quantity * Unit_Price) AS Total_Sales -- Calculate total sales for the order
    FROM orders)
SELECT 
    WarehouseCode,
    COUNT(Order_Quantity) AS Total_Orders,
    AVG(Shipping_Time) AS Average_Shipping_Time,
    SUM(Total_Sales) AS Total_Sales_Volume
FROM ShippingData
GROUP BY WarehouseCode
ORDER BY Average_Shipping_Time;

--(27) (How do procurement lead times (ProcuredDate to OrderDate) affect overall sales?)
WITH ProcurementData AS (
    SELECT 
        DATEDIFF(DAY, ProcuredDate, OrderDate) AS Procurement_Lead_Time, -- Calculate procurement lead time in days
        Order_Quantity,
        Unit_Price,
        (Order_Quantity * Unit_Price) AS Total_Sales -- Calculate total sales for the order
    FROM orders)

SELECT 
    Procurement_Lead_Time,
    COUNT(Order_Quantity) AS Total_Orders,
    SUM(Total_Sales) AS Total_Sales_Volume,
    AVG(Total_Sales) AS Average_Sales_Per_Order
FROM ProcurementData
GROUP BY Procurement_Lead_Time
ORDER BY Procurement_Lead_Time;

--(28) (Which sales team generates the most revenue?)
SELECT 
    st.Sales_Team,
    SUM(o.Order_Quantity * o.Unit_Price) AS Total_Revenue
FROM orders o
JOIN [Sales_Teams] st ON o.SalesTeamID = st.SalesTeamID
GROUP BY st.Sales_Team
ORDER BY Total_Revenue DESC;

--Sales Team Performance--
--(29) (WITH Sales_Performance AS (Are there patterns or trends in sales based on the delivery date (e.g., holiday seasons)?)
    SELECT 
        st.Sales_Team, 
        r.Region, 
        SUM(o.Order_Quantity * o.Unit_Price) AS Total_Revenue,
        SUM(o.Order_Quantity * (o.Unit_Price - o.Unit_Cost)) AS Total_Profit
    FROM 
        orders o
    JOIN [Store_Location] sl ON o.StoreID = sl.StoreID
    JOIN Regions r ON sl.StateCode = r.StateCode
    JOIN Sales_Teams st ON o.SalesTeamID = st.SalesTeamID
    GROUP BY 
        st.Sales_Team, r.Region)
SELECT 
    Sales_Team, 
    Region, 
    Total_Revenue,
    Total_Profit
FROM Sales_Performance
ORDER BY Sales_Team, Region;

--(30) (What is the relationship between sales team performance and product or customer type?)
WITH Sales_Team_Product_Performance AS (
    SELECT 
        st.Sales_Team,
        p.Product_Name,
        SUM(o.Order_Quantity * o.Unit_Price) AS Total_Sales,
        SUM(o.Order_Quantity * (o.Unit_Price - o.Unit_Cost)) AS Total_Profit
    FROM orders o
    JOIN Products p ON o.ProductID = p.ProductID
    JOIN Sales_Teams st ON o.SalesTeamID = st.SalesTeamID
    GROUP BY st.Sales_Team, p.Product_Name)
SELECT 
    Sales_Team, 
    Product_Name, 
    Total_Sales, 
    Total_Profit
FROM Sales_Team_Product_Performance
ORDER BY Sales_Team, Total_Sales DESC;

--(31) (How do discounts applied by specific sales teams affect profit margins?)
WITH Sales_Team_Discount_Impact AS (
    SELECT 
        st.Sales_Team,
        SUM(o.Order_Quantity * o.Unit_Price) AS Total_Sales,
        SUM(o.Order_Quantity * o.Unit_Price * (1 - o.Discount_Applied)) AS Discounted_Sales,
        SUM(o.Order_Quantity * (o.Unit_Price - o.Unit_Cost)) AS Total_Profit,
        SUM(o.Order_Quantity * (o.Unit_Price - o.Unit_Cost) * (1 - o.Discount_Applied)) AS Discounted_Profit
    FROM orders o
    JOIN Sales_Teams st ON o.SalesTeamID = st.SalesTeamID
    GROUP BY st.Sales_Team)
SELECT 
    Sales_Team,
    Total_Sales,
    Discounted_Sales,
    Total_Profit,
    Discounted_Profit,
    ROUND((Discounted_Profit / Discounted_Sales) * 100, 2) AS Profit_Margin
FROM Sales_Team_Discount_Impact
ORDER BY Profit_Margin DESC;

--(32) (How do sales and profitability vary by geographic factors such as county, state, and region?)
--What Data is Needed? The tables that provide geographic and sales-related data are:
--orders: (Order_Quantity, Unit_Price, Unit_Cost, StoreID)
--Store_Location: (StoreID, County, State, StateCode)
--Regions: (StateCode, Region)
--Key metrics to analyze:Sales: (Order_Quantity * Unit_Price) & Profit: (Order_Quantity * (Unit_Price - Unit_Cost))

WITH Sales_and_Profit_By_Geography AS (
    SELECT 
        sl.County, 
        sl.State, 
        r.Region, 
        SUM(o.Order_Quantity * o.Unit_Price) AS Total_Sales,
        SUM(o.Order_Quantity * (o.Unit_Price - o.Unit_Cost)) AS Total_Profit
    FROM orders o
    JOIN Store_Locations sl ON o.StoreID = sl.StoreID
    JOIN Regions r ON sl.StateCode = r.StateCode
    GROUP BY sl.County, sl.State, r.Region)
SELECT 
    County, 
    State, 
    Region, 
    Total_Sales, 
    Total_Profit
FROM Sales_and_Profit_By_Geography
ORDER BY Region, State, County;

--Geographic Analysis--
--(33) (What impact does the stores proximity to customers (latitude/longitude) have on sales?)
--What Data is Needed?
--From the orders table, we will use:Order_Quantity: The quantity of products sold.
--From the Store_Location table:Latitude and Longitude: The geographic coordinates of each store.
--We also need to calculate the distance between the store and the customer.
WITH Sales_By_Proximity AS (
    SELECT 
        sl.StoreID,
        sl.Latitude AS Store_Lat, 
        sl.Longitude AS Store_Long,
        c.CustomerID,
        c.Customer_Lat,  -- Assuming you have customer latitude and longitude data
        c.Customer_Long, 
        SUM(o.Order_Quantity * o.Unit_Price) AS Total_Sales,
        
-- Haversine Formula for distance calculation (in kilometers)
        CASE 
            WHEN 6371 * 2 * 
            ASIN(SQRT(POWER(SIN(RADIANS(c.Customer_Lat - sl.Latitude) / 2), 2) + 
            COS(RADIANS(sl.Latitude)) * COS(RADIANS(c.Customer_Lat)) * 
            POWER(SIN(RADIANS(c.Customer_Long - sl.Longitude) / 2), 2))) <= 10 
            THEN 'Within 10 km'
            
            WHEN 6371 * 2 * 
            ASIN(SQRT(POWER(SIN(RADIANS(c.Customer_Lat - sl.Latitude) / 2), 2) + 
            COS(RADIANS(sl.Latitude)) * COS(RADIANS(c.Customer_Lat)) * 
            POWER(SIN(RADIANS(c.Customer_Long - sl.Longitude) / 2), 2))) <= 20 
            THEN 'Within 20 km'
            
            WHEN 6371 * 2 * 
            ASIN(SQRT(POWER(SIN(RADIANS(c.Customer_Lat - sl.Latitude) / 2), 2) + 
            COS(RADIANS(sl.Latitude)) * COS(RADIANS(c.Customer_Lat)) * 
            POWER(SIN(RADIANS(c.Customer_Long - sl.Longitude) / 2), 2))) <= 50 
            THEN 'Within 50 km'
            
            ELSE '50+ km' 
        END AS Proximity_Category
    FROM 
        orders o
    JOIN [Store_Locations] sl ON o.StoreID = sl.StoreID
    JOIN Customers c ON o.CustomerID = c.CustomerID  -- Assuming you have customer data with lat/long
    GROUP BY 
        sl.StoreID, sl.Latitude, sl.Longitude, c.Customer_Lat, c.Customer_Long)
SELECT 
    Proximity_Category, 
    COUNT(DISTINCT StoreID) AS Store_Count,
    SUM(Total_Sales) AS Total_Sales,
    AVG(Total_Sales) AS Avg_Sales
FROM Sales_By_Proximity
GROUP BY Proximity_Category
ORDER BY Proximity_Category; -- Query didn't work for some reason 

--(34) (Do areas with higher household income or population result in higher sales volumes?)
WITH Sales_By_Store AS (
    SELECT 
        o.StoreID,
        SUM(o.Order_Quantity * o.Unit_Price) AS Total_Sales
    FROM orders o
    GROUP BY o.StoreID)
-- Correlate sales with household income and population
SELECT 
    sl.StoreID,
    sl.City_Name, 
    sl.State, 
    sl.Household_Income, 
    sl.Population, 
    sbs.Total_Sales,
-- Income impact on sales
    CASE 
        WHEN sl.Household_Income >= 100000 THEN 'High Income'
        WHEN sl.Household_Income BETWEEN 50000 AND 99999 THEN 'Middle Income'
        ELSE 'Low Income'
    END AS Income_Category,
    
-- Population impact on sales
    CASE 
        WHEN sl.Population >= 100000 THEN 'High Population'
        WHEN sl.Population BETWEEN 50000 AND 99999 THEN 'Medium Population'
        ELSE 'Low Population'
    END AS Population_Category
FROM 
    Sales_By_Store sbs
JOIN [Store_Locations] sl ON sbs.StoreID = sl.StoreID
ORDER BY sbs.Total_Sales DESC;

--(35) (How does the time zone affect store sales and shipping patterns?) 
WITH Sales_By_Store AS (
    SELECT 
        sl.Time_Zone,
        SUM(o.Order_Quantity * o.Unit_Price) AS Total_Sales
    FROM orders o
    JOIN [Store_Locations] sl ON o.StoreID = sl.StoreID
    GROUP BY sl.Time_Zone)
-- Calculate total sales for each time zone
SELECT 
    Time_Zone,
    Total_Sales
FROM Sales_By_Store
ORDER BY Total_Sales DESC;

--(36) (How does unit cost vary across different products and stores?)
-- Average Unit Cost by Product
SELECT 
    p.Product_Name,
    AVG(o.Unit_Cost) AS Avg_Unit_Cost
FROM orders o
JOIN Products p ON o.ProductID = p.ProductID
GROUP BY p.Product_Name
ORDER BY Avg_Unit_Cost DESC;
-- Average Unit Cost by Store
SELECT 
    sl.StoreID,
    AVG(o.Unit_Cost) AS Avg_Unit_Cost
FROM orders o
JOIN [Store_Locations] sl ON o.StoreID = sl.StoreID
GROUP BY sl.StoreID
ORDER BY Avg_Unit_Cost DESC;
-- Unit Cost by Product Across Different Stores
SELECT 
    sl.StoreID,
    p.Product_Name,
    AVG(o.Unit_Cost) AS Avg_Unit_Cost
FROM orders o
JOIN Products p ON o.ProductID = p.ProductID
JOIN [Store_Locations] sl ON o.StoreID = sl.StoreID
GROUP BY sl.StoreID, p.Product_Name
ORDER BY sl.StoreID, Avg_Unit_Cost DESC;

--Cost and Profit Analysis--
--(37) (What is the overall profit margin across different sales channels, regions, or time periods?)
-- Profit Margin by Sales Channel
SELECT 
    Sales_Channel,
    SUM(Order_Quantity * Unit_Price * (1 - Discount_Applied)) AS Total_Revenue,
    SUM(Order_Quantity * Unit_Cost) AS Total_Cost,
    ROUND(
        (SUM(Order_Quantity * Unit_Price * (1 - Discount_Applied)) - SUM(Order_Quantity * Unit_Cost)) / 
        SUM(Order_Quantity * Unit_Price * (1 - Discount_Applied)), 2) AS Profit_Margin
FROM orders
GROUP BY Sales_Channel;
-- Profit Margin by Region
SELECT 
    sl.Region,
    SUM(o.Order_Quantity * o.Unit_Price * (1 - o.Discount_Applied)) AS Total_Revenue,
    SUM(o.Order_Quantity * o.Unit_Cost) AS Total_Cost,
    ROUND(
        (SUM(o.Order_Quantity * o.Unit_Price * (1 - o.Discount_Applied)) - SUM(o.Order_Quantity * o.Unit_Cost)) / 
        SUM(o.Order_Quantity * o.Unit_Price * (1 - o.Discount_Applied)), 2) AS Profit_Margin
FROM orders o
JOIN Sales_Teams sl ON sl.SalesTeamID = o.SalesTeamID
GROUP BY sl.Region;
-- Profit Margin by Month
SELECT 
    FORMAT(OrderDate, 'yyyy-MM') AS Order_Month,
    SUM(Order_Quantity * Unit_Price * (1 - Discount_Applied)) AS Total_Revenue,
    SUM(Order_Quantity * Unit_Cost) AS Total_Cost,
    ROUND(
        (SUM(Order_Quantity * Unit_Price * (1 - Discount_Applied)) - SUM(Order_Quantity * Unit_Cost)) / 
        SUM(Order_Quantity * Unit_Price * (1 - Discount_Applied)), 2) AS Profit_Margin
FROM orders
GROUP BY FORMAT(OrderDate, 'yyyy-MM')
ORDER BY Order_Month;

--(38) (How does the application of discounts affect overall profitability?)
-- Total Revenue With and Without Discounts
SELECT 
    SUM(Order_Quantity * Unit_Price * (1 - Discount_Applied)) AS Sales_With_Discounts,
    SUM(Order_Quantity * Unit_Price) AS Sales_Without_Discounts
FROM orders;
-- Total Profit With and Without Discounts
SELECT 
    SUM(Order_Quantity * Unit_Price * (1 - Discount_Applied) - Order_Quantity * Unit_Cost) AS Profit_With_Discounts,
    SUM(Order_Quantity * Unit_Price - Order_Quantity * Unit_Cost) AS Profit_Without_Discounts
FROM orders;
-- Profit Margin With and Without Discounts
SELECT 
    ROUND(
        (SUM(Order_Quantity * Unit_Price * (1 - Discount_Applied)) - SUM(Order_Quantity * Unit_Cost)) 
        / NULLIF(SUM(Order_Quantity * Unit_Price * (1 - Discount_Applied)), 0), 2) AS Profit_Margin_With_Discounts,
    ROUND((SUM(Order_Quantity * Unit_Price) - SUM(Order_Quantity * Unit_Cost)) 
	/ NULLIF(SUM(Order_Quantity * Unit_Price), 0), 2) AS Profit_Margin_Without_Discounts
FROM orders;
-- Impact of Discounts by Product
-- CTE to calculate revenue and profit margins
WITH Discounted_Sales AS (
    SELECT 
        p.Product_Name,
        SUM(o.Order_Quantity * o.Unit_Price * (1 - o.Discount_Applied)) AS Sales_With_Discount,
        SUM(o.Order_Quantity * o.Unit_Price) AS Sales_Without_Discount,
        SUM(o.Order_Quantity * o.Unit_Cost) AS Total_Cost
    FROM orders o
    JOIN Products p ON o.ProductID = p.ProductID
    GROUP BY p.Product_Name)
SELECT 
    Product_Name,
    Sales_With_Discount,
    Sales_Without_Discount,
    Total_Cost,
    ROUND((Sales_With_Discount - Total_Cost) / NULLIF(Sales_With_Discount, 0), 2) AS Profit_Margin_With_Discount,
    ROUND((Sales_Without_Discount - Total_Cost) / NULLIF(Sales_Without_Discount, 0), 2) AS Profit_Margin_Without_Discount
FROM Discounted_Sales;

--(39) (Which products or stores offer the highest profit margin after considering costs and discounts?)
SELECT 
    sl.StoreID,
    p.ProductID,
    p.Product_Name,
    SUM(o.Order_Quantity * o.Unit_Price * (1 - o.Discount_Applied)) AS Total_Sales,
    SUM(o.Order_Quantity * o.Unit_Cost) AS Total_Cost,
    ROUND((SUM(o.Order_Quantity * o.Unit_Price * (1 - o.Discount_Applied)) - SUM(o.Order_Quantity * o.Unit_Cost)) 
         / NULLIF(SUM(o.Order_Quantity * o.Unit_Price * (1 - o.Discount_Applied)), 0), 2) AS Profit_Margin
FROM orders o
JOIN [Store_Locations] sl ON o.StoreID = sl.StoreID
JOIN Products p ON o.ProductID = p.ProductID
GROUP BY sl.StoreID, p.ProductID, p.Product_Name
ORDER BY Profit_Margin DESC;
--The end--
