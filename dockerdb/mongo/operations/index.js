// ============================================
// 📌 Бенчмарк индексов MongoDB (с понятной статистикой)
// ============================================

db = db.getSiblingDB("sport_center");

print("\n============================================");
print("📌 Бенчмарк индексов MongoDB (ясные запросы)");
print("============================================\n");

// Коллекции
const users = db.users;
const activities = db.activities;
const logs = db.logs;

// -----------------------------------------------------
// 🧹 1. Удаляем индексы
// -----------------------------------------------------

function dropIndexes(coll, name) {
    print(`\n🧹 Очистка индексов коллекции ${name}...`);
    try {
        coll.dropIndexes();
        print("   ✅ Индексы удалены");
    } catch (err) {
        print(`   ❌ Ошибка удаления: ${err}`);
    }
}

dropIndexes(users, "users");
dropIndexes(activities, "activities");
dropIndexes(logs, "logs");

// -----------------------------------------------------
// 🛠 Вспомогательные функции
// -----------------------------------------------------

function runExplainWithStats(coll, filter, projection = {}) {
    const stats = coll.find(filter, projection).explain("executionStats").executionStats;

    return {
        time: stats.executionTimeMillis,
        examined: stats.totalDocsExamined,
        returned: stats.nReturned
    };
}

function showResult(name, filter, before, after) {
    const speedup = before.time > 0 ? (before.time / Math.max(after.time, 1)).toFixed(1) : "∞";

    print(`\n🔎 ${name}`);
    print(`   filter: ${EJSON.stringify(filter)}`);

    print("   BEFORE:");
    print(`      time:     ${before.time} ms`);
    print(`      scanned:  ${before.examined} docs`);
    print(`      returned: ${before.returned} docs`);

    print("   AFTER:");
    print(`      time:     ${after.time} ms`);
    print(`      scanned:  ${after.examined} docs`);
    print(`      returned: ${after.returned} docs`);

    print(`   SPEEDUP: x${speedup}`);
}

// -----------------------------------------------------
// 🔍 2. Формируем запросы
// -----------------------------------------------------

const q1 = { phone: "+79991234567" };
const q2 = {
    hall_id: 14,
    datetime: {
        $gte: ISODate("2025-02-01T00:00:00Z"),
        $lt: ISODate("2025-04-01T00:00:00Z")
    }
};
const q3 = { tags: "активный" };

const before1 = runExplainWithStats(users, q1);
const before2 = runExplainWithStats(activities, q2);
const before3 = runExplainWithStats(users, q3);

// -----------------------------------------------------
// ⚙️ 4. СОЗДАЁМ ИНДЕКСЫ
// -----------------------------------------------------

print("\n============================================");
print("⚙️ СОЗДАНИЕ ИНДЕКСОВ");
print("============================================\n");

// Single index
print("⚙️ Single index: phone");
users.createIndex({ phone: 1 });

// Compound index
print("⚙️ Compound index: { hall_id, datetime }");
activities.createIndex({ hall_id: 1, datetime: 1 });

// Multikey index (for array field)
print("⚙️ Multikey index: tags");
users.createIndex({ tags: 1 });

// Partial index
print("⚙️ Partial index: subscription_id only for clients");
users.createIndex(
    { subscription_id: 1 },
    { partialFilterExpression: { role: "client" } }
);

// TTL index
print("⚙️ TTL index: logs.created_at expires after 30 days");
db.createCollection("logs");
logs.createIndex(
    { created_at: 1 },
    { expireAfterSeconds: 60 }
);

// Unique index
print("⚙️ Unique index: phone");
try {
    users.createIndex({ phone:1 }, { unique: true });
} catch (e) {
    print("   ⚠️ Не удалось создать unique index: возможно есть дубликаты");
}

const after1 = runExplainWithStats(users, q1);
const after2 = runExplainWithStats(activities, q2);
const after3 = runExplainWithStats(users, q3);

// -----------------------------------------------------
// 📈 6. Сравнение
// -----------------------------------------------------

print("\n============================================");
print("📊 РЕЗУЛЬТАТЫ СРАВНЕНИЯ");
print("============================================");

showResult("Query 1: Find user by phone", q1, before1, after1);
showResult("Query 2: Workouts by hall + date range", q2, before2, after2);
showResult("Query 3: Clients by tag 'активный'", q3, before3, after3);

print("✅");
