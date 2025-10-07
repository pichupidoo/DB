-- generate_data.sql
-- Добавляет тестовые данные к существующей физической модели (append-mode).
-- Учитывает таблицы: Subscriptions, Clients, Staff, Payments, Halls, Equipment,
-- Workouts, Bookings, Sections, Services, Reviews.
-- Настройки в начале можно изменить под вашу систему.

DO $$
DECLARE
  -- Параметры (подкорректируй при необходимости)
  v_new_subscriptions int := 0;     -- обычно 0, т.к. уже есть 3 типа
  v_new_staff int := 50;
  v_new_halls int := 2;
  v_new_equipment int := 300;
  v_new_services int := 1200;
  v_new_sections int := 50;
  v_new_clients int := 20000;
  v_new_workouts int := 200000;
  v_new_bookings int := 3200000;   -- целевая добавка в Bookings (по умолчанию ~3.2M)
  v_new_payments int := 160000;
  v_new_reviews int := 160000;

  v_batch int := 100000; -- размер батча для вставки Bookings (уменьшай если ОЗУ/IO слабые)

  base_staff_max int := 0;
  base_hall_max int := 0;
  base_service_max int := 0;
  base_client_max int := 0;
  base_workout_max int := 0;

  n_clients int;
  n_workouts int;

  iterations int;
  i int;
  offset_rows int;
  cur_batch int;
  sql text;
