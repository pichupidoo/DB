import express from "express";
import { MongoClient, ObjectId } from "mongodb";

const app = express();
const PORT = 3000;

app.use(express.json());

// ----------------------
// Подключение к MongoDB
// ----------------------
const uri = "mongodb://127.0.0.1:27017"; // локальный доступ
const client = new MongoClient(uri);
let db;

async function connectDB() {
  await client.connect();
  db = client.db("sport_center");
  console.log("✅ Connected to MongoDB");
}

connectDB().catch(console.error);

// ----------------------
// ENDPOINTS
// ----------------------

// 1️⃣ GET user by ID
app.get("/users/:id", async (req, res) => {
  const id = parseInt(req.params.id);
  const user = await db.collection("users").findOne({ _id: id });
  res.json(user || { error: "User not found" });
});

// 2️⃣ POST create user
app.post("/users", async (req, res) => {
  const user = req.body;
  if (!user._id) {
  let unique = false;
  while (!unique) {
    const id = Math.floor(Math.random() * 1000000);
    const exists = await db.collection("users").findOne({ _id: id });
    if (!exists) {
      user._id = id;
      unique = true;
    }
  }
};
  const result = await db.collection("users").insertOne(user);
  res.json({ insertedId: result.insertedId });
});

// 3️⃣ PUT update user
app.put("/users/:id", async (req, res) => {
  const id = parseInt(req.params.id);
  const update = req.body; // например { $set: { full_name: "New Name" } }
  const result = await db.collection("users").updateOne({ _id: id }, update);
  res.json({ matchedCount: result.matchedCount, modifiedCount: result.modifiedCount });
});

// 4️⃣ GET activities with filters
app.get("/activities", async (req, res) => {
  const { hall_id, start, end } = req.query;
  const filter = {};
  if (hall_id) filter.hall_id = parseInt(hall_id);
  if (start || end) filter.datetime = {};
  if (start) filter.datetime.$gte = new Date(start);
  if (end) filter.datetime.$lt = new Date(end);

  const activities = await db.collection("activities")
    .find(filter)
    .sort({ datetime: 1 })
    .toArray();
  res.json(activities);
});

// 5️⃣ DELETE activity by ID
app.delete("/activities/:id", async (req, res) => {
  const id = parseInt(req.params.id);
  const result = await db.collection("activities").deleteOne({ _id: id });
  res.json({ deletedCount: result.deletedCount });
});

// ----------------------
app.listen(PORT, () => {
  console.log(`🚀 REST API running at http://localhost:${PORT}`);
});
