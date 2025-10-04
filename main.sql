DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;

CREATE TABLE clients (
	id SERIAL PRIMARY KEY,
	name VARCHAR(255) NOT NULL,
	address TEXT NOT NULL
);

CREATE TABLE categories (
	id SERIAL PRIMARY KEY,
	name VARCHAR(255) NOT NULL,
	parent_id INTEGER REFERENCES categories(id) ON DELETE CASCADE ON UPDATE CASCADE NULL
);

CREATE TABLE products (
	id SERIAL PRIMARY KEY,
	name VARCHAR(255) NOT NULL,
	count INTEGER CHECK (count >= 0) NOT NULL,
	price DECIMAL(10,2) CHECK(price>0) NOT NULL
);

CREATE TABLE product_category (
	id SERIAL PRIMARY KEY,
	category_id INTEGER REFERENCES categories(id) ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
	product_id INTEGER REFERENCES products(id) ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
	UNIQUE (category_id, product_id)
);

CREATE TABLE orders (
	id SERIAL PRIMARY KEY,
	client_id INTEGER REFERENCES clients(id) ON DELETE CASCADE ON UPDATE CASCADE NOT NULL
);

CREATE TABLE order_products (
    id SERIAL PRIMARY KEY,
	order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
	product_id INTEGER REFERENCES products(id) ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
	count INTEGER CHECK (count > 0) NOT NULL,
	UNIQUE (order_id, product_id)
);


INSERT INTO categories(id, name, parent_id) values 
(1, 'Бытовая техника',NULL),
	(2, 'Стиральные машины',1),
	(3, 'Холодильники',1),
		(4, 'однокамерные',3),
		(5, 'двухкамерные',3),
	(6, 'Телевизоры',1),
(7, 'Компьютеры',NULL),
	(8, 'Ноутбуки',7),
		(9, '17“',8),
		(10, '19“',8),
	(11, 'Моноблоки',7);

INSERT INTO products (id, name, count, price) VALUES 
(1, 'Холодильник однокамерный', 40, 40000.00),
(2, 'Ноутбук 17“', 20, 80000.00),
(3, 'Телевизор', 10, 60000.00),
(4, 'Моноблок', 40, 35000.00),
(5, 'Стиральная машина', 40, 30000.00);

INSERT INTO product_category (product_id, category_id) VALUES 
(1, 4),
(2, 9),
(3, 6),
(4, 11),
(5, 2);


INSERT INTO clients(id, name, address) VALUES 
(1, 'name1', 'address1'),
(2, 'name2', 'address2'),
(3, 'name3', 'address3'),
(4, 'name4', 'address4');

INSERT INTO orders(id, client_id) VALUES 
(1, 1),
(2, 2),
(3, 1),
(4, 3);

INSERT INTO order_products(order_id, product_id, count) VALUES 
(1, 1, 1), (1, 2, 2), (1, 4, 1),
(2, 1, 2), (2, 5, 3),
(3, 5, 4),
(4, 3, 2),(4, 4, 1);

SELECT 
	c.name, 
	COALESCE(SUM(op.count * p.price),0.00) as summa
FROM clients c
LEFT JOIN orders o ON c.id = o.client_id
LEFT JOIN order_products op ON o.id = op.order_id
LEFT JOIN products p ON p.id=op.product_id
GROUP BY c.id;

SELECT
	c2.name, 
	COUNT(CASE WHEN c1.id IS NOT NULL THEN 1 END) as count
FROM categories c1
RIGHT JOIN categories c2 ON c2.id = c1.parent_id
GROUP BY c2.id;