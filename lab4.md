# Лабораторная работа 4

## Вариант `421`

Составить запросы на языке SQL (пункты 1-2).

Для каждого запроса предложить индексы, добавление которых уменьшит время выполнения запроса (указать таблицы/атрибуты,
для которых нужно добавить индексы, написать тип индекса; объяснить, почему добавление индекса будет полезным для
данного запроса).

Для запросов 1-2 необходимо составить возможные планы выполнения запросов. Планы составляются на основании
предположения, что в таблицах отсутствуют индексы. Из составленных планов необходимо выбрать оптимальный и объяснить
свой выбор.
Изменятся ли планы при добавлении индекса и как?

Для запросов 1-2 необходимо добавить в отчет вывод команды EXPLAIN ANALYZE [запрос]

Подробные ответы на все вышеперечисленные вопросы должны присутствовать в отчете (планы выполнения запросов должны быть
нарисованы, ответы на вопросы - представлены в текстовом виде).

---

    Сделать запрос для получения атрибутов из указанных таблиц, применив фильтры по указанным условиям:
    Таблицы: Н_ЛЮДИ, Н_СЕССИЯ.
    Вывести атрибуты: Н_ЛЮДИ.ФАМИЛИЯ, Н_СЕССИЯ.ДАТА.
    Фильтры (AND):
    a) Н_ЛЮДИ.ИМЯ < Владимир.
    b) Н_СЕССИЯ.УЧГОД > 2008/2009.
    Вид соединения: RIGHT JOIN.

----

    Сделать запрос для получения атрибутов из указанных таблиц, применив фильтры по указанным условиям:
    Таблицы: Н_ЛЮДИ, Н_ОБУЧЕНИЯ, Н_УЧЕНИКИ.
    Вывести атрибуты: Н_ЛЮДИ.ОТЧЕСТВО, Н_ОБУЧЕНИЯ.НЗК, Н_УЧЕНИКИ.ГРУППА.
    Фильтры: (AND)
    a) Н_ЛЮДИ.ФАМИЛИЯ = Афанасьев.
    b) Н_ОБУЧЕНИЯ.НЗК = 933232.
    c) Н_УЧЕНИКИ.НАЧАЛО > 2009-02-09.
    Вид соединения: RIGHT JOIN.

----

## Выполнение работы

### 1. Подготовка окружения

Тестовый стенд - ryzen 3700X | 32GB RAM 3200\
ОС - Linux Manjaro

#### 1.1. "Крадём" с helios.cs.ifmo.ru дамп базы и с помощью `psql` воссоздаем такую же базу данных на локальной машине

#### 1.2. В запросах моего варианта используются только таблицы `Н_ЛЮДИ`, `Н_СЕССИЯ`, `Н_ОБУЧЕНИЯ`, `Н_УЧЕНИКИ`. Для чистоты эксперимента необходимо убрать все существующие индексы кроме PK

#### 1.3. Добавление строк для более наглядного реузльтата

Выполнив следующий sql-код мы дополним базу ~10 миллионами строк в кажду из использованных таблиц

----

