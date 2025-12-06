-- === Симуляция пользовательской активности (запускать в цикле) ===

DO $$
DECLARE
  v_client_id INT;
  v_workout_id INT;
  v_service_id INT;
  v_new_client_id INT;
BEGIN
  -- 1. Выбираем случайного клиента
  SELECT client_id INTO v_client_id
  FROM clients
  ORDER BY random()
  LIMIT 1;

  -- 2. Проверяем расписание (SELECT с JOIN)
  PERFORM
    w.datetime,
    h.name AS hall,
    s.full_name AS trainer
  FROM workouts w
  JOIN halls h ON w.hall_id = h.hall_id
  JOIN staff s ON w.trainer_id = s.staff_id
  WHERE w.datetime BETWEEN NOW() AND NOW() + INTERVAL '7 days'
  ORDER BY w.datetime
  LIMIT 5;

    -- 3. Записываемся на случайное занятие (если ещё не записаны)
  SELECT workout_id INTO v_workout_id
  FROM workouts
  ORDER BY random()
  LIMIT 1;

  IF v_workout_id IS NOT NULL THEN
    INSERT INTO bookings (client_id, class_id, status)
    SELECT v_client_id, v_workout_id, 'записан'
    WHERE NOT EXISTS (
      SELECT 1 FROM bookings
      WHERE client_id = v_client_id AND class_id = v_workout_id
    );
  END IF;

  -- 4. С вероятностью 30% — посещаем занятие (обновляем статус)
  IF random() < 0.3 THEN
    UPDATE bookings
    SET status = 'посетил'
    WHERE booking_id = (
      SELECT booking_id
      FROM bookings
      WHERE client_id = v_client_id
        AND status = 'записан'
      ORDER BY booking_id DESC
      LIMIT 1
    );
  END IF;

  -- 5. С вероятностью 20% — отменяем запись
  IF random() < 0.2 THEN
    UPDATE bookings
    SET status = 'отменил'
    WHERE booking_id = (
      SELECT booking_id
      FROM bookings
      WHERE client_id = v_client_id
        AND status = 'записан'
      ORDER BY booking_id DESC
      LIMIT 1
    );
  END IF;

  -- 6. С вероятностью 15% — оставляем отзыв
  IF random() < 0.15 THEN
    -- Выбираем случайную услугу или занятие
    IF random() < 0.5 THEN
      -- Отзыв на занятие
      INSERT INTO reviews (client_id, target_type, rating, comment, review_date)
      VALUES (
        v_client_id,
        'занятие',
        3 + floor(random() * 3)::INT,
        'Хорошее занятие!',
        CURRENT_DATE
      );
    ELSE
      -- Отзыв на услугу
      SELECT service_id INTO v_service_id
      FROM services
      ORDER BY random()
      LIMIT 1;

      INSERT INTO reviews (client_id, target_type, rating, comment, review_date)
      VALUES (
        v_client_id,
        'услуга',
        3 + floor(random() * 3)::INT,
        'Рекомендую!',
        CURRENT_DATE
      );
    END IF;
  END IF;

  -- 7. С вероятностью 5% — новый клиент покупает абонемент
  IF random() < 0.05 THEN
    INSERT INTO clients (full_name, birth_date, gender, phone, subscription_id)
    VALUES (
      'Новый клиент ' || NOW(),
      CURRENT_DATE - (floor(random() * 10000) || ' days')::interval,
      CASE WHEN random() > 0.5 THEN 'м' ELSE 'ж' END,
      '+7999' || lpad(floor(1000000 + random() * 8999999)::text, 7, '0'),
      (SELECT subscription_id FROM subscriptions ORDER BY random() LIMIT 1)
    )
    RETURNING client_id INTO v_new_client_id;

    -- Оплата
    INSERT INTO payments (client_id, subscription_id, amount, payment_date, method)
    SELECT
      v_new_client_id,
      subscription_id,
      price,
      CURRENT_DATE,
      CASE WHEN random() > 0.7 THEN 'наличные' WHEN random() > 0.3 THEN 'карта' ELSE 'онлайн' END
    FROM subscriptions
    ORDER BY random()
    LIMIT 1;
  END IF;
END $$;