import json
import random
import uuid
from datetime import datetime, timedelta, timezone
from typing import Generator, Dict, Any

# --- КОНФИГУРАЦИЯ (ваши параметры + расширения) ---
NUM_CLIENTS = 280000      # Клиенты (было 280)
NUM_STAFF = 200           # Сотрудники (было 20)
NUM_WORKOUTS = 100    # Тренировки (было 120)
NUM_BOOKINGS = 100000     # Бронирования (было 50)
NUM_SERVICES = 5000       # Услуги (было 20)
NUM_REVIEWS = 50000       # Отзывы (было 10)
NUM_PAYMENTS = 300000     # Платежи (было 200)
NUM_SESSION_LOGS = 50000  # Логи сессий для TTL-индекса

# --- ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ ---
used_phones = set()
client_ids = list(range(1001, 1001 + NUM_CLIENTS + 2))  # Все ID клиентов
staff_ids = list(range(NUM_CLIENTS + 3, NUM_CLIENTS + NUM_STAFF))
workout_ids = list(range(3001, 3001 + NUM_WORKOUTS))
booking_ids = list(range(40000, 40000 + NUM_BOOKINGS))
service_ids = list(range(60000, 60000 + NUM_SERVICES))

# --- ВСПОМОГАТЕЛЬНЫЕ ДАННЫЕ ---
male_names = ["Алексей", "Дмитрий", "Сергей", "Андрей", "Максим", "Игорь", "Павел", "Артём", "Роман", "Владимир", "Михаил", "Николай", "Александр", "Константин", "Юрий"]
female_names = ["Елена", "Ольга", "Татьяна", "Наталья", "Мария", "Дарья", "Анастасия", "Екатерина", "Оксана", "Ирина", "Светлана", "Виктория", "Анна", "Ксения", "Полина"]
surnames = ["Иванов", "Смирнов", "Козлов", "Попов", "Соколов", "Лебедев", "Новиков", "Морозов", "Федоров", "Кузнецов", "Петров", "Волков", "Соловьёв", "Васильев", "Зайцев"]
positions = ["тренер", "администратор", "инструктор", "менеджер", "массажист", "диетолог"]
hall_ids = [10, 11, 12, 13, 14, 15, 16, 17, 18, 19]  # Расширено
trainer_ids = staff_ids[:10]  # Первые 10 сотрудников — тренеры
equipment_types = [
    {"name": "Беговая дорожка", "base_status": ["исправно", "требует обслуживания"]},
    {"name": "Велотренажер", "base_status": ["исправно", "требует обслуживания", "на ремонте"]},
    {"name": "Эллиптический тренажер", "base_status": ["исправно", "требует обслуживания"]},
    {"name": "Гантели", "base_status": ["исправно"]},
    {"name": "Штанга", "base_status": ["исправно", "требует обслуживания"]},
    {"name": "Тренажер для пресса", "base_status": ["исправно", "на ремонте"]}
]

