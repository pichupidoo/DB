db = db.getSiblingDB("sport_center");

db.createCollection("users");
db.createCollection("facilities");
db.createCollection("activities");
db.createCollection("finance");

db.users.insertMany([
    {
        _id: 1001,
        role: "client",
        full_name: "Иванов Иван",
        birth_date: "1990-02-10",
        gender: "м",
        phone: "+79998887766",
        subscription_id: 1
    },
    {
        _id: 1002,
        role: "client",
        full_name: "Смирнова Анна",
        birth_date: "1995-06-20",
        gender: "ж",
        phone: "+79995554433",
        subscription_id: 2
    },
    {
        _id: 5001,
        role: "staff",
        full_name: "Петров Петр",
        position: "тренер",
        phone: "+79990001234"
    },
    {
        _id: 5002,
        role: "staff",
        full_name: "Кузнецова Мария",
        position: "администратор",
        phone: "+79992223344"
    }
]);

db.facilities.insertMany([
    {
        _id: 10,
        type: "hall",
        name: "Зал №1",
        equipment: [
            { equipment_id: 201, name: "Беговая дорожка", status: "исправно" },
            { equipment_id: 202, name: "Велотренажер", status: "исправно" }
        ]
    },
    {
        _id: 11,
        type: "hall",
        name: "Зал №2",
        equipment: [
            { equipment_id: 203, name: "Гантели", status: "исправно" },
            { equipment_id: 204, name: "Штанга", status: "на ремонте" }
        ]
    },
    {
        _id: 30,
        type: "section",
        name: "Йога",
        trainer_id: 5001
    },
    {
        _id: 31,
        type: "section",
        name: "Пилатес",
        trainer_id: 5001
    }
]);

db.activities.insertMany([
    {
        _id: 3001,
        type: "workout",
        datetime: "2025-02-05T10:00:00",
        hall_id: 10,
        trainer_id: 5001
    },
    {
        _id: 3002,
        type: "workout",
        datetime: "2025-02-05T12:00:00",
        hall_id: 11,
        trainer_id: 5001
    },
    {
        _id: 40001,
        type: "booking",
        client_id: 1001,
        workout_id: 3001,
        status: "записан"
    },
    {
        _id: 40002,
        type: "booking",
        client_id: 1002,
        workout_id: 3001,
        status: "посетил"
    },
    {
        _id: 41,
        type: "service",
        name: "Массаж спины",
        price: 1500,
        staff_id: 5002
    },
    {
        _id: 42,
        type: "service",
        name: "Персональная тренировка",
        price: 2200,
        staff_id: 5001
    },
    {
        _id: 7701,
        type: "review",
        client_id: 1001,
        target: { type: "service", id: 41 },
        rating: 5,
        comment: "Отличный массаж!",
        review_date: "2025-02-01"
    },
    {
        _id: 7702,
        type: "review",
        client_id: 1002,
        target: { type: "workout", id: 3001 },
        rating: 4,
        comment: "Хорошая тренировка!",
        review_date: "2025-02-03"
    }
]);

db.finance.insertMany([
    {
        _id: 1,
        type: "subscription",
        plan: "месячный",
        price: 3500
    },
    {
        _id: 2,
        type: "subscription",
        plan: "годовой",
        price: 29000
    },
    {
        _id: 9001,
        type: "payment",
        client_id: 1001,
        subscription_id: 1,
        amount: 3500,
        method: "карта",
        date: "2025-01-15"
    },
    {
        _id: 9002,
        type: "payment",
        client_id: 1002,
        subscription_id: 2,
        amount: 29000,
        method: "онлайн",
        date: "2025-01-05"
    }
]);