```postgresql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

DO
$$
    DECLARE
        i           INT    := 0;
        last_names  TEXT[] := ARRAY ['Афанасьев'];
        first_names TEXT[] := ARRAY ['Алексей', 'Игорь', 'Владислав', 'Георгий', 'Виктор'];
        patronymics TEXT[] := ARRAY ['Иванович', 'Петрович', 'Сидорович', 'Кузнецович', 'Смирнович'];
        genders     CHAR[] := ARRAY ['М', 'Ж'];
    BEGIN
        FOR i IN 1..1000000
            LOOP
                INSERT INTO "Н_ЛЮДИ" ("ФАМИЛИЯ",
                                      "ИМЯ",
                                      "ОТЧЕСТВО",
                                      "ПИН",
                                      "ИНН",
                                      "ДАТА_РОЖДЕНИЯ",
                                      "ПОЛ",
                                      "МЕСТО_РОЖДЕНИЯ",
                                      "ИНОСТРАН",
                                      "КТО_СОЗДАЛ",
                                      "КОГДА_СОЗДАЛ",
                                      "КТО_ИЗМЕНИЛ",
                                      "КОГДА_ИЗМЕНИЛ",
                                      "ДАТА_СМЕРТИ",
                                      "ФИО")
                VALUES (last_names[ceil(random() * array_length(last_names, 1))],
                        first_names[ceil(random() * array_length(first_names, 1))],
                        patronymics[ceil(random() * array_length(patronymics, 1))],
                        substr(md5(random()::text), 1, 20),
                        substr(md5(random()::text), 1, 20),
                        timestamp '1970-01-01' + random() * (timestamp '2000-01-01' - timestamp '1970-01-01'),
                        genders[ceil(random() * array_length(genders, 1))],
                        substr(md5(random()::text), 1, 200),
                        CASE WHEN random() > 0.5 THEN 'Да' ELSE 'Нет' END,
                        substr(uuid_generate_v4()::text, 1, 40),
                        now(),
                        substr(uuid_generate_v4()::text, 1, 40),
                        now(),
                        NULL,
                        last_names[ceil(random() * array_length(last_names, 1))] || ' ' ||
                        first_names[ceil(random() * array_length(first_names, 1))] || ' ' ||
                        patronymics[ceil(random() * array_length(patronymics, 1))]);
            END LOOP;
    END
$$;

DO
$$
    DECLARE
        i         INT    := 0;
        auditoria TEXT[] := ARRAY ['A101', 'B202', 'C303', 'D404', 'E505'];
    BEGIN
        FOR i IN 1..10000000
            LOOP
                INSERT INTO "Н_СЕССИЯ" ("СЭС_ИД",
                                        "ЧЛВК_ИД",
                                        "ДАТА",
                                        "ВРЕМЯ",
                                        "АУДИТОРИЯ",
                                        "ДАТА_К",
                                        "ВРЕМЯ_К",
                                        "АУДИТОРИЯ_К",
                                        "УЧГОД",
                                        "ГРУППА",
                                        "СЕМЕСТР",
                                        "КТО_СОЗДАЛ",
                                        "КОГДА_СОЗДАЛ",
                                        "КТО_ИЗМЕНИЛ",
                                        "КОГДА_ИЗМЕНИЛ")
                VALUES (trunc(random() * 1000)::INT,
                        trunc(random() * 1000000)::INT,
                        timestamp '1970-01-01' + random() * (timestamp '2024-01-01' - timestamp '1970-01-01'),
                        timestamp '1970-01-01' + random() * (timestamp '2024-01-01' - timestamp '1970-01-01'),
                        auditoria[ceil(random() * array_length(auditoria, 1))],
                        timestamp '1970-01-01' + random() * (timestamp '2024-01-01' - timestamp '1970-01-01'),
                        timestamp '1970-01-01' + random() * (timestamp '2024-01-01' - timestamp '1970-01-01'),
                        auditoria[ceil(random() * array_length(auditoria, 1))],
                        '2007/2008',
                        trunc(random() * 100)::INT,
                        trunc(random() * 10)::INT,
                        substr(uuid_generate_v4()::text, 1, 20),
                        now(),
                        substr(uuid_generate_v4()::text, 1, 20),
                        now());
            END LOOP;
    END
$$;

DO
$$
    DECLARE
        i      INT := 0;
        чел_ид INT;
    BEGIN
        FOR i IN 16005119..17005110
            LOOP
                чел_ид := i; -- Assuming IDs are sequential and start from 1 in Н_ЛЮДИ
                INSERT INTO "Н_ОБУЧЕНИЯ" ("НЗК",
                                          "ЧЛВК_ИД",
                                          "ВИД_ОБУЧ_ИД",
                                          "КТО_СОЗДАЛ",
                                          "КОГДА_СОЗДАЛ",
                                          "КТО_ИЗМЕНИЛ",
                                          "КОГДА_ИЗМЕНИЛ")
                VALUES ('933232',
                        чел_ид,
                        1,
                        substr(uuid_generate_v4()::text, 1, 40),
                        now(),
                        substr(uuid_generate_v4()::text, 1, 40),
                        now());
            END LOOP;
    END
$$;

DO
$$
    DECLARE
        чел_ид INT;
    BEGIN
        FOR чел_ид IN 16005119..17005110
            LOOP
                INSERT INTO "Н_УЧЕНИКИ" ("ЧЛВК_ИД",
                                         "ПРИЗНАК",
                                         "СОСТОЯНИЕ",
                                         "НАЧАЛО",
                                         "КОНЕЦ",
                                         "ПЛАН_ИД",
                                         "ГРУППА",
                                         "П_ПРКОК_ИД",
                                         "ВИД_ОБУЧ_ИД",
                                         "ПРИМЕЧАНИЕ",
                                         "КТО_СОЗДАЛ",
                                         "КОГДА_СОЗДАЛ",
                                         "КТО_ИЗМЕНИЛ",
                                         "КОГДА_ИЗМЕНИЛ",
                                         "КОНЕЦ_ПО_ПРИКАЗУ",
                                         "ВМЕСТО",
                                         "В_СВЯЗИ_С",
                                         "ТЕКСТ")
                VALUES (чел_ид,
                        substr(md5(random()::text), 1, 10),
                        substr(md5(random()::text), 1, 9),
                        timestamp '1970-01-01' + random() * (timestamp '2024-01-01' - timestamp '1970-01-01'),
                        timestamp '1970-01-01' + random() * (timestamp '2024-01-01' - timestamp '1970-01-01'),
                        trunc(random() * 1000)::INT,
                        substr(md5(random()::text), 1, 4),
                        trunc(random() * 1000)::INT,
                        trunc(random() * 10)::INT,
                        substr(md5(random()::text), 1, 200),
                        substr(uuid_generate_v4()::text, 1, 40),
                        now(),
                        substr(uuid_generate_v4()::text, 1, 40),
                        now(),
                        timestamp '1970-01-01' + random() * (timestamp '2024-01-01' - timestamp '1970-01-01'),
                        trunc(random() * 1000)::INT,
                        trunc(random() * 1000)::INT,
                        substr(md5(random()::text), 1, 200));
            END LOOP;
    END
$$;
```

----

### 1.1. Итоговое количество данных в каждой таблице:

