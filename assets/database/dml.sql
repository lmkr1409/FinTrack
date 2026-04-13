-- ──────────────────────────────────────────────────────────────────────
-- DML: SEED DATA
-- Includes configurations from old_db.sql and modern transaction rules
-- Transactions are excluded.
-- ──────────────────────────────────────────────────────────────────────

-- 1. category
-- 1. category
INSERT INTO category (category_name, icon, icon_color, priority, category_type) VALUES ('Income', 'payments', '#4CAF50', 1, 'TRANSACTIONS');
INSERT INTO category (category_name, icon, icon_color, priority, category_type) VALUES ('Housing', 'home', '#8B4513', 2, 'TRANSACTIONS');
INSERT INTO category (category_name, icon, icon_color, priority, category_type) VALUES ('Groceries', 'shopping_basket', '#4CAF50', 3, 'TRANSACTIONS');
INSERT INTO category (category_name, icon, icon_color, priority, category_type) VALUES ('Utilities', 'lightbulb', '#FFD700', 4, 'TRANSACTIONS');
INSERT INTO category (category_name, icon, icon_color, priority, category_type) VALUES ('Food', 'restaurant', '#FF6347', 5, 'TRANSACTIONS');
INSERT INTO category (category_name, icon, icon_color, priority, category_type) VALUES ('Shopping', 'shopping_cart', '#FF8C00', 6, 'TRANSACTIONS');
INSERT INTO category (category_name, icon, icon_color, priority, category_type) VALUES ('Transportation', 'directions_bus', '#1E90FF', 7, 'TRANSACTIONS');
INSERT INTO category (category_name, icon, icon_color, priority, category_type) VALUES ('Gifts & Donation', 'card_giftcard', '#E91E63', 8, 'TRANSACTIONS');
INSERT INTO category (category_name, icon, icon_color, priority, category_type) VALUES ('Education', 'school', '#6A5ACD', 9, 'TRANSACTIONS');
INSERT INTO category (category_name, icon, icon_color, priority, category_type) VALUES ('Healthcare', 'favorite', '#DC143C', 10, 'TRANSACTIONS');
INSERT INTO category (category_name, icon, icon_color, priority, category_type) VALUES ('Entertainment', 'movie', '#FF69B4', 11, 'TRANSACTIONS');
INSERT INTO category (category_name, icon, icon_color, priority, category_type) VALUES ('Insurance', 'shield', '#808080', 12, 'TRANSACTIONS');
INSERT INTO category (category_name, icon, icon_color, priority, category_type) VALUES ('Travel', 'flight', '#4682B4', 13, 'TRANSACTIONS');
INSERT INTO category (category_name, icon, icon_color, priority, category_type) VALUES ('Debt Repayment', 'money_off', '#E53935', 14, 'TRANSACTIONS');
INSERT INTO category (category_name, icon, icon_color, priority, category_type) VALUES ('Other', 'more_horiz', '#A9A9A9', 99, 'TRANSACTIONS');
INSERT INTO category (category_name, icon, icon_color, priority, category_type) VALUES ('Mutual Funds', 'pie_chart', '#6366F1', 1, 'INVESTMENTS');
INSERT INTO category (category_name, icon, icon_color, priority, category_type) VALUES ('Stocks', 'show_chart', '#34D399', 2, 'INVESTMENTS');
INSERT INTO category (category_name, icon, icon_color, priority, category_type) VALUES ('National Pension Scheme', 'account_balance_wallet', '#8B5CF6', 3, 'INVESTMENTS');
INSERT INTO category (category_name, icon, icon_color, priority, category_type) VALUES ('Provident Fund', 'savings', '#14B8A6', 4, 'INVESTMENTS');
INSERT INTO category (category_name, icon, icon_color, priority, category_type) VALUES ('Fixed Deposit', 'lock', '#FBBF24', 5, 'INVESTMENTS');
INSERT INTO category (category_name, icon, icon_color, priority, category_type) VALUES ('Recurring Deposit', 'history', '#0EA5E9', 6, 'INVESTMENTS');
INSERT INTO category (category_name, icon, icon_color, priority, category_type) VALUES ('Chit Funds', 'account_balance', '#D946EF', 7, 'INVESTMENTS');
INSERT INTO category (category_name, icon, icon_color, priority, category_type) VALUES ('Savings Account', 'account_balance', '#916b47ff', 8, 'INVESTMENTS');
INSERT INTO category (category_name, icon, icon_color, priority, category_type) VALUES ('Self Transfer', 'swap_horiz', '#607D8B', 1, 'TRANSFERS');


