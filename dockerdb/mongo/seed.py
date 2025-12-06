import json
import random
from datetime import datetime, timedelta

# --- Настройки ---
NUM_CLIENTS = 280      # клиенты с _id от 1003
NUM_STAFF = 20         # сотрудники с _id от 5003
NUM_WORKOUTS = 120     # тренировки
NUM_BOOKINGS = 50      # бронирования
NUM_SERVICES = 20      # доп. услуги
NUM_REVIEWS = 10       # отзывы
NUM_PAYMENTS = 200     # платежи

# --- Вспомогательные данные ---
male_names = ["Алексей", "Дмитрий", "Сергей", "Андрей", "Максим", "Игорь", "Павел", "Артём", "Роман", "Владимир"]
female_names = ["Елена", "Ольга", "Татьяна", "Наталья", "Мария", "Дарья", "Анастасия", "Екатерина", "Оксана", "Ирина"]
surnames = ["Иванов", "Смирнов", "Козлов", "Попов", "Соколов", "Лебедев", "Новиков", "Морозов", "Федоров", "Кузнецов"]
positions = ["тренер", "администратор", "инструктор", "менеджер"]
hall_ids = [10, 11, 12, 13, 14]
trainer_ids = [5001, 5002, 5003, 5004, 5005]
client_ids = list(range(1001, 1001 + 2 + NUM_CLIENTS))  # включая тех, что уже есть
section_ids = [30, 31, 32, 33, 34, 35, 36]
service_ids = list(range(41, 41 + NUM_SERVICES))
workout_ids = list(range(3001, 3001 + NUM_WORKOUTS))

# --- Генерация users ---
users = []

# Уже существующие не дублируем — начинаем с 1003 и 5003
for i in range(NUM_CLIENTS):
    _id = 1003 + i
    gender = random.choice(["м", "ж"])
    if gender == "м":
        name = random.choice(surnames) + " " + random.choice(male_names)
    else:
        name = random.choice(surnames) + "а " + random.choice(female_names)
        if name.startswith("Козлов"): name = "Козлова " + random.choice(female_names)
    birth_date = (datetime(1980, 1, 1) + timedelta(days=random.randint(10000, 18000))).strftime("%Y-%m-%d")
    phone = "+79" + str(random.randint(100000000, 999999999))
    sub_id = random.choice([1, 2])
    users.append({
        "_id": _id,
        "role": "client",
        "full_name": name,
        "birth_date": birth_date,
        "gender": gender,
        "phone": phone,
        "subscription_id": sub_id
    })

for i in range(NUM_STAFF):
    _id = 5003 + i
    name = random.choice(surnames) + " " + random.choice(male_names + female_names)
    pos = random.choice(positions)
    phone = "+79" + str(random.randint(100000000, 999999999))
    users.append({
        "_id": _id,
        "role": "staff",
        "full_name": name,
        "position": pos,
        "phone": phone
    })

# --- Генерация facilities (дополнение) ---
facilities = [
    {"_id": 12, "type": "hall", "name": "Зал №3", "equipment": [{"equipment_id": 205, "name": "Эллиптический тренажер", "status": "исправно"}, {"equipment_id": 206, "name": "Гребной тренажер", "status": "исправно"}]},
    {"_id": 13, "type": "hall", "name": "Зал №4", "equipment": [{"equipment_id": 207, "name": "Скамья", "status": "исправно"}, {"equipment_id": 208, "name": "Тяга верхняя", "status": "на ремонте"}]},
    {"_id": 14, "type": "hall", "name": "Зал кардио", "equipment": [{"equipment_id": 209, "name": "Велотренажер", "status": "исправно"}, {"equipment_id": 210, "name": "Беговая дорожка", "status": "исправно"}]},
    {"_id": 32, "type": "section", "name": "Кроссфит", "trainer_id": 5003},
    {"_id": 33, "type": "section", "name": "Стретчинг", "trainer_id": 5005},
    {"_id": 34, "type": "section", "name": "Бокс", "trainer_id": 5003},
    {"_id": 35, "type": "section", "name": "Танцы", "trainer_id": 5005},
    {"_id": 36, "type": "section", "name": "Плавание", "trainer_id": 5001}
]