| таблица        | кол-во строк | запрос для получения кол-ва строк   |
|----------------|--------------|-------------------------------------|
| **Н_УЧЕНИКИ**  | 16005118     | `SELECT count(*) FROM "Н_УЧЕНИКИ"`  |
| **Н_СЕССИЯ**   | 23003752     | `SELECT count(*) FROM "Н_СЕССИЯ"`   |
| **Н_ОБУЧЕНИЯ** | 10000000     | `SELECT count(*) FROM "Н_ОБУЧЕНИЯ"` |
| **Н_УЧЕНИКИ**  | 1023303      | `SELECT count(*) FROM "Н_УЧЕНИКИ"`  |

----

### 2. Выполнение пунктов 1-2

#### 2.1. Неоптимизированные запросы + без использования индексов

`Запрос 1`

```postgresql
EXPLAIN ANALYSE
SELECT human."ФАМИЛИЯ", session."ДАТА"
FROM "Н_ЛЮДИ" human
         RIGHT JOIN "Н_СЕССИЯ" session ON session."ЧЛВК_ИД" = human."ИД"
WHERE human."ИМЯ" < 'Владимир'
  AND session."УЧГОД" > '2008/2009';
```

`Результат EXPLAIN ANALYSE`

```text
Gather  (cost=1000.45..1161437.08 rows=1996 width=22) (actual time=118.929..10249.957 rows=1833 loops=1)
  Workers Planned: 2
  Workers Launched: 2
  ->  Nested Loop  (cost=0.45..1160237.48 rows=832 width=22) (actual time=5398.107..10195.146 rows=611 loops=3)
"        ->  Parallel Seq Scan on ""Н_ЛЮДИ"" human  (cost=0.00..773507.32 rows=2824545 width=18) (actual time=138.578..7524.894 rows=2266946 loops=3)"
"              Filter: ((""ИМЯ"")::text < 'Владимир'::text)"
              Rows Removed by Filter: 3401426
        ->  Memoize  (cost=0.45..61.97 rows=1 width=12) (actual time=0.000..0.001 rows=0 loops=6800839)
"              Cache Key: human.""ИД"""
              Cache Mode: logical
              Hits: 2080929  Misses: 640  Evictions: 0  Overflows: 0  Memory Usage: 69kB
              Worker 0:  Hits: 2351418  Misses: 570  Evictions: 0  Overflows: 0  Memory Usage: 66kB
              Worker 1:  Hits: 2366724  Misses: 558  Evictions: 0  Overflows: 0  Memory Usage: 62kB
"              ->  Index Scan using ""SYS_C003500_IFK"" on ""Н_СЕССИЯ"" session  (cost=0.44..61.96 rows=1 width=12) (actual time=1.578..3.806 rows=1 loops=1768)"
"                    Index Cond: (""ЧЛВК_ИД"" = human.""ИД"")"
"                    Filter: ((""УЧГОД"")::text > '2008/2009'::text)"
                    Rows Removed by Filter: 22
Planning Time: 0.920 ms
JIT:
  Functions: 45
"  Options: Inlining true, Optimization true, Expressions true, Deforming true"
"  Timing: Generation 2.251 ms, Inlining 98.974 ms, Optimization 189.644 ms, Emission 127.086 ms, Total 417.956 ms"
Execution Time: 10250.749 ms
```

Из EXPLAIN ANALYSE мы видим, что только спустя **10250.749 ms** мы получили результат, обрабатывая 1833 строки с использованием параллельного сканирования и вложенных циклов. Основное время уходит на параллельное сканирование таблицы `Н_ЛЮДИ` и последующее кэширование для ускорения соединений.

`Запрос 2`

```postgresql
EXPLAIN ANALYSE
SELECT human."ОТЧЕСТВО", study."НЗК", student."ГРУППА"
FROM "Н_ЛЮДИ" human
         RIGHT JOIN "Н_ОБУЧЕНИЯ" study ON study."ЧЛВК_ИД" = human."ИД"
         RIGHT JOIN "Н_УЧЕНИКИ" student ON student."ЧЛВК_ИД" = human."ИД"
WHERE human."ФАМИЛИЯ" = 'Афанасьев'
  AND study."НЗК" = '933232'
  AND student."НАЧАЛО" > '2009-02-09';
```

`Результат EXPLAIN ANALYSE`

