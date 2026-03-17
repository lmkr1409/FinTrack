INSERT INTO merchant (merchant_name, icon, icon_color, priority) VALUES
('Swiggy','store','#FF5722',0),
('Zomato','store','#E53935',0),
('Indian Oil Petrol Pump','store','#FF9800',0),
('HP Petrol Pump','store','#FF9800',0),
('BigBasket','store','#4CAF50',0),
('DMart','store','#4CAF50',0),
('Netflix','store','#E50914',0),
('Spotify','store','#1DB954',0),
('ACT Fibernet','store','#2196F3',0),
('Airtel','store','#E91E63',0),
('APSPDCL','store','#FFC107',0),
('IRCTC','store','#3F51B5',0),
('MakeMyTrip','store','#1976D2',0),
('Flipkart','store','#2874F0',0),
('HDFC Mutual Fund','store','#005587',0),
('Zerodha','store','#FF5722',0),
('Local Vegetable Market','store','#4CAF50',0),
('Local Kirana Store','store','#4CAF50',0),
('Starbucks','store','#006241',0),
('Dominos','store','#E31837',0);

INSERT INTO merchant_mapping
(merchant_id,category_id,subcategory_id,purpose_id,payment_method_id)
VALUES
((SELECT merchant_id FROM merchant WHERE merchant_name='Amazon'),
 (SELECT category_id FROM category WHERE category_name='Shopping'),
 (SELECT subcategory_id FROM sub_category WHERE subcategory_name='Electronics'),
 (SELECT purpose_id FROM expense_purpose WHERE expense_for='Household'),
 (SELECT payment_method_id FROM payment_method WHERE payment_method_name='UPI')),

((SELECT merchant_id FROM merchant WHERE merchant_name='Uber'),
 (SELECT category_id FROM category WHERE category_name='Transportation'),
 (SELECT subcategory_id FROM sub_category WHERE subcategory_name='Commute'),
 (SELECT purpose_id FROM expense_purpose WHERE expense_for='Manoj'),
 (SELECT payment_method_id FROM payment_method WHERE payment_method_name='UPI')),

((SELECT merchant_id FROM merchant WHERE merchant_name='Swiggy'),
 (SELECT category_id FROM category WHERE category_name='Food'),
 (SELECT subcategory_id FROM sub_category WHERE subcategory_name='Restaurant'),
 (SELECT purpose_id FROM expense_purpose WHERE expense_for='Household'),
 (SELECT payment_method_id FROM payment_method WHERE payment_method_name='UPI')),

((SELECT merchant_id FROM merchant WHERE merchant_name='Indian Oil Petrol Pump'),
 (SELECT category_id FROM category WHERE category_name='Transportation'),
 (SELECT subcategory_id FROM sub_category WHERE subcategory_name='Petrol'),
 (SELECT purpose_id FROM expense_purpose WHERE expense_for='Manoj'),
 (SELECT payment_method_id FROM payment_method WHERE payment_method_name='CARD'));

WITH RECURSIVE seq(n) AS (
  SELECT 1
  UNION ALL
  SELECT n + 1 FROM seq WHERE n < 920
)

INSERT INTO "transaction" (
transaction_type,
amount,
transaction_date,
description,
category_id,
subcategory_id,
purpose_id,
account_id,
merchant_id,
payment_method_id,
expense_source_id,
labeled,
created_time,
updated_time
)

SELECT

CASE
WHEN n % 40 = 0 THEN 'CREDIT'
ELSE 'DEBIT'
END,

CASE
WHEN n % 40 = 0 THEN 75000
WHEN n % 10 = 0 THEN (ABS(RANDOM())%3000)+500
WHEN n % 5 = 0 THEN (ABS(RANDOM())%800)+200
ELSE (ABS(RANDOM())%400)+50
END,

DATE(
  '2025-05-01',
  '+' || (ABS(RANDOM()) % (
    julianday('now') - julianday('2025-05-01')
  )) || ' days'
),

CASE
WHEN n % 40 = 0 THEN 'Salary Credit'
WHEN n % 12 = 0 THEN 'Monthly SIP'
WHEN n % 8 = 0 THEN 'Amazon Purchase'
WHEN n % 7 = 0 THEN 'Uber Ride'
WHEN n % 6 = 0 THEN 'Swiggy Order'
WHEN n % 5 = 0 THEN 'Petrol'
WHEN n % 4 = 0 THEN 'Groceries'
ELSE 'Daily Expense'
END,

(SELECT category_id FROM category ORDER BY RANDOM() LIMIT 1),

(SELECT subcategory_id FROM sub_category ORDER BY RANDOM() LIMIT 1),

(SELECT purpose_id FROM expense_purpose ORDER BY RANDOM() LIMIT 1),

(SELECT account_id FROM account ORDER BY RANDOM() LIMIT 1),

(SELECT merchant_id FROM merchant ORDER BY RANDOM() LIMIT 1),

(SELECT payment_method_id FROM payment_method ORDER BY RANDOM() LIMIT 1),

(SELECT expense_source_id FROM expense_source WHERE expense_source_name='BANK_STATEMENT'),

1,

CURRENT_TIMESTAMP,
CURRENT_TIMESTAMP

FROM seq;