# --- ГЕНЕРАТОРЫ ДАННЫХ (оптимизация памяти) ---
def generate_users() -> Generator[Dict[str, Any], None, None]:
    """Генератор пользователей с уникальными телефонами"""
    # Существующие пользователи (1001, 1002)
    yield {
        "_id": 1001,
        "role": "client",
        "full_name": "Иванов Иван",
        "birth_date": "1985-03-15",
        "gender": "м",
        "phone": "+79991112233",
        "subscription_id": 1,
        "tags": ["новичок", "активный"]
    }
    yield {
        "_id": 1002,
        "role": "client",
        "full_name": "Петрова Анна",
        "birth_date": "1992-07-22",
        "gender": "ж",
        "phone": "+79994445566",
        "subscription_id": 2,
        "reviews": [
            {
                "review_id": 7701,
                "rating": 5,
                "comment": "Отличный зал!",
                "date": "2025-02-10"
            }
        ]
    }

    # Генерация клиентов
    for i in range(NUM_CLIENTS):
        _id = 1003 + i
        
        # Уникальный телефон
        while True:
            phone = f"+79{random.randint(100000000, 999999999)}"
            if phone not in used_phones:
                used_phones.add(phone)
                break
        
        # Случайное имя
        gender = random.choice(["м", "ж"])
        if gender == "м":
            name = f"{random.choice(surnames)} {random.choice(male_names)}"
        else:
            surname = random.choice(surnames)
            if surname in ["Козлов", "Морозов", "Соколов"]:
                surname = f"{surname}а"
            name = f"{surname} {random.choice(female_names)}"
        
        # 10% клиентов — с медицинскими ограничениями (реалистичность)
        medical_history = None
        if random.random() < 0.1:
            medical_history = random.choice([
                "Гипертония 1 степени",
                "Проблемы с суставами",
                "Сахарный диабет 2 типа",
                "Нет ограничений"
            ])
        
        user = {
            "_id": _id,
            "role": "client",
            "full_name": name,
            "birth_date": (datetime(1970, 1, 1) + timedelta(days=random.randint(9000, 18000))).strftime("%Y-%m-%d"),
            "gender": gender,
            "phone": phone,
            "subscription_id": random.choice([1, 2]),
            "created_at": (datetime.utcnow() - timedelta(days=random.randint(0, 365))).replace(tzinfo=timezone.utc).isoformat(),
            "last_visit": (datetime.utcnow() - timedelta(hours=random.randint(0, 72))).replace(tzinfo=timezone.utc).isoformat()
        }
        
        if medical_history:
            user["medical_history"] = medical_history
        
        yield user

    # Генерация сотрудников
    for i in range(NUM_STAFF):
        _id = NUM_CLIENTS + 1010 + i
        name = f"{random.choice(surnames)} {random.choice(male_names + female_names)}"
        position = random.choice(positions)
        
        # Уникальный телефон для сотрудников
        while True:
            phone = f"+79{random.randint(100000000, 999999999)}"
            if phone not in used_phones:
                used_phones.add(phone)
                break
        
        yield {
            "_id": _id,
            "role": "staff",
            "full_name": name,
            "position": position,
            "phone": phone,
            "hire_date": (datetime(2020, 1, 1) + timedelta(days=random.randint(0, 1800))).strftime("%Y-%m-%d"),
            "specialization": random.choice(["кардио", "силовые", "групповые"]) if position == "тренер" else None,
            "rating": round(random.uniform(4.0, 5.0), 1)
        }

def generate_facilities() -> Generator[Dict[str, Any], None, None]:
    """Генератор залов и секций с оборудованием"""
    # Секции (не меняются)
    sections = [
        {"_id": 30, "type": "section", "name": "Йога", "trainer_id": random.choice(trainer_ids)},
        {"_id": 31, "type": "section", "name": "Пилатес", "trainer_id": random.choice(trainer_ids)},
        {"_id": 32, "type": "section", "name": "Кроссфит", "trainer_id": random.choice(trainer_ids)},
        {"_id": 33, "type": "section", "name": "Стретчинг", "trainer_id": random.choice(trainer_ids)},
        {"_id": 34, "type": "section", "name": "Бокс", "trainer_id": random.choice(trainer_ids)},
        {"_id": 35, "type": "section", "name": "Танцы", "trainer_id": random.choice(trainer_ids)},
        {"_id": 36, "type": "section", "name": "Плавание", "trainer_id": random.choice(trainer_ids)}
    ]
    
    for section in sections:
        yield section

    # Генерация 10 000 залов
    for hall_id in range(100, 10100):
        num_equipment = random.randint(5, 20)  # 5-20 единиц оборудования
        equipment = []
        
        for eq_id in range(1, num_equipment + 1):
            eq_type = random.choice(equipment_types)
            # 15% оборудования — требует обслуживания
            status = "требует обслуживания" if random.random() < 0.15 else random.choice(eq_type["base_status"])
            
            equipment.append({
                "equipment_id": eq_id,
                "name": eq_type["name"],
                "status": status,
                "last_maintenance": (datetime.utcnow() - timedelta(days=random.randint(0, 180))).replace(tzinfo=timezone.utc).isoformat(),
                "serial_number": f"SN-{uuid.uuid4().hex[:8].upper()}"
            })
        
        # 5% залов — с камерами наблюдения (реалистичность)
        has_cameras = random.random() < 0.05
        
        yield {
            "_id": hall_id,
            "type": "hall",
            "name": f"Зал №{hall_id}",
            "capacity": random.randint(10, 50),
            "equipment": equipment,
            "location": random.choice(["1 этаж", "2 этаж", "3 этаж", "подвал"]),
            "has_cameras": has_cameras,
            "created_at": (datetime.utcnow() - timedelta(days=random.randint(0, 1000))).replace(tzinfo=timezone.utc).isoformat()
        }