```text
Nested Loop  (cost=45316.74..954867.49 rows=1 width=29) (actual time=8644.274..9715.802 rows=6 loops=1)
"  Join Filter: (study.""ЧЛВК_ИД"" = human.""ИД"")"
  ->  Gather  (cost=45316.30..818824.62 rows=1 width=30) (actual time=8641.615..8646.413 rows=6 loops=1)
        Workers Planned: 2
        Workers Launched: 2
        ->  Parallel Hash Join  (cost=44316.30..817824.52 rows=1 width=30) (actual time=8628.880..8629.046 rows=2 loops=3)
"              Hash Cond: (human.""ИД"" = student.""ЧЛВК_ИД"")"
"              ->  Parallel Seq Scan on ""Н_ЛЮДИ"" human  (cost=0.00..773507.32 rows=236 width=22) (actual time=3964.511..7507.657 rows=333336 loops=3)"
"                    Filter: ((""ФАМИЛИЯ"")::text = 'Афанасьев'::text)"
                    Rows Removed by Filter: 5335036
              ->  Parallel Hash  (cost=42906.70..42906.70 rows=112768 width=8) (actual time=1105.315..1105.315 rows=93193 loops=3)
                    Buckets: 524288  Batches: 1  Memory Usage: 17280kB
"                    ->  Parallel Seq Scan on ""Н_УЧЕНИКИ"" student  (cost=0.00..42906.70 rows=112768 width=8) (actual time=157.108..1078.225 rows=93193 loops=3)"
"                          Filter: (""НАЧАЛО"" > '2009-02-09 00:00:00'::timestamp without time zone)"
                          Rows Removed by Filter: 247908
"  ->  Index Scan using ""ОБУЧ_PK"" on ""Н_ОБУЧЕНИЯ"" study  (cost=0.43..136042.86 rows=1 width=11) (actual time=2.711..178.223 rows=1 loops=6)"
"        Index Cond: (""ЧЛВК_ИД"" = student.""ЧЛВК_ИД"")"
"        Filter: ((""НЗК"")::text = '933232'::text)"
Planning Time: 0.225 ms
JIT:
  Functions: 54
"  Options: Inlining true, Optimization true, Expressions true, Deforming true"
"  Timing: Generation 2.388 ms, Inlining 105.273 ms, Optimization 217.582 ms, Emission 147.941 ms, Total 473.184 ms"
Execution Time: 9716.989 ms
```

Запрос выполняется за **9716.989 мс**, обрабатывая 6 строк с использованием параллельного хеш-соединения и вложенного цикла. Основное время затрачено на параллельное последовательное сканирование таблицы "Н_ЛЮДИ", фильтрацию по фамилии "Афанасьев", а также на параллельное хеширование таблицы "Н_УЧЕНИКИ" и индексное сканирование таблицы `Н_ОБУЧЕНИЯ`.

#### 2.2. Оптимизируем запрос + не используем индексы

`Запрос 1`

Исследуя вывод EXPLAIN ANALYSE можно уверенно сказать, что большая часть времени уходит на последовательное сканирование
таблиц `Н_ЛЮДИ` и `Н_СЕССИЯ`, а также на фильтрацию строк\
Поскольку условия данного пункта не разрешают нам использовать индексы - нам нужно выделить основные узкие места:

- Сканирование таблицы `Н_ЛЮДИ`: Фильтр по `"ИМЯ" < 'Владимир'` удаляет около **половины** строк.
- Сканирование таблицы `Н_СЕССИЯ`: Фильтр по `"УЧГОД" > '2008/2009'` удаляет **большинство** строк.
- Соединение таблиц: Параллельное соединение также занимает значительное время

Я попробую разделить запросы на части: сначала отфильтровать нужные данные и держать их во временной таблице, а затем
выполнить соединение на меньших данных

Так же выставлю `SET work_mem = '10000MB'`

`Обновленный запрос #1`

```postgresql
EXPLAIN ANALYSE
SELECT human."ФАМИЛИЯ", session."ДАТА"
FROM (SELECT "ИД", "ФАМИЛИЯ"
      FROM "Н_ЛЮДИ"
      WHERE "ИМЯ" < 'Владимир') AS human
         RIGHT JOIN (SELECT "ЧЛВК_ИД", "ДАТА"
                     FROM "Н_СЕССИЯ"
                     WHERE "УЧГОД" > '2008/2009') AS session ON session."ЧЛВК_ИД" = human."ИД";
```

`результаты EXPLAIN ANALYSE`

```text
Gather  (cost=503538.66..1409872.61 rows=869243 width=22) (actual time=315.597..8396.920 rows=876123 loops=1)
  Workers Planned: 2
  Workers Launched: 2
  ->  Parallel Hash Right Join  (cost=502538.66..1321948.31 rows=362185 width=22) (actual time=5561.328..8235.687 rows=292041 loops=3)
"        Hash Cond: (""Н_ЛЮДИ"".""ИД"" = ""Н_СЕССИЯ"".""ЧЛВК_ИД"")"
"        ->  Parallel Seq Scan on ""Н_ЛЮДИ""  (cost=0.00..773507.32 rows=2824545 width=18) (actual time=0.045..7803.256 rows=2266946 loops=3)"
"              Filter: ((""ИМЯ"")::text < 'Владимир'::text)"
              Rows Removed by Filter: 3401426
        ->  Parallel Hash  (cost=498011.35..498011.35 rows=362185 width=12) (actual time=298.174..298.175 rows=292041 loops=3)
              Buckets: 1048576  Batches: 1  Memory Usage: 49344kB
"              ->  Parallel Bitmap Heap Scan on ""Н_СЕССИЯ""  (cost=303.76..498011.35 rows=362185 width=12) (actual time=136.185..223.755 rows=292041 loops=3)"
"                    Recheck Cond: ((""УЧГОД"")::text > '2008/2009'::text)"
                    Rows Removed by Index Recheck: 43000
                    Heap Blocks: lossy=8879
"                    ->  Bitmap Index Scan on ""idx_н_сессия_учгод_brin""  (cost=0.00..86.45 rows=1588912 width=0) (actual time=5.601..5.601 rows=213760 loops=1)"
"                          Index Cond: ((""УЧГОД"")::text > '2008/2009'::text)"
Planning Time: 0.362 ms
JIT:
  Functions: 45
"  Options: Inlining true, Optimization true, Expressions true, Deforming true"
"  Timing: Generation 3.498 ms, Inlining 90.010 ms, Optimization 187.275 ms, Emission 125.557 ms, Total 406.339 ms"
Execution Time: 8423.783 ms
```

