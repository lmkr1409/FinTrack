-- ──────────────────────────────────────────────────────────────────────
-- DML: SEED DATA
-- Includes configurations from old_db.sql and modern transaction rules
-- Transactions are excluded.
-- ──────────────────────────────────────────────────────────────────────

-- 1. category
INSERT INTO category (category_name, icon, icon_color, priority, category_type) VALUES ('Housing', 'home', '#8B4513', 1, 'EXPENSE');
INSERT INTO category (category_name, icon, icon_color, priority, category_type) VALUES ('Groceries', 'shopping_basket', '#4CAF50', 2, 'EXPENSE');
INSERT INTO category (category_name, icon, icon_color, priority, category_type) VALUES ('Utilities', 'lightbulb', '#FFD700', 3, 'EXPENSE');
INSERT INTO category (category_name, icon, icon_color, priority, category_type) VALUES ('Investments', 'pie_chart', '#2E86C1', 4, 'TRANSFER');
INSERT INTO category (category_name, icon, icon_color, priority, category_type) VALUES ('Food', 'restaurant', '#FF6347', 5, 'EXPENSE');
INSERT INTO category (category_name, icon, icon_color, priority, category_type) VALUES ('Shopping', 'shopping_cart', '#FF8C00', 6, 'EXPENSE');
INSERT INTO category (category_name, icon, icon_color, priority, category_type) VALUES ('Transportation', 'directions_bus', '#1E90FF', 7, 'EXPENSE');
INSERT INTO category (category_name, icon, icon_color, priority, category_type) VALUES ('Gifts & Donation', 'card_giftcard', '#E91E63', 8, 'EXPENSE');
INSERT INTO category (category_name, icon, icon_color, priority, category_type) VALUES ('Self Transfer', 'swap_horiz', '#607D8B', 9, 'TRANSFER');
INSERT INTO category (category_name, icon, icon_color, priority, category_type) VALUES ('Education', 'school', '#6A5ACD', 10, 'EXPENSE');
INSERT INTO category (category_name, icon, icon_color, priority, category_type) VALUES ('Healthcare', 'favorite', '#DC143C', 11, 'EXPENSE');
INSERT INTO category (category_name, icon, icon_color, priority, category_type) VALUES ('Entertainment', 'movie', '#FF69B4', 12, 'EXPENSE');
INSERT INTO category (category_name, icon, icon_color, priority, category_type) VALUES ('Insurance', 'shield', '#808080', 13, 'EXPENSE');
INSERT INTO category (category_name, icon, icon_color, priority, category_type) VALUES ('Salary', 'payments', '#43A047', 1, 'INCOME');
INSERT INTO category (category_name, icon, icon_color, priority, category_type) VALUES ('Dividends', 'show_chart', '#00C853', 98, 'INCOME');
INSERT INTO category (category_name, icon, icon_color, priority, category_type) VALUES ('Travel', 'flight', '#4682B4', 98, 'EXPENSE');
INSERT INTO category (category_name, icon, icon_color, priority, category_type) VALUES ('Other', 'more_horiz', '#A9A9A9', 99, 'EXPENSE');