def generate_activities() -> Generator[Dict[str, Any], None, None]:
    """Генератор активностей (тренировки, бронирования, услуги, отзывы)"""
    # 1. Тренировки (150k)
    for i in range(NUM_WORKOUTS):
        wid = 3001 + i
        
        # 40% тренировок — в зале 14 в феврале 2025 (для теста индекса)
        if i < NUM_WORKOUTS * 0.4:
            hall_id = 14
            base_date = datetime(2025, 2, 1)
            dt = base_date + timedelta(
                days=random.randint(0, 28),
                hours=random.randint(8, 22),
                minutes=random.choice([0, 30])
            )
        else:
            hall_id = random.choice(hall_ids)
            base_date = datetime(2025, 1, 1)
            dt = base_date + timedelta(
                days=random.randint(0, 365),
                hours=random.randint(6, 22),
                minutes=random.choice([0, 15, 30, 45])
            )
        
        # Для 30% тренировок — добавляем поле current_participants
        current_participants = None
        max_participants = None
        if random.random() < 0.3 and hall_id != 14:  # В зале 14 — только кардио, без групп
            max_participants = random.randint(5, 20)
            current_participants = random.randint(0, max_participants)
        
        activity = {
            "_id": wid,
            "type": "workout",
            "datetime": dt.replace(tzinfo=timezone.utc).isoformat(),
            "hall_id": hall_id,
            "trainer_id": random.choice(trainer_ids),
            "section_id": random.choice([30, 31, 32, 33, 34, 35, 36]) if hall_id != 14 else None
        }
        
        if current_participants is not None:
            activity["current_participants"] = current_participants
            activity["max_participants"] = max_participants
        
        yield activity

    # 2. Бронирования (100k)
    for i in range(NUM_BOOKINGS):
        bid = NUM_WORKOUTS + 3010 + i
        cid = random.choice(client_ids)
        wid = random.choice(workout_ids)
        
        # 25% бронирований — активные ("записан")
        # 60% — посещенные
        # 15% — отмененные
        status_weights = [0.25, 0.60, 0.15]
        status = random.choices(["записан", "посетил", "отменён"], weights=status_weights)[0]
        
        # Для активных бронирований — свежие даты
        if status == "записан":
            dt = datetime.utcnow() + timedelta(days=random.randint(1, 30))
        else:
            dt = datetime.utcnow() - timedelta(days=random.randint(1, 365))
        
        yield {
            "_id": bid,
            "type": "booking",
            "client_id": cid,
            "workout_id": wid,
            "status": status,
            "datetime": dt.replace(tzinfo=timezone.utc).isoformat(),
            "created_at": (dt - timedelta(hours=random.randint(1, 72))).replace(tzinfo=timezone.utc).isoformat()
        }

    # 3. Услуги (5k)
    service_names = [
        "Персональная тренировка", "Групповая тренировка", "Консультация", 
        "Массаж шеи", "Массаж спины", "Разминка", "Диагностика", 
        "Питание", "Восстановление", "Йога-сессия"
    ]
    
    for i in range(NUM_SERVICES):
        sid = NUM_WORKOUTS + NUM_BOOKINGS + 3010 + i
        name = random.choice(service_names)
        base_price = {
            "Персональная тренировка": 3000,
            "Групповая тренировка": 1500,
            "Консультация": 2000,
            "Массаж шеи": 1800,
            "Массаж спины": 2500,
            "Разминка": 1000,
            "Диагностика": 2200,
            "Питание": 4000,
            "Восстановление": 3500,
            "Йога-сессия": 2000
        }
        
        price = base_price.get(name, 1500) * random.uniform(0.9, 1.2)
        staff_id = random.choice(staff_ids)
        
        yield {
            "_id": sid,
            "type": "service",
            "name": name,
            "price": round(price, 2),
            "staff_id": staff_id,
            "duration_minutes": random.choice([30, 45, 60, 90]),
            "created_at": (datetime.utcnow() - timedelta(days=random.randint(0, 365))).replace(tzinfo=timezone.utc).isoformat()
        }

    # 4. Отзывы (50k)
    for i in range(NUM_REVIEWS):
        rid = NUM_WORKOUTS + NUM_BOOKINGS + NUM_SERVICES + 3010 + i
        cid = random.choice(client_ids)
        
        # 70% отзывов — о тренировках, 30% — об услугах
        if random.random() < 0.7:
            target = {
                "type": "workout",
                "id": random.choice(workout_ids)
            }
        else:
            target = {
                "type": "service",
                "id": random.choice(service_ids)
            }
        
        rating = random.choices(
            [1, 2, 3, 4, 5],
            weights=[0.01, 0.04, 0.15, 0.30, 0.50]  # Больше позитивных
        )[0]
        
        comments = {
            1: ["Ужасно!", "Никогда больше не приду", "Тренер не профессионал"],
            2: ["Плохо", "Неудобное расписание", "Плохое оборудование"],
            3: ["Нормально", "Можно лучше", "Средний зал"],
            4: ["Хорошо", "Понравился тренер", "Удобное расположение"],
            5: ["Отлично!", "Супер тренер!", "Рекомендую", "Лучший фитнес-центр!"]
        }
        
        yield {
            "_id": rid,
            "type": "review",
            "client_id": cid,
            "target": target,
            "rating": rating,
            "comment": random.choice(comments[rating]),
            "review_date": (datetime.utcnow() - timedelta(days=random.randint(0, 365))).replace(tzinfo=timezone.utc).isoformat()
        }

