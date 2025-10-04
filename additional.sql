DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;


-- Создание таблиц
CREATE TABLE clients (
    id SERIAL PRIMARY KEY,
    username VARCHAR(255) NOT NULL,
    address TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE NULL
);

CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    parent_id INTEGER NULL CHECK(parent_id!=id), -- для того чтобы не могла ссылаться на саму себя
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE NULL,
    CONSTRAINT fk_categories_parent 
        FOREIGN KEY (parent_id) 
        REFERENCES categories(id) 
        ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    quantity INTEGER CHECK (quantity >= 0) NOT NULL,
    price DECIMAL(10,2) CHECK(price>0) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE NULL
);

CREATE TABLE product_category (
    id SERIAL PRIMARY KEY,
    category_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE NULL,
    CONSTRAINT fk_product_category_category 
        FOREIGN KEY (category_id) 
        REFERENCES categories(id) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_product_category_product 
        FOREIGN KEY (product_id) 
        REFERENCES products(id) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT uq_product_category_unique 
        UNIQUE (category_id, product_id)
);

CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    client_id INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE NULL,
    CONSTRAINT fk_orders_client 
        FOREIGN KEY (client_id) 
        REFERENCES clients(id) 
        ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE order_products (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity INTEGER CHECK (quantity > 0) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE NULL,
    CONSTRAINT fk_order_products_order 
        FOREIGN KEY (order_id) 
        REFERENCES orders(id) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_order_products_product 
        FOREIGN KEY (product_id) 
        REFERENCES products(id) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT uq_order_products_unique 
        UNIQUE (order_id, product_id)
);


-- Создание индексов
CREATE INDEX idx_order_products_product_id ON order_products(product_id);
CREATE INDEX idx_order_products_order_id ON order_products(order_id);
CREATE INDEX idx_orders_client_id ON orders(client_id);

CREATE INDEX idx_categories_parent_id ON categories(parent_id);


-- Создание триггеров
CREATE OR REPLACE FUNCTION check_category_cycle()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.parent_id IS NOT NULL THEN
		IF NEW.parent_id = NEW.id THEN
            RAISE EXCEPTION 'Ошибка: категория не может ссылаться на саму себя';
        END IF;
        IF EXISTS (
            WITH RECURSIVE descendants AS (
                SELECT id, parent_id
                FROM categories
                WHERE parent_id = NEW.id AND deleted_at IS NULL

                UNION ALL

                SELECT c.id, c.parent_id
                FROM categories c
                JOIN descendants d ON c.parent_id = d.id
                WHERE c.deleted_at IS NULL
            )
            SELECT 1 FROM descendants WHERE id = NEW.parent_id
        ) THEN
            RAISE EXCEPTION 
                'Ошибка: установка категории % родителем категории % создаёт цикл', 
                NEW.parent_id, NEW.id;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Триггер