-- 2. sub_category
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Fruits', 'nutrition', '#FF4C4C', 99, (SELECT category_id FROM category WHERE category_name = 'Groceries'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Vegetables', 'eco', '#4CAF50', 99, (SELECT category_id FROM category WHERE category_name = 'Groceries'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Dairy', 'breakfast_dining', '#2196F3', 99, (SELECT category_id FROM category WHERE category_name = 'Groceries'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Meat', 'set_meal', '#795548', 99, (SELECT category_id FROM category WHERE category_name = 'Groceries'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Other', 'shopping_basket', '#9E9E9E', 99, (SELECT category_id FROM category WHERE category_name = 'Groceries'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Electricity', 'lightbulb', '#FFD600', 99, (SELECT category_id FROM category WHERE category_name = 'Utilities'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Mobile Bill', 'smartphone', '#00C853', 99, (SELECT category_id FROM category WHERE category_name = 'Utilities'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Internet Bill', 'language', '#2962FF', 99, (SELECT category_id FROM category WHERE category_name = 'Utilities'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Gas Bill', 'local_fire_department', '#FF5722', 99, (SELECT category_id FROM category WHERE category_name = 'Utilities'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Other', 'bolt', '#9E9E9E', 99, (SELECT category_id FROM category WHERE category_name = 'Utilities'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Petrol', 'local_gas_station', '#FF9800', 99, (SELECT category_id FROM category WHERE category_name = 'Transportation'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Bike Service', 'two_wheeler', '#607D8B', 99, (SELECT category_id FROM category WHERE category_name = 'Transportation'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Other', 'directions_car', '#9E9E9E', 99, (SELECT category_id FROM category WHERE category_name = 'Transportation'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Rent', 'home', '#3F51B5', 99, (SELECT category_id FROM category WHERE category_name = 'Housing'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Maintenance', 'build', '#9E9D24', 99, (SELECT category_id FROM category WHERE category_name = 'Housing'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Other', 'house', '#9E9E9E', 99, (SELECT category_id FROM category WHERE category_name = 'Housing'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Movies', 'movie', '#E91E63', 99, (SELECT category_id FROM category WHERE category_name = 'Entertainment'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Concerts', 'music_note', '#673AB7', 99, (SELECT category_id FROM category WHERE category_name = 'Entertainment'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Other', 'theater_comedy', '#9E9E9E', 99, (SELECT category_id FROM category WHERE category_name = 'Entertainment'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Doctor', 'medical_services', '#00BCD4', 99, (SELECT category_id FROM category WHERE category_name = 'Healthcare'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Medicine', 'medication', '#F44336', 99, (SELECT category_id FROM category WHERE category_name = 'Healthcare'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Other', 'local_hospital', '#9E9E9E', 99, (SELECT category_id FROM category WHERE category_name = 'Healthcare'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Health Insurance', 'health_and_safety', '#F44336', 99, (SELECT category_id FROM category WHERE category_name = 'Insurance'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Car Insurance', 'car_crash', '#009688', 99, (SELECT category_id FROM category WHERE category_name = 'Insurance'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Bike Insurance', 'two_wheeler', '#FF9800', 99, (SELECT category_id FROM category WHERE category_name = 'Insurance'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Other', 'shield', '#9E9E9E', 99, (SELECT category_id FROM category WHERE category_name = 'Insurance'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Books', 'menu_book', '#3F51B5', 99, (SELECT category_id FROM category WHERE category_name = 'Education'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Courses', 'school', '#4CAF50', 99, (SELECT category_id FROM category WHERE category_name = 'Education'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Other', 'edit', '#9E9E9E', 99, (SELECT category_id FROM category WHERE category_name = 'Education'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Clothes', 'checkroom', '#FF5722', 99, (SELECT category_id FROM category WHERE category_name = 'Shopping'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Electronics', 'laptop', '#2196F3', 99, (SELECT category_id FROM category WHERE category_name = 'Shopping'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Other', 'shopping_bag', '#9E9E9E', 99, (SELECT category_id FROM category WHERE category_name = 'Shopping'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Office', 'coffee', '#6D4C41', 99, (SELECT category_id FROM category WHERE category_name = 'Food'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Breakfast', 'breakfast_dining', '#FF9800', 99, (SELECT category_id FROM category WHERE category_name = 'Food'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Outside', 'lunch_dining', '#FF9800', 99, (SELECT category_id FROM category WHERE category_name = 'Food'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Restaurant', 'restaurant', '#795548', 99, (SELECT category_id FROM category WHERE category_name = 'Food'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Snacks', 'bakery_dining', '#8D6E63', 99, (SELECT category_id FROM category WHERE category_name = 'Food'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Other', 'restaurant', '#9E9E9E', 99, (SELECT category_id FROM category WHERE category_name = 'Food'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Tour', 'map', '#009688', 99, (SELECT category_id FROM category WHERE category_name = 'Travel'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Hotel', 'hotel', '#3F51B5', 99, (SELECT category_id FROM category WHERE category_name = 'Travel'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Other', 'flight', '#9E9E9E', 99, (SELECT category_id FROM category WHERE category_name = 'Travel'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Other', 'help_outline', '#9E9E9E', 99, (SELECT category_id FROM category WHERE category_name = 'Other'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Repairs', 'build', '#9E9E9E', 99, (SELECT category_id FROM category WHERE category_name = 'Housing'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Milling', 'grain', '#DAA520', 99, (SELECT category_id FROM category WHERE category_name = 'Groceries'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Gift', 'card_giftcard', '#9C27B0', 99, (SELECT category_id FROM category WHERE category_name = 'Gifts & Donation'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Donation', 'volunteer_activism', '#4CAF50', 99, (SELECT category_id FROM category WHERE category_name = 'Gifts & Donation'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Commute', 'airport_shuttle', '#0288D1', 99, (SELECT category_id FROM category WHERE category_name = 'Transportation'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('MF', 'trending_up', '#2E86C1', 1, (SELECT category_id FROM category WHERE category_name = 'Investments'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Stocks', 'show_chart', '#2E86C1', 2, (SELECT category_id FROM category WHERE category_name = 'Investments'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('FD', 'lock', '#2E86C1', 3, (SELECT category_id FROM category WHERE category_name = 'Investments'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('RD', 'history', '#2E86C1', 4, (SELECT category_id FROM category WHERE category_name = 'Investments'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('ChitFund', 'groups', '#2E86C1', 5, (SELECT category_id FROM category WHERE category_name = 'Investments'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('HandLoan', 'handshake', '#2E86C1', 6, (SELECT category_id FROM category WHERE category_name = 'Investments'));

