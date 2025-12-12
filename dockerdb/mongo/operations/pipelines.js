db = db.getSiblingDB("sport_center");

print("\n============================================");
print("📌 Aggregation Pipelines - Витрины/Отчеты");
print("============================================\n");

const reportsCollection = db.reports;

// Очистка старых отчетов
reportsCollection.deleteMany({});
print("🧹 Очищены старые отчеты\n");

// -----------------------------------------------------
// 1️⃣ Топ-5 активных клиентов по количеству посещений
// -----------------------------------------------------
const pipelineTopClients = [
  { $match: { type: "booking", status: { $in: ["посетил", "записан"] } } },
  { $group: { _id: "$client_id", total_workouts: { $sum: 1 } } },
  { $sort: { total_workouts: -1 } },
  { $limit: 5 },
  { $lookup: {
      from: "users",
      localField: "_id",
      foreignField: "_id",
      as: "user"
  }},
  { $unwind: "$user" },
  { $project: {
      _id: 0,
      user_name: "$user.full_name",
      total_workouts: 1
  }}
];

const topClients = db.activities.aggregate(pipelineTopClients).toArray();
print("🔹 Top 5 active clients:");
printjson(topClients);
reportsCollection.insertOne({
  name: "Top Active Clients",
  created_at: new Date(),
  data: topClients
});

// -----------------------------------------------------
// 2️⃣ Количество отзывов по каждому тренеру
// -----------------------------------------------------
const pipelineTrainerReviews = [
  { $match: { type: "review", "target.type": "workout" } },
  { $lookup: {
      from: "activities",
      localField: "target.id",
      foreignField: "_id",
      as: "workout"
  }},
  { $unwind: "$workout" },
  { $group: { _id: "$workout.trainer_id", total_reviews: { $sum: 1 } } },
  { $lookup: {
      from: "users",
      localField: "_id",
      foreignField: "_id",
      as: "trainer"
  }},
  { $unwind: "$trainer" },
  { $project: {
      _id: 0,
      trainer_name: "$trainer.full_name",
      total_reviews: 1
  }}
];

const trainerReviews = db.activities.aggregate(pipelineTrainerReviews).toArray();
print("\n🔹 Top trainers by reviews:");
printjson(trainerReviews);
reportsCollection.insertOne({
  name: "Top Trainers Reviews",
  created_at: new Date(),
  data: trainerReviews
});

// -----------------------------------------------------
// 3️⃣ Последние тренировки
// -----------------------------------------------------
const pipelineRecentWorkouts = [
  { $match: { type: "workout" } },
  { $project: { _id: 1, trainer_id: 1, datetime: 1 } },
  { $sort: { datetime: -1 } },
  { $limit: 10 }
];

const recentWorkouts = db.activities.aggregate(pipelineRecentWorkouts).toArray();
print("\n🔹 Recent workouts:");
printjson(recentWorkouts);
reportsCollection.insertOne({
  name: "Recent Workouts",
  created_at: new Date(),
  data: recentWorkouts
});

// -----------------------------------------------------
// 4️⃣ Количество клиентов по подпискам
// -----------------------------------------------------
const pipelineClientsBySubscription = [
  { $match: { role: "client" } },
  { $group: { _id: "$subscription_id", clients_count: { $sum: 1 } } },
  { $sort: { clients_count: -1 } },
  { $project: { subscription_id: "$_id", clients_count: 1, _id: 0 } }
];

const clientsBySubscription = db.users.aggregate(pipelineClientsBySubscription).toArray();
print("\n🔹 Clients count by subscription:");
printjson(clientsBySubscription);
reportsCollection.insertOne({
  name: "Clients by Subscription",
  created_at: new Date(),
  data: clientsBySubscription
});

// -----------------------------------------------------
// 5️⃣ Тренировки с участниками и их контактами
// -----------------------------------------------------
const pipelineWorkoutsWithParticipants_NN = [
  { $match: { type: "booking" } }, // только бронирования
  { $lookup: {
      from: "activities",          // подключаем тренировки
      localField: "workout_id",
      foreignField: "_id",
      as: "workout"
  }},
  { $unwind: "$workout" },
  { $lookup: {
      from: "users",               // подключаем участников
      localField: "client_id",
      foreignField: "_id",
      as: "participant"
  }},
  { $unwind: "$participant" },
  { $group: {
      _id: "$workout._id",
      workout_name: { $first: "$workout.name" },
      datetime: { $first: "$workout.datetime" },
      participants: { $push: { 
          name: "$participant.full_name", 
          phone: "$participant.phone" 
      }}
  }},
  { $sort: { datetime: -1 } },
  { $limit: 20 }
];

const workoutsWithParticipants_NN = db.activities.aggregate(pipelineWorkoutsWithParticipants_NN).toArray();
print("\n🔹 Workouts with Participants (N→N):");
reportsCollection.insertOne({
  name: "Workouts with Participants (N→N)",
  created_at: new Date(),
  data: workoutsWithParticipants_NN
});

print("\n============================================");
print("✅ All pipelines executed and reports saved!");
print("============================================\n");
