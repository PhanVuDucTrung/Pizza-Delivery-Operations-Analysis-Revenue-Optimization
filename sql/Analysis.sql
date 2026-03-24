-----EDA & Data Analytics-----
--A. Order volume & Sale Analytics
---Business question 1: What is the total volume of pizzas ordered and unique customer orders?
SELECT 
	COUNT(pizza_id) AS pizza_count
FROM customer_orders;

SELECT
	COUNT(DISTINCT order_id) AS customer_order_count
FROM customer_orders;

---Business question 2: Which product (Vegetarian vs. Meatlovers) is driving the most sales?
SELECT 
    n.pizza_name as Type_of_pizza, 
    COUNT(c.pizza_id) as Delivered_pizza_count
FROM pizza_runner.customer_orders as c
JOIN pizza_runner.pizza_names as n 
    USING(pizza_id)
JOIN pizza_runner.runner_orders as r 
    USING(order_id)
WHERE r.cancellation IS NULL 
  AND r.pickup_time IS NOT NULL
GROUP BY n.pizza_name
ORDER BY Type_of_pizza;

---Business Question 3: What are the peak hours for pizza orders during the day?
SELECT 
    EXTRACT(HOUR FROM order_time) as Hour, 
    COUNT(pizza_id) as total_volume
FROM pizza_runner.customer_orders
GROUP BY Hour
ORDER BY Hour;

---Business Question 4: Which days of the week experience the highest order volume?
SELECT 
    EXTRACT(DOW FROM order_time) AS Day_of_week, 
    COUNT(order_id) as total_volume
FROM pizza_runner.customer_orders
GROUP BY Day_of_week
ORDER BY Day_of_week;

---Business Question 5: What proportion of delivered pizzas required at least one customization vs. no changes?
WITH CTE AS(
    SELECT 
        order_id, 
        CASE 
            WHEN exclusions IS NULL and extras IS NULL THEN 'No changes'
            ELSE 'Have changes' 
        END AS Changing
    FROM pizza_runner.customer_orders as c
) 
SELECT 
    Changing, 
    COUNT(Changing)
FROM CTE
Group by Changing; 

---Business Question 6: How many highly customized pizzas (both extras and exclusions) were delivered?
WITH CTE AS(
    SELECT 
        order_id, 
        CASE 
            WHEN exclusions IS NOT NULL and extras IS NOT NULL THEN 'Both changes'
            WHEN exclusions IS NULL and extras IS NULL THEN 'Not changes'
            ELSE 'Have 1 change' 
        END AS Changing
    FROM pizza_runner.customer_orders as c
) 
SELECT 
    Changing, 
    COUNT(Changing)
FROM CTE
WHERE Changing = 'Both changes'
Group by Changing; 

---Business Question 7: What is the personal preference profile (Meatlovers vs. Vegetarian) for each customer?
SELECT 
    c.customer_id as Customer, 
    n.pizza_name as Type_of_pizza, 
    COUNT(c.pizza_id) as pizza_count
FROM pizza_runner.customer_orders as c
JOIN pizza_runner.pizza_names as n 
    USING(pizza_id)
GROUP BY Customer, n.pizza_name
ORDER BY Type_of_pizza;

---Business Question 8: What is the maximum logistics capacity required for a single delivery trip?
WITH CTE as(
    SELECT 
        c.order_id, 
        COUNT(c.pizza_id) as count
    FROM pizza_runner.customer_orders as c
    JOIN pizza_runner.runner_orders as r 
        USING(order_id)
    WHERE r.cancellation IS NULL
    GROUP BY order_id
) 
SELECT 
    max(count) as Highest_deliveried_pizza_per_order
FROM CTE; 

---Business Question 9: What is the successful delivery contribution of each runner?
SELECT 
    runner_id, 
    COUNT(order_id) AS order_count
FROM runner_orders
WHERE duration IS NOT NULL
GROUP BY runner_id;



--B. Logistic Performance & Delivery efficiency
---Business Question 1: What is the weekly acquisition rate of new delivery partners?
SELECT 
    COUNT(runner_id) as Registered_runner 
