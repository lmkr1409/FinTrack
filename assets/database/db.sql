-- ──────────────────────────────────────────────────────────────────────
-- SQLite Database Schema and Seed Data for FinTrack
-- Converted from PostgreSQL ddl.sql and dml.sql
-- Icons use Flutter Material Icons names (loaded via IconHelper)
-- ──────────────────────────────────────────────────────────────────────

-- ──────────────────────────────────────────────────────────────────────
-- DDL: TABLE DEFINITIONS
-- ──────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS category (
	category_id INTEGER PRIMARY KEY AUTOINCREMENT,
	category_name TEXT NOT NULL,
	icon TEXT,
	icon_color TEXT,
	priority INTEGER NOT NULL DEFAULT 99
);

CREATE TABLE IF NOT EXISTS sub_category (
	subcategory_id INTEGER PRIMARY KEY AUTOINCREMENT,
	subcategory_name TEXT NOT NULL,
	icon TEXT,
	category_id INTEGER NOT NULL,
	icon_color TEXT,
	priority INTEGER DEFAULT 99,
	FOREIGN KEY (category_id) REFERENCES category(category_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS account (
	account_id INTEGER PRIMARY KEY AUTOINCREMENT,
	account_name TEXT NOT NULL,
	balance REAL NOT NULL DEFAULT 0,
	created_time TEXT DEFAULT CURRENT_TIMESTAMP,
	updated_time TEXT DEFAULT CURRENT_TIMESTAMP,
	icon TEXT,
	icon_color TEXT,
	priority INTEGER DEFAULT 99
);

CREATE TABLE IF NOT EXISTS cards (
	card_id INTEGER PRIMARY KEY AUTOINCREMENT,
	card_name TEXT NOT NULL,
	card_type TEXT NOT NULL,
	card_number TEXT NOT NULL,
	card_expiry_date TEXT NOT NULL,
	card_network TEXT NOT NULL,
	balance REAL NOT NULL DEFAULT 0,
	account_id INTEGER,
	created_time TEXT DEFAULT CURRENT_TIMESTAMP,
	updated_time TEXT DEFAULT CURRENT_TIMESTAMP,
	icon TEXT,
	icon_color TEXT,
	priority INTEGER DEFAULT 99,
	FOREIGN KEY (account_id) REFERENCES account(account_id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS expense_source (
	expense_source_id INTEGER PRIMARY KEY AUTOINCREMENT,
	expense_source_name TEXT NOT NULL,
	icon TEXT,
	icon_color TEXT,
	priority INTEGER DEFAULT 99
);

CREATE TABLE IF NOT EXISTS expense_purpose (
	purpose_id INTEGER PRIMARY KEY AUTOINCREMENT,
	expense_for TEXT NOT NULL,
	icon TEXT,
	icon_color TEXT,
	priority INTEGER DEFAULT 99
);

CREATE TABLE IF NOT EXISTS budget (
	budget_id INTEGER PRIMARY KEY AUTOINCREMENT,
	category_id INTEGER,
	budget_amount REAL NOT NULL,
	budget_frequency TEXT NOT NULL,
	created_time TEXT DEFAULT CURRENT_TIMESTAMP,
	updated_time TEXT DEFAULT CURRENT_TIMESTAMP,
	month INTEGER,
	year INTEGER,
	FOREIGN KEY (category_id) REFERENCES category(category_id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS payment_method (
	payment_method_id INTEGER PRIMARY KEY AUTOINCREMENT,
	payment_method_name TEXT NOT NULL,
	icon TEXT,
	icon_color TEXT,
	priority INTEGER DEFAULT 99
);

CREATE TABLE IF NOT EXISTS merchant (
	merchant_id INTEGER PRIMARY KEY AUTOINCREMENT,
	merchant_name TEXT NOT NULL,
	created_time TEXT DEFAULT CURRENT_TIMESTAMP,
	updated_time TEXT DEFAULT CURRENT_TIMESTAMP,
	icon_color TEXT DEFAULT '#FF9800',
	icon TEXT DEFAULT 'store',
	priority INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS merchant_mapping (
	merchant_mapping_id INTEGER PRIMARY KEY AUTOINCREMENT,
	merchant_id INTEGER NOT NULL,
	category_id INTEGER,
	subcategory_id INTEGER,
	purpose_id INTEGER,
	payment_method_id INTEGER,
	account_id INTEGER,
	card_id INTEGER,
	created_time TEXT DEFAULT CURRENT_TIMESTAMP,
	updated_time TEXT DEFAULT CURRENT_TIMESTAMP,
	FOREIGN KEY (card_id) REFERENCES cards(card_id) ON DELETE SET NULL ON UPDATE CASCADE,
	FOREIGN KEY (category_id) REFERENCES category(category_id) ON DELETE SET NULL ON UPDATE CASCADE,
	FOREIGN KEY (purpose_id) REFERENCES expense_purpose(purpose_id) ON DELETE SET NULL ON UPDATE CASCADE,
	FOREIGN KEY (merchant_id) REFERENCES merchant(merchant_id) ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY (payment_method_id) REFERENCES payment_method(payment_method_id) ON DELETE SET NULL ON UPDATE CASCADE,
	FOREIGN KEY (subcategory_id) REFERENCES sub_category(subcategory_id) ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS labeling_rule (
	rule_id INTEGER PRIMARY KEY AUTOINCREMENT,
	keyword TEXT NOT NULL,
	transaction_type TEXT,
	category_id INTEGER,
	subcategory_id INTEGER,
	merchant_id INTEGER,
	payment_method_id INTEGER,
	expense_source_id INTEGER,
	purpose_id INTEGER,
	account_id INTEGER,
	card_id INTEGER,
	created_time TEXT DEFAULT CURRENT_TIMESTAMP,
	updated_time TEXT DEFAULT CURRENT_TIMESTAMP,
	FOREIGN KEY (category_id) REFERENCES category(category_id) ON DELETE SET NULL,
	FOREIGN KEY (subcategory_id) REFERENCES sub_category(subcategory_id) ON DELETE SET NULL,
	FOREIGN KEY (merchant_id) REFERENCES merchant(merchant_id) ON DELETE SET NULL,
	FOREIGN KEY (payment_method_id) REFERENCES payment_method(payment_method_id) ON DELETE SET NULL,
	FOREIGN KEY (expense_source_id) REFERENCES expense_source(expense_source_id) ON DELETE SET NULL,
	FOREIGN KEY (purpose_id) REFERENCES expense_purpose(purpose_id) ON DELETE SET NULL,
	FOREIGN KEY (account_id) REFERENCES account(account_id) ON DELETE SET NULL,
	FOREIGN KEY (card_id) REFERENCES cards(card_id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS "transaction" (
	transaction_id INTEGER PRIMARY KEY AUTOINCREMENT,
	transaction_type TEXT NOT NULL,
	amount REAL NOT NULL,
	transaction_date TEXT NOT NULL,
	description TEXT,
	category_id INTEGER,
	subcategory_id INTEGER,
	purpose_id INTEGER,
	account_id INTEGER,
	card_id INTEGER,
	merchant_id INTEGER,
	payment_method_id INTEGER,
	expense_source_id INTEGER,
	related_transaction_id INTEGER,
	created_time TEXT DEFAULT CURRENT_TIMESTAMP,
	updated_time TEXT DEFAULT CURRENT_TIMESTAMP,
	labeled INTEGER NOT NULL DEFAULT 0,
	is_auto_labeled INTEGER NOT NULL DEFAULT 0,
	FOREIGN KEY (account_id) REFERENCES account(account_id) ON DELETE SET NULL,
	FOREIGN KEY (card_id) REFERENCES cards(card_id) ON DELETE SET NULL,
	FOREIGN KEY (category_id) REFERENCES category(category_id) ON DELETE SET NULL,
	FOREIGN KEY (merchant_id) REFERENCES merchant(merchant_id) ON DELETE SET NULL,
	FOREIGN KEY (payment_method_id) REFERENCES payment_method(payment_method_id) ON DELETE SET NULL,
	FOREIGN KEY (purpose_id) REFERENCES expense_purpose(purpose_id) ON DELETE SET NULL,
	FOREIGN KEY (related_transaction_id) REFERENCES "transaction"(transaction_id) ON DELETE SET NULL,
	FOREIGN KEY (expense_source_id) REFERENCES expense_source(expense_source_id) ON DELETE SET NULL,
	FOREIGN KEY (subcategory_id) REFERENCES sub_category(subcategory_id) ON DELETE SET NULL
);

-- ──────────────────────────────────────────────────────────────────────
-- DML: SEED DATA (Icons use Flutter Material Icons names)
-- ──────────────────────────────────────────────────────────────────────

-- 1. category
INSERT INTO category (category_name, icon, icon_color, priority) VALUES ('Housing', 'home', '#8B4513', 1);
INSERT INTO category (category_name, icon, icon_color, priority) VALUES ('Groceries', 'shopping_basket', '#4CAF50', 2);
INSERT INTO category (category_name, icon, icon_color, priority) VALUES ('Utilities', 'lightbulb', '#FFD700', 3);
INSERT INTO category (category_name, icon, icon_color, priority) VALUES ('Investments', 'pie_chart', '#2E86C1', 4);
INSERT INTO category (category_name, icon, icon_color, priority) VALUES ('Food', 'restaurant', '#FF6347', 5);
INSERT INTO category (category_name, icon, icon_color, priority) VALUES ('Shopping', 'shopping_cart', '#FF8C00', 6);
INSERT INTO category (category_name, icon, icon_color, priority) VALUES ('Transportation', 'directions_bus', '#1E90FF', 7);
INSERT INTO category (category_name, icon, icon_color, priority) VALUES ('Gifts & Donation', 'card_giftcard', '#E91E63', 8);
INSERT INTO category (category_name, icon, icon_color, priority) VALUES ('Transfer', 'swap_horiz', '#607D8B', 9);
INSERT INTO category (category_name, icon, icon_color, priority) VALUES ('Education', 'school', '#6A5ACD', 10);
INSERT INTO category (category_name, icon, icon_color, priority) VALUES ('Healthcare', 'favorite', '#DC143C', 11);
INSERT INTO category (category_name, icon, icon_color, priority) VALUES ('Entertainment', 'movie', '#FF69B4', 12);
INSERT INTO category (category_name, icon, icon_color, priority) VALUES ('Insurance', 'shield', '#808080', 13);
INSERT INTO category (category_name, icon, icon_color, priority) VALUES ('Travel', 'flight', '#4682B4', 98);
INSERT INTO category (category_name, icon, icon_color, priority) VALUES ('Other', 'more_horiz', '#A9A9A9', 99);

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
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Outside', 'lunch_dining', '#FF9800', 99, (SELECT category_id FROM category WHERE category_name = 'Food'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Restaurant', 'restaurant', '#795548', 99, (SELECT category_id FROM category WHERE category_name = 'Food'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Snacks', 'bakery_dining', '#8D6E63', 99, (SELECT category_id FROM category WHERE category_name = 'Food'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Other', 'restaurant', '#9E9E9E', 99, (SELECT category_id FROM category WHERE category_name = 'Food'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Tour', 'map', '#009688', 99, (SELECT category_id FROM category WHERE category_name = 'Travel'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Hotel', 'hotel', '#3F51B5', 99, (SELECT category_id FROM category WHERE category_name = 'Travel'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Other', 'flight', '#9E9E9E', 99, (SELECT category_id FROM category WHERE category_name = 'Travel'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Other', 'help_outline', '#9E9E9E', 99, (SELECT category_id FROM category WHERE category_name = 'Other'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Repairs', 'build', '#9E9E9E', 99, (SELECT category_id FROM category WHERE category_name = 'Housing'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('SIP', 'savings', '#27AE60', 99, (SELECT category_id FROM category WHERE category_name = 'Investments'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Stocks', 'show_chart', '#E74C3C', 99, (SELECT category_id FROM category WHERE category_name = 'Investments'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Fixed Deposit', 'lock', '#F1C40F', 99, (SELECT category_id FROM category WHERE category_name = 'Investments'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Bonds', 'description', '#8E44AD', 99, (SELECT category_id FROM category WHERE category_name = 'Investments'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Milling', 'grain', '#DAA520', 99, (SELECT category_id FROM category WHERE category_name = 'Groceries'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Gift', 'card_giftcard', '#9C27B0', 99, (SELECT category_id FROM category WHERE category_name = 'Gifts & Donation'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Donation', 'volunteer_activism', '#4CAF50', 99, (SELECT category_id FROM category WHERE category_name = 'Gifts & Donation'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Self Transfer', 'swap_horiz', '#607D8B', 99, (SELECT category_id FROM category WHERE category_name = 'Transfer'));
INSERT INTO sub_category (subcategory_name, icon, icon_color, priority, category_id) VALUES ('Commute', 'airport_shuttle', '#0288D1', 99, (SELECT category_id FROM category WHERE category_name = 'Transportation'));

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
INSERT INTO expense_purpose (expense_for, icon, icon_color, priority) VALUES ('Kid', 'child_care', '#32CD32', 99);
INSERT INTO expense_purpose (expense_for, icon, icon_color, priority) VALUES ('Girl', 'woman', '#FF1493', 99);
INSERT INTO expense_purpose (expense_for, icon, icon_color, priority) VALUES ('Boy', 'person', '#4682B4', 99);
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

-- 8. budget
INSERT INTO budget (budget_amount, budget_frequency, month, year, created_time, updated_time, category_id) VALUES (2000.00, 'MONTHLY', 10, 2025, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT category_id FROM category WHERE category_name = 'Utilities'));
INSERT INTO budget (budget_amount, budget_frequency, month, year, created_time, updated_time, category_id) VALUES (2000.00, 'MONTHLY', 10, 2025, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT category_id FROM category WHERE category_name = 'Transportation'));
INSERT INTO budget (budget_amount, budget_frequency, month, year, created_time, updated_time, category_id) VALUES (5000.00, 'MONTHLY', 10, 2025, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT category_id FROM category WHERE category_name = 'Groceries'));
INSERT INTO budget (budget_amount, budget_frequency, month, year, created_time, updated_time, category_id) VALUES (12000.00, 'MONTHLY', 10, 2025, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT category_id FROM category WHERE category_name = 'Housing'));
INSERT INTO budget (budget_amount, budget_frequency, month, year, created_time, updated_time, category_id) VALUES (500.00, 'MONTHLY', 10, 2025, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT category_id FROM category WHERE category_name = 'Entertainment'));
INSERT INTO budget (budget_amount, budget_frequency, month, year, created_time, updated_time, category_id) VALUES (4000.00, 'MONTHLY', 9, 2025, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT category_id FROM category WHERE category_name = 'Groceries'));
INSERT INTO budget (budget_amount, budget_frequency, month, year, created_time, updated_time, category_id) VALUES (5000.00, 'ANNUAL', NULL, 2025, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT category_id FROM category WHERE category_name = 'Education'));
INSERT INTO budget (budget_amount, budget_frequency, month, year, created_time, updated_time, category_id) VALUES (999.99, 'MONTHLY', 9, 2025, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT category_id FROM category WHERE category_name = 'Utilities'));
INSERT INTO budget (budget_amount, budget_frequency, month, year, created_time, updated_time, category_id) VALUES (50000.00, 'ANNUAL', NULL, 2025, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT category_id FROM category WHERE category_name = 'Travel'));

-- 9. merchant
INSERT INTO merchant (merchant_name, icon, icon_color, priority, created_time, updated_time) VALUES ('Amazon', 'store', '#FF9800', 0, '2025-09-18 03:42:09', '2025-09-18 03:42:09');
INSERT INTO merchant (merchant_name, icon, icon_color, priority, created_time, updated_time) VALUES ('Uber', 'store', '#FF9800', 0, '2025-09-18 03:42:09', '2025-09-18 03:42:09');
INSERT INTO merchant (merchant_name, icon, icon_color, priority, created_time, updated_time) VALUES ('Reliance Fresh', 'store', '#FF9800', 0, '2025-09-18 03:42:09', '2025-09-18 03:42:09');
INSERT INTO merchant (merchant_name, icon, icon_color, priority, created_time, updated_time) VALUES ('ABC', 'store', '#FF9800', 0, '2025-09-20 15:15:14', '2025-09-20 15:15:14');
INSERT INTO merchant (merchant_name, icon, icon_color, priority, created_time, updated_time) VALUES ('TCS', 'store', '#6B7280', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
INSERT INTO merchant (merchant_name, icon, icon_color, priority, created_time, updated_time) VALUES ('Maryada Ramanna', 'store', '#6B7280', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- 11. transaction
INSERT INTO "transaction" (transaction_type, amount, transaction_date, description, labeled, created_time, updated_time, category_id, subcategory_id, purpose_id, account_id, card_id, merchant_id, payment_method_id, expense_source_id, related_transaction_id) VALUES ('DEBIT', 20.00, '2025-11-13', 'UPI-MOHD SAIFUL', 0, '2025-12-08 17:15:23', '2025-12-08 17:15:23', NULL, NULL, NULL, (SELECT account_id FROM account WHERE account_name = 'HDFC Bank'), (SELECT card_id FROM cards WHERE card_name = 'Tata Neu'), NULL, NULL, (SELECT expense_source_id FROM expense_source WHERE expense_source_name = 'BANK_STATEMENT'), NULL);
INSERT INTO "transaction" (transaction_type, amount, transaction_date, description, labeled, created_time, updated_time, category_id, subcategory_id, purpose_id, account_id, card_id, merchant_id, payment_method_id, expense_source_id, related_transaction_id) VALUES ('DEBIT', 50.00, '2025-11-13', 'UPI-BHAIJAN', 0, '2025-12-08 17:15:23', '2025-12-08 17:15:23', NULL, NULL, NULL, (SELECT account_id FROM account WHERE account_name = 'HDFC Bank'), (SELECT card_id FROM cards WHERE card_name = 'Tata Neu'), NULL, NULL, (SELECT expense_source_id FROM expense_source WHERE expense_source_name = 'BANK_STATEMENT'), NULL);
INSERT INTO "transaction" (transaction_type, amount, transaction_date, description, labeled, created_time, updated_time, category_id, subcategory_id, purpose_id, account_id, card_id, merchant_id, payment_method_id, expense_source_id, related_transaction_id) VALUES ('DEBIT', 20.00, '2025-11-13', 'UPI-Devsath Aruna bai', 0, '2025-12-08 17:15:23', '2025-12-08 17:15:23', NULL, NULL, NULL, (SELECT account_id FROM account WHERE account_name = 'HDFC Bank'), (SELECT card_id FROM cards WHERE card_name = 'Tata Neu'), NULL, NULL, (SELECT expense_source_id FROM expense_source WHERE expense_source_name = 'BANK_STATEMENT'), NULL);
INSERT INTO "transaction" (transaction_type, amount, transaction_date, description, labeled, created_time, updated_time, category_id, subcategory_id, purpose_id, account_id, card_id, merchant_id, payment_method_id, expense_source_id, related_transaction_id) VALUES ('DEBIT', 30.00, '2025-11-13', 'UPI-Kadadhanar Santhosh', 0, '2025-12-08 17:15:23', '2025-12-08 17:15:23', NULL, NULL, NULL, (SELECT account_id FROM account WHERE account_name = 'HDFC Bank'), (SELECT card_id FROM cards WHERE card_name = 'Tata Neu'), NULL, NULL, (SELECT expense_source_id FROM expense_source WHERE expense_source_name = 'BANK_STATEMENT'), NULL);
INSERT INTO "transaction" (transaction_type, amount, transaction_date, description, labeled, created_time, updated_time, category_id, subcategory_id, purpose_id, account_id, card_id, merchant_id, payment_method_id, expense_source_id, related_transaction_id) VALUES ('DEBIT', 50.00, '2025-11-13', 'UPI-SINGAPANGA YADAIAH', 0, '2025-12-08 17:15:23', '2025-12-08 17:15:23', NULL, NULL, NULL, (SELECT account_id FROM account WHERE account_name = 'HDFC Bank'), (SELECT card_id FROM cards WHERE card_name = 'Tata Neu'), NULL, NULL, (SELECT expense_source_id FROM expense_source WHERE expense_source_name = 'BANK_STATEMENT'), NULL);
