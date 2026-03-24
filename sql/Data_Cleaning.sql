-----Data Cleaning & Data Wraggling-----
-- Cleaning data of 'customer_orders' table
UPDATE pizza_runner.customer_orders
SET 
    exclusions = CASE 
        WHEN exclusions IS NULL OR exclusions = '' OR exclusions = 'null'
        THEN NULL
        ELSE TRIM(exclusions)
    END,

    extras = CASE 
        WHEN extras IS NULL OR extras = '' OR extras = 'null'
        THEN NULL
        ELSE TRIM(extras)
    END;

-- Cleaning data of 'runner_orders' table
UPDATE pizza_runner.runner_orders
SET 
    pickup_time = CASE 
        WHEN pickup_time IS NULL OR pickup_time = '' OR pickup_time = 'null'
        THEN NULL
        ELSE TRIM(pickup_time)
    END,

    distance = CASE 
        WHEN distance IS NULL OR distance = '' OR distance = 'null'
        THEN NULL
        ELSE TRIM(distance)
    END,

    duration = CASE 
        WHEN duration IS NULL OR duration = '' OR duration = 'null'
        THEN NULL
        ELSE TRIM(duration)
    END,

    cancellation = CASE 
        WHEN cancellation IS NULL OR cancellation = '' OR cancellation = 'null'
        THEN NULL
        ELSE TRIM(cancellation)
    END;

-- Cleaning data of 'runne_orders' table
UPDATE pizza_runner.runner_orders
SET distance =
	Case When distance IS NULL Then NULL
	Else Trim(replace(distance,'km',''))
	END;
ALTER TABLE pizza_runner.runner_orders
ALTER COLUMN distance TYPE FLOAT
USING distance::float;


UPDATE pizza_runner.runner_orders
SET duration =
	Case When duration IS NULL Then NULL
	Else TRIM(LEFT(duration,2))
	END;
ALTER TABLE pizza_runner.runner_orders
ALTER COLUMN durationTYPE FLOAT
USING duration::float;


ALTER TABLE pizza_runner.runner_orders
ALTER COLUMN pickup_time TYPE TIMESTAMP
USING pickup_time::timestamp;

-- Cleaning data of 'customer_orders' table
ALTER TABLE pizza_runner.customer_orders
ADD COLUMN exclusions_array int[],
ADD COLUMN extras_array int[];

UPDATE pizza_runner.customer_orders
SET
    exclusions_array = CASE
        WHEN exclusions IS NULL OR exclusions = '' OR exclusions = 'null'
            THEN NULL
        ELSE string_to_array(REPLACE(exclusions, ' ', ''), ',')::int[]
    END,
    
    extras_array = CASE
        WHEN extras IS NULL OR extras = '' OR extras = 'null'
            THEN NULL
        ELSE string_to_array(REPLACE(extras, ' ', ''), ',')::int[]
    END;

-- Cleaning data of 'pizza_recipes' table
ALTER TABLE pizza_runner.pizza_recipes
ADD COLUMN toppings_array int[];

UPDATE pizza_runner.customer_orders
SET
    toppings_array =  string_to_array(REPLACE(toppings, ' ', ''), ',')::int[]
    END,

