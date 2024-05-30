-- RESET
RESET shared_buffers;
RESET work_mem;
RESET effective_cache_size;
RESET max_parallel_workers_per_gather;

DROP INDEX idx_н_люди_имя;
DROP INDEX idx_н_люди_ид;
DROP INDEX idx_н_сессия_учгод;
DROP INDEX idx_н_сессия_члвк_ид;

DROP INDEX idx_н_люди_фамилия;
DROP INDEX idx_н_обучения_нзк;
DROP INDEX idx_н_ученики_начало;
DROP INDEX idx_н_обучения_члвк_ид;
DROP INDEX idx_н_ученики_члвк_ид;
DROP INDEX idx_н_обучения_ид_unique;

DROP INDEX idx_unique_н_люди_имя;

-- ### без оптимизаций, без индексов ###

-- ЗАПРОС 1
-- ЗАПРОС 1
-- ЗАПРОС 1

EXPLAIN ANALYSE
SELECT human."ФАМИЛИЯ", session."ДАТА"
FROM "Н_ЛЮДИ" human
         RIGHT JOIN "Н_СЕССИЯ" session ON session."ЧЛВК_ИД" = human."ИД"
WHERE human."ИМЯ" < 'Владимир'
  AND session."УЧГОД" > '2008/2009';

-- ЗАПРОС 2
-- ЗАПРОС 2
-- ЗАПРОС 2

EXPLAIN ANALYSE
SELECT human."ОТЧЕСТВО", study."НЗК", student."ГРУППА"
FROM "Н_ЛЮДИ" human
         RIGHT JOIN "Н_ОБУЧЕНИЯ" study ON study."ЧЛВК_ИД" = human."ИД"
         RIGHT JOIN "Н_УЧЕНИКИ" student ON student."ЧЛВК_ИД" = human."ИД"
WHERE human."ФАМИЛИЯ" = 'Афанасьев'
  AND study."НЗК" = '933232'
  AND student."НАЧАЛО" > '2009-02-09';


-- ### с оптимизациями, без индексов ###

SET work_mem = '10000MB';

-- ЗАПРОС 1
-- ЗАПРОС 1
-- ЗАПРОС 1

-- использование подзапроса не позволяет достичь высокой скорости выполнения, хоть и снижает кол-во фильтруемых и присоединяемых строк

EXPLAIN ANALYSE
SELECT human."ФАМИЛИЯ", session."ДАТА"
FROM (SELECT "ИД", "ФАМИЛИЯ"
      FROM "Н_ЛЮДИ"
      WHERE "ИМЯ" < 'Владимир') AS human
         RIGHT JOIN (SELECT "ЧЛВК_ИД", "ДАТА"
                     FROM "Н_СЕССИЯ"
                     WHERE "УЧГОД" > '2008/2009') AS session ON session."ЧЛВК_ИД" = human."ИД";

-- ЗАПРОС 2
-- ЗАПРОС 2
-- ЗАПРОС 2

EXPLAIN ANALYZE
SELECT human."ОТЧЕСТВО", study."НЗК", student."ГРУППА"
FROM "Н_ЛЮДИ" human
         JOIN "Н_ОБУЧЕНИЯ" study ON study."ЧЛВК_ИД" = human."ИД" AND study."НЗК" = '933232'
         JOIN "Н_УЧЕНИКИ" student ON student."ЧЛВК_ИД" = human."ИД" AND student."НАЧАЛО" > '2009-02-09'
WHERE human."ФАМИЛИЯ" = 'Афанасьев';


-- ### с оптимизациями, с индексами ###

-- ЗАПРОС 1
-- ЗАПРОС 1
-- ЗАПРОС 1

CREATE INDEX idx_н_люди_имя ON "Н_ЛЮДИ"("ИМЯ");             -- 20s
CREATE INDEX idx_н_люди_ид ON "Н_ЛЮДИ"("ИД");               -- 15s
CREATE INDEX idx_н_сессия_учгод ON "Н_СЕССИЯ"("УЧГОД");     -- 18s
CREATE INDEX idx_н_сессия_члвк_ид ON "Н_СЕССИЯ"("ЧЛВК_ИД"); -- 17s

CREATE UNIQUE INDEX idx_unique_н_люди_имя ON "Н_ЛЮДИ" ("ИД", "ИМЯ");                -- 30s

-- summary time: 1m 12s 402ms

EXPLAIN ANALYSE
SELECT human."ФАМИЛИЯ", session."ДАТА"
FROM "Н_ЛЮДИ" human
         RIGHT JOIN "Н_СЕССИЯ" session ON session."ЧЛВК_ИД" = human."ИД"
WHERE human."ИМЯ" < 'Владимир'
  AND session."УЧГОД" > '2008/2009';

-- ЗАПРОС 2
-- ЗАПРОС 2
-- ЗАПРОС 2

CREATE INDEX idx_н_люди_фамилия ON "Н_ЛЮДИ" ("ФАМИЛИЯ");          -- 16s
CREATE INDEX idx_н_обучения_нзк ON "Н_ОБУЧЕНИЯ" ("НЗК");          -- 15s
CREATE INDEX idx_н_ученики_начало ON "Н_УЧЕНИКИ" ("НАЧАЛО");      -- 5s
CREATE INDEX idx_н_обучения_члвк_ид ON "Н_ОБУЧЕНИЯ" ("ЧЛВК_ИД");  -- 7s
CREATE INDEX idx_н_ученики_члвк_ид ON "Н_УЧЕНИКИ" ("ЧЛВК_ИД");    -- 3s

-- summary time: 31s 781ms

EXPLAIN ANALYZE
SELECT human."ОТЧЕСТВО", study."НЗК", student."ГРУППА"
FROM "Н_ЛЮДИ" human
         JOIN "Н_ОБУЧЕНИЯ" study ON study."ЧЛВК_ИД" = human."ИД" AND study."НЗК" = '933232'
         JOIN "Н_УЧЕНИКИ" student ON student."ЧЛВК_ИД" = human."ИД" AND student."НАЧАЛО" > '2009-02-09'
WHERE human."ФАМИЛИЯ" = 'Афанасьев';



-- доп SET'ы + индексы

SET shared_buffers = '2GB';
SET work_mem = '512MB';
SET effective_cache_size = '4GB';
SET max_parallel_workers_per_gather = 12;