-- 2. sub_category
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Fruits', 'nutrition', '#FF5252', 99, (SELECT category_id FROM category WHERE category_name = 'Groceries'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Dry Fruits', 'shopping_basket', '#FB8C00', 99, (SELECT category_id FROM category WHERE category_name = 'Groceries'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Salary', 'payments', '#2E7D32', 99, (SELECT category_id FROM category WHERE category_name = 'Income'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Investment', 'show_chart', '#00C853', 99, (SELECT category_id FROM category WHERE category_name = 'Income'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Other', 'attach_money', '#81C784', 99, (SELECT category_id FROM category WHERE category_name = 'Income'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Vegetables', 'eco', '#4CAF50', 99, (SELECT category_id FROM category WHERE category_name = 'Groceries'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Dairy', 'breakfast_dining', '#03A9F4', 99, (SELECT category_id FROM category WHERE category_name = 'Groceries'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Meat', 'set_meal', '#795548', 99, (SELECT category_id FROM category WHERE category_name = 'Groceries'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Other', 'shopping_basket', '#9E9E9E', 99, (SELECT category_id FROM category WHERE category_name = 'Groceries'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Electricity', 'lightbulb', '#FFEB3B', 99, (SELECT category_id FROM category WHERE category_name = 'Utilities'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Mobile Bill', 'smartphone', '#EC407A', 99, (SELECT category_id FROM category WHERE category_name = 'Utilities'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Internet Bill', 'language', '#5C6BC0', 99, (SELECT category_id FROM category WHERE category_name = 'Utilities'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Gas Bill', 'local_fire_department', '#FF7043', 99, (SELECT category_id FROM category WHERE category_name = 'Utilities'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Other', 'bolt', '#BDBDBD', 99, (SELECT category_id FROM category WHERE category_name = 'Utilities'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Petrol', 'local_gas_station', '#FF9800', 99, (SELECT category_id FROM category WHERE category_name = 'Transportation'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Bike Service', 'two_wheeler', '#455A64', 99, (SELECT category_id FROM category WHERE category_name = 'Transportation'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Other', 'directions_car', '#78909C', 99, (SELECT category_id FROM category WHERE category_name = 'Transportation'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Rent', 'home', '#3F51B5', 99, (SELECT category_id FROM category WHERE category_name = 'Housing'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Maintenance', 'build', '#689F38', 99, (SELECT category_id FROM category WHERE category_name = 'Housing'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Other', 'house', '#A1887F', 99, (SELECT category_id FROM category WHERE category_name = 'Housing'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Movies', 'movie', '#E91E63', 99, (SELECT category_id FROM category WHERE category_name = 'Entertainment'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Concerts', 'music_note', '#9C27B0', 99, (SELECT category_id FROM category WHERE category_name = 'Entertainment'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Other', 'theater_comedy', '#F06292', 99, (SELECT category_id FROM category WHERE category_name = 'Entertainment'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Doctor', 'medical_services', '#00BCD4', 99, (SELECT category_id FROM category WHERE category_name = 'Healthcare'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Medicine', 'medication', '#E53935', 99, (SELECT category_id FROM category WHERE category_name = 'Healthcare'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Other', 'local_hospital', '#80CBC4', 99, (SELECT category_id FROM category WHERE category_name = 'Healthcare'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Health Insurance', 'health_and_safety', '#EF5350', 99, (SELECT category_id FROM category WHERE category_name = 'Insurance'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Car Insurance', 'car_crash', '#26A69A', 99, (SELECT category_id FROM category WHERE category_name = 'Insurance'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Bike Insurance', 'two_wheeler', '#FFA726', 99, (SELECT category_id FROM category WHERE category_name = 'Insurance'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Other', 'shield', '#90A4AE', 99, (SELECT category_id FROM category WHERE category_name = 'Insurance'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Books', 'menu_book', '#5C6BC0', 99, (SELECT category_id FROM category WHERE category_name = 'Education'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Courses', 'school', '#26A69A', 99, (SELECT category_id FROM category WHERE category_name = 'Education'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Other', 'edit', '#7986CB', 99, (SELECT category_id FROM category WHERE category_name = 'Education'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Clothes', 'checkroom', '#FF4081', 99, (SELECT category_id FROM category WHERE category_name = 'Shopping'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Electronics', 'laptop', '#7E57C2', 99, (SELECT category_id FROM category WHERE category_name = 'Shopping'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Other', 'shopping_bag', '#FFAB91', 99, (SELECT category_id FROM category WHERE category_name = 'Shopping'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Office', 'coffee', '#A1887F', 99, (SELECT category_id FROM category WHERE category_name = 'Food'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Breakfast', 'breakfast_dining', '#FFB300', 99, (SELECT category_id FROM category WHERE category_name = 'Food'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Outside', 'lunch_dining', '#FF5722', 99, (SELECT category_id FROM category WHERE category_name = 'Food'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Restaurant', 'restaurant', '#D84315', 99, (SELECT category_id FROM category WHERE category_name = 'Food'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Snacks', 'bakery_dining', '#FFCA28', 99, (SELECT category_id FROM category WHERE category_name = 'Food'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Other', 'restaurant', '#BCAAA4', 99, (SELECT category_id FROM category WHERE category_name = 'Food'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Tour', 'map', '#009688', 99, (SELECT category_id FROM category WHERE category_name = 'Travel'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Hotel', 'hotel', '#1976D2', 99, (SELECT category_id FROM category WHERE category_name = 'Travel'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Other', 'flight', '#64B5F6', 99, (SELECT category_id FROM category WHERE category_name = 'Travel'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Other', 'help_outline', '#9E9E9E', 99, (SELECT category_id FROM category WHERE category_name = 'Other'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Repairs', 'build', '#F44336', 99, (SELECT category_id FROM category WHERE category_name = 'Housing'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Milling', 'grain', '#FDD835', 99, (SELECT category_id FROM category WHERE category_name = 'Groceries'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Gift', 'card_giftcard', '#EC407A', 99, (SELECT category_id FROM category WHERE category_name = 'Gifts & Donation'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Donation', 'volunteer_activism', '#66BB6A', 99, (SELECT category_id FROM category WHERE category_name = 'Gifts & Donation'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Commute', 'airport_shuttle', '#0288D1', 99, (SELECT category_id FROM category WHERE category_name = 'Transportation'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('SIP', 'trending_up', '#3F51B5', 1, (SELECT category_id FROM category WHERE category_name = 'Mutual Funds'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('LumpSum', 'add_chart', '#3949AB', 2, (SELECT category_id FROM category WHERE category_name = 'Mutual Funds'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Equity', 'show_chart', '#34D399', 1, (SELECT category_id FROM category WHERE category_name = 'Stocks'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('ETF', 'account_balance_wallet', '#10B981', 2, (SELECT category_id FROM category WHERE category_name = 'Stocks'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Tier 1', 'lock', '#8B5CF6', 1, (SELECT category_id FROM category WHERE category_name = 'National Pension Scheme'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Tier 2', 'lock_open', '#A78BFA', 2, (SELECT category_id FROM category WHERE category_name = 'National Pension Scheme'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Interest', 'add_circle', '#916b47ff', 1, (SELECT category_id FROM category WHERE category_name = 'Savings Account'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Bonus', 'star', '#916b47ff', 2, (SELECT category_id FROM category WHERE category_name = 'Savings Account'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Dividend', 'payments', '#916b47ff', 3, (SELECT category_id FROM category WHERE category_name = 'Savings Account'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('EMI', 'event_repeat', '#E53935', 1, (SELECT category_id FROM category WHERE category_name = 'Debt Repayment'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Credit Card Bill', 'credit_card', '#C62828', 2, (SELECT category_id FROM category WHERE category_name = 'Debt Repayment'));

