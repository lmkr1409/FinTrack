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
    SELECT n + 1 FROM seq WHERE n < 720
)

INSERT INTO "transaction" (
    transaction_type,
    amount,
    transaction_date,
    description,
    expense_source_id,
    labeled,
    created_time,
    updated_time
)

SELECT

CASE
WHEN n % 45 = 0 THEN 'CREDIT'
ELSE 'DEBIT'
END,

CASE
WHEN n % 45 = 0 THEN 75000
WHEN n % 12 = 0 THEN (ABS(RANDOM()) % 4000) + 500
WHEN n % 7 = 0 THEN (ABS(RANDOM()) % 1500) + 200
ELSE (ABS(RANDOM()) % 500) + 50
END,

DATE('2025-09-01', '+' || (ABS(RANDOM()) % 240) || ' days'),

CASE
WHEN n % 45 = 0 THEN 'NEFT-SALARY-TCS'
WHEN n % 20 = 0 THEN 'ACH-HDFC MUTUAL FUND SIP'
WHEN n % 18 = 0 THEN 'UPI-AMAZON PAY'
WHEN n % 15 = 0 THEN 'UPI-UBER INDIA'
WHEN n % 14 = 0 THEN 'UPI-SWIGGY'
WHEN n % 12 = 0 THEN 'POS-INDIAN OIL PETROL'
WHEN n % 10 = 0 THEN 'UPI-DMART'
WHEN n % 9 = 0 THEN 'UPI-BIGBASKET'
WHEN n % 8 = 0 THEN 'UPI-NETFLIX'
WHEN n % 7 = 0 THEN 'UPI-ZOMATO'
WHEN n % 6 = 0 THEN 'UPI-AIRTEL BILL'
WHEN n % 5 = 0 THEN 'UPI-ACT FIBERNET'
WHEN n % 4 = 0 THEN 'UPI-LOCAL KIRANA STORE'
ELSE 'UPI-MERCHANT PAYMENT'
END,

(SELECT expense_source_id FROM expense_source WHERE expense_source_name='BANK_STATEMENT'),

0,

CURRENT_TIMESTAMP,
CURRENT_TIMESTAMP

FROM seq;