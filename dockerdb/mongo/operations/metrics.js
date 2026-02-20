db = db.getSiblingDB("sport_center");

print("\n============================================");
print("📌 Спец-витрины: Заполняемость и Ретеншен");
print("============================================\n");

const reports = db.reports;

// удаляем только старые версии этих двух витрин
reports.deleteMany({ name: { $in: ["Class Occupancy", "Client Retention"] } });

// -----------------------------------------------------
// 1️⃣ Заполняемость классов (по дням и тренерам)
// -----------------------------------------------------
const pipelineClassOccupancy = [
  { $match: { type: "booking" } },

  {
    $lookup: {
      from: "activities",
      localField: "workout_id",
      foreignField: "_id",
      as: "workout"
    }
  },
  { $unwind: "$workout" },

  // 🔥 Конвертируем workout.datetime в нормальный Date
  {
    $addFields: {
      workout_datetime: { $toDate: "$workout.datetime" }
    }
  },

  {
    $group: {
      _id: {
        trainer_id: "$workout.trainer_id",
        date: {
          $dateToString: {
            format: "%Y-%m-%d",
            date: "$workout_datetime"
          }
        }
      },
      total_bookings: { $sum: 1 }
    }
  },
  {
    $lookup: {
      from: "users",
      localField: "_id.trainer_id",
      foreignField: "_id",
      as: "trainer"
    }
  },
  { $unwind: "$trainer" },

  {
    $project: {
      _id: 0,
      date: "$_id.date",
      trainer_name: "$trainer.full_name",
      total_bookings: 1
    }
  },

  { $sort: { date: 1, trainer_name: 1 } }
];

// выполняем
const classOccupancy = db.activities.aggregate(pipelineClassOccupancy).toArray();

// сохраняем витрину
reports.insertOne({
  name: "Class Occupancy",
  created_at: new Date(),
  data: classOccupancy
});

print("✔ Витрина 'Class Occupancy' создана");

// -----------------------------------------------------
// 2️⃣ Ретеншен клиентов
// -----------------------------------------------------
const pipelineRetention = [
  { $match: { type: "booking", status: "посетил" } },

  // 🔥 Конвертация booking.datetime → Date
  {
    $addFields: {
      datetime_date: { $toDate: "$datetime" }
    }
  },

  {
    $group: {
      _id: "$client_id",
      first_visit: { $min: "$datetime_date" },
      last_visit: { $max: "$datetime_date" },
      total_visits: { $sum: 1 }
    }
  },

  {
    $project: {
      _id: 0,
      client_id: "$_id",
      first_visit: 1,
      last_visit: 1,
      total_visits: 1,
      retention_days: {
        $dateDiff: {
          startDate: "$first_visit",
          endDate: "$last_visit",
          unit: "day"
        }
      }
    }
  },

  { $sort: { total_visits: -1 } },
  { $limit: 20 }
];

// выполняем
const retention = db.activities.aggregate(pipelineRetention).toArray();

// сохраняем витрину
reports.insertOne({
  name: "Client Retention",
  created_at: new Date(),
  data: retention
});

print("✔ Витрина 'Client Retention' создана");

print("✅");