Запрос выполняется за **8423.783 мс**, обрабатывая 876123 строки с использованием параллельного хеш-соединения. Основное время затрачено на параллельное последовательное сканирование таблицы `Н_ЛЮДИ` и параллельное сканирование таблицы `Н_СЕССИЯ` с повторной проверкой индекса. Узкое место — фильтрация и сканирование большой таблицы `Н_ЛЮДИ`.

`Запрос 2`

В запросе #2, чтобы добитсья лучшей производительности нужнно сократить объем обрабатываемых данных. Это можно сделать с помощью условий фильтраций непосредственно в JOIN, что уменьшает количество строк, участвующих в соединении.

`Обновленный запрос #2`
```postgresql
EXPLAIN ANALYZE
SELECT human."ОТЧЕСТВО", study."НЗК", student."ГРУППА"
FROM "Н_ЛЮДИ" human
         JOIN "Н_ОБУЧЕНИЯ" study ON study."ЧЛВК_ИД" = human."ИД" AND study."НЗК" = '933232'
         JOIN "Н_УЧЕНИКИ" student ON student."ЧЛВК_ИД" = human."ИД" AND student."НАЧАЛО" > '2009-02-09'
WHERE human."ФАМИЛИЯ" = 'Афанасьев';
```

`результаты EXPLAIN ANALYSE`

```text
Nested Loop  (cost=45316.74..954867.49 rows=1 width=29) (actual time=9727.360..10789.054 rows=6 loops=1)
"  Join Filter: (study.""ЧЛВК_ИД"" = human.""ИД"")"
  ->  Gather  (cost=45316.30..818824.62 rows=1 width=30) (actual time=9724.556..9729.699 rows=6 loops=1)
        Workers Planned: 2
        Workers Launched: 2
        ->  Parallel Hash Join  (cost=44316.30..817824.52 rows=1 width=30) (actual time=9709.009..9709.660 rows=2 loops=3)
"              Hash Cond: (human.""ИД"" = student.""ЧЛВК_ИД"")"
"              ->  Parallel Seq Scan on ""Н_ЛЮДИ"" human  (cost=0.00..773507.32 rows=236 width=22) (actual time=4533.589..8820.302 rows=333336 loops=3)"
"                    Filter: ((""ФАМИЛИЯ"")::text = 'Афанасьев'::text)"
                    Rows Removed by Filter: 5335036
              ->  Parallel Hash  (cost=42906.70..42906.70 rows=112768 width=8) (actual time=874.690..874.691 rows=93193 loops=3)
                    Buckets: 524288  Batches: 1  Memory Usage: 17280kB
"                    ->  Parallel Seq Scan on ""Н_УЧЕНИКИ"" student  (cost=0.00..42906.70 rows=112768 width=8) (actual time=153.656..848.961 rows=93193 loops=3)"
"                          Filter: (""НАЧАЛО"" > '2009-02-09 00:00:00'::timestamp without time zone)"
                          Rows Removed by Filter: 247908
"  ->  Index Scan using ""ОБУЧ_PK"" on ""Н_ОБУЧЕНИЯ"" study  (cost=0.43..136042.86 rows=1 width=11) (actual time=2.777..176.553 rows=1 loops=6)"
"        Index Cond: (""ЧЛВК_ИД"" = student.""ЧЛВК_ИД"")"
"        Filter: ((""НЗК"")::text = '933232'::text)"
Planning Time: 0.185 ms
JIT:
  Functions: 54
"  Options: Inlining true, Optimization true, Expressions true, Deforming true"
"  Timing: Generation 3.881 ms, Inlining 102.776 ms, Optimization 211.774 ms, Emission 146.058 ms, Total 464.489 ms"
Execution Time: 10789.936 ms
```

Запрос выполняется за **10789.936 мс**, обрабатывая 6 строк с использованием параллельного хеш-соединения и вложенного цикла. Основное время затрачено на параллельное последовательное сканирование таблицы "Н_ЛЮДИ" и фильтрацию по фамилии "Афанасьев", а также на параллельное хеширование таблицы `Н_УЧЕНИКИ` и индексное сканирование таблицы `Н_ОБУЧЕНИЯ`.\
Узкое место — фильтрация большого объема данных в таблице `Н_ЛЮДИ`.

#### 2.2. Оптимизируем запрос + используем индексы

`Запрос 1`
1. **CREATE INDEX idx_н_люди_имя ON "Н_ЛЮДИ"("ИМЯ");**
    - Ускоряет поиск людей по имени для условия `human."ИМЯ" < 'Владимир'`.

2. **CREATE INDEX idx_н_люди_ид ON "Н_ЛЮДИ"("ИД");**
    - Ускоряет соединение с таблицей "Н_СЕССИЯ".

3. **CREATE INDEX idx_н_сессия_учгод ON "Н_СЕССИЯ"("УЧГОД");**
    - Ускоряет поиск сессий по году для условия `session."УЧГОД" > '2008/2009'`.

4. **CREATE INDEX idx_н_сессия_члвк_ид ON "Н_СЕССИЯ"("ЧЛВК_ИД");**
    - Ускоряет соединение с таблицей "Н_ЛЮДИ".