# --- Генерация activities ---
activities = []

# Тренировки
for i in range(NUM_WORKOUTS):
    wid = 3003 + i
    dt = datetime(2025, 2, 5) + timedelta(days=random.randint(0, 30), hours=random.randint(8, 20))
    activities.append({
        "_id": wid,
        "type": "workout",
        "datetime": dt.strftime("%Y-%m-%dT%H:%M:%S"),
        "hall_id": random.choice(hall_ids),
        "trainer_id": random.choice(trainer_ids)
    })

# Бронирования
for i in range(NUM_BOOKINGS):
    bid = 40003 + i
    cid = random.choice(client_ids)
    wid = random.choice(workout_ids[:len(workout_ids)//2])  # только первые тренировки
    status = random.choice(["записан", "посетил", "отменён"])
    activities.append({
        "_id": bid,
        "type": "booking",
        "client_id": cid,
        "workout_id": wid,
        "status": status
    })

# Услуги
for i in range(NUM_SERVICES):
    sid = 43 + i
    name = random.choice(["Групповая тренировка", "Консультация", "Массаж шеи", "Разминка", "Диагностика"])
    price = random.choice([500, 800, 1000, 1500, 2200])
    staff_id = random.choice(trainer_ids)
    activities.append({
        "_id": sid,
        "type": "service",
        "name": name,
        "price": price,
        "staff_id": staff_id
    })

# Отзывы
for i in range(NUM_REVIEWS):
    rid = 7703 + i
    cid = random.choice(client_ids)
    if random.choice([True, False]):
        target = {"type": "service", "id": random.choice(service_ids)}
    else:
        target = {"type": "workout", "id": random.choice(workout_ids)}
    rating = random.randint(3, 5)
    comments = ["Отлично!", "Хорошо", "Супер тренер!", "Рекомендую", "Нормально"]
    activities.append({
        "_id": rid,
        "type": "review",
        "client_id": cid,
        "target": target,
        "rating": rating,
        "comment": random.choice(comments),
        "review_date": (datetime(2025, 2, 1) + timedelta(days=random.randint(0, 10))).strftime("%Y-%m-%d")
    })

# --- Генерация finance (платежи) ---
finance = []

for i in range(NUM_PAYMENTS):
    fid = 9003 + i
    cid = random.choice(client_ids)
    sub_id = random.choice([1, 2])
    amount = 3500 if sub_id == 1 else 29000
    method = random.choice(["карта", "онлайн", "наличные"])
    date = (datetime(2025, 1, 1) + timedelta(days=random.randint(0, 60))).strftime("%Y-%m-%d")
    finance.append({
        "_id": fid,
        "type": "payment",
        "client_id": cid,
        "subscription_id": sub_id,
        "amount": amount,
        "method": method,
        "date": date
    })

# --- Сохранение в файлы (в формате JSON Lines) ---
def save_json_lines(data, filename):
    with open(filename, 'w', encoding='utf-8') as f:
        for item in data:
            f.write(json.dumps(item, ensure_ascii=False) + '\n')

save_json_lines(users, 'users.seed.json')
save_json_lines(facilities, 'facilities.seed.json')
save_json_lines(activities, 'activities.seed.json')
save_json_lines(finance, 'finance.seed.json')

print(f"   Сгенерировано:")
print(f"   users: {len(users)}")
print(f"   facilities: {len(facilities)}")
print(f"   activities: {len(activities)}")
print(f"   finance: {len(finance)}")
print(f"   ВСЕГО: {len(users)+len(facilities)+len(activities)+len(finance)} документов")
print("\nФайлы сохранены в текущую папку.")