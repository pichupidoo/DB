db = db.getSiblingDB('sport_center');

/* ===============================
   ПОДГОТОВКА
================================ */
db.logs.drop();
db.facilities.deleteOne({ _id: 1 });
db.users.deleteOne({ _id: 1 });
db.finance.deleteMany({ _id: {$in: [1,2]} });
db.activities.deleteMany({ _id: {$in: [1,2,3]} });

/* ===============================
   1️⃣ 1:N — ВСТРАИВАНИЕ
   ЗАЛ → ОБОРУДОВАНИЕ
================================ */
db.facilities.insertOne({
  _id: 1,
  type: "hall",
  name: "Зал №1",
  capacity: 30,
  equipment: [
    {
      equipment_id: 1,
      name: "Беговая дорожка",
      status: "исправно",
      serial_number: "SN-001"
    },
    {
      equipment_id: 2,
      name: "Велотренажер",
      status: "требует обслуживания",
      serial_number: "SN-002"
    }
  ]
});

print("\n1️⃣ 1:N (embedded) — Зал и оборудование:");
printjson(db.facilities.findOne({ _id: 1 }));

/* ===============================
   2️⃣ 1:N — ССЫЛКИ
   КЛИЕНТ → ПЛАТЕЖИ
================================ */
db.users.insertOne({
  _id: 1,
  role: "client",
  full_name: "Иванов Алексей"
});

db.finance.insertMany([
  {
    _id: 1,
    client_id: 1,
    subscription_id: 1,
    amount: 3500,
    method: "карта",
    date: new Date("2024-06-01")
  },
  {
    _id: 2,
    client_id: 1,
    subscription_id: 1,
    amount: 3500,
    method: "онлайн",
    date: new Date("2024-07-01")
  }
]);

db.finance.createIndex({ client_id: 1 });

print("\n2️⃣ 1:N (reference) — Платежи клиента:");
printjson(db.finance.find({ client_id: 1 }).toArray());

/* ===============================
   3️⃣ M:N — ПРОМЕЖУТОЧНАЯ КОЛЛЕКЦИЯ
   КЛИЕНТЫ ↔ ТРЕНИРОВКИ
================================ */
db.activities.insertMany([
  {
    _id: 1,
    type: "workout",
    hall_id: 1,
    trainer_id: 2,
    datetime: new Date("2025-02-10T18:00:00Z")
  },
  {
    _id: 2,
    type: "booking",
    client_id: 1,
    workout_id: 1,
    status: "записан",
    created_at: new Date()
  }
]);

db.activities.createIndex({ client_id: 1 });
db.activities.createIndex({ workout_id: 1 });

print("\n3️⃣ M:N — Тренировки клиента (через booking):");
printjson(
  db.activities.aggregate([
    { $match: { type: "booking", client_id: 1 } },
    {
      $lookup: {
        from: "activities",
        localField: "workout_id",
        foreignField: "_id",
        as: "workout"
      }
    },
    { $unwind: "$workout" }
  ]).toArray()
);