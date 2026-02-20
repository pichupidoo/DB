db.activities.aggregate([
  { $match: { type: "workout" } },
  { $addFields: { dayOfWeek: { $dayOfWeek: "$datetime" } } },
  {
    $lookup: {
      from: "facilities",
      localField: "hall_id",
      foreignField: "_id",
      as: "hall"
    }
  },
  { $unwind: { path: "$hall", preserveNullAndEmptyArrays: true } },
  {
    $addFields: {
      hallName: { $ifNull: ["$hall.name", { $toString: "$hall_id" }] }
    }
  },
  {
    $group: {
      _id: { hall: "$hallName", dayOfWeek: "$dayOfWeek" },
      totalWorkouts: { $sum: 1 }
    }
  },
  { $sort: { "_id.hall": 1, "_id.dayOfWeek": 1 } },
  {
    $project: {
      _id: 0,
      hall: "$_id.hall",
      dayOfWeek: "$_id.dayOfWeek",
      totalWorkouts: 1
    }
  }
]).pretty();