def generate_finance() -> Generator[Dict[str, Any], None, None]:
    """Генератор финансовых операций"""
    payment_methods = ["карта", "онлайн", "наличные", "перевод"]
    subscription_types = {
        1: {"name": "Стандарт", "base_price": 3500},
        2: {"name": "Премиум", "base_price": 29000}
    }
    
    for i in range(NUM_PAYMENTS):
        fid = 80000 + i
        cid = random.choice(client_ids)
        sub_id = random.choice([1, 2])
        
        # Базовая цена + сезонный коэффициент
        base_price = subscription_types[sub_id]["base_price"]
        month = random.randint(1, 12)
        season_coef = 1.2 if month in [6, 7, 8] else 1.0  # Летом дороже
        amount = base_price * season_coef * random.uniform(0.95, 1.05)
        
        method = random.choice(payment_methods)
        date = datetime(2024, 1, 1) + timedelta(days=random.randint(0, 730))
        
        # 5% платежей — с возвратом (реалистичность)
        is_refunded = random.random() < 0.05
        refund_amount = round(amount * 0.8, 2) if is_refunded else None
        
        payment = {
            "_id": fid,
            "type": "payment",
            "client_id": cid,
            "subscription_id": sub_id,
            "amount": round(amount, 2),
            "method": method,
            "date": date.replace(tzinfo=timezone.utc).isoformat(),
            "transaction_id": f"TXN-{uuid.uuid4().hex[:12].upper()}"
        }
        
        if is_refunded:
            payment["refunded"] = True
            payment["refund_amount"] = refund_amount
            payment["refund_date"] = (date + timedelta(days=random.randint(1, 30))).replace(tzinfo=timezone.utc).isoformat()
        
        yield payment

