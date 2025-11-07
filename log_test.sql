-- =========================================================
-- Эксперимент: Logged vs Unlogged tables
-- =========================================================

-- Включаем вывод времени выполнения
\timing

-- ========================
-- 1. Создание таблиц
-- ========================
DROP TABLE IF EXISTS logged_table;
DROP TABLE IF EXISTS unlogged_table;

CREATE TABLE logged_table (
    id BIGSERIAL PRIMARY KEY,
    client_id INT NOT NULL,
    class_id INT NOT NULL,
    status TEXT
);

CREATE UNLOGGED TABLE unlogged_table (
    id BIGSERIAL PRIMARY KEY,
    client_id INT NOT NULL,
    class_id INT NOT NULL,
    status TEXT
);

-- ========================
-- 2. Вставка данных по одной записи
-- ========================
INSERT INTO logged_table (client_id, class_id, status) VALUES (1, 1, 'active');
INSERT INTO unlogged_table (client_id, class_id, status) VALUES (1, 1, 'active');

-- ========================
-- 3. Вставка данных bulk (100000 строк)
-- ========================
INSERT INTO logged_table (client_id, class_id, status)
SELECT i, i % 200000, 'active'
FROM generate_series(2,100001) AS s(i);

INSERT INTO unlogged_table (client_id, class_id, status)
SELECT i, i % 200000, 'active'
FROM generate_series(2,100001) AS s(i);

-- ========================
-- 4. Чтение данных
-- ========================
SELECT COUNT(*) FROM logged_table;
SELECT COUNT(*) FROM unlogged_table;


-- ========================
-- 5. Удаление данных
-- ========================
DELETE FROM logged_table WHERE client_id <= 50000;
DELETE FROM unlogged_table WHERE client_id <= 50000;

-- ========================
-- 6. Финальный подсчёт строк
-- ========================
SELECT COUNT(*) AS logged_count FROM logged_table;
SELECT COUNT(*) AS unlogged_count FROM unlogged_table;
