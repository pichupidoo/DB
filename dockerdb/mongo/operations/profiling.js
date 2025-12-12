db = db.getSiblingDB("sport_center");

print("\n============================================");
print("📌 Мини-профайлинг: только executionTimeMillis");
print("============================================\n");

// -------------------------
// Удаляем старые индексы
print("\n📌 Удаляем старые индексы...");
const dropSafe = (coll, indexName) => {
  try {
    coll.dropIndex(indexName);
    print(`✔ Индекс ${indexName} удалён`);
  } catch(e) {
    print(`⚠ Индекс ${indexName} не найден, пропускаем`);
  }
}

dropSafe(db.activities, "type_1");
dropSafe(db.activities, "workout_id_1");
dropSafe(db.activities, "client_id_1");
dropSafe(db.activities, "trainer_id_1");
dropSafe(db.activities, "datetime_1");
dropSafe(db.users, "_id_1");

print("✔ Старые индексы обработаны");

// -------------------------
// Определяем пайплайны
const pipelines = {
  "Workouts with Participants": [
    { $match: { type: "booking" } },
    { $lookup: { from: "activities", localField: "workout_id", foreignField: "_id", as: "workout" } },
    { $unwind: "$workout" },
    { $lookup: { from: "users", localField: "client_id", foreignField: "_id", as: "participant" } },
    { $unwind: "$participant" },
    { $group: {
        _id: "$workout._id",
        workout_name: { $first: "$workout.name" },
        datetime: { $first: "$workout.datetime" },
        participants: { $push: { name: "$participant.full_name", phone: "$participant.phone" } }
    }},
    { $sort: { datetime: -1 } },
    { $limit: 20 }
  ],

  "Class Occupancy": [
    { $match: { type: "booking" } },
    { $lookup: { from: "activities", localField: "workout_id", foreignField: "_id", as: "workout" } },
    { $unwind: "$workout" },
    { $addFields: { workout_datetime: { $toDate: "$workout.datetime" } } },
    { $group: {
        _id: { trainer_id: "$workout.trainer_id", date: { $dateToString: { format: "%Y-%m-%d", date: "$workout_datetime" } } },
        total_bookings: { $sum: 1 }
    }},
    { $lookup: { from: "users", localField: "_id.trainer_id", foreignField: "_id", as: "trainer" } },
    { $unwind: "$trainer" },
    { $project: { _id: 0, date: "$_id.date", trainer_name: "$trainer.full_name", total_bookings: 1 } },
    { $sort: { date: 1, trainer_name: 1 } }
  ]
};

// -------------------------
// Функция для безопасного извлечения executionTimeMillis
function getExecutionTime(stats) {
  if (!stats) return 0;
  if (stats.stages) {
    return stats.stages.reduce((acc, stage) => acc + (stage.$cursor?.executionStats?.executionTimeMillis || 0), 0);
  } else if (stats.executionStats) {
    return stats.executionStats.executionTimeMillis || 0;
  }
  return 0;
}

// -------------------------
// Explain до индексов
print("🔹 Время выполнения ДО индексов:");
for (let name in pipelines) {
  const stats = db.activities.aggregate(pipelines[name], { explain: "executionStats" });
  const time = getExecutionTime(stats);
  print(`${name}: ${time} ms`);
}

// -------------------------
// Создаём индексы
print("\n📌 Создаём индексы для ускорения $match...");
db.activities.createIndex({ type: 1 });
db.activities.createIndex({ workout_id: 1 });
db.activities.createIndex({ client_id: 1 });
db.activities.createIndex({ trainer_id: 1 });
db.activities.createIndex({ datetime: 1 });
db.users.createIndex({ _id: 1 });
print("✔ Индексы созданы");

// -------------------------
// Explain после индексов
print("\n🔹 Время выполнения ПОСЛЕ индексов:");
for (let name in pipelines) {
  const stats = db.activities.aggregate(pipelines[name], { explain: "executionStats" });
  const time = getExecutionTime(stats);
  print(`${name}: ${time} ms`);
}

// -------------------------
// Материализация Class Occupancy в отдельную коллекцию
print("\n📌 Материализация витрины Class Occupancy в коллекцию 'class_occupancy_report'...");
db.activities.aggregate([
  ...pipelines["Class Occupancy"],
  { $merge: { into: "class_occupancy_report" } } // создаёт или обновляет коллекцию
]);
print("✔ Витрина 'class_occupancy_report' создана\n");

print("============================================");
print("✅ Профайлинг и материализация завершены!");
print("============================================\n");