-- 3. account
INSERT INTO account (account_name, balance, icon, icon_color, priority, created_time, updated_time) VALUES ('HDFC Bank', 0, 'account_balance', '#005587', 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
INSERT INTO account (account_name, balance, icon, icon_color, priority, created_time, updated_time) VALUES ('Standard Chartered Bank', 0, 'account_balance', '#007474', 2, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
INSERT INTO account (account_name, balance, icon, icon_color, priority, created_time, updated_time) VALUES ('State Bank Of India', 0, 'account_balance', '#1E88E5', 3, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
INSERT INTO account (account_name, balance, icon, icon_color, priority, created_time, updated_time) VALUES ('Canara Bank', 0, 'account_balance', '#FFD700', 4, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
INSERT INTO account (account_name, balance, icon, icon_color, priority, created_time, updated_time) VALUES ('Indian Bank', 0, 'account_balance', '#FAAFFB', 5, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

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
INSERT INTO expense_purpose (expense_for, icon, icon_color, priority) VALUES ('Husband', 'person', '#1E90FF', 2);
INSERT INTO expense_purpose (expense_for, icon, icon_color, priority) VALUES ('Wife', 'woman', '#FF69B4', 3);
INSERT INTO expense_purpose (expense_for, icon, icon_color, priority) VALUES ('Kids', 'child_care', '#32CD32', 4);
INSERT INTO expense_purpose (expense_for, icon, icon_color, priority) VALUES ('Future Investment', 'schedule', '#2980B9', 5);
INSERT INTO expense_purpose (expense_for, icon, icon_color, priority) VALUES ('Charity', 'handshake', '#16A085', 6);
INSERT INTO expense_purpose (expense_for, icon, icon_color, priority) VALUES ('Self', 'account_circle', '#9E9E9E', 7);
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
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('TRANSACTION_TYPE', 'NSE CLEARING LIMITED', 'CREDIT');
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
INSERT INTO transaction_rule (rule_type, pattern, mapped_type, payment_method_id) VALUES ('PAYMENT_METHOD', 'INDIAN CLEARING CORP LTD', NULL, (SELECT payment_method_id FROM payment_method WHERE payment_method_name = 'NACH'));
INSERT INTO transaction_rule (rule_type, pattern, mapped_type, account_id) VALUES ('ACCOUNT', 'HDFC Bank', NULL, (SELECT account_id FROM account WHERE account_name = 'HDFC Bank'));
INSERT INTO transaction_rule (rule_type, pattern, mapped_type, card_id) VALUES ('CARD', '0591', NULL, (SELECT card_id FROM cards WHERE card_name = 'Tata Neu'));
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'HDFCBK', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'HDFCCB', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'HDFCFB', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'HDFCBN', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'SBIINB', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'SBIPSG', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'SBICRD', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'SBIUPI', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'SBIN', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'ATMSBI', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'SBIOTR', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'SBIPAY', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'ICICIB', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'ICICIS', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'ICICIP', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'ICICIV', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'ICICIA', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'AXISBK', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'AXISPB', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'AXISCN', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'AXISRM', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'KOTAKB', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'KOTAKM', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'KOTAKN', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'PNBSMS', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'PNBBNK', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'PNBORG', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'BOBBNK', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'BOBSMS', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'BOIIND', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'UNIONB', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'UBIINB', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'UBIRES', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'CANBNK', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'CANARA', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'INDBNK', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'IDNBNK', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'CBIIND', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'CBIINB', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'IOBTXT', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'UCOBNK', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'MAHABK', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'PSBANK', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'INDUSI', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'INDUSB', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'INDSBK', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'IDFCFB', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'IDFCBK', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'YESBNK', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'YESPBT', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'FEDBNK', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'SIBTXT', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'RBLBNK', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'BNDHAN', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'IDBIBK', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'SCBBNK', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'CITIBK', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'HSBCBK', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'DBSBNK', NULL);
INSERT INTO transaction_rule (rule_type, pattern, mapped_type) VALUES ('BANK_SENDER', 'KVBSMS', NULL);

-- 9. merchant
INSERT INTO merchant (merchant_name, icon, icon_color, priority, created_time, updated_time) VALUES ('Zerodha', 'show_chart', '#2196F3', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- 10. merchant_rule
INSERT INTO merchant_rule (keyword, merchant_id, category_id, subcategory_id, purpose_id) VALUES ('INDIAN CLEARING CORP LTD', (SELECT merchant_id FROM merchant WHERE merchant_name = 'Zerodha'), (SELECT category_id FROM category WHERE category_name = 'Mutual Funds'), (SELECT subcategory_id FROM sub_category WHERE subcategory_name = 'SIP'), (SELECT purpose_id FROM expense_purpose WHERE expense_for = 'Future Investment'));
INSERT INTO merchant_rule (keyword, merchant_id, category_id, subcategory_id, purpose_id) VALUES ('NSE CLEARING LIMITED', (SELECT merchant_id FROM merchant WHERE merchant_name = 'Zerodha'), (SELECT category_id FROM category WHERE category_name = 'Mutual Funds'), NULL, (SELECT purpose_id FROM expense_purpose WHERE expense_for = 'Future Investment'));

-- 11. general_settings
INSERT INTO general_settings (setting_key, setting_value) VALUES ('security_lock_enabled', 'true');
INSERT INTO general_settings (setting_key, setting_value) VALUES ('security_auth_method', 'none');
INSERT INTO general_settings (setting_key, setting_value) VALUES ('security_lock_timeout', '180');
INSERT INTO general_settings (setting_key, setting_value) VALUES ('privacy_hide_details', 'false');
INSERT INTO general_settings (setting_key, setting_value) VALUES ('flow_salary_mode', 'PREV');
INSERT INTO general_settings (setting_key, setting_value) VALUES ('flow_other_mode', 'CURRENT');

-- 12. investment_goal
INSERT INTO investment_goal (goal_name, target_amount, category_id, subcategory_id, purpose_id) VALUES ('Emergency Fund', 500000, (SELECT category_id FROM category WHERE category_name = 'Savings Account'), (SELECT subcategory_id FROM sub_category WHERE subcategory_name = 'Interest'), (SELECT purpose_id FROM expense_purpose WHERE expense_for = 'Household'));
INSERT INTO investment_goal (goal_name, target_amount, category_id, subcategory_id, purpose_id) VALUES ('Retirement', 50000000, (SELECT category_id FROM category WHERE category_name = 'Mutual Funds'), (SELECT subcategory_id FROM sub_category WHERE subcategory_name = 'SIP'), (SELECT purpose_id FROM expense_purpose WHERE expense_for = 'Future Investment'));

-- 13. budget_framework
INSERT INTO budget_framework (name, is_active) VALUES ('50/30/20 Rule', 1);
INSERT INTO budget_framework (name, is_active) VALUES ('50/25/15/10 Rule', 0);
INSERT INTO budget_framework (name, is_active) VALUES ('80/20 Rule', 0);
INSERT INTO budget_framework (name, is_active) VALUES ('70/20/10 Rule', 0);

-- 14. budget_bucket
INSERT INTO budget_bucket (framework_id, name, percentage, bucket_type, icon, icon_color) VALUES ((SELECT framework_id FROM budget_framework WHERE name = '50/30/20 Rule'), 'Essentials', 50, 'NEEDS', 'fact_check_rounded', '#2196F3');
INSERT INTO budget_bucket (framework_id, name, percentage, bucket_type, icon, icon_color) VALUES ((SELECT framework_id FROM budget_framework WHERE name = '50/30/20 Rule'), 'Wants', 30, 'WANTS', 'shopping_bag_rounded', '#E91E63');
INSERT INTO budget_bucket (framework_id, name, percentage, bucket_type, icon, icon_color) VALUES ((SELECT framework_id FROM budget_framework WHERE name = '50/30/20 Rule'), 'Savings & Investments', 20, 'SAVINGS', 'savings_rounded', '#4CAF50');

-- 15. category_bucket_mapping
-- Needs
INSERT INTO category_bucket_mapping (category_id, framework_id, bucket_id) VALUES ((SELECT category_id FROM category WHERE category_name = 'Housing'), (SELECT framework_id FROM budget_framework WHERE name = '50/30/20 Rule'), (SELECT bucket_id FROM budget_bucket WHERE name = 'Essentials' AND framework_id = (SELECT framework_id FROM budget_framework WHERE name = '50/30/20 Rule')));
INSERT INTO category_bucket_mapping (category_id, framework_id, bucket_id) VALUES ((SELECT category_id FROM category WHERE category_name = 'Groceries'), (SELECT framework_id FROM budget_framework WHERE name = '50/30/20 Rule'), (SELECT bucket_id FROM budget_bucket WHERE name = 'Essentials' AND framework_id = (SELECT framework_id FROM budget_framework WHERE name = '50/30/20 Rule')));
INSERT INTO category_bucket_mapping (category_id, framework_id, bucket_id) VALUES ((SELECT category_id FROM category WHERE category_name = 'Utilities'), (SELECT framework_id FROM budget_framework WHERE name = '50/30/20 Rule'), (SELECT bucket_id FROM budget_bucket WHERE name = 'Essentials' AND framework_id = (SELECT framework_id FROM budget_framework WHERE name = '50/30/20 Rule')));
INSERT INTO category_bucket_mapping (category_id, framework_id, bucket_id) VALUES ((SELECT category_id FROM category WHERE category_name = 'Healthcare'), (SELECT framework_id FROM budget_framework WHERE name = '50/30/20 Rule'), (SELECT bucket_id FROM budget_bucket WHERE name = 'Essentials' AND framework_id = (SELECT framework_id FROM budget_framework WHERE name = '50/30/20 Rule')));
INSERT INTO category_bucket_mapping (category_id, framework_id, bucket_id) VALUES ((SELECT category_id FROM category WHERE category_name = 'Transportation'), (SELECT framework_id FROM budget_framework WHERE name = '50/30/20 Rule'), (SELECT bucket_id FROM budget_bucket WHERE name = 'Essentials' AND framework_id = (SELECT framework_id FROM budget_framework WHERE name = '50/30/20 Rule')));
INSERT INTO category_bucket_mapping (category_id, framework_id, bucket_id) VALUES ((SELECT category_id FROM category WHERE category_name = 'Insurance'), (SELECT framework_id FROM budget_framework WHERE name = '50/30/20 Rule'), (SELECT bucket_id FROM budget_bucket WHERE name = 'Essentials' AND framework_id = (SELECT framework_id FROM budget_framework WHERE name = '50/30/20 Rule')));

-- Wants
INSERT INTO category_bucket_mapping (category_id, framework_id, bucket_id) VALUES ((SELECT category_id FROM category WHERE category_name = 'Food'), (SELECT framework_id FROM budget_framework WHERE name = '50/30/20 Rule'), (SELECT bucket_id FROM budget_bucket WHERE name = 'Wants' AND framework_id = (SELECT framework_id FROM budget_framework WHERE name = '50/30/20 Rule')));
INSERT INTO category_bucket_mapping (category_id, framework_id, bucket_id) VALUES ((SELECT category_id FROM category WHERE category_name = 'Shopping'), (SELECT framework_id FROM budget_framework WHERE name = '50/30/20 Rule'), (SELECT bucket_id FROM budget_bucket WHERE name = 'Wants' AND framework_id = (SELECT framework_id FROM budget_framework WHERE name = '50/30/20 Rule')));
INSERT INTO category_bucket_mapping (category_id, framework_id, bucket_id) VALUES ((SELECT category_id FROM category WHERE category_name = 'Entertainment'), (SELECT framework_id FROM budget_framework WHERE name = '50/30/20 Rule'), (SELECT bucket_id FROM budget_bucket WHERE name = 'Wants' AND framework_id = (SELECT framework_id FROM budget_framework WHERE name = '50/30/20 Rule')));
INSERT INTO category_bucket_mapping (category_id, framework_id, bucket_id) VALUES ((SELECT category_id FROM category WHERE category_name = 'Travel'), (SELECT framework_id FROM budget_framework WHERE name = '50/30/20 Rule'), (SELECT bucket_id FROM budget_bucket WHERE name = 'Wants' AND framework_id = (SELECT framework_id FROM budget_framework WHERE name = '50/30/20 Rule')));
INSERT INTO category_bucket_mapping (category_id, framework_id, bucket_id) VALUES ((SELECT category_id FROM category WHERE category_name = 'Other'), (SELECT framework_id FROM budget_framework WHERE name = '50/30/20 Rule'), (SELECT bucket_id FROM budget_bucket WHERE name = 'Wants' AND framework_id = (SELECT framework_id FROM budget_framework WHERE name = '50/30/20 Rule')));

-- Savings
INSERT INTO category_bucket_mapping (category_id, framework_id, bucket_id) VALUES ((SELECT category_id FROM category WHERE category_name = 'Mutual Funds'), (SELECT framework_id FROM budget_framework WHERE name = '50/30/20 Rule'), (SELECT bucket_id FROM budget_bucket WHERE name = 'Savings & Investments' AND framework_id = (SELECT framework_id FROM budget_framework WHERE name = '50/30/20 Rule')));
INSERT INTO category_bucket_mapping (category_id, framework_id, bucket_id) VALUES ((SELECT category_id FROM category WHERE category_name = 'Stocks'), (SELECT framework_id FROM budget_framework WHERE name = '50/30/20 Rule'), (SELECT bucket_id FROM budget_bucket WHERE name = 'Savings & Investments' AND framework_id = (SELECT framework_id FROM budget_framework WHERE name = '50/30/20 Rule')));
INSERT INTO category_bucket_mapping (category_id, framework_id, bucket_id) VALUES ((SELECT category_id FROM category WHERE category_name = 'National Pension Scheme'), (SELECT framework_id FROM budget_framework WHERE name = '50/30/20 Rule'), (SELECT bucket_id FROM budget_bucket WHERE name = 'Savings & Investments' AND framework_id = (SELECT framework_id FROM budget_framework WHERE name = '50/30/20 Rule')));
INSERT INTO category_bucket_mapping (category_id, framework_id, bucket_id) VALUES ((SELECT category_id FROM category WHERE category_name = 'Provident Fund'), (SELECT framework_id FROM budget_framework WHERE name = '50/30/20 Rule'), (SELECT bucket_id FROM budget_bucket WHERE name = 'Savings & Investments' AND framework_id = (SELECT framework_id FROM budget_framework WHERE name = '50/30/20 Rule')));
INSERT INTO category_bucket_mapping (category_id, framework_id, bucket_id) VALUES ((SELECT category_id FROM category WHERE category_name = 'Fixed Deposit'), (SELECT framework_id FROM budget_framework WHERE name = '50/30/20 Rule'), (SELECT bucket_id FROM budget_bucket WHERE name = 'Savings & Investments' AND framework_id = (SELECT framework_id FROM budget_framework WHERE name = '50/30/20 Rule')));
INSERT INTO category_bucket_mapping (category_id, framework_id, bucket_id) VALUES ((SELECT category_id FROM category WHERE category_name = 'Recurring Deposit'), (SELECT framework_id FROM budget_framework WHERE name = '50/30/20 Rule'), (SELECT bucket_id FROM budget_bucket WHERE name = 'Savings & Investments' AND framework_id = (SELECT framework_id FROM budget_framework WHERE name = '50/30/20 Rule')));
INSERT INTO category_bucket_mapping (category_id, framework_id, bucket_id) VALUES ((SELECT category_id FROM category WHERE category_name = 'Chit Funds'), (SELECT framework_id FROM budget_framework WHERE name = '50/30/20 Rule'), (SELECT bucket_id FROM budget_bucket WHERE name = 'Savings & Investments' AND framework_id = (SELECT framework_id FROM budget_framework WHERE name = '50/30/20 Rule')));
INSERT INTO category_bucket_mapping (category_id, framework_id, bucket_id) VALUES ((SELECT category_id FROM category WHERE category_name = 'Savings Account'), (SELECT framework_id FROM budget_framework WHERE name = '50/30/20 Rule'), (SELECT bucket_id FROM budget_bucket WHERE name = 'Savings & Investments' AND framework_id = (SELECT framework_id FROM budget_framework WHERE name = '50/30/20 Rule')));

-- Additional Budgeting Frameworks


-- Buckets for 50/25/15/10 Rule
INSERT INTO budget_bucket (framework_id, name, percentage, bucket_type, icon, icon_color) VALUES ((SELECT framework_id FROM budget_framework WHERE name = '50/25/15/10 Rule'), 'Essentials', 50, 'NEEDS', 'fact_check_rounded', '#2196F3');
INSERT INTO budget_bucket (framework_id, name, percentage, bucket_type, icon, icon_color) VALUES ((SELECT framework_id FROM budget_framework WHERE name = '50/25/15/10 Rule'), 'Growth', 25, 'SAVINGS', 'rocket_launch_rounded', '#4CAF50');
INSERT INTO budget_bucket (framework_id, name, percentage, bucket_type, icon, icon_color) VALUES ((SELECT framework_id FROM budget_framework WHERE name = '50/25/15/10 Rule'), 'Stability', 15, 'SAVINGS', 'shield_rounded', '#00BCD4');
INSERT INTO budget_bucket (framework_id, name, percentage, bucket_type, icon, icon_color) VALUES ((SELECT framework_id FROM budget_framework WHERE name = '50/25/15/10 Rule'), 'Rewards', 10, 'WANTS', 'card_giftcard_rounded', '#FF9800');

-- Buckets for 80/20 Rule
INSERT INTO budget_bucket (framework_id, name, percentage, bucket_type, icon, icon_color) VALUES ((SELECT framework_id FROM budget_framework WHERE name = '80/20 Rule'), 'Every day expense', 80, 'NEEDS', 'shopping_bag_rounded', '#2196F3');
INSERT INTO budget_bucket (framework_id, name, percentage, bucket_type, icon, icon_color) VALUES ((SELECT framework_id FROM budget_framework WHERE name = '80/20 Rule'), 'Savings', 20, 'SAVINGS', 'savings_rounded', '#4CAF50');

-- Buckets for 70/20/10 Rule
INSERT INTO budget_bucket (framework_id, name, percentage, bucket_type, icon, icon_color) VALUES ((SELECT framework_id FROM budget_framework WHERE name = '70/20/10 Rule'), 'Living Expenses', 70, 'NEEDS', 'home_rounded', '#FF9800');
INSERT INTO budget_bucket (framework_id, name, percentage, bucket_type, icon, icon_color) VALUES ((SELECT framework_id FROM budget_framework WHERE name = '70/20/10 Rule'), 'Savings & Retirement', 20, 'SAVINGS', 'savings_rounded', '#4CAF50');
INSERT INTO budget_bucket (framework_id, name, percentage, bucket_type, icon, icon_color) VALUES ((SELECT framework_id FROM budget_framework WHERE name = '70/20/10 Rule'), 'Debt & Giving', 10, 'SAVINGS', 'volunteer_activism_rounded', '#9C27B0');

-- Mappings for 50/25/15/10 Rule
INSERT INTO category_bucket_mapping (category_id, framework_id, bucket_id)
SELECT category_id, (SELECT framework_id FROM budget_framework WHERE name = '50/25/15/10 Rule'), (SELECT bucket_id FROM budget_bucket WHERE name = 'Essentials' AND framework_id = (SELECT framework_id FROM budget_framework WHERE name = '50/25/15/10 Rule'))
FROM category WHERE category_name IN ('Housing', 'Groceries', 'Utilities', 'Healthcare', 'Transportation', 'Insurance');

INSERT INTO category_bucket_mapping (category_id, framework_id, bucket_id)
SELECT category_id, (SELECT framework_id FROM budget_framework WHERE name = '50/25/15/10 Rule'), (SELECT bucket_id FROM budget_bucket WHERE name = 'Rewards' AND framework_id = (SELECT framework_id FROM budget_framework WHERE name = '50/25/15/10 Rule'))
FROM category WHERE category_name IN ('Food', 'Shopping', 'Entertainment', 'Travel', 'Other');

INSERT INTO category_bucket_mapping (category_id, framework_id, bucket_id)
SELECT category_id, (SELECT framework_id FROM budget_framework WHERE name = '50/25/15/10 Rule'), (SELECT bucket_id FROM budget_bucket WHERE name = 'Growth' AND framework_id = (SELECT framework_id FROM budget_framework WHERE name = '50/25/15/10 Rule'))
FROM category WHERE category_name IN ('Mutual Funds', 'Stocks');

INSERT INTO category_bucket_mapping (category_id, framework_id, bucket_id)
SELECT category_id, (SELECT framework_id FROM budget_framework WHERE name = '50/25/15/10 Rule'), (SELECT bucket_id FROM budget_bucket WHERE name = 'Stability' AND framework_id = (SELECT framework_id FROM budget_framework WHERE name = '50/25/15/10 Rule'))
FROM category WHERE category_name IN ('National Pension Scheme', 'Provident Fund', 'Fixed Deposit', 'Recurring Deposit', 'Chit Funds', 'Savings Account', 'Debt Repayment');

-- Mappings for 80/20 Rule
INSERT INTO category_bucket_mapping (category_id, framework_id, bucket_id)
SELECT category_id, (SELECT framework_id FROM budget_framework WHERE name = '80/20 Rule'), (SELECT bucket_id FROM budget_bucket WHERE name = 'Every day expense' AND framework_id = (SELECT framework_id FROM budget_framework WHERE name = '80/20 Rule'))
FROM category WHERE category_name NOT IN ('Mutual Funds', 'Stocks', 'National Pension Scheme', 'Provident Fund', 'Fixed Deposit', 'Recurring Deposit', 'Chit Funds', 'Savings Account', 'Income', 'Self Transfer');

INSERT INTO category_bucket_mapping (category_id, framework_id, bucket_id)
SELECT category_id, (SELECT framework_id FROM budget_framework WHERE name = '80/20 Rule'), (SELECT bucket_id FROM budget_bucket WHERE name = 'Savings' AND framework_id = (SELECT framework_id FROM budget_framework WHERE name = '80/20 Rule'))
FROM category WHERE category_name IN ('Mutual Funds', 'Stocks', 'National Pension Scheme', 'Provident Fund', 'Fixed Deposit', 'Recurring Deposit', 'Chit Funds', 'Savings Account');

-- Mappings for 70/20/10 Rule
INSERT INTO category_bucket_mapping (category_id, framework_id, bucket_id)
SELECT category_id, (SELECT framework_id FROM budget_framework WHERE name = '70/20/10 Rule'), (SELECT bucket_id FROM budget_bucket WHERE name = 'Living Expenses' AND framework_id = (SELECT framework_id FROM budget_framework WHERE name = '70/20/10 Rule'))
FROM category WHERE category_name IN ('Housing', 'Groceries', 'Utilities', 'Healthcare', 'Transportation', 'Insurance');

INSERT INTO category_bucket_mapping (category_id, framework_id, bucket_id)
SELECT category_id, (SELECT framework_id FROM budget_framework WHERE name = '70/20/10 Rule'), (SELECT bucket_id FROM budget_bucket WHERE name = 'Savings & Retirement' AND framework_id = (SELECT framework_id FROM budget_framework WHERE name = '70/20/10 Rule'))
FROM category WHERE category_name IN ('Mutual Funds', 'Stocks', 'National Pension Scheme', 'Provident Fund', 'Fixed Deposit', 'Recurring Deposit', 'Chit Funds', 'Savings Account');

INSERT INTO category_bucket_mapping (category_id, framework_id, bucket_id)
SELECT category_id, (SELECT framework_id FROM budget_framework WHERE name = '70/20/10 Rule'), (SELECT bucket_id FROM budget_bucket WHERE name = 'Debt & Giving' AND framework_id = (SELECT framework_id FROM budget_framework WHERE name = '70/20/10 Rule'))
FROM category WHERE category_name IN ('Food', 'Shopping', 'Entertainment', 'Travel', 'Other', 'Debt Repayment', 'Gifts & Donation');

