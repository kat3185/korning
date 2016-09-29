-- DEFINE YOUR DATABASE SCHEMA HERE

DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS invoices;
DROP TABLE IF EXISTS frequencies;
DROP TABLE IF EXISTS sales;

CREATE TABLE employees (
  id BIGSERIAL PRIMARY KEY,
  name varchar(255) NOT NULL,
  email varchar(255) UNIQUE NOT NULL
);

CREATE TABLE products (
  id BIGSERIAL PRIMARY KEY,
  name varchar(255) UNIQUE NOT NULL
);

CREATE TABLE customers (
  id BIGSERIAL PRIMARY KEY,
  name varchar(255) NOT NULL,
  account_number varchar(255) UNIQUE NOT NULL
);

CREATE TABLE invoices (
  id BIGSERIAL PRIMARY KEY,
  invoice_number integer UNIQUE NOT NULL
);

CREATE TABLE frequencies (
  id BIGSERIAL PRIMARY KEY,
  frequency varchar(63) UNIQUE NOT NULL
);

CREATE TABLE sales (
  id BIGSERIAL PRIMARY KEY,
  employee_id integer NOT NULL,
  product_id integer NOT NULL,
  customer_id integer NOT NULL,
  date_sold date NOT NULL,
  revenue money NOT NULL,
  units_sold integer NOT NULL,
  invoice_id integer NOT NULL
);