BEGIN
  -- === Подстраховка: если нет subscriptions, добавим стандартные три типа ===
  IF (SELECT COUNT(*) FROM subscriptions) = 0 THEN
    RAISE NOTICE 'Subscriptions пустые — создаём 3 стандартных типа.';
    INSERT INTO subscriptions(type, price)
      VALUES ('разовый', 500.00),
             ('месячный', 3500.00),
             ('годовой', 30000.00);
  END IF;

  -- Берём текущие максимумы (чтобы генерировать уникальные телефоны и имена)
  base_staff_max := COALESCE((SELECT MAX(staff_id) FROM staff), 0);
  base_hall_max := COALESCE((SELECT MAX(hall_id) FROM halls), 0);
  base_service_max := COALESCE((SELECT MAX(service_id) FROM services), 0);
  base_client_max := COALESCE((SELECT MAX(client_id) FROM clients), 0);
  base_workout_max := COALESCE((SELECT MAX(workout_id) FROM workouts), 0);

  -- === 1) Staff (добавляем новых сотрудников) ===
  IF v_new_staff > 0 THEN
    INSERT INTO staff (full_name, position, phone)
    SELECT
      'Фамилия_' || (base_staff_max + g) || ' Имя_' || (base_staff_max + g) || ' Отч_' || (base_staff_max + g),
      CASE WHEN (base_staff_max + g) % 10 = 0 THEN 'менеджер'
           WHEN (base_staff_max + g) % 3 = 0 THEN 'тренер'
           ELSE 'администратор' END,
      -- уникальный телефон (основываем на base_staff_max чтобы избегать коллизий)
      '8' || lpad((700000000 + base_staff_max + g)::text,9,'0')
    FROM generate_series(1, v_new_staff) AS g;
    RAISE NOTICE 'Inserted % new staff', v_new_staff;
  END IF;

  -- === 2) Halls ===
  IF v_new_halls > 0 THEN
    INSERT INTO halls (name)
    SELECT
      CASE WHEN (base_hall_max + g) = 1 THEN 'Тренажёрный зал'
           WHEN (base_hall_max + g) = 2 THEN 'Бассейн'
           WHEN (base_hall_max + g) = 3 THEN 'Йога-зал'
           WHEN (base_hall_max + g) = 4 THEN 'Зал для груп. тренировок'
           ELSE 'Зал_' || (base_hall_max + g) END
    FROM generate_series(1, v_new_halls) AS g;
    RAISE NOTICE 'Inserted % new halls', v_new_halls;
  END IF;

  -- === 3) Services (привязаны к staff) ===
  IF v_new_services > 0 THEN
    INSERT INTO services (name, price, staff_id)
    SELECT
      CASE (g % 5)
        WHEN 0 THEN 'Персональная тренировка'
        WHEN 1 THEN 'Массаж'
        WHEN 2 THEN 'Консультация диетолога'
        WHEN 3 THEN 'Групповая тренировка'
        ELSE 'Анализ состава тела'
      END,
      (500 + (g % 3000))::numeric,
      -- привязка к реальному staff_id (берём случайный существующий сотрудник)
      (SELECT staff_id FROM staff ORDER BY random() LIMIT 1)
    FROM generate_series(1, v_new_services) AS g;
    RAISE NOTICE 'Inserted % new services', v_new_services;
  END IF;

  -- === 4) Sections (привязаны к trainer_id из Staff) ===
  IF v_new_sections > 0 THEN
    INSERT INTO sections (name, trainer_id)
    SELECT
      'Секция_' || (base_service_max + g),
      (SELECT staff_id FROM staff ORDER BY random() LIMIT 1)
    FROM generate_series(1, v_new_sections) AS g;
    RAISE NOTICE 'Inserted % new sections', v_new_sections;
  END IF;

  -- === 5) Equipment (привязан к halls) ===
  IF v_new_equipment > 0 THEN
    -- подготовим список hall_id в массив, чтобы не делать ORDER BY random для каждой строки
    -- но для простоты используем выбор по модулю: создадим временную таблицу с rn
    CREATE TEMP TABLE __tmp_halls AS SELECT hall_id, row_number() OVER (ORDER BY hall_id) AS rn FROM halls;
    PERFORM setseed((extract(epoch from now()) % 1000000) / 500000.0 - 1); -- немного случайности
    INSERT INTO equipment (name, hall_id, status)
    SELECT
      'Оборудование_' || ( (base_service_max + g) ),
      (SELECT hall_id FROM __tmp_halls WHERE rn = ((g - 1) % (SELECT COUNT(*) FROM __tmp_halls)) + 1),
      CASE
        WHEN g % 37 = 0 THEN 'списано'
        WHEN g % 11 = 0 THEN 'на ремонте'
        ELSE 'исправно'
      END
    FROM generate_series(1, v_new_equipment) AS g;
    DROP TABLE IF EXISTS __tmp_halls;
    RAISE NOTICE 'Inserted % new equipment', v_new_equipment;
  END IF;

  -- === 6) Clients ===
  IF v_new_clients > 0 THEN
    INSERT INTO clients (full_name, birth_date, gender, phone, subscription_id)
    SELECT
      'Клиент_' || (base_client_max + g) || ' Фамилия_' || ((base_client_max + g) % 1000),
      (date '1955-01-01' + ((base_client_max + g) % 20000) * INTERVAL '1 day')::date,
      CASE ((base_client_max + g) % 3) WHEN 0 THEN 'м' WHEN 1 THEN 'ж' ELSE 'другое' END,
      '8' || lpad((700000000 + base_client_max + g)::text,9,'0'),
      -- подписка: берём случайную существующую subscription
      (SELECT subscription_id FROM subscriptions ORDER BY random() LIMIT 1)
    FROM generate_series(1, v_new_clients) AS g;
    RAISE NOTICE 'Inserted % new clients', v_new_clients;
  END IF;

  -- === 7) Workouts ===
  IF v_new_workouts > 0 THEN
    -- для trainer_id используем random staff, для hall_id random hall, и создаём распределение дат
    INSERT INTO workouts (datetime, hall_id, trainer_id)
    SELECT
      (timestamp '2021-01-01 06:00:00' + ((base_workout_max + g) % 1500) * INTERVAL '1 hour' + ((g % 60) * INTERVAL '1 minute')),
      (SELECT hall_id FROM halls ORDER BY random() LIMIT 1),
      (SELECT staff_id FROM staff ORDER BY random() LIMIT 1)
    FROM generate_series(1, v_new_workouts) AS g;
    RAISE NOTICE 'Inserted % new workouts', v_new_workouts;
  END IF;

  -- === Подготовка временных таблиц для эффективного маппинга при вставке Bookings ===
  -- Создаём temp таблицы с рн (row_number) для clients и workouts.
  DROP TABLE IF EXISTS __tmp_clients;
  DROP TABLE IF EXISTS __tmp_workouts;

  CREATE TEMP TABLE __tmp_clients AS
    SELECT client_id, row_number() OVER (ORDER BY client_id) AS rn FROM clients;

  CREATE TEMP TABLE __tmp_workouts AS
    SELECT workout_id, row_number() OVER (ORDER BY workout_id) AS rn FROM workouts;

  n_clients := (SELECT COUNT(*) FROM __tmp_clients);
  n_workouts := (SELECT COUNT(*) FROM __tmp_workouts);

  IF n_clients = 0 THEN
    RAISE EXCEPTION 'В таблице clients нет записей. Добавь клиентов или уменьши параметры.';
  END IF;
  IF n_workouts = 0 THEN
    RAISE EXCEPTION 'В таблице workouts нет записей. Добавь занятия или уменьши параметры.';
  END IF;

    -- === 8) Bookings (побатчовая вставка, каждый батч -- v_batch строк) ===
  IF v_new_bookings > 0 THEN
    RAISE NOTICE 'Start inserting % bookings in batches of % (clients=%, workouts=%)',
      v_new_bookings, v_batch, n_clients, n_workouts;

    iterations := CEIL(v_new_bookings::numeric / v_batch::numeric)::int;
    FOR i IN 0..iterations-1 LOOP
      offset_rows := i * v_batch;
      cur_batch := LEAST(v_batch, v_new_bookings - offset_rows);

      sql := format($f$
        INSERT INTO bookings (client_id, class_id, status)
        SELECT c.client_id, w.workout_id,
          CASE WHEN gs.g %% 20 = 0 THEN 'отменил'
               WHEN gs.g %% 5 = 0 THEN 'записан'
               ELSE 'посетил' END
        FROM generate_series(1, %s) AS gs(g)
        JOIN __tmp_clients c ON c.rn = ((gs.g - 1 + %s) %% %s) + 1
        JOIN __tmp_workouts w ON w.rn = ((gs.g - 1 + %s) %% %s) + 1
        ;
      $f$, cur_batch, offset_rows, n_clients, offset_rows, n_workouts);

      EXECUTE sql;

      RAISE NOTICE 'Batch % of % inserted % bookings (offset %)',
        i+1, iterations, cur_batch, offset_rows;
    END LOOP;

    RAISE NOTICE 'All bookings inserted: % rows added', v_new_bookings;
  END IF;


  -- === 9) Payments (добавляем платежи, привязанные к существующим клиентам и подпискам) ===
  IF v_new_payments > 0 THEN
    INSERT INTO payments (client_id, subscription_id, amount, payment_date, method)
    SELECT
      (SELECT client_id FROM clients ORDER BY random() LIMIT 1),
      (SELECT subscription_id FROM subscriptions ORDER BY random() LIMIT 1),
      CASE WHEN s.type = 'разовый' THEN 500.00
           WHEN s.type = 'месячный' THEN 3000.00
           WHEN s.type = 'годовой' THEN 30000.00
           ELSE 1000.00 END
        + ((g % 500)::numeric / 10),
      (current_date - (g % 700)),
      CASE (g % 3) WHEN 0 THEN 'карта' WHEN 1 THEN 'наличные' ELSE 'онлайн' END
    FROM generate_series(1, v_new_payments) g
    LEFT JOIN LATERAL (SELECT type FROM subscriptions ORDER BY random() LIMIT 1) s ON true;
    RAISE NOTICE 'Inserted % new payments', v_new_payments;
  END IF;

  -- === 10) Reviews ===
  IF v_new_reviews > 0 THEN
    INSERT INTO reviews (client_id, target_type, rating, comment, review_date)
    SELECT
      (SELECT client_id FROM clients ORDER BY random() LIMIT 1),
      CASE WHEN (g % 2) = 0 THEN 'занятие' ELSE 'услуга' END,
      1 + (g % 5),
      'Комментарий ' || (g + (SELECT COALESCE(MAX(review_id),0) FROM reviews)),
      (current_date - (g % 700))
    FROM generate_series(1, v_new_reviews) AS g;
    RAISE NOTICE 'Inserted % new reviews', v_new_reviews;
  END IF;

  -- === 11) Обновление последовательностей (если необходимо) ===
  -- (это полезно если где-то вручную вставлялись id — но мы в основном использовали автогенерацию)
  PERFORM setval(pg_get_serial_sequence('subscriptions','subscription_id'), COALESCE((SELECT MAX(subscription_id) FROM subscriptions),0));
  PERFORM setval(pg_get_serial_sequence('clients','client_id'), COALESCE((SELECT MAX(client_id) FROM clients),0));
  PERFORM setval(pg_get_serial_sequence('staff','staff_id'), COALESCE((SELECT MAX(staff_id) FROM staff),0));
  PERFORM setval(pg_get_serial_sequence('payments','payment_id'), COALESCE((SELECT MAX(payment_id) FROM payments),0));
  PERFORM setval(pg_get_serial_sequence('halls','hall_id'), COALESCE((SELECT MAX(hall_id) FROM halls),0));
  PERFORM setval(pg_get_serial_sequence('equipment','equipment_id'), COALESCE((SELECT MAX(equipment_id) FROM equipment),0));
  PERFORM setval(pg_get_serial_sequence('workouts','workout_id'), COALESCE((SELECT MAX(workout_id) FROM workouts),0));
  PERFORM setval(pg_get_serial_sequence('bookings','booking_id'), COALESCE((SELECT MAX(booking_id) FROM bookings),0));
  PERFORM setval(pg_get_serial_sequence('sections','section_id'), COALESCE((SELECT MAX(section_id) FROM sections),0));
  PERFORM setval(pg_get_serial_sequence('services','service_id'), COALESCE((SELECT MAX(service_id) FROM services),0));
  PERFORM setval(pg_get_serial_sequence('reviews','review_id'), COALESCE((SELECT MAX(review_id) FROM reviews),0));

  -- Финальный отчёт
  RAISE NOTICE 'Генерация завершена. Totals: clients=%, workouts=%, bookings=%',
    (SELECT COUNT(*) FROM clients),
    (SELECT COUNT(*) FROM workouts),
    (SELECT COUNT(*) FROM bookings);

END $$;
