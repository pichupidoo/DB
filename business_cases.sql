-- ============================================================
-- Бизнес-кейсы для спортивного центра
-- ============================================================

-- ==========================
-- 3-5 агрегирующих запросов
-- ==========================
-- 1. Количество клиентов по типу абонемента
SELECT s.type, COUNT(c.client_id) AS clients_count
FROM Clients c
JOIN Subscriptions s ON c.subscription_id = s.subscription_id
GROUP BY s.type;

-- 2. Общая сумма оплат по способу оплаты
SELECT method, SUM(amount) AS total_amount
FROM Payments
GROUP BY method;

-- 3. Средняя стоимость услуги по тренеру
SELECT staff_id, AVG(price) AS avg_service_price
FROM Services
GROUP BY staff_id;

-- 4. Максимальная и минимальная стоимость абонемента
SELECT MAX(price) AS max_price, MIN(price) AS min_price
FROM Subscriptions;

-- 5. Количество записей на занятия по статусу
SELECT status, COUNT(*) AS bookings_count
FROM Bookings
GROUP BY status;


-- ==========================
-- 3-5 оконных функций
-- ==========================
-- 1. Рейтинг клиентов по сумме оплат
SELECT client_id, SUM(amount) AS total_paid,
       RANK() OVER (ORDER BY SUM(amount) DESC) AS client_rank
FROM Payments
GROUP BY client_id;

-- 2. Накопительная сумма оплат по дате
SELECT payment_id, client_id, amount, payment_date,
       SUM(amount) OVER (ORDER BY payment_date) AS cumulative_sum
FROM Payments;

-- 3. Предыдущая и следующая запись на занятие для клиента
SELECT booking_id, client_id, class_id, status,
       LAG(class_id) OVER (PARTITION BY client_id ORDER BY booking_id) AS prev_class,
       LEAD(class_id) OVER (PARTITION BY client_id ORDER BY booking_id) AS next_class
FROM Bookings;

-- 4. Номер строки для услуги по тренеру
SELECT service_id, staff_id, price,
       ROW_NUMBER() OVER (PARTITION BY staff_id ORDER BY price DESC) AS row_num
FROM Services;

-- 5. Скользящее среднее рейтинга отзывов по дате
SELECT review_id, rating, review_date,
       AVG(rating) OVER (ORDER BY review_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg
FROM Reviews;


-- ==========================
-- 8 запросов с объединениями
-- ==========================
-- 2 объединения 2 таблиц
-- 1. Клиенты с их абонементами
SELECT c.client_id, c.full_name, s.type, s.price
FROM Clients c
JOIN Subscriptions s ON c.subscription_id = s.subscription_id;

-- 2. Услуги с тренерами
SELECT srv.service_id, srv.name, srv.price, st.full_name AS trainer_name
FROM Services srv
JOIN Staff st ON srv.staff_id = st.staff_id;

-- 4 объединения 3 таблиц
-- 3. Оплаты с клиентами и абонементами
SELECT p.payment_id, c.full_name, s.type, p.amount
FROM Payments p
JOIN Clients c ON p.client_id = c.client_id
JOIN Subscriptions s ON p.subscription_id = s.subscription_id;

-- 4. Записи на занятия с клиентами и занятиями
SELECT b.booking_id, c.full_name, w.datetime, b.status
FROM Bookings b
JOIN Clients c ON b.client_id = c.client_id
JOIN Workouts w ON b.class_id = w.workout_id;

-- 5. Оборудование с залами и статусом
SELECT e.equipment_id, e.name AS equipment_name, h.name AS hall_name, e.status
FROM Equipment e
JOIN Halls h ON e.hall_id = h.hall_id;

-- 6. Отзывы с клиентами и занятиями/услугами
SELECT r.review_id, c.full_name, r.target_type, r.rating, r.comment
FROM Reviews r
JOIN Clients c ON r.client_id = c.client_id;

-- 1 объединение 4 таблиц
-- 7. Полная информация о записи на занятие
SELECT b.booking_id, c.full_name, w.datetime, h.name AS hall_name, st.full_name AS trainer_name
FROM Bookings b
JOIN Clients c ON b.client_id = c.client_id
JOIN Workouts w ON b.class_id = w.workout_id
JOIN Halls h ON w.hall_id = h.hall_id
JOIN Staff st ON w.trainer_id = st.staff_id;

-- 1 объединение 5 таблиц
-- 8. Оплаты с клиентами, абонементами и последними записями на занятия
SELECT p.payment_id, c.full_name, s.type, p.amount, w.datetime AS last_workout
FROM Payments p
JOIN Clients c ON p.client_id = c.client_id
JOIN Subscriptions s ON p.subscription_id = s.subscription_id
LEFT JOIN Bookings b ON c.client_id = b.client_id
LEFT JOIN Workouts w ON b.class_id = w.workout_id
WHERE w.datetime = (SELECT MAX(w2.datetime) 
                    FROM Bookings b2
                    JOIN Workouts w2 ON b2.class_id = w2.workout_id
                    WHERE b2.client_id = c.client_id);
