// Подключаемся к правильной БД
db = db.getSiblingDB('sport_center');

print("\n✅ Начало выполнения операций MongoDB");
print("========================================\n");

// Очистка тестовых данных перед запуском
db.users.deleteMany({ _id: { $in: [9990, 9999, 9998, 8888] } });
db.activities.deleteMany({ _id: { $in: [44000, 44001] } });
// === ДОБАВЛЕНИЕ ТЕСТОВЫХ ДАННЫХ ДЛЯ СТАБИЛЬНОГО ВЫВОДА ===

// 1. Гарантируем наличие хотя бы одного отменённого бронирования
db.activities.deleteOne({ _id: 99999 }); // удаляем, если уже есть
db.activities.insertOne({
  _id: 99999,
  type: "booking",
  status: "отменён",
  user_id: 1003,
  datetime: ISODate("2025-12-01T10:00:00Z")
});

// 2. Гарантируем наличие оборудования "на ремонте" в зале 13
const hall13 = db.facilities.findOne({ _id: 13 });
if (!hall13) {
  // если зала 13 нет — создаём минимальный
  db.facilities.insertOne({
    _id: 13,
    name: "Тестовый зал",
    equipment: [
      { equipment_id: 500, status: "на ремонте" }
    ]
  });
} else {
  // если есть — проверим, есть ли оборудование "на ремонте"
  const hasRepair = hall13.equipment && hall13.equipment.some(eq => eq.status === "на ремонте");
  if (!hasRepair) {
    // добавим, если нет
    db.facilities.updateOne(
      { _id: 13 },
      { $push: { equipment: { equipment_id: 500, status: "на ремонте" } } }
    );
  }
}

// 3. Убедимся, что у клиента 1003 нет тега "активный" (чтобы $addToSet всегда работал одинаково)

const client1003 = db.users.findOne({ _id: 1003 });
if (!client1003) {
  db.users.insertOne({
    _id: 1003,
    role: "client",
    full_name: "Тестовый Клиент",
    phone: "+70000000000",
    reviews: []
  });
} else if (!client1003.reviews) {
  db.users.updateOne({ _id: 1003 }, { $set: { reviews: [] } });
}
// 1. INSERT OPERATIONS
print("\n1️⃣ INSERT OPERATIONS");
print("---------------------");

// insertOne: Новый клиент
const newClient = {
  _id: 9999,
  role: "client",
  full_name: "Сидоров Сидор",
  birth_date: "1995-08-20",
  gender: "м",
  phone: "+79991234567",
  subscription_id: 1
};
const insertOneRes = db.users.insertOne(newClient);
print(`   ✅ insertOne: Добавлен клиент ID ${insertOneRes.insertedId}`);

// insertMany: Новые услуги
const newServices = [
  { _id:44000, type: "service", name: "Йога-студия", price: 1500, staff_id: 5004 },
  { _id:44001, type: "service", name: "ВИИТ-тренировка", price: 2000, staff_id: 5003 }
];
const insertManyRes = db.activities.insertMany(newServices);
const insertedCount = Object.keys(insertManyRes.insertedIds).length;
print(`   ✅ insertMany: Добавлено ${insertedCount} услуг`);

// 2. UPDATE OPERATIONS
print("\n2️⃣ UPDATE OPERATIONS");
print("---------------------");

// $set: Обновляем статус беговой дорожки
const setRes = db.facilities.updateOne(
  { _id: 14, "equipment.equipment_id": 210 },
  { $set: { "equipment.$.status": "требует обслуживания" } }
);
print(`   ✅ $set: Обновлен статус беговой дорожки (модифицировано: ${setRes.modifiedCount})`);

// $inc: Увеличиваем участников тренировки
const incRes = db.activities.updateOne(
  { _id: 3003, type: "workout" },
  { $inc: { current_participants: 1 } }
);
print(`   ✅ $inc: Увеличено количество участников (модифицировано: ${incRes.modifiedCount})`);

// $push: Добавляем отзыв клиенту 1003
if (db.users.findOne({ _id: 1003 })) {
  db.users.updateOne(
  { _id: 9999999, reviews: { $exists: false } },
  { $set: { reviews: [] } }
  );
  const pushRes = db.users.updateOne(
    { _id: 1003 },
    { 
      $push: { 
        reviews: {
          review_id: 7777,
          rating: 5,
          comment: "Отличный зал!",
          date: ISODate("2025-12-11")
        }
      } 
    }
  );
  print(`   ✅ $push: Добавлен отзыв клиенту 1003 (модифицировано: ${pushRes.modifiedCount})`);
}