5. **CREATE UNIQUE INDEX idx_unique_н_люди_имя ON "Н_ЛЮДИ" ("ИД", "ИМЯ");**
    - Обеспечивает уникальность комбинации идентификатора и имени и ускоряет выполнение запросов.

Эти индексы помогают значительно ускорить выполнение запроса:

`Обновленный запрос #1`

```postgresql
CREATE INDEX idx_н_люди_имя ON "Н_ЛЮДИ" ("ИМЯ"); -- 20s
CREATE INDEX idx_н_люди_ид ON "Н_ЛЮДИ" ("ИД"); -- 15s
CREATE INDEX idx_н_сессия_учгод ON "Н_СЕССИЯ" ("УЧГОД"); -- 18s
CREATE INDEX idx_н_сессия_члвк_ид ON "Н_СЕССИЯ" ("ЧЛВК_ИД"); -- 17s

CREATE UNIQUE INDEX idx_unique_н_люди_имя ON "Н_ЛЮДИ" ("ИД", "ИМЯ");
-- 30s

-- summary time: 1m 12s 402ms

EXPLAIN ANALYSE
SELECT human."ФАМИЛИЯ", session."ДАТА"
FROM "Н_ЛЮДИ" human
         RIGHT JOIN "Н_СЕССИЯ" session ON session."ЧЛВК_ИД" = human."ИД"
WHERE human."ИМЯ" < 'Владимир'
  AND session."УЧГОД" > '2008/2009';
```

`результаты EXPLAIN ANALYSE`

```text
Merge Join  (cost=595862.25..604710.04 rows=1996 width=22) (actual time=488.266..497.843 rows=1833 loops=1)
"  Merge Cond: (human.""ИД"" = session.""ЧЛВК_ИД"")"
"  ->  Index Scan using ""idx_unique_н_люди_имя"" on ""Н_ЛЮДИ"" human  (cost=0.56..16640137.17 rows=6778915 width=18) (actual time=0.026..1.083 rows=1766 loops=1)"
"        Index Cond: ((""ИМЯ"")::text < 'Владимир'::text)"
  ->  Sort  (cost=595345.38..597518.48 rows=869243 width=12) (actual time=372.209..387.575 rows=143830 loops=1)
"        Sort Key: session.""ЧЛВК_ИД"""
        Sort Method: quicksort  Memory: 58796kB
"        ->  Bitmap Heap Scan on ""Н_СЕССИЯ"" session  (cost=303.76..509597.16 rows=869243 width=12) (actual time=1.415..206.577 rows=876123 loops=1)"
"              Recheck Cond: ((""УЧГОД"")::text > '2008/2009'::text)"
              Rows Removed by Index Recheck: 129000
              Heap Blocks: lossy=21376
"              ->  Bitmap Index Scan on ""idx_н_сессия_учгод_brin""  (cost=0.00..86.45 rows=1588912 width=0) (actual time=1.330..1.330 rows=213760 loops=1)"
"                    Index Cond: ((""УЧГОД"")::text > '2008/2009'::text)"
Planning Time: 0.253 ms
JIT:
  Functions: 13
"  Options: Inlining true, Optimization true, Expressions true, Deforming true"
"  Timing: Generation 0.608 ms, Inlining 5.227 ms, Optimization 59.925 ms, Emission 37.455 ms, Total 103.215 ms"
Execution Time: 500.918 ms
```

Запрос выполняется за 500.918 мс, возвращая 1833 строки. Основное время затрачено на `Merge Join`, который использует индексное сканирование по таблице "Н_ЛЮДИ" с условием на `ИМЯ` и сортировку по таблице "Н_СЕССИЯ" с использованием `Bitmap Heap Scan`. Индексы значительно ускорили выполнение запроса.

`Запрос 2`
1. **CREATE INDEX idx_н_люди_фамилия ON "Н_ЛЮДИ" ("ФАМИЛИЯ");**
    - Ускоряет поиск людей по фамилии для условия `human."ФАМИЛИЯ" = 'Афанасьев'`.

2. **CREATE INDEX idx_н_обучения_нзк ON "Н_ОБУЧЕНИЯ" ("НЗК");**
    - Ускоряет поиск по коду обучения для условия `study."НЗК" = '933232'`.

3. **CREATE INDEX idx_н_ученики_начало ON "Н_УЧЕНИКИ" ("НАЧАЛО");**
    - Ускоряет поиск учеников по дате начала для условия `student."НАЧАЛО" > '2009-02-09'`.

4. **CREATE INDEX idx_н_обучения_члвк_ид ON "Н_ОБУЧЕНИЯ" ("ЧЛВК_ИД");**
    - Ускоряет соединение с таблицей "Н_ЛЮДИ".

5. **CREATE INDEX idx_н_ученики_члвк_ид ON "Н_УЧЕНИКИ" ("ЧЛВК_ИД");**
    - Ускоряет соединение с таблицей "Н_ЛЮДИ".

6. **CREATE UNIQUE INDEX idx_н_обучения_ид_unique ON "Н_ОБУЧЕНИЯ" ("ЧЛВК_ИД", "НЗК");**
    - Обеспечивает уникальность комбинации идентификатора человека и кода обучения, ускоряя выполнение запросов.

