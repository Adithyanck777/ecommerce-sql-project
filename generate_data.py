"""
Generates a synthetic e-commerce dataset (Olist-style schema) since the
Kaggle dataset isn't reachable from this environment. Distributions
(order volume growth, seasonality, repeat-purchase rates, regional mix,
category revenue skew) are deliberately built in so the SQL analysis
below produces realistic, non-trivial results.

Output: CSVs in data/ + a normalized SQLite DB in db/ecommerce.db
"""
import csv
import random
import sqlite3
import os
from datetime import date, timedelta
from faker import Faker

random.seed(42)
fake = Faker("pt_BR")
Faker.seed(42)

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(BASE_DIR, "data")
DB_PATH = os.path.join(BASE_DIR, "db", "ecommerce.db")

N_CUSTOMERS = 9000
N_PRODUCTS = 1200
N_ORDERS = 26000
START_DATE = date(2023, 1, 1)
END_DATE = date(2024, 12, 31)
TOTAL_DAYS = (END_DATE - START_DATE).days

STATES = {
    "SP": "Southeast", "RJ": "Southeast", "MG": "Southeast", "ES": "Southeast",
    "PR": "South", "SC": "South", "RS": "South",
    "BA": "Northeast", "PE": "Northeast", "CE": "Northeast",
    "DF": "Central-West", "GO": "Central-West", "MT": "Central-West",
    "AM": "North", "PA": "North",
}
STATE_WEIGHTS = {
    "SP": 28, "RJ": 12, "MG": 10, "ES": 3, "PR": 8, "SC": 6, "RS": 7,
    "BA": 7, "PE": 5, "CE": 4, "DF": 4, "GO": 3, "MT": 2, "AM": 1, "PA": 1,
}

CATEGORIES = {
    "electronics": (150, 3500, 0.14),
    "home_furniture": (80, 2200, 0.22),
    "fashion_accessories": (25, 400, 0.35),
    "beauty_health": (20, 300, 0.30),
    "sports_leisure": (40, 900, 0.20),
    "toys_baby": (25, 500, 0.18),
    "books_stationery": (15, 200, 0.15),
    "housewares": (20, 600, 0.25),
    "computers_tablets": (300, 6000, 0.10),
    "auto_parts": (30, 1500, 0.20),
}
CATEGORY_WEIGHTS = {
    "electronics": 14, "home_furniture": 12, "fashion_accessories": 18,
    "beauty_health": 15, "sports_leisure": 9, "toys_baby": 7,
    "books_stationery": 6, "housewares": 8, "computers_tablets": 5,
    "auto_parts": 6,
}

PAYMENT_TYPES = ["credit_card", "credit_card", "credit_card", "boleto", "voucher", "debit_card"]


def weighted_choice(weights_dict):
    items = list(weights_dict.keys())
    weights = list(weights_dict.values())
    return random.choices(items, weights=weights, k=1)[0]


def random_order_date():
    """Skewed toward recent months + holiday-season (Nov/Dec) bump, with overall upward growth trend."""
    # growth trend: later days more likely
    t = random.random() ** 0.6  # bias toward higher t (recent)
    day_offset = int(t * TOTAL_DAYS)
    d = START_DATE + timedelta(days=day_offset)
    # Nov/Dec seasonal bump: occasionally reroll into Nov/Dec of a random year in range
    if random.random() < 0.12:
        yr = random.choice([2023, 2024])
        d = date(yr, random.choice([11, 12]), random.randint(1, 28))
    return d


def gen_customers():
    customers = []
    for i in range(1, N_CUSTOMERS + 1):
        state = weighted_choice(STATE_WEIGHTS)
        signup = START_DATE + timedelta(days=random.randint(0, TOTAL_DAYS - 30))
        customers.append({
            "customer_id": i,
            "customer_unique_key": fake.uuid4(),
            "customer_city": fake.city(),
            "customer_state": state,
            "region": STATES[state],
            "signup_date": signup.isoformat(),
        })
    return customers


def gen_products():
    products = []
    for i in range(1, N_PRODUCTS + 1):
        cat = weighted_choice(CATEGORY_WEIGHTS)
        lo, hi, margin = CATEGORIES[cat]
        price = round(random.uniform(lo, hi), 2)
        cost = round(price * (1 - margin - random.uniform(-0.03, 0.03)), 2)
        products.append({
            "product_id": i,
            "product_category": cat,
            "product_name": f"{cat.replace('_', ' ').title()} Item {i}",
            "unit_cost": cost,
            "list_price": price,
            "weight_g": random.randint(100, 15000),
        })
    return products


