-- ============================================================
-- 00_schema.sql
-- Schema for the e-commerce analytics database.
-- (Reference only — the DB is already built by data/generate_data.py.
--  Run this against a fresh Postgres/MySQL/SQLite instance if loading
--  the CSVs in data/ manually.)
-- ============================================================

CREATE TABLE customers (
    customer_id         INTEGER PRIMARY KEY,
    customer_unique_key TEXT,
    customer_city       TEXT,
    customer_state      TEXT,
    region              TEXT,
    signup_date         DATE
);

CREATE TABLE products (
    product_id       INTEGER PRIMARY KEY,
    product_category TEXT,
    product_name     TEXT,
    unit_cost        NUMERIC(10,2),
    list_price       NUMERIC(10,2),
    weight_g         INTEGER
);

CREATE TABLE orders (
    order_id     INTEGER PRIMARY KEY,
    customer_id  INTEGER REFERENCES customers(customer_id),
    order_date   DATE,
    order_status TEXT,   -- delivered | shipped | canceled | returned
    order_total  NUMERIC(10,2)
);

CREATE TABLE order_items (
    order_item_id INTEGER PRIMARY KEY,
    order_id      INTEGER REFERENCES orders(order_id),
    product_id    INTEGER REFERENCES products(product_id),
    quantity      INTEGER,
    unit_price    NUMERIC(10,2),
    freight_value NUMERIC(10,2)
);

CREATE TABLE payments (
    payment_id    INTEGER PRIMARY KEY,
    order_id      INTEGER REFERENCES orders(order_id),
    payment_type  TEXT,   -- credit_card | boleto | voucher | debit_card
    installments  INTEGER,
    payment_value NUMERIC(10,2)
);

CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_date     ON orders(order_date);
CREATE INDEX idx_items_order     ON order_items(order_id);
CREATE INDEX idx_items_product   ON order_items(product_id);