`Обновленный запрос #2`
```postgresql
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
```

`результаты EXPLAIN ANALYSE`

```text
Nested Loop  (cost=1.31..4788.95 rows=1 width=29) (actual time=4.189..599.494 rows=6 loops=1)
  ->  Nested Loop  (cost=0.88..4785.07 rows=1 width=33) (actual time=1.151..592.272 rows=9 loops=1)
"        ->  Index Scan using ""idx_н_люди_фамилия"" on ""Н_ЛЮДИ"" human  (cost=0.44..2192.68 rows=567 width=22) (actual time=0.613..373.408 rows=1000009 loops=1)"
"              Index Cond: ((""ФАМИЛИЯ"")::text = 'Афанасьев'::text)"
        ->  Memoize  (cost=0.45..4.81 rows=1 width=11) (actual time=0.000..0.000 rows=0 loops=1000009)
"              Cache Key: human.""ИД"""
              Cache Mode: logical
              Hits: 999999  Misses: 10  Evictions: 0  Overflows: 0  Memory Usage: 2kB
"              ->  Index Only Scan using ""idx_н_обучения_ид_unique"" on ""Н_ОБУЧЕНИЯ"" study  (cost=0.43..4.80 rows=1 width=11) (actual time=0.558..0.558 rows=1 loops=10)"
"                    Index Cond: ((""ЧЛВК_ИД"" = human.""ИД"") AND (""НЗК"" = '933232'::text))"
                    Heap Fetches: 0
"  ->  Index Scan using ""idx_н_ученики_члвк_ид"" on ""Н_УЧЕНИКИ"" student  (cost=0.42..3.86 rows=1 width=8) (actual time=0.738..0.801 rows=1 loops=9)"
"        Index Cond: (""ЧЛВК_ИД"" = study.""ЧЛВК_ИД"")"
"        Filter: (""НАЧАЛО"" > '2009-02-09 00:00:00'::timestamp without time zone)"
        Rows Removed by Filter: 4
Planning Time: 3.500 ms
Execution Time: 599.526 ms
```
Запрос выполняется за **599.526 мс**, обрабатывая 6 строк с использованием вложенного цикла. Основное время затрачено на индексное сканирование по фамилии "Афанасьев" и кэширование результатов соединения, что значительно ускоряет выполнение.

#### 2.4 Последний шаг к безумию

выставить 
```postgresql
SET shared_buffers = '2GB';
SET work_mem = '512MB';
SET effective_cache_size = '4GB';
SET max_parallel_workers_per_gather = 12;
```

`Запрос #1 EXPLAIN ANALYZE` Выполнился за **504.464 ms**
```text
Merge Join  (cost=595862.25..604710.04 rows=1996 width=22) (actual time=492.194..501.730 rows=1833 loops=1)
"  Merge Cond: (human.""ИД"" = session.""ЧЛВК_ИД"")"
"  ->  Index Scan using ""idx_unique_н_люди_имя"" on ""Н_ЛЮДИ"" human  (cost=0.56..16640137.17 rows=6778915 width=18) (actual time=0.025..1.048 rows=1766 loops=1)"
"        Index Cond: ((""ИМЯ"")::text < 'Владимир'::text)"
  ->  Sort  (cost=595345.38..597518.48 rows=869243 width=12) (actual time=371.883..387.155 rows=143830 loops=1)
"        Sort Key: session.""ЧЛВК_ИД"""
        Sort Method: quicksort  Memory: 58796kB
"        ->  Bitmap Heap Scan on ""Н_СЕССИЯ"" session  (cost=303.76..509597.16 rows=869243 width=12) (actual time=1.334..206.568 rows=876123 loops=1)"
"              Recheck Cond: ((""УЧГОД"")::text > '2008/2009'::text)"
              Rows Removed by Index Recheck: 129000
              Heap Blocks: lossy=21376
"              ->  Bitmap Index Scan on ""idx_н_сессия_учгод_brin""  (cost=0.00..86.45 rows=1588912 width=0) (actual time=1.251..1.251 rows=213760 loops=1)"
"                    Index Cond: ((""УЧГОД"")::text > '2008/2009'::text)"
Planning Time: 0.226 ms
JIT:
  Functions: 13
"  Options: Inlining true, Optimization true, Expressions true, Deforming true"
"  Timing: Generation 0.506 ms, Inlining 5.041 ms, Optimization 63.590 ms, Emission 38.540 ms, Total 107.677 ms"
Execution Time: 504.464 ms
```