def gen_orders_items_payments(customers, products):
    orders, items, payments = [], [], []
    # customer purchase-count distribution: most buy once, some are repeat/loyal (power-law-ish)
    cust_weights = []
    for c in customers:
        r = random.random()
        if r < 0.65:
            w = 1
        elif r < 0.88:
            w = random.randint(2, 3)
        elif r < 0.97:
            w = random.randint(4, 7)
        else:
            w = random.randint(8, 15)
        cust_weights.append(w)

    order_id = 1
    item_id = 1
    orders_left = N_ORDERS
    cust_ids = [c["customer_id"] for c in customers]

    # Pre-build product pool with category for weighted item selection
    prod_ids = [p["product_id"] for p in products]

    while orders_left > 0:
        cust_idx = random.choices(range(len(customers)), weights=cust_weights, k=1)[0]
        cust = customers[cust_idx]
        order_date = random_order_date()
        signup = date.fromisoformat(cust["signup_date"])
        if order_date < signup:
            order_date = signup + timedelta(days=random.randint(0, 5))

        status_roll = random.random()
        if status_roll < 0.92:
            status = "delivered"
        elif status_roll < 0.96:
            status = "shipped"
        elif status_roll < 0.98:
            status = "canceled"
        else:
            status = "returned"

        n_items = random.choices([1, 2, 3, 4, 5], weights=[45, 28, 15, 8, 4])[0]
        chosen_products = random.sample(prod_ids, min(n_items, len(prod_ids)))
        order_total = 0.0
        for pid in chosen_products:
            prod = products[pid - 1]
            qty = random.choices([1, 1, 1, 2, 3], weights=[70, 10, 10, 7, 3])[0]
            unit_price = prod["list_price"] * random.uniform(0.92, 1.05)
            unit_price = round(unit_price, 2)
            freight = round(random.uniform(5, 45), 2)
            items.append({
                "order_item_id": item_id,
                "order_id": order_id,
                "product_id": pid,
                "quantity": qty,
                "unit_price": unit_price,
                "freight_value": freight,
            })
            order_total += unit_price * qty + freight
            item_id += 1

        orders.append({
            "order_id": order_id,
            "customer_id": cust["customer_id"],
            "order_date": order_date.isoformat(),
            "order_status": status,
            "order_total": round(order_total, 2),
        })

        # payments: sometimes split into installments (credit_card)
        ptype = weighted_choice({p: 1 for p in PAYMENT_TYPES})
        if ptype == "credit_card" and order_total > 200 and random.random() < 0.5:
            installments = random.choice([2, 3, 4, 6, 10])
        else:
            installments = 1
        payments.append({
            "payment_id": order_id,
            "order_id": order_id,
            "payment_type": ptype,
            "installments": installments,
            "payment_value": round(order_total, 2),
        })

        order_id += 1
        orders_left -= 1

    return orders, items, payments


def write_csv(path, rows, fieldnames):
    with open(path, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fieldnames)
        w.writeheader()
        w.writerows(rows)


def build_sqlite(customers, products, orders, items, payments):
    if os.path.exists(DB_PATH):
        os.remove(DB_PATH)
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()
    cur.executescript("""
    CREATE TABLE customers (
        customer_id INTEGER PRIMARY KEY,
        customer_unique_key TEXT,
        customer_city TEXT,
        customer_state TEXT,
        region TEXT,
        signup_date TEXT
    );
    CREATE TABLE products (
        product_id INTEGER PRIMARY KEY,
        product_category TEXT,
        product_name TEXT,
        unit_cost REAL,
        list_price REAL,
        weight_g INTEGER
    );
    CREATE TABLE orders (
        order_id INTEGER PRIMARY KEY,
        customer_id INTEGER REFERENCES customers(customer_id),
        order_date TEXT,
        order_status TEXT,
        order_total REAL
    );
    CREATE TABLE order_items (
        order_item_id INTEGER PRIMARY KEY,
        order_id INTEGER REFERENCES orders(order_id),
        product_id INTEGER REFERENCES products(product_id),
        quantity INTEGER,
        unit_price REAL,
        freight_value REAL
    );
    CREATE TABLE payments (
        payment_id INTEGER PRIMARY KEY,
        order_id INTEGER REFERENCES orders(order_id),
        payment_type TEXT,
        installments INTEGER,
        payment_value REAL
    );
    """)
    cur.executemany(
        "INSERT INTO customers VALUES (:customer_id,:customer_unique_key,:customer_city,:customer_state,:region,:signup_date)",
        customers,
    )
    cur.executemany(
        "INSERT INTO products VALUES (:product_id,:product_category,:product_name,:unit_cost,:list_price,:weight_g)",
        products,
    )
    cur.executemany(
        "INSERT INTO orders VALUES (:order_id,:customer_id,:order_date,:order_status,:order_total)",
        orders,
    )
    cur.executemany(
        "INSERT INTO order_items VALUES (:order_item_id,:order_id,:product_id,:quantity,:unit_price,:freight_value)",
        items,
    )
    cur.executemany(
        "INSERT INTO payments VALUES (:payment_id,:order_id,:payment_type,:installments,:payment_value)",
        payments,
    )
    cur.execute("CREATE INDEX idx_orders_customer ON orders(customer_id);")
    cur.execute("CREATE INDEX idx_orders_date ON orders(order_date);")
    cur.execute("CREATE INDEX idx_items_order ON order_items(order_id);")
    cur.execute("CREATE INDEX idx_items_product ON order_items(product_id);")
    conn.commit()
    conn.close()


def main():
    customers = gen_customers()
    products = gen_products()
    orders, items, payments = gen_orders_items_payments(customers, products)

    write_csv(os.path.join(DATA_DIR, "customers.csv"), customers, list(customers[0].keys()))
    write_csv(os.path.join(DATA_DIR, "products.csv"), products, list(products[0].keys()))
    write_csv(os.path.join(DATA_DIR, "orders.csv"), orders, list(orders[0].keys()))
    write_csv(os.path.join(DATA_DIR, "order_items.csv"), items, list(items[0].keys()))
    write_csv(os.path.join(DATA_DIR, "payments.csv"), payments, list(payments[0].keys()))

    build_sqlite(customers, products, orders, items, payments)

    print(f"customers={len(customers)} products={len(products)} orders={len(orders)} "
          f"order_items={len(items)} payments={len(payments)}")


if __name__ == "__main__":
    main()
