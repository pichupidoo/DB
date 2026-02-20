db.runCommand({
  collMod: "finance",
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["type", "amount", "method", "transaction_id"],
      properties: {
        type: {
          bsonType: "string",
          enum: ["payment"],
          description: "Тип документа должен быть 'payment'"
        },
        amount: {
          bsonType: ["double", "int", "decimal"],
          minimum: 0.01,
          description: "Сумма платежа должна быть больше 0"
        },
        method: {
          bsonType: "string",
          enum: ["наличные", "карта", "перевод", "онлайн"],
          description: "Недопустимый метод оплаты"
        },
        transaction_id: {
          bsonType: "string",
          minLength: 5,
          description: "transaction_id обязателен"
        }
      }
    }
  },
  validationLevel: "moderate",
  validationAction: "error"
});


db.finance.insertOne({
  _id: 99999,
  type: "payment",
  client_id: 1,
  subscription_id: 1,
  amount: -100,
  method: "карта",
  transaction_id: "TXN-FAIL"
})

db.finance.insertOne({
  _id: 99998,
  type: "payment",
  amount: 1000,
  method: "бартер",
  transaction_id: "TXN-FAIL"
})

db.finance.insertOne({
  _id: 99997,
  type: "payment",
  client_id: 1,
  subscription_id: 1,
  amount: 1500,
  method: "карта",
  transaction_id: "TXN-OK-001"
})