`Запрос #2 EXPLAIN ANALYZE` Выполнился за **395.099 ms**
```text
Nested Loop  (cost=1.31..4788.95 rows=1 width=29) (actual time=0.487..395.068 rows=6 loops=1)
  ->  Nested Loop  (cost=0.88..4785.07 rows=1 width=33) (actual time=0.426..394.920 rows=9 loops=1)
"        ->  Index Scan using ""idx_н_люди_фамилия"" on ""Н_ЛЮДИ"" human  (cost=0.44..2192.68 rows=567 width=22) (actual time=0.024..193.358 rows=1000009 loops=1)"
"              Index Cond: ((""ФАМИЛИЯ"")::text = 'Афанасьев'::text)"
        ->  Memoize  (cost=0.45..4.81 rows=1 width=11) (actual time=0.000..0.000 rows=0 loops=1000009)
"              Cache Key: human.""ИД"""
              Cache Mode: logical
              Hits: 999999  Misses: 10  Evictions: 0  Overflows: 0  Memory Usage: 2kB
"              ->  Index Only Scan using ""idx_н_обучения_ид_unique"" on ""Н_ОБУЧЕНИЯ"" study  (cost=0.43..4.80 rows=1 width=11) (actual time=0.043..0.043 rows=1 loops=10)"
"                    Index Cond: ((""ЧЛВК_ИД"" = human.""ИД"") AND (""НЗК"" = '933232'::text))"
                    Heap Fetches: 0
"  ->  Index Scan using ""idx_н_ученики_члвк_ид"" on ""Н_УЧЕНИКИ"" student  (cost=0.42..3.86 rows=1 width=8) (actual time=0.015..0.016 rows=1 loops=9)"
"        Index Cond: (""ЧЛВК_ИД"" = study.""ЧЛВК_ИД"")"
"        Filter: (""НАЧАЛО"" > '2009-02-09 00:00:00'::timestamp without time zone)"
        Rows Removed by Filter: 4
Planning Time: 2.242 ms
Execution Time: 395.099 ms
```

### 3. Итоговая таблица

#### 3.1. Запрос #1

каждый замер проводился после `systemctl reload postgresql.service  `

| Параметры                                                 | Время обработки <br/> (среднее) |       | #1 (ms)   | #2 (ms)   | #3 (ms)   | #4 (ms)   |
|-----------------------------------------------------------|---------------------------------|-------|-----------|-----------|-----------|-----------|
| - неоптимизированный запрос <br/> - не используем индексы | **11394.337ms** ~ **11.4s**     |       | 13311.425 | 11269.798 | 10549.443 | 10446.682 |
| - оптимизированный запрос <br/> - не используем индексы   | **8327.702ms** ~ **8.3s**       |       | 8357.725  | 8320.090  | 8346.285  | 8286.708  |
| - оптимизированный запрос <br/> - используем индексы      | **516.69025ms** ~  **0.5s**     |       | 504.940   | 534.442   | 511.734   | 515.645   |

Ускорение:
- Оптимизированный запрос без индексов: 11394.337ms до 8327.702ms (примерно на 27%)
- Оптимизированный запрос с индексами: 11394.337ms до 516.69025ms (примерно на 95.5%)

#### 3.2. Запрос #2

| Параметры                                                 | Время обработки <br/> (среднее) |       | #1 (ms)   | #2 (ms)  | #3 (ms)  | #4 (ms)  |
|-----------------------------------------------------------|---------------------------------|-------|-----------|----------|----------|----------|
| - неоптимизированный запрос <br/> - не используем индексы | **10563.4625ms** ~  **10.5s**   |       | 13311.425 | 9707.682 | 9598.447 | 9636.296 |
| - оптимизированный запрос <br/> - не используем индексы   | **9522.5245ms**  ~ **9.5s**     |       | 9598.910  | 9498.271 | 9499.890 | 9493.027 |
| - оптимизированный запрос <br/> - используем индексы      | **405.7035ms** ~ **0.4s**       |       | 443.051   | 397.310  | 387.760  | 394.693  |

Ускорение:
- Оптимизированный запрос без индексов: 10563.4625ms до 9522.5245ms (примерно на 9.8%)
- Оптимизированный запрос с индексами: 10563.4625ms до 405.7035ms (примерно на 96.2%)

#### 3.2. Своевременные итоги

Использование индексов позволяет значительно ускорить выполнение запросов. Для запроса #1 удалось сократить время выполнения на 95.5%, а для запроса #2 на 96.2%. Это важно, поскольку позволяет обрабатывать большие объемы данных значительно быстрее, улучшая общую производительность системы и снижая нагрузку на базу данных.

### Так а почему BTREE?

Я выбрал BTREE для всех индексов, потому что этот тип индекса отлично подходит для большинства операций поиска и сортировки. BTREE-индексы помогают быстро находить нужные данные, даже если запросы содержат условия на сравнение или диапазон. Это делает их универсальными и эффективными для моих запросов.

### Важность индексов и их применение

Индексы значительно ускоряют выполнение запросов к базе данных. Они работают как содержимое в книге: позволяют быстро найти нужную информацию, вместо того чтобы просматривать все страницы подряд.

#### Типы индексов и их применение

1. **BTREE индексы**:
    - **Почему BTREE**: Они хорошо работают для поиска и сортировки данных.
    - **Когда использовать**:
        - Когда нужно часто искать данные по определенным столбцам.
        - Когда запросы содержат условия вроде `меньше`, `больше`, `равно`.

2. **Hash индексы**:
    - **Почему Hash**: Очень быстрые для поиска точных совпадений.
    - **Когда использовать**:
        - Когда запросы всегда ищут точное совпадение по какому-то значению.
        - Например, для поиска пользователя по уникальному идентификатору.

Использование правильных индексов помогает базе данных работать быстрее, снижая время выполнения запросов и улучшая общую производительность системы.

ну и секретный compose.yaml для поднятия базы:
```
version: '3.8'

services:
  db:
    image: postgres:latest
    environment:
      POSTGRES_DB: lab4
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: HackMe228
    ports:
      - "5433:5432"
```