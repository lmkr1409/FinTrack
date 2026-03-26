-- ──────────────────────────────────────────────────────────────────────
-- DDL: TABLE DEFINITIONS FOR FINTRACK
-- Includes updated Merchant Rule and Transaction Rule schemas
-- ──────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS category (
	category_id INTEGER PRIMARY KEY AUTOINCREMENT,
	category_name TEXT NOT NULL,
	icon TEXT,
	icon_color TEXT,
	priority INTEGER NOT NULL DEFAULT 99,
	category_type TEXT NOT NULL DEFAULT 'EXPENSE'
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

CREATE TABLE IF NOT EXISTS budget_total (
  total_id INTEGER PRIMARY KEY AUTOINCREMENT,
  budget_amount REAL NOT NULL,
  budget_frequency TEXT NOT NULL, -- 'MONTHLY', 'ANNUAL'
  month INTEGER,                  -- NULL for ANNUAL
  year INTEGER NOT NULL,
  created_time TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_time TEXT DEFAULT CURRENT_TIMESTAMP
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

CREATE TABLE IF NOT EXISTS merchant_rule (
  rule_id INTEGER PRIMARY KEY AUTOINCREMENT,
  keyword TEXT NOT NULL,
  merchant_id INTEGER,
  category_id INTEGER,
  subcategory_id INTEGER,
  purpose_id INTEGER,
  created_time TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_time TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (merchant_id) REFERENCES merchant(merchant_id) ON DELETE SET NULL,
  FOREIGN KEY (category_id) REFERENCES category(category_id) ON DELETE SET NULL,
  FOREIGN KEY (subcategory_id) REFERENCES sub_category(subcategory_id) ON DELETE SET NULL,
  FOREIGN KEY (purpose_id) REFERENCES expense_purpose(purpose_id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS transaction_rule (
  rule_id INTEGER PRIMARY KEY AUTOINCREMENT,
  rule_type TEXT NOT NULL,
  pattern TEXT NOT NULL,
  mapped_type TEXT,
  payment_method_id INTEGER,
  account_id INTEGER,
  card_id INTEGER,
  created_time TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_time TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (payment_method_id) REFERENCES payment_method(payment_method_id) ON DELETE SET NULL,
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