-- 3. account
INSERT INTO account (account_name, balance, icon, icon_color, priority, created_time, updated_time) VALUES ('HDFC Bank', 20900, 'account_balance', '#005587', 1, '2025-09-20 06:02:51', '2025-09-20 06:02:51');
INSERT INTO account (account_name, balance, icon, icon_color, priority, created_time, updated_time) VALUES ('Standard Chartered Bank', 0, 'account_balance', '#007474', 2, '2025-09-20 06:02:51', '2025-09-20 06:02:51');
INSERT INTO account (account_name, balance, icon, icon_color, priority, created_time, updated_time) VALUES ('State Bank Of India', 0, 'account_balance', '#1E88E5', 3, '2025-09-20 06:02:51', '2025-09-20 06:02:51');
INSERT INTO account (account_name, balance, icon, icon_color, priority, created_time, updated_time) VALUES ('Canara Bank', 0, 'account_balance', '#FFD700', 4, '2025-09-20 06:02:51', '2025-09-20 06:02:51');
INSERT INTO account (account_name, balance, icon, icon_color, priority, created_time, updated_time) VALUES ('Andhra Pragathi Grameena Bank', 100.00, 'account_balance', '#FAAFFB', 5, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- 4. cards
INSERT INTO cards (card_name, card_type, card_number, card_expiry_date, card_network, balance, icon, icon_color, priority, created_time, updated_time, account_id) VALUES ('Tata Neu', 'CREDIT', 'XXXX-XXXX-XXXX-0591', '2028-12-31', 'RUPAY', 0, 'credit_card', '#005587', 1, '2025-09-20 06:06:09', '2025-09-20 06:06:09', (SELECT account_id FROM account WHERE account_name = 'HDFC Bank'));
INSERT INTO cards (card_name, card_type, card_number, card_expiry_date, card_network, balance, icon, icon_color, priority, created_time, updated_time, account_id) VALUES ('Diners Club', 'DEBIT', 'XXXX-XXXX-XXXX-3333', '2028-12-31', 'MASTERCARD', 0, 'credit_card', '#007474', 2, '2025-09-20 06:06:09', '2025-09-20 06:06:09', (SELECT account_id FROM account WHERE account_name = 'Standard Chartered Bank'));
INSERT INTO cards (card_name, card_type, card_number, card_expiry_date, card_network, balance, icon, icon_color, priority, created_time, updated_time, account_id) VALUES ('Reward Plus', 'DEBIT', 'XXXX-XXXX-XXXX-2222', '2028-12-31', 'VISA', 0, 'credit_card', '#005587', 3, '2025-09-20 06:06:09', '2025-09-20 06:06:09', (SELECT account_id FROM account WHERE account_name = 'HDFC Bank'));

-- 5. expense_source
INSERT INTO expense_source (expense_source_name, icon, icon_color, priority) VALUES ('BANK_STATEMENT', 'account_balance', '#8B4513', 1);
INSERT INTO expense_source (expense_source_name, icon, icon_color, priority) VALUES ('SMS_READING', 'sms', '#32CD32', 2);
INSERT INTO expense_source (expense_source_name, icon, icon_color, priority) VALUES ('MANUAL_ENTRY', 'keyboard', '#1E90FF', 3);
INSERT INTO expense_source (expense_source_name, icon, icon_color, priority) VALUES ('OTHERS', 'more_horiz', '#808080', 4);

-- 6. expense_purpose
INSERT INTO expense_purpose (expense_for, icon, icon_color, priority) VALUES ('Household', 'home', '#8B4513', 1);
INSERT INTO expense_purpose (expense_for, icon, icon_color, priority) VALUES ('Manoj', 'person', '#1E90FF', 2);
INSERT INTO expense_purpose (expense_for, icon, icon_color, priority) VALUES ('Pallavi', 'woman', '#FF69B4', 3);
INSERT INTO expense_purpose (expense_for, icon, icon_color, priority) VALUES ('Hemansh', 'child_care', '#32CD32', 4);
INSERT INTO expense_purpose (expense_for, icon, icon_color, priority) VALUES ('Future Investment', 'schedule', '#2980B9', 5);
INSERT INTO expense_purpose (expense_for, icon, icon_color, priority) VALUES ('Charity', 'handshake', '#16A085', 6);
INSERT INTO expense_purpose (expense_for, icon, icon_color, priority) VALUES ('Self Transfer', 'account_circle', '#9E9E9E', 7);
INSERT INTO expense_purpose (expense_for, icon, icon_color, priority) VALUES ('OTHERS', 'more_horiz', '#808080', 99);

-- 7. payment_method
INSERT INTO payment_method (payment_method_name, icon, icon_color, priority) VALUES ('UPI', 'smartphone', '#32CD32', 1);
INSERT INTO payment_method (payment_method_name, icon, icon_color, priority) VALUES ('NACH', 'swap_horiz', '#34495E', 2);
INSERT INTO payment_method (payment_method_name, icon, icon_color, priority) VALUES ('CARD', 'credit_card', '#1E90FF', 3);
INSERT INTO payment_method (payment_method_name, icon, icon_color, priority) VALUES ('NET_BANKING', 'language', '#8A2BE2', 4);
INSERT INTO payment_method (payment_method_name, icon, icon_color, priority) VALUES ('CASH', 'payments', '#228B22', 5);
INSERT INTO payment_method (payment_method_name, icon, icon_color, priority) VALUES ('BANK_TRANSFER', 'account_balance', '#2F4F4F', 6);
INSERT INTO payment_method (payment_method_name, icon, icon_color, priority) VALUES ('CHEQUE', 'receipt_long', '#FF8C00', 98);
INSERT INTO payment_method (payment_method_name, icon, icon_color, priority) VALUES ('OTHERS', 'more_horiz', '#808080', 99);

-- 8. transaction_rule (defaults)
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('TRANSACTION_TYPE', 'debited', 'DEBIT');
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('TRANSACTION_TYPE', 'paid', 'DEBIT');
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('TRANSACTION_TYPE', 'spent', 'DEBIT');
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('TRANSACTION_TYPE', 'sent', 'DEBIT');
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('TRANSACTION_TYPE', 'deducted', 'DEBIT');
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('TRANSACTION_TYPE', 'withdrawn', 'DEBIT');
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('TRANSACTION_TYPE', 'auto pay', 'DEBIT');
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('TRANSACTION_TYPE', 'txn rs', 'DEBIT');
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('TRANSACTION_TYPE', 'used', 'DEBIT');
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('TRANSACTION_TYPE', 'credited', 'CREDIT');
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('TRANSACTION_TYPE', 'received', 'CREDIT');
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('TRANSACTION_TYPE', 'deposited', 'CREDIT');
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('TRANSACTION_TYPE', 'credit card payment', 'TRANSFER');
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('AMOUNT_REGEX', '(?:(?:[Rr]s\.?|INR|₹)\s*([\d,]+(?:\.\d{1,2})?))', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type, payment_method_id) VALUES ('PAYMENT_METHOD', 'UPI', NULL, (SELECT payment_method_id FROM payment_method WHERE payment_method_name = 'UPI'));
INSERT INTO transaction_rule (rule_type, pattern, mapped_type, account_id) VALUES ('ACCOUNT', 'HDFC Bank', NULL, (SELECT account_id FROM account WHERE account_name = 'HDFC Bank'));
INSERT INTO transaction_rule (rule_type, pattern, mapped_type, card_id) VALUES ('CARD', '0591', NULL, (SELECT card_id FROM cards WHERE card_name = 'Tata Neu'));
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'HDFCBK', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'HDFCCB', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'SBIINB', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'SBIPSG', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'SBICRD', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'ICICIB', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'AXISBK', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'KOTAKB', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'PNBSMS', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'BOBBNK', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'BOIIND', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'UNIONB', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'CANBNK', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'INDBNK', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'CBIIND', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'IOBTXT', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'UCOBNK', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'MAHABK', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'PSBANK', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'INDUSI', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'IDFCFB', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'YESBNK', NULL);
INSERT INTO merchant (merchant_name, icon, icon_color, priority, created_time, updated_time) VALUES ('Amazon', 'store', '#FF9800', 0, '2025-09-18 03:42:09', '2025-09-18 03:42:09');
INSERT INTO merchant (merchant_name, icon, icon_color, priority, created_time, updated_time) VALUES ('Uber', 'store', '#FF9800', 0, '2025-09-18 03:42:09', '2025-09-18 03:42:09');
INSERT INTO merchant (merchant_name, icon, icon_color, priority, created_time, updated_time) VALUES ('TCS', 'store', '#6B7280', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
INSERT INTO merchant (merchant_name, icon, icon_color, priority, created_time, updated_time) VALUES ('Maryada Ramanna', 'store', '#6B7280', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
INSERT INTO merchant (merchant_name, icon, icon_color, priority, created_time, updated_time) VALUES ('Paytm', 'store', '#00B9F5', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
INSERT INTO merchant (merchant_name, icon, icon_color, priority, created_time, updated_time) VALUES ('Mahalakshmi Milk Point', 'local_drink', '#E0E0E0', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
INSERT INTO merchant (merchant_name, icon, icon_color, priority, created_time, updated_time) VALUES ('HungerBox', 'restaurant', '#FF5722', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
INSERT INTO merchant (merchant_name, icon, icon_color, priority, created_time, updated_time) VALUES ('Venkateswarulu Tiffi Center', 'restaurant', '#FF9800', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
INSERT INTO merchant (merchant_name, icon, icon_color, priority, created_time, updated_time) VALUES ('Sneha Chicken Center', 'set_meal', '#E91E63', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- 10. merchant_rule
INSERT INTO merchant_rule (keyword, merchant_id, category_id, subcategory_id, purpose_id) VALUES ('paytmqr6pn2x7@ptys', (SELECT merchant_id FROM merchant WHERE merchant_name = 'Mahalakshmi Milk Point'), (SELECT category_id FROM category WHERE category_name = 'Groceries'), (SELECT subcategory_id FROM sub_category WHERE subcategory_name = 'Dairy' AND category_id = (SELECT category_id FROM category WHERE category_name = 'Groceries')), (SELECT purpose_id FROM expense_purpose WHERE expense_for = 'Household'));
INSERT INTO merchant_rule (keyword, merchant_id, category_id, subcategory_id, purpose_id) VALUES ('q027684884@ybl', (SELECT merchant_id FROM merchant WHERE merchant_name = 'Mahalakshmi Milk Point'), (SELECT category_id FROM category WHERE category_name = 'Groceries'), (SELECT subcategory_id FROM sub_category WHERE subcategory_name = 'Dairy' AND category_id = (SELECT category_id FROM category WHERE category_name = 'Groceries')), (SELECT purpose_id FROM expense_purpose WHERE expense_for = 'Household'));
INSERT INTO merchant_rule (keyword, merchant_id, category_id, subcategory_id, purpose_id) VALUES ('paytmqr66xnm5@ptys', (SELECT merchant_id FROM merchant WHERE merchant_name = 'Mahalakshmi Milk Point'), (SELECT category_id FROM category WHERE category_name = 'Groceries'), (SELECT subcategory_id FROM sub_category WHERE subcategory_name = 'Dairy' AND category_id = (SELECT category_id FROM category WHERE category_name = 'Groceries')), (SELECT purpose_id FROM expense_purpose WHERE expense_for = 'Household'));
INSERT INTO merchant_rule (keyword, merchant_id, category_id, subcategory_id, purpose_id) VALUES ('paytm-8774066@ptybl', (SELECT merchant_id FROM merchant WHERE merchant_name = 'HungerBox'), (SELECT category_id FROM category WHERE category_name = 'Food'), (SELECT subcategory_id FROM sub_category WHERE subcategory_name = 'Office' AND category_id = (SELECT category_id FROM category WHERE category_name = 'Food')), (SELECT purpose_id FROM expense_purpose WHERE expense_for = 'Manoj'));
INSERT INTO merchant_rule (keyword, merchant_id, category_id, subcategory_id, purpose_id) VALUES ('paytm-8774066@paytm', (SELECT merchant_id FROM merchant WHERE merchant_name = 'HungerBox'), (SELECT category_id FROM category WHERE category_name = 'Food'), (SELECT subcategory_id FROM sub_category WHERE subcategory_name = 'Office' AND category_id = (SELECT category_id FROM category WHERE category_name = 'Food')), (SELECT purpose_id FROM expense_purpose WHERE expense_for = 'Manoj'));
INSERT INTO merchant_rule (keyword, merchant_id, category_id, subcategory_id, purpose_id) VALUES ('paytmqr60kv92@ptys', (SELECT merchant_id FROM merchant WHERE merchant_name = 'Mahalakshmi Milk Point'), (SELECT category_id FROM category WHERE category_name = 'Groceries'), (SELECT subcategory_id FROM sub_category WHERE subcategory_name = 'Dairy' AND category_id = (SELECT category_id FROM category WHERE category_name = 'Groceries')), (SELECT purpose_id FROM expense_purpose WHERE expense_for = 'Household'));
INSERT INTO merchant_rule (keyword, merchant_id, category_id, subcategory_id, purpose_id) VALUES ('paytmqr6r268q@ptys', (SELECT merchant_id FROM merchant WHERE merchant_name = 'Venkateswarulu Tiffi Center'), (SELECT category_id FROM category WHERE category_name = 'Food'), (SELECT subcategory_id FROM sub_category WHERE subcategory_name = 'Breakfast' AND category_id = (SELECT category_id FROM category WHERE category_name = 'Food')), (SELECT purpose_id FROM expense_purpose WHERE expense_for = 'Household'));
INSERT INTO merchant_rule (keyword, merchant_id, category_id, subcategory_id, purpose_id) VALUES ('ombk.aaev92261hbywo55vtw@mbk', (SELECT merchant_id FROM merchant WHERE merchant_name = 'Sneha Chicken Center'), (SELECT category_id FROM category WHERE category_name = 'Groceries'), (SELECT subcategory_id FROM sub_category WHERE subcategory_name = 'Meat' AND category_id = (SELECT category_id FROM category WHERE category_name = 'Groceries')), (SELECT purpose_id FROM expense_purpose WHERE expense_for = 'Household'));
INSERT INTO merchant_rule (keyword, merchant_id, category_id, subcategory_id, purpose_id) VALUES ('bharatpe90728138967@yesbankltd', (SELECT merchant_id FROM merchant WHERE merchant_name = 'Venkateswarulu Tiffi Center'), (SELECT category_id FROM category WHERE category_name = 'Food'), (SELECT subcategory_id FROM sub_category WHERE subcategory_name = 'Breakfast' AND category_id = (SELECT category_id FROM category WHERE category_name = 'Food')), (SELECT purpose_id FROM expense_purpose WHERE expense_for = 'Household'));