FROM pizza_runner.runners 
WHERE registration_date between '2021-01-01' AND ('2021-01-01'::date + INTERVAL '7 DAY');

---Business Question 2: What is the average response time for runners to arrive at the dispatch center?
SELECT 
    EXTRACT(MINUTE FROM AVG(r.pickup_time - c.order_time)) as Avr_Time_to_pickup_order 
FROM pizza_runner.customer_orders as c 
JOIN pizza_runner.runner_orders as r 
    USING(order_id); 

---Business Question 3: How does the order size (number of pizzas) impact kitchen preparation time?
WITH CTE AS( 
    SELECT 
        COUNT(pizza_id) as Number_of_pizza, 
        r.pickup_time - c.order_time as Time_to_prepare 
    FROM pizza_runner.runner_orders as r 
    JOIN pizza_runner.customer_orders as c 
        USING(order_id) 
    WHERE r.cancellation IS NULL 
    GROUP BY c.order_id, r.pickup_time, c.order_time
) 
SELECT 
    Number_of_pizza, 
    Time_to_prepare 
FROM CTE 
ORDER BY Number_of_pizza; 

---Business Question 4: What is the average delivery radius for our active customer base?
SELECT 
    c.customer_id as customers, 
    AVG(r.distance) as average_distance 
FROM pizza_runner.runner_orders as r 
JOIN pizza_runner.customer_orders as c 
    USING(order_id) 
WHERE r.cancellation IS NULL 
GROUP BY customers 
ORDER BY customers; 

---Business Question 5: What is the variance between our fastest and slowest delivery times?
SELECT 
    MAX(duration) - MIN(duration) as diff 
FROM pizza_runner.runner_orders 
WHERE cancellation IS NULL; 

---Business Question 6: What is the average moving speed of each runner, and are there any safety anomalies?
WITH CTE AS( 
    SELECT 
        order_id, 
        runner_id, 
        distance/duration * 60 as km_per_hour 
    FROM pizza_runner.runner_orders 
    WHERE cancellation IS NULL
) 
SELECT 
    order_id as Order, 
    runner_id as Runner, 
    ROUND(km_per_hour) as kms_per_hour 
FROM CTE 
ORDER BY runner_id;

---Business Question 7: What is the delivery success (fulfillment) rate for each partner?
WITH Success_Delivery AS( 
    SELECT 
        runner_id, 
        COUNT(order_id)::float as success 
    FROM pizza_runner.runner_orders 
    WHERE cancellation IS NULL 
    GROUP BY runner_id
), 
Failed_Delivery AS( 
    SELECT 
        runner_id, 
        COUNT(order_id)::float as failed 
    FROM pizza_runner.runner_orders 
    WHERE cancellation IS NOT NULL 
    GROUP BY runner_id
) 
SELECT 
    runner_id as Runner, 
    s.success, 
    f.failed, 
    CASE 
        WHEN s.success IS NULL THEN 0 
        WHEN f.failed IS NULL THEN 100 
        ELSE (s.success/(s.success+f.failed))*100 
    END AS Success_percentage 
FROM Success_Delivery as S 
LEFT JOIN Failed_Delivery as F 
    USING(runner_id) 
ORDER BY runner; 

--C. Inventory management & Product customization
---Business Question 1: What is the standardized ingredient blueprint for our core pizza menu?
WITH CTE AS( 
    SELECT  
        n.pizza_name,  
        pizza_id,  
        unnest(r.toppings_array) as topping_id 
    FROM pizza_runner.pizza_recipes as r 
    JOIN pizza_runner.pizza_names as n USING(pizza_id)
)  
SELECT  
    cte.pizza_name,  
    t.topping_name as ingredients 
FROM CTE 
JOIN pizza_runner.pizza_toppings as t ON CTE.topping_id = t.topping_id 
ORDER BY pizza_name, cte.topping_id;