def generate_session_logs() -> Generator[Dict[str, Any], None, None]:
    """Генератор логов сессий для TTL-индекса"""
    actions = ["login", "booking_create", "booking_cancel", "payment", "schedule_view", "profile_update"]
    
    for i in range(NUM_SESSION_LOGS):
        # 70% записей — свежие (менее 1 часа)
        # 30% — старые (более 1 часа, для удаления TTL)
        if random.random() < 0.7:
            hours_ago = random.uniform(0, 1)
        else:
            hours_ago = random.uniform(1, 168)  # 1-7 дней
        
        created_at = datetime.utcnow() - timedelta(hours=hours_ago)
        
        yield {
            "_id": i,
            "user_id": random.choice(client_ids + staff_ids),
            "action": random.choice(actions),
            "ip_address": f"192.168.{random.randint(0, 255)}.{random.randint(0, 255)}",
            "user_agent": random.choice([
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
                "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X)",
                "Mozilla/5.0 (Linux; Android 11; SM-G998B)"
            ]),
            "created_at": created_at.replace(tzinfo=timezone.utc).isoformat(),
            "success": random.random() < 0.98  # 98% успешных действий
        }

# --- ПОТОКОВАЯ ЗАПИСЬ В ФАЙЛЫ ---
def save_json_array(generator: Generator[Dict[str, Any], None, None], filename: str):
    """Запись данных в файл как JSON-массив"""
    with open(filename, 'w', encoding='utf-8') as f:
        f.write('[\n')  # открываем массив
        first = True
        for i, item in enumerate(generator, 1):
            if not first:
                f.write(',\n')  # разделяем запятыми
            else:
                first = False
            f.write(json.dumps(item, ensure_ascii=False))
            if i % 50000 == 0:
                print(f"   ✅ Добавлено {i} документов в {filename}")
        f.write('\n]')  # закрываем массив
    print(f"✅ Файл {filename} сохранён как JSON-массив ({i} объектов)")

# --- ОСНОВНОЙ БЛОК ---
if __name__ == "__main__":
    print("🚀 Генерация продакшен-данных для тестирования индексов MongoDB")
    print("=" * 60)
    
    # 1. Пользователи
    print("\n👤 Генерация пользователей...")
    save_json_array(generate_users(), 'users.seed.json')
    
    # 2. Залы и оборудование
    print("\n🏋️ Генерация залов и оборудования...")
    save_json_array(generate_facilities(), 'facilities.seed.json')
    
    # 3. Активности
    print("\n🏃 Генерация активностей (тренировки, бронирования, услуги, отзывы)...")
    save_json_array(generate_activities(), 'activities.seed.json')
    
    # 4. Финансы
    print("\n💰 Генерация финансовых операций...")
    save_json_array(generate_finance(), 'finance.seed.json')
    
    # 5. Логи сессий для TTL
    #print("\n⏳ Генерация логов сессий для TTL-индекса...")
    #save_json_array(generate_session_logs(), 'session_logs.seed.json')
    
    print("\n✅ Генерация данных завершена!")
    print("=" * 60)
    print(f"📊 Статистика:")
    print(f"   • Пользователи: {NUM_CLIENTS + NUM_STAFF + 2} (клиенты + сотрудники)")
    print(f"   • Залы: 10,000 + 7 секций")
    print(f"   • Активности: {NUM_WORKOUTS + NUM_BOOKINGS + NUM_SERVICES + NUM_REVIEWS}")
    print(f"   • Финансы: {NUM_PAYMENTS}")
    print(f"   • Логи сессий: {NUM_SESSION_LOGS}")
    print(f"\n📁 Файлы сохранены в текущую директорию:")
    print("   • users.seed.json")
    print("   • facilities.seed.json")
    print("   • activities.seed.json")
    print("   • finance.seed.json")
    print("   • session_logs.seed.json")
    print("\n⚡ Следующие шаги:")
    print("   1. Загрузите данные в MongoDB через mongoimport")
    print("   2. Создайте индексы с помощью indexes_performance.js")
    print("   3. Протестируйте производительность до/после индексов")