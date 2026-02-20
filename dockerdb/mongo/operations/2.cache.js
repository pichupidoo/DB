db = db.getSiblingDB("sport_center");

print("\n============================================");
print("📌 Материализация: Class Occupancy");
print("============================================\n");

// -------------------------
// Создаём уникальный индекс, чтобы $merge работал корректно
print("📌 Проверка/создание индекса для class_occupancy_report...");
db.client_report.createIndex(
  { trainer_id: 1, date: 1 },
  { unique: true }
);
print("✔ Индекс готов\n");

// -------------------------
// Определяем пайплайн Class Occupancy
const classOccupancyPipeline = [
  // Фильтруем только бронирования
  { $match: { type: "booking" } },

  // Присоединяем информацию о тренировке
  { $lookup: { from: "activities", localField: "workout_id", foreignField: "_id", as: "workout" } },
  { $unwind: "$workout" },

  // Преобразуем дату тренировки в объект Date
  { $addFields: { workout_datetime: { $toDate: "$workout.datetime" } } },

  // Группируем по тренеру и дате
  { $group: {
      _id: { trainer_id: "$workout.trainer_id", date: { $dateToString: { format: "%Y-%m-%d", date: "$workout_datetime" } } },
      total_bookings: { $sum: 1 }
  }},

  // Присоединяем данные о тренере
  { $lookup: { from: "users", localField: "_id.trainer_id", foreignField: "_id", as: "trainer" } },
  // Игнорируем записи без тренера
  { $unwind: { path: "$trainer", preserveNullAndEmptyArrays: false } },

  // Формируем итоговую структуру отчёта
  { $project: { 
      _id: 0,
      trainer_id: "$_id.trainer_id",
      date: "$_id.date", 
      trainer_name: "$trainer.full_name", 
      total_bookings: 1 
  }},

  // Сортировка
  { $sort: { date: 1, trainer_name: 1 } },

  // -------------------------
  // Материализация в коллекцию с обновлением
  { $merge: { 
      into: "client_report", 
      on: ["trainer_id", "date"],   // ключи для обновления
      whenMatched: "replace",       // если запись с таким ключом есть — заменяем
      whenNotMatched: "insert"      // если нет — создаём
  }}
];

// -------------------------
// Выполняем агрегацию
print("\n📌 Выполняем Class Occupancy...");
db.activities.aggregate(classOccupancyPipeline);
print("✔ Витрина 'class_occupancy_report' создана/обновлена\n");

print("============================================");
print("✅ Выполнение Class Occupancy завершено!");
print("============================================\n");

db.activities.insertOne({
  _id: ObjectId(),
  type: "booking",
  workout_id: 12345,      // ID существующей тренировки
  client_id: 999990,
});