---Business Question 2: What is the aggregate consumption of each raw material across all fulfilled orders?
WITH delivered AS( 
    SELECT  
        c.order_id,  
        c.pizza_id,  
        c.exclusions_array,  
        c.extras_array 
    FROM pizza_runner.customer_orders c 
    JOIN pizza_runner.runner_orders r USING(order_id) 
    WHERE cancellation IS NULL 
), 
base_topping AS( 
    SELECT   
        d.order_id,  
        unnest(toppings_array) as basetopping_id 
    FROM delivered d 
    JOIN pizza_runner.pizza_recipes as pr USING(pizza_id) 
    ORDER BY order_id 
), 
remove_exclusion as( 
    SElECT  
        d.order_id,  
        b.basetopping_id 
    FROM delivered d 
    JOIN base_topping as b USING(order_id) 
    WHERE d.exclusions_array IS NULL OR b.basetopping_id <> ALL (d.exclusions_array) 
), 
add_extra as( 
    SELECT  
        d.order_id,  
        unnest(d.extras_array) as basetopping_id 
    FROM delivered d 
    WHERE extras_array IS NOT NULL 
), 
final_topping as( 
    SELECT * FROM remove_exclusion 
    UNION ALL 
    SELECT * FROM add_extra
) 
SELECT  
    t.topping_name,  
    count(*) as total_used 
FROM final_topping f 
JOIN pizza_runner.pizza_toppings t ON f.basetopping_id = t.topping_id 
GROUP BY t.topping_name 
ORDER BY total_used DESC;

---Business Question 3: Which ingredient drives the highest demand as an add-on (Upsell opportunity)?
WITH CTE AS( 
    SELECT   
        unnest(extras_array) as extras_id 
    FROM pizza_runner.customer_orders 
    WHERE extras_array IS NOT NULL
)  
SELECT  
    t.topping_name,  
    COUNT(extras_id) as frequency 
FROM pizza_runner.pizza_toppings as t 
JOIN CTE ON CTE.extras_id = t.topping_id 
GROUP BY topping_name 
ORDER BY frequency DESC 
LIMIT 1; 

---Business Question 4: Which default ingredient is most frequently rejected by customers (Cost-saving opportunity)?
WITH CTE AS( 
    SELECT   
        unnest(exclusions_array) as exclusion_id 
    FROM pizza_runner.customer_orders 
    WHERE exclusions_array IS NOT NULL
)  
SELECT  
    t.topping_name,  
    COUNT(exclusion_id) as frequency 
FROM pizza_runner.pizza_toppings as t 
JOIN CTE ON CTE.exclusion_id = t.topping_id 
GROUP BY topping_name 
ORDER BY frequency DESC 
LIMIT 1;

---Business Question 5: How can we generate an automated, human-readable Kitchen Display receipt detailing exclusions and additions?
WITH exclusion AS( 
    SELECT   
        c.order_id,  
        n.pizza_name,  
        unnest(c.exclusions_array) as exclusion_id 
    FROM pizza_runner.customer_orders as c 
    JOIN pizza_runner.pizza_names as n USING(pizza_id) 
    WHERE exclusions_array IS NOT NULL 
    ORDER BY order_id, pizza_name
),  
extra AS( 
    SELECT   
        c.order_id,  
        n.pizza_name,  
        unnest(c.extras_array) as extra_id 
    FROM pizza_runner.customer_orders as c 
    JOIN pizza_runner.pizza_names as n USING(pizza_id) 
    WHERE extras_array IS NOT NULL 
    ORDER BY order_id, pizza_name
),  
exclusion_list as( 
    SELECT         
        e.order_id,         
        STRING_AGG(t.topping_name, ', ') AS exclusion_list 
    FROM exclusion as e 
    JOIN pizza_runner.pizza_toppings as t ON e.exclusion_id = t.topping_id 
    GROUP BY e.order_id
),  
extra_list as( 
    SELECT  
        e.order_id,  
        STRING_AGG(t.topping_name, ', ') as extra_list 
    FROM extra as e 
    JOIN pizza_runner.pizza_toppings as t ON e.extra_id = t.topping_id 
    GROUP BY e.order_id
)  
SELECT  
    c.order_id,  
    n.pizza_name ||  
    CASE   
        WHEN e1.exclusion_list IS NOT NULL THEN ' - Exclude ' || e1.exclusion_list   
        ELSE '' 
    END ||  
    CASE   
        WHEN e2.extra_list IS NOT NULL THEN ' - Extra ' || e2.extra_list 
        ELSE '' 
    END AS order_item 
