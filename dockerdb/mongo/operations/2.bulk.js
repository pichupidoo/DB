db = db.getSiblingDB("sport_center");

print("\n📦 BULK-операции для finance\n");

const result = db.finance.bulkWrite([
  /* 1️⃣ INSERT */
  {
    insertOne: {
      document: {
        type: "payment",
        client_id: 229145,
        subscription_id: 1,
        amount: 3900,
        method: "карта",
        date: new Date("2025-04-01"),
        transaction_id: "TXN-BULK-001"
      }
    }
  },

  /* 2️⃣ UPDATE ONE */
  {
    updateOne: {
      filter: { _id: 80001 },
      update: { $set: { method: "онлайн" } }
    }
  },

  /* 3️⃣ UPDATE MANY */
  {
    updateMany: {
      filter: { subscription_id: 1 },
      update: { $inc: { amount: -100 } }
    }
  },

  /* 4️⃣ DELETE ONE */
  {
    deleteOne: {
      filter: { transaction_id: "TXN-TEST" }
    }
  }
]);

print("✅ Bulk result:");
printjson(result);