// $addToSet: Добавляем тег ТОЛЬКО если его нет
const user1003 = db.users.findOne({ _id: 1003 }, { tags: 1 });
if (user1003 && user1003.tags && user1003.tags.includes("активный")) {
  print(`   ℹ️  Тег 'активный' уже существует у клиента 1003 — добавление пропущено`);
} else {
  const addToSetRes = db.users.updateOne(
    { _id: 1003 },
    { $addToSet: { tags: "активный" } }
  );
  print(`   ✅ $addToSet: Добавлен тег 'активный' (модифицировано: ${addToSetRes.modifiedCount})`);
}

// $arrayFilters: Обновляем оборудование со статусом "на ремонте"
const hasOnRepair = db.facilities.findOne({
  _id: 13,
  "equipment.status": "на ремонте"
});
if (hasOnRepair) {
  const arrayFilterRes = db.facilities.updateOne(
    { _id: 13 },
    { $set: { "equipment.$[elem].status": "в ремонте" } },
    { arrayFilters: [ { "elem.status": "на ремонте" } ] }
  );
  print(`   ✅ $arrayFilters: Обновлены статусы оборудования в зале 13 (модифицировано: ${arrayFilterRes.modifiedCount})`);
} else {
  print(`   ⚠️  В зале 13 нет оборудования со статусом "на ремонте" — обновление пропущено`);
}

// 3. DELETE OPERATION
print("\n3️⃣ DELETE OPERATION");
print("-------------------");
const hasCancelled = db.activities.countDocuments({ 
  type: "booking", 
  status: "отменён" 
});
if (hasCancelled > 0) {
  const deleteRes = db.activities.deleteMany({ 
    type: "booking", 
    status: "отменён" 
  });
  print(`   ✅ deleteMany: Удалено ${deleteRes.deletedCount} отменённых бронирований`);
} else {
  print(`   ℹ️  Нет отменённых бронирований для удаления`);
}

// 4. REPLACE OPERATION
print("\n4️⃣ REPLACE OPERATION");
print("--------------------");
const client9999 = db.users.findOne({ _id: 9999 });
if (client9999) {
  const replaceRes = db.users.replaceOne(
    { _id: 9999 },
    {
      _id: 9999,
      role: "client",
      full_name: "Петров Петр",
      phone: "+79999887766",
      updated_at: ISODate()
    }
  );
  print(`   ✅ replaceOne: Заменён документ клиента 9999 (модифицировано: ${replaceRes.modifiedCount})`);
} else {
  print(`   ⚠️  Клиент 9999 не существует — замена невозможна. Сначала добавьте его через insertOne.`);
}

// 5. UPSERT OPERATION
print("\n5️⃣ UPSERT OPERATION");
print("-------------------");
const upsertRes = db.users.updateOne(
  { phone: "+799888766" },
  { 
    $setOnInsert: {
      _id: 48884899,
      role: "client",
      full_name: "Новый Клиент",
      subscription_id: 1,
      created_at: ISODate()
    },
    $set: {  
      last_seen: ISODate()
    }
  },
  { upsert: true }
);
print(`   ✅ upsert: ${upsertRes.upsertedId ? "Создан новый клиент" : "Обновлён существующий"} (ID: ${upsertRes.upsertedId || "N/A"})`);

// 6. QUERY OPERATIONS
print("\n6️⃣ QUERY OPERATIONS");
print("-------------------");

// Запрос: Тренировки в зале 14 в феврале-марте 2025
print("   🔍 Запрос: Тренировки в зале 14 в феврале-марте 2025");
const complexQuery = db.activities.find({
  hall_id: 14,
  type: "workout",
  datetime: {
    $gte: ISODate("2025-02-01T00:00:00"),
    $lt: ISODate("2025-04-01T00:00:00")
  }
}, { datetime: 1, trainer_id: 1, _id: 0 }).sort({ datetime: 1 });

const count = complexQuery.count();
print(`      Найдено: ${count} тренировок`);
if (count > 0) {
  complexQuery.forEach(doc => printjson(doc));
} else {
  print("      Нет тренировок в зале 14 за указанный период");
}

// Запрос клиентов
print("\n   🔍 Запрос: Клиенты с подписками 1 или 2 ");
const inQuery = db.users.find({
  subscription_id: { $in: [1, 2] },
  _id: { $nin: [1001, 1002, 1003, 1004, 1005] },
  role: "client"
}, { full_name: 1, subscription_id: 1, _id: 0 }).limit(3);

const inCount = inQuery.count();
print(`      Найдено: ${inCount} клиентов (показаны первые 3):`);
if (inCount > 0) {
  inQuery.forEach(doc => printjson(doc));
}

print("✅");