FROM pizza_runner.customer_orders as c 
JOIN pizza_runner.pizza_names as n USING(pizza_id) 
LEFT JOIN exclusion_list as e1 USING(order_id) 
LEFT JOIN extra_list as e2 USING(order_id) 
ORDER BY c.order_id; 

---Business Question 6: How can we engineer an automated final preparation checklist for chefs that aggregates base recipes with dynamic modifications?
WITH CTE_Orders AS (  
    SELECT    
        ROW_NUMBER() OVER( ORDER BY order_id) AS record_id,   
        [order_id],   
        [customer_id],   
        [pizza_id],   
        [exclusions],    
        [extras]  
    FROM [dbo].[customer_orders]  
), 
CTE_Standard AS (  
    SELECT    
        cte.record_id,   
        cte.[pizza_id],   
        TRIM(spl.value) AS topping_id  
    FROM CTE_Orders AS cte  
    INNER JOIN [dbo].[pizza_recipes] AS r ON r.[pizza_id] = cte.[pizza_id]  
    CROSS APPLY STRING_SPLIT(r.toppings, ',') AS spl 
), 
CTE_Extras AS (  
    SELECT    
        record_id,   
        [pizza_id],   
        TRIM(ext.value) AS topping_id  
    FROM CTE_Orders AS cte  
    OUTER APPLY STRING_SPLIT(extras, ',') AS ext  
    WHERE ext.value IS NOT NULL  
), 
CTE_Exclusions AS (
    SELECT    
        record_id,   
        [pizza_id],   
        TRIM(exc.value) AS topping_id  
    FROM CTE_Orders AS cte  
    OUTER APPLY STRING_SPLIT(exclusions, ',') AS exc  
    WHERE exc.value IS NOT NULL  
), 
CTE_Combined AS (  
    SELECT record_id, pizza_id, topping_id     
    FROM (         
        SELECT record_id, pizza_id, topping_id FROM CTE_Standard         
        UNION ALL         
        SELECT record_id, pizza_id, topping_id FROM CTE_Extras     
    ) AS Raw_Ingredients     
    WHERE topping_id NOT IN (         
        SELECT topping_id FROM CTE_Exclusions         
        WHERE CTE_Exclusions.record_id = Raw_Ingredients.record_id     
    ) 
), 
CTE_Counted AS (  
    SELECT         
        c.record_id,         
        c.pizza_id,         
        t.topping_name,         
        COUNT(*) AS qty,         
        CASE             
            WHEN COUNT(*) > 1 THEN CAST(COUNT(*) AS VARCHAR) + 'x ' + t.topping_name    
            ELSE t.topping_name         
        END AS ingredient_display     
    FROM CTE_Combined c     
    JOIN pizza_toppings t ON c.topping_id = t.topping_id     
    GROUP BY c.record_id, c.pizza_id, t.topping_name 
) 
SELECT   
    o.order_id,     
    CONCAT(         
        p.pizza_name,         
        ': ',         
        STRING_AGG(ci.ingredient_display, ', ') WITHIN GROUP (ORDER BY ci.topping_name)     
    ) AS full_ingredient_list
FROM CTE_Orders o 
JOIN pizza_names p ON o.pizza_id = p.pizza_id 
JOIN CTE_Counted ci ON o.record_id = ci.record_id 
GROUP BY o.order_id, o.record_id, p.pizza_name 
ORDER BY o.order_id;

--D. Financial Performance & Service quality assessment
---Business Question 1: What is the baseline gross revenue generated from successful deliveries (assuming fixed base prices and no delivery fees)?
SELECT 
    SUM(
        CASE WHEN [pizza_id] = 1 THEN 12 
        ELSE 10 
    END) AS Total_Money 
FROM [dbo].[customer_orders] co 
INNER JOIN [dbo].[runner_orders] ro 
    ON co.order_id = ro.order_id 
WHERE pickup_time IS NOT NULL;

---Business Question 2: Revenue Simulation: How much additional gross revenue could be generated if a $1 surcharge is applied for every extra ingredient requested?
WITH pizza AS(  
    SELECT    
        co.order_id,   
        pizza_id,   
        extras  
    FROM [dbo].[customer_orders] AS co  
    INNER JOIN [dbo].[runner_orders] AS ro  
        ON co.order_id = ro.order_id  
    WHERE pickup_time IS NOT NULL 
), 
Extra_toppings AS(  
    SELECT   
        TRIM(e.value) AS Extra_id  
    FROM pizza  
    OUTER APPLY string_split(extras, ',') AS e  
) 
SELECT   
    (SELECT SUM(CASE WHEN pizza_id = 1 THEN 12 ELSE 10 END) FROM pizza) -- Base revenue
    +  
    (SELECT COUNT(Extra_id) FROM Extra_toppings ) -- Additional revenue from extras
    AS Total_Revenue; 

---Business Question 3: What is the Net Profit (Leftover Money) per order after deducting runner compensation ($0.30 per kilometer traveled)?
SELECT   
    (SUM(CASE WHEN pizza_id = 1 THEN 12 ELSE 10 END)  
    -  
    SUM(CAST(distance AS FLOAT) * 0.30)) AS Left_money 
FROM [dbo].[customer_orders] AS co 
INNER JOIN [dbo].[runner_orders] AS ro 
    ON co.order_id = ro.order_id 
WHERE pickup_time IS NOT NULL;

---Business Question 4: How can we design and implement a relational schema to capture post-delivery customer ratings and feedback?
DROP TABLE IF EXISTS runner_ratings; 

CREATE TABLE runner_ratings (  
    order_id INT PRIMARY KEY ,  
    rating INT,  
    comment VARCHAR(100),  
    CHECK (rating >= 0 AND rating <=5) 
); 

INSERT INTO runner_ratings (order_id, rating, comment) 
VALUES   
    (1, 5,'thuc an con nong'),  
    (2, 4, 'hoi nguoi'),
    (3, 5, 'shipper than thien'),  
    (4, 3, NULL),  
    (5, 5,'tuyet voi'),  
    (7, 1,'banh bi moc, shipper coc can'),     
    (8, 1, 'Banh bi nat, shipper tho lo'),     
    (10, 5, 'Ship den dung gio');

---Business Question 5: How can we consolidate operational data (speed, duration, distance) with customer ratings to create a 360-degree view of delivery performance?
SELECT   
    customer_id,  
    co.order_id,  
    runner_id,  
    rating,  
    order_time,  
    pickup_time,  
    DATEDIFF(minute, order_time, pickup_time) AS [Time between order and pickup],  
    duration AS [Delivery duration],  
    ROUND((CAST(distance AS FLOAT)/CAST((duration) AS FLOAT))*60,2) AS Avg_speed,  
    COUNT(pizza_id) AS Total_pizzas 
FROM runner_ratings AS rt 
INNER JOIN [dbo].[customer_orders] AS co 
    ON co.order_id = rt.order_id 
INNER JOIN [dbo].[runner_orders] AS ro 
    ON ro.order_id = rt.order_id 
GROUP BY   
    customer_id,  
    co.order_id,  
    runner_id,  
    rating,  
    order_time,  
    pickup_time,  
    duration,
    distance;

--E. Database scalability & Data modeling
---Business Question: How scalable is our current data model when introducing a new "Supreme" pizza containing all available ingredients? 
----pizza_names holds the list of pizza types, so adding a new pizza just means inserting one more row.
----pizza_recipes and pizza_toppings already separate recipes from toppings, so the new pizza can reuse all existing toppings via their IDs.
INSERT INTO pizza_names (pizza_id, pizza_name)
VALUES (3, 'Supreme');
INSERT INTO pizza_recipes (pizza_id, toppings)
VALUES
  (3, '1,2,3,4,5,6,7,8,9,10,11,12');
