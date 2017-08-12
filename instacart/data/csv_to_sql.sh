#!/bin/bash

# This script transforms the CSV files into a set of SQL tables that can then
# be joined via queries.

DB_FILE="instacart.db"

# Need to be done table by table just to get the column types right
sqlcommand='
CREATE TABLE aisles(
  "aisle_id" INTEGER PRIMARY KEY,
  "aisle" TEXT
);
CREATE TABLE departments(
  "department_id" INTEGER PRIMARY KEY,
  "department" TEXT
);
CREATE TABLE order_products__prior(
  "order_id" INTEGER,
  "product_id" INTEGER,
  "add_to_cart_order" INTEGER,
  "reordered" INTEGER
);
CREATE INDEX order_products__prior_order_id_idx ON order_products__prior(order_id);
CREATE TABLE order_products__train(
  "order_id" INTEGER,
  "product_id" INTEGER,
  "add_to_cart_order" INTEGER,
  "reordered" INTEGER
);
CREATE INDEX order_products__train_order_id_idx ON order_products__train(order_id);
CREATE TABLE orders(
  "order_id" INTEGER PRIMARY KEY,
  "user_id" INTEGER,
  "eval_set" TEXT,
  "order_number" INTEGER,
  "order_dow" INTEGER,
  "order_hour_of_day" INTEGER,
  "days_since_prior_order" INTEGER
);
CREATE INDEX orders_user_idx_idx ON orders(user_id);
CREATE INDEX orders_order_id_idx ON orders(order_id);
CREATE INDEX orders_order_id_user_id_idx ON orders(order_id, user_id);
CREATE INDEX orders_order_number_idx ON orders(order_number);
CREATE TABLE products(
  "product_id" INTEGER PRIMARY KEY,
  "product_name" TEXT,
  "aisle_id" INTEGER,
  "department_id" INTEGER
);'

echo $sqlcommand | sqlite3 ${DB_FILE}

# Do everything
for f in *.csv.bz2; do
    tablename=$(basename ${f} .csv.bz2)
    # From https://dba.stackexchange.com/questions/128520/directly-import-a-csv-gziped-file-into-sqlite-3
    commandfile=$(mktemp)
    echo ".mode csv" >> ${commandfile}
    echo ".import /dev/stdin ${tablename}" >> ${commandfile}
    # bzcat, but remove header so it doesn't reset the column type
    bzcat ${f} | tail -n +2 | sqlite3 --init ${commandfile} ${DB_FILE}
    #bzcat ${f} | sqlite3 --init ${commandfile} ${DB_FILE}
done
