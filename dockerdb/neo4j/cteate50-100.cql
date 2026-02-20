// ==========================
// 1. Клиенты (30)
// ==========================
UNWIND range(1,30) AS id
MERGE (c:Client {id:id})
SET c.name = "Client_" + toString(id),
    c.gender = CASE WHEN id % 2 = 0 THEN "ж" ELSE "м" END,
    c.birth_year = 1980 + (id % 20);

// ==========================
// 2. Персонал (5 тренеров)
// ==========================
UNWIND range(1,5) AS id
MERGE (s:Staff {id:id})
SET s.name = "Trainer_" + toString(id),
    s.position = "Trainer",
    s.phone = "+79000000" + toString(id);

// ==========================
// 3. Залы (5)
// ==========================
UNWIND range(1,5) AS id
MERGE (h:Hall {id:id})
SET h.name = "Hall_" + toString(id),
    h.capacity = 20 + id * 10;

// 4. Типы тренировок (с индексом)
WITH ["силовая","йога","кардио","пилатес","растяжка"] AS types
UNWIND range(0, size(types)-1) AS i
MERGE (wt:WorkoutType {name: types[i]})
SET wt.idx = i;

// 5. DateTime занятий (20) + slot_id
UNWIND range(1,20) AS slot
MERGE (dt:DateTime {slot_id: slot})
SET dt.date = date({year:2026, month:2, day:(slot % 28)+1}),
    dt.time = localtime({hour:10 + (slot % 8), minute: (slot*5) % 60})
WITH dt, slot
MATCH (wt:WorkoutType {idx: slot % 5})
MERGE (dt)-[:OF_WORKOUT]->(wt);

// 6. Тренер ведёт слот (стабильно через slot_id)
MATCH (s:Staff), (dt:DateTime)
WHERE (dt.slot_id - 1) / 4 + 1 = s.id
MERGE (s)-[:LEADS]->(dt);

// 7. Зал принимает слот (стабильно через slot_id)
MATCH (h:Hall), (dt:DateTime)
WHERE (dt.slot_id % 5) + 1 = h.id
MERGE (h)-[:HOSTS]->(dt);

// 8. Клиенты записываются на конкретный slot_id (~150)
UNWIND range(1,150) AS i
MATCH (c:Client {id: (i % 30) + 1})
MATCH (dt:DateTime {slot_id: (i % 20) + 1})
MERGE (c)-[b:BOOKED]->(dt)
SET b.status = CASE
    WHEN i % 3 = 0 THEN "посетил"
    WHEN i % 3 = 1 THEN "записан"
    ELSE "отменил"
END,
b.booking_id = i,
b.booking_time = datetime();

// 9. Тренер умеет вести тип
MATCH (s:Staff), (wt:WorkoutType)
WHERE wt.idx = (s.id - 1)  // простое соответствие 1->0,2->1...
MERGE (s)-[:TEACHES]->(wt);

// 10. Зал поддерживает тип
MATCH (h:Hall), (wt:WorkoutType)
WHERE wt.idx = (h.id - 1)
MERGE (h)-[:HOSTS_TYPE]->(wt);
