// Инициализация single-node replica set для поддержки транзакций и change streams
// Скрипты из /docker-entrypoint-initdb.d выполняются только при первом старте
// (когда /data/db пустой).

try {
  const status = rs.status();
  print("ℹ️ Replica set уже инициализирован:", status.set);
} catch (e) {
  print("📌 Инициализируем replica set rs0...");
  const res = rs.initiate({
    _id: "rs0",
    members: [{ _id: 0, host: "localhost:27017" }]
  });
  printjson(res);
}


