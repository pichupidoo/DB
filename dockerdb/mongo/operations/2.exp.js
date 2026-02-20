// ==========================================================
// 🟢 Скрипт для тестирования и оптимизации медленных запросов
// ==========================================================
db = db.getSiblingDB('sport_center');
// ==========================================================
// 🟢 Скрипт оптимизации медленных запросов с % ускорения
// ==========================================================

function dropAllIndexes(collName) {
    const indexes = db.getCollection(collName).getIndexes();
    indexes.forEach(idx => {
        if (idx.name !== "_id_") {
            print(`Удаляем индекс ${idx.name} в коллекции ${collName}`);
            db.getCollection(collName).dropIndex(idx.name);
        }
    });
}

function printStats(label, cursorOrAgg) {
    let stats = cursorOrAgg.explain("executionStats").executionStats;
    return {
        label,
        time: stats.executionTimeMillis,
        docs: stats.totalDocsExamined,
        keys: stats.totalKeysExamined || 0
    };
}

function printComparison(before, after) {
    const speedup = ((before.time - after.time) / before.time * 100).toFixed(1);
    print(`\n=== ${before.label} ===`);
    print(`Before: ${before.time} ms, Docs: ${before.docs}, Keys: ${before.keys}`);
    print(`After:  ${after.time} ms, Docs: ${after.docs}, Keys: ${after.keys}`);
    print(`Speedup: ${speedup}%`);
}

// ----------------------------
// 0️⃣ Очистка индексов
// ----------------------------
dropAllIndexes("activities");
dropAllIndexes("users");
dropAllIndexes("finance");

// ----------------------------
// 1️⃣ Запросы до оптимизации
// ----------------------------
let actBefore = printStats("Activities: Заполняемость залов по дням недели", db.activities.aggregate([
    { $match: { type: "workout" } },
    { $group: { _id: { hall_id: "$hall_id", day: { $dayOfWeek: "$datetime" } }, total: { $sum: 1 } } }
]));

let usersBefore = printStats("Users: Клиенты с медицинскими ограничениями", db.users.find({
    role: "client", medical_history: { $exists: true }
}));

let financeBefore = printStats("Finance: Средний доход по подпискам", db.finance.aggregate([
    { $match: { date: { $gte: ISODate("2025-01-01"), $lt: ISODate("2025-03-31") } } },
    { $group: { _id: "$subscription_id", totalAmount: { $sum: "$amount" }, avgAmount: { $avg: "$amount" } } }
]));

// ----------------------------
// 2️⃣ Создание оптимальных индексов
// ----------------------------
// Activities
db.activities.createIndex({ type: 1, datetime: 1, hall_id: 1 });

// Users (partial index для medical_history)
db.users.createIndex(
    { role: 1, medical_history: 1 },
    { partialFilterExpression: { medical_history: { $exists: true } } }
);

// Finance (индекс для диапазонного фильтра по дате)
db.finance.createIndex({ date: 1, subscription_id: 1 });

// ----------------------------
// 3️⃣ Запросы после оптимизации
// ----------------------------
let actAfter = printStats("Activities: Заполняемость залов по дням недели", db.activities.aggregate([
    { $match: { type: "workout" } },
    { $group: { _id: { hall_id: "$hall_id", day: { $dayOfWeek: "$datetime" } }, total: { $sum: 1 } } }
]));

let usersAfter = printStats("Users: Клиенты с медицинскими ограничениями", db.users.find({
    role: "client", medical_history: { $exists: true }
}));

let financeAfter = printStats("Finance: Средний доход по подпискам", db.finance.aggregate([
    { $match: { date: { $gte: ISODate("2025-01-01"), $lt: ISODate("2025-03-31") } } },
    { $group: { _id: "$subscription_id", totalAmount: { $sum: "$amount" }, avgAmount: { $avg: "$amount" } } }
]));

// ----------------------------
// 4️⃣ Сравнение и % ускорения
// ----------------------------
printComparison(actBefore, actAfter);
printComparison(usersBefore, usersAfter);
printComparison(financeBefore, financeAfter);

print("\n✅ Скрипт выполнен. Сравните время выполнения и ускорение.");