CREATE TRIGGER trg_check_category_cycle 
    BEFORE INSERT OR UPDATE ON categories
    FOR EACH ROW EXECUTE FUNCTION check_category_cycle();

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = TIMEZONE('utc', now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_clients_updated_at 
    BEFORE UPDATE ON clients 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_categories_updated_at 
    BEFORE UPDATE ON categories 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at 
    BEFORE UPDATE ON products 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_orders_updated_at 
    BEFORE UPDATE ON orders 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_product_category_updated_at 
    BEFORE UPDATE ON product_category 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_order_products_updated_at 
    BEFORE UPDATE ON order_products 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


-- Вставка данных	
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

INSERT INTO products (id, name, quantity, price) VALUES 
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

INSERT INTO clients(id, username, address) VALUES 
(1, 'name1', 'address1'),
(2, 'name2', 'address2'),
(3, 'name3', 'address3'),
(4, 'name4', 'address4');

INSERT INTO orders(id, client_id) VALUES 
(1, 1),
(2, 2),
(3, 1),
(4, 3);

INSERT INTO order_products(order_id, product_id, quantity) VALUES 
(1, 1, 1), (1, 2, 2), (1, 4, 1),
(2, 1, 2), (2, 5, 3),
(3, 5, 4),
(4, 3, 2),(4, 4, 1);


-- Корректировка sequences после ручной вставки ID
SELECT setval('categories_id_seq', COALESCE((SELECT MAX(id) FROM categories), 1));
SELECT setval('products_id_seq', COALESCE((SELECT MAX(id) FROM products), 1));
SELECT setval('clients_id_seq', COALESCE((SELECT MAX(id) FROM clients), 1));
SELECT setval('product_category_id_seq', COALESCE((SELECT MAX(id) FROM product_category), 1));
SELECT setval('orders_id_seq', COALESCE((SELECT MAX(id) FROM orders), 1));
SELECT setval('order_products_id_seq', COALESCE((SELECT MAX(id) FROM order_products), 1));


-- Запрос 2.1. Получение информации о сумме товаров заказанных под каждого клиента (Наименование клиента, сумма)
SELECT 
	c.username, 
	SUM((op.quantity * p.price)) as summa
FROM products p
JOIN order_products op ON p.id=op.product_id
JOIN orders o ON o.id = op.order_id
JOIN clients c ON c.id = o.client_id
WHERE c.deleted_at IS NULL
GROUP BY c.id;

-- Запрос 2.2. Найти количество дочерних элементов первого уровня вложенности для категорий номенклатуры.
SELECT 
	c.username, 
	COALESCE(SUM(op.quantity * p.price),0.00) as summa
FROM clients c
LEFT JOIN orders o ON c.id = o.client_id
LEFT JOIN order_products op ON o.id = op.order_id
LEFT JOIN products p ON p.id=op.product_id
WHERE c.deleted_at IS NULL
GROUP BY c.id;


-- Комментарии к таблицам
COMMENT ON TABLE clients IS 'Клиенты';
COMMENT ON TABLE categories IS 'Дерево категорий (корень=NULL)';
COMMENT ON TABLE products IS 'Номенклатура товаров';
COMMENT ON TABLE product_category IS 'Связь многие-ко-многим между товарами и категориями';
COMMENT ON TABLE orders IS 'Заказы клиентов';
COMMENT ON TABLE order_products IS 'Товары в заказе';

-- Комментарии к колонкам clients
COMMENT ON COLUMN clients.id IS 'Уникальный идентификатор';
COMMENT ON COLUMN clients.username IS 'Имя клиента';
COMMENT ON COLUMN clients.address IS 'Адрес клиента';
COMMENT ON COLUMN clients.created_at IS 'Дата и время создания записи';
COMMENT ON COLUMN clients.updated_at IS 'Дата и время последнего обновления записи';
COMMENT ON COLUMN clients.deleted_at IS 'Дата и время удаления записи для мягкого удаления';

-- Комментарии к колонкам categories
COMMENT ON COLUMN categories.id IS 'Уникальный идентификатор';
COMMENT ON COLUMN categories.name IS 'Наименование категории';
COMMENT ON COLUMN categories.parent_id IS 'Ссылка на родительскую категорию (для построения дерева)';
COMMENT ON COLUMN categories.created_at IS 'Дата и время создания записи';
COMMENT ON COLUMN categories.updated_at IS 'Дата и время последнего обновления записи';
COMMENT ON COLUMN categories.deleted_at IS 'Дата и время удаления записи для мягкого удаления';

-- Комментарии к колонкам products
COMMENT ON COLUMN products.id IS 'Уникальный идентификатор';
COMMENT ON COLUMN products.quantity IS 'Количество товара на складе (>=0)';
COMMENT ON COLUMN products.price IS 'Цена товара (>0.00)';
COMMENT ON COLUMN products.created_at IS 'Дата и время создания записи';
COMMENT ON COLUMN products.updated_at IS 'Дата и время последнего обновления записи';
COMMENT ON COLUMN products.deleted_at IS 'Дата и время удаления записи для мягкого удаления';

-- Комментарии к колонкам product_category
COMMENT ON COLUMN product_category.id IS 'Уникальный идентификатор';
COMMENT ON COLUMN product_category.category_id IS 'Ссылка на категорию';
COMMENT ON COLUMN product_category.product_id IS 'Ссылка на товар';
COMMENT ON COLUMN product_category.created_at IS 'Дата и время создания записи';
COMMENT ON COLUMN product_category.updated_at IS 'Дата и время последнего обновления записи';
COMMENT ON COLUMN product_category.deleted_at IS 'Дата и время удаления записи для мягкого удаления';

-- Комментарии к колонкам orders
COMMENT ON COLUMN orders.id IS 'Уникальный идентификатор';
COMMENT ON COLUMN orders.client_id IS 'Ссылка на клиента, сделавшего заказ';
COMMENT ON COLUMN orders.created_at IS 'Дата и время создания записи';
COMMENT ON COLUMN orders.updated_at IS 'Дата и время последнего обновления записи';
COMMENT ON COLUMN orders.deleted_at IS 'Дата и время удаления записи для мягкого удаления';

-- Комментарии к колонкам order_products
COMMENT ON COLUMN order_products.id IS 'Уникальный идентификатор';
COMMENT ON COLUMN order_products.order_id IS 'Ссылка на заказ';
COMMENT ON COLUMN order_products.product_id IS 'Ссылка на товар в заказе';
COMMENT ON COLUMN order_products.quantity IS 'Количество товара в заказе (>0)';
COMMENT ON COLUMN order_products.created_at IS 'Дата и время создания записи';
COMMENT ON COLUMN order_products.updated_at IS 'Дата и время последнего обновления записи';
COMMENT ON COLUMN order_products.deleted_at IS 'Дата и время удаления записи для мягкого удаления';

-- Комментарии к индексам
COMMENT ON INDEX idx_order_products_product_id IS 'Индекс для поиска товаров в заказах';
COMMENT ON INDEX idx_order_products_order_id IS 'Индекс для поиска заказов по товарам';
COMMENT ON INDEX idx_orders_client_id IS 'Индекс для поиска заказов клиента';
COMMENT ON INDEX idx_categories_parent_id IS 'Индекс для построения дерева категорий';

-- Комментарии к ограничениям
COMMENT ON CONSTRAINT fk_categories_parent ON categories IS 'Рекурсивная связь для построения дерева категорий';
COMMENT ON CONSTRAINT fk_orders_client ON orders IS 'Связь заказа с клиентом';
COMMENT ON CONSTRAINT uq_product_category_unique ON product_category IS 'Уникальность связи товар-категория';

-- Комментарии к функции и триггерам
COMMENT ON FUNCTION update_updated_at_column() IS 'Функция для автоматического обновления updated_at';
COMMENT ON TRIGGER update_clients_updated_at ON clients IS 'Триггер для автоматического обновления updated_at';
COMMENT ON FUNCTION check_category_cycle() IS 'Функция для проверки зациклинности категорий';
COMMENT ON TRIGGER trg_check_category_cycle ON categories IS 'Триггер для проверки зациклинности категорий';


/* Проверка на создание цикла категориями

INSERT INTO categories (id, name, parent_id) VALUES 
(100, 'Электроника', NULL),
(200, 'Телефоны', 100),
(300, 'Смартфоны', 200);

-- Должен вызвать ошибку
UPDATE categories SET parent_id = 300 WHERE id = 100;
SELECT * FROM categories;

*/