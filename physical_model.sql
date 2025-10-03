-- 01_physical_model.sql
-- Физическая модель базы данных для спортивного центра

-- Удаляем таблицы если существуют (для повторных запусков)
DROP TABLE IF EXISTS Reviews CASCADE;
DROP TABLE IF EXISTS Services CASCADE;
DROP TABLE IF EXISTS Sections CASCADE;
DROP TABLE IF EXISTS Bookings CASCADE;
DROP TABLE IF EXISTS Workouts CASCADE;
DROP TABLE IF EXISTS Equipment CASCADE;
DROP TABLE IF EXISTS Halls CASCADE;
DROP TABLE IF EXISTS Payments CASCADE;
DROP TABLE IF EXISTS Clients CASCADE;
DROP TABLE IF EXISTS Staff CASCADE;
DROP TABLE IF EXISTS Subscriptions CASCADE;

-- =============================
-- Таблица: Абонементы
-- =============================
CREATE TABLE Subscriptions (
    subscription_id SERIAL PRIMARY KEY,
    type VARCHAR(50) NOT NULL CHECK (type IN ('разовый', 'месячный', 'годовой')),
    price NUMERIC(10,2) NOT NULL CHECK (price >= 0)
);

-- =============================
-- Таблица: Клиенты
-- =============================
CREATE TABLE Clients (
    client_id SERIAL PRIMARY KEY,
    full_name VARCHAR(150) NOT NULL,
    birth_date DATE NOT NULL,
    gender VARCHAR(20) CHECK (gender IN ('м','ж','другое')),
    phone VARCHAR(20) UNIQUE NOT NULL,
    subscription_id INT REFERENCES Subscriptions(subscription_id)
);

-- =============================
-- Таблица: Сотрудники
-- =============================
CREATE TABLE Staff (
    staff_id SERIAL PRIMARY KEY,
    full_name VARCHAR(150) NOT NULL,
    position VARCHAR(100) NOT NULL,
    phone VARCHAR(20) UNIQUE NOT NULL
);

-- =============================
-- Таблица: Оплаты
-- =============================
CREATE TABLE Payments (
    payment_id SERIAL PRIMARY KEY,
    client_id INT NOT NULL REFERENCES Clients(client_id),
    subscription_id INT NOT NULL REFERENCES Subscriptions(subscription_id),
    amount NUMERIC(10,2) NOT NULL CHECK (amount >= 0),
    payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    method VARCHAR(50) NOT NULL CHECK (method IN ('карта','наличные','онлайн'))
);

-- =============================
-- Таблица: Залы
-- =============================
CREATE TABLE Halls (
    hall_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
);

-- =============================
-- Таблица: Оборудование
-- =============================
CREATE TABLE Equipment (
    equipment_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    hall_id INT NOT NULL REFERENCES Halls(hall_id) ON DELETE CASCADE,
    status VARCHAR(50) NOT NULL CHECK (status IN ('исправно','на ремонте','списано'))
);

-- =============================
-- Таблица: Занятия
-- =============================
CREATE TABLE Workouts (
    workout_id SERIAL PRIMARY KEY,
    datetime TIMESTAMP NOT NULL,
    hall_id INT NOT NULL REFERENCES Halls(hall_id),
    trainer_id INT NOT NULL REFERENCES Staff(staff_id)
);

-- =============================
-- Таблица: Записи на занятия
-- =============================
CREATE TABLE Bookings (
    booking_id SERIAL PRIMARY KEY,
    client_id INT NOT NULL REFERENCES Clients(client_id),
    class_id INT NOT NULL REFERENCES Workouts(workout_id),
    status VARCHAR(20) NOT NULL CHECK (status IN ('записан','отменил','посетил'))
);

-- =============================
-- Таблица: Секции
-- =============================
CREATE TABLE Sections (
    section_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    trainer_id INT NOT NULL REFERENCES Staff(staff_id)
);

-- =============================
-- Таблица: Услуги
-- =============================
CREATE TABLE Services (
    service_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price NUMERIC(10,2) NOT NULL CHECK (price >= 0),
    staff_id INT NOT NULL REFERENCES Staff(staff_id)
);

-- =============================
-- Таблица: Отзывы
-- =============================
CREATE TABLE Reviews (
    review_id SERIAL PRIMARY KEY,
    client_id INT NOT NULL REFERENCES Clients(client_id),
    target_type VARCHAR(20) NOT NULL CHECK (target_type IN ('занятие','услуга')),
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    review_date DATE NOT NULL DEFAULT CURRENT_DATE
);
