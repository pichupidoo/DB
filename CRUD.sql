-- Файлы CRUD для репозитория DB (спортивный центр)

-- insert_data.sql
-- Subscriptions
INSERT INTO Subscriptions (type, price) VALUES
('разовый', 500),
('месячный', 3000),
('годовой', 30000);

-- Clients
INSERT INTO Clients (full_name, birth_date, gender, phone, subscription_id) VALUES
('Иван Иванов', '1990-05-12', 'м', '+79991234567', 1),
('Мария Петрова', '1985-03-20', 'ж', '+79997654321', 2);

-- Staff
INSERT INTO Staff (full_name, position, phone) VALUES
('Алексей Тренер', 'Тренер', '+79990001122'),
('Ольга Администратор', 'Администратор', '+79998887766');

-- Payments
INSERT INTO Payments (client_id, subscription_id, amount, method) VALUES
(1, 1, 500, 'карта'),
(2, 2, 3000, 'наличные');

-- Halls
INSERT INTO Halls (name) VALUES
('Зал А'),
('Зал Б');

-- Equipment
INSERT INTO Equipment (name, hall_id, status) VALUES
('Беговая дорожка', 1, 'исправно'),
('Гантели', 2, 'исправно');

-- Workouts
INSERT INTO Workouts (datetime, hall_id, trainer_id) VALUES
('2025-10-05 18:00', 1, 1),
('2025-10-06 10:00', 2, 1);

-- Bookings
INSERT INTO Bookings (client_id, class_id, status) VALUES
(1, 1, 'записан'),
(2, 2, 'записан');

-- Sections
INSERT INTO Sections (name, trainer_id) VALUES
('Йога', 1),
('Силовые тренировки', 1);

-- Services
INSERT INTO Services (name, price, staff_id) VALUES
('Массаж', 1000, 2),
('Персональная тренировка', 1500, 1);

-- Reviews
INSERT INTO Reviews (client_id, target_type, rating, comment) VALUES
(1, 'занятие', 5, 'Отличная тренировка!'),
(2, 'услуга', 4, 'Хороший массаж');


-- select_data.sql
-- Все клиенты
SELECT * FROM Clients;

-- Все занятия с тренером и залом
SELECT w.workout_id, w.datetime, s.full_name AS trainer, h.name AS hall
FROM Workouts w
JOIN Staff s ON w.trainer_id = s.staff_id
JOIN Halls h ON w.hall_id = h.hall_id;

-- Все записи клиентов на занятия
SELECT b.booking_id, c.full_name, w.datetime, b.status
FROM Bookings b
JOIN Clients c ON b.client_id = c.client_id
JOIN Workouts w ON b.class_id = w.workout_id;

-- Все услуги с ответственным сотрудником
SELECT s.name, s.price, st.full_name AS staff
FROM Services s
JOIN Staff st ON s.staff_id = st.staff_id;

-- Все отзывы с клиентами
SELECT r.review_id, c.full_name, r.target_type, r.rating, r.comment
FROM Reviews r
JOIN Clients c ON r.client_id = c.client_id;


-- update_data.sql
-- Обновить абонемент
UPDATE Subscriptions SET price = 3500 WHERE subscription_id = 2;

-- Обновить данные клиента
UPDATE Clients SET phone = '+79990009999' WHERE client_id = 1;

-- Обновить статус записи на занятие
UPDATE Bookings SET status = 'посетил' WHERE booking_id = 1;

-- Обновить статус оборудования
UPDATE Equipment SET status = 'на ремонте' WHERE equipment_id = 2;

-- Обновить цену услуги
UPDATE Services SET price = 1200 WHERE service_id = 1;


-- delete_data.sql
-- Удалить клиента
DELETE FROM Clients WHERE client_id = 2;

-- Удалить запись на занятие
DELETE FROM Bookings WHERE booking_id = 2;

-- Удалить услугу
DELETE FROM Services WHERE service_id = 2;

-- Удалить оборудование
DELETE FROM Equipment WHERE equipment_id = 2;

-- Удалить абонемент
DELETE FROM Subscriptions WHERE subscription_id = 1;