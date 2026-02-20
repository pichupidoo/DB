/*docker compose exec mongos mongoimport \
  --host localhost:27020 \
  --db sport_center \
  --collection users \
  --file /seeds/users.seed.json \
  --jsonArray

db.users.createIndex({ client_id: 1 })
sh.shardCollection("sport_center.users", { client_id: 1 })


sh.splitAt("sport_center.activities", { hall_id: 12 });
sh.splitAt("sport_center.activities", { hall_id: 18 });
sh.moveChunk("sport_center.users", { client_id: 100000 }, "shard1rs")*/

// Файл: 2.shardKey.js
// Используем в mongosh: mongosh --file 2.shard.js

const dbName = "sport_center";
const collName = "users";

const db = connect("mongodb://localhost:27020/" + dbName);

// Пример shardKeys для запросов
const shardKeys = [
  1001,     // первый клиент
  140000,   // середина диапазона
  280202,   // последний клиент
  50000,    // случайный
  210000    // другой случайный
];

// Выполнение запросов
for (const key of shardKeys) {
  print(`\n🔹 Query for shardKey _id=${key}`);
  
  const result = db[collName].find({ _id: key }).limit(5).toArray();
  print(`Result count: ${result.length}`);
  if (result.length > 0) {
    printjson(result[0]); // показываем первый документ
  }
}

// Получение распределения по шардам
print("\n📊 Shard distribution after queries:");
printjson(db[collName].getShardDistribution());
