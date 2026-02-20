db = db.getSiblingDB('sport_center');

/* ===============================
   ПОДГОТОВКА
================================ */
db.logs.drop();
db.facilities.deleteOne({ _id: 1 });
db.users.deleteOne({ _id: 1 });
db.finance.deleteOne({ _id: { $in: [1, 2] } });
db.activities.deleteOne({ _id: 2 }); 

print("\n🏋️ Исходная тренировка:");
printjson(db.activities.findOne({ _id: 3007 }));

/* ===============================
   ТРАНЗАКЦИЯ
================================ */
const session = db.getMongo().startSession();

try {
  session.startTransaction();

  const activities = db.activities;
  const logs = db.logs;

  // Читаем нужную тренировку
  const workout = activities.findOne({ _id: 3007, type: "workout" });

  if (!workout) {
    throw new Error("Тренировка не найдена");
  }

  // Проверяем наличие нужных полей
  if (workout.max_participants === undefined || workout.current_participants === undefined) {
    throw new Error("Тренировка не содержит полей max_participants или current_participants");
  }

  if (workout.current_participants >= workout.max_participants) {
    throw new Error("❌ Нет свободных мест");
  }

  // Создаём бронирование НА ЭТУ ТРЕНИРОВКУ
  activities.insertOne(
    {
      _id: 2,
      type: "booking",
      client_id: 1,
      workout_id: 3007, // ✅ исправлено
      status: "записан",
      created_at: new Date()
    }
  );

  // Обновляем ИМЕННО ЭТУ тренировку
  activities.updateOne(
    { _id: 3007 }, // ✅ исправлено
    { $inc: { current_participants: 1 } }
  );

  // Лог
  logs.insertOne(
    {
      _id: 1,
      action: "booking_create",
      client_id: 1,
      workout_id: 3007, // ✅ для согласованности
      created_at: new Date()
    }
  );

  session.commitTransaction();
  print("\n✅ Транзакция успешно зафиксирована");

} catch (e) {
  session.abortTransaction();
  print("\n❌ Транзакция отменена:");
  print(e.message);
} finally {
  session.endSession();
}

/* ===============================
   ПРОВЕРКА
================================ */
print("\n📌 Тренировка после транзакции:");
printjson(db.activities.findOne({ _id: 3007 }));

print("\n📌 Бронирования:");
printjson(db.activities.find({ type: "booking", workout_id: 3007 }).limit(5).toArray());

print("\n📌 Логи:");
printjson(db.logs.find().toArray());