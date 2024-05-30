CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

DO
$$
    DECLARE
        i INT := 0;
        last_names TEXT[] := ARRAY['Афанасьев'];
        first_names TEXT[] := ARRAY['Алексей', 'Игорь', 'Владислав', 'Георгий', 'Виктор'];
        patronymics TEXT[] := ARRAY['Иванович', 'Петрович', 'Сидорович', 'Кузнецович', 'Смирнович'];
        genders CHAR[] := ARRAY['М', 'Ж'];
    BEGIN
        FOR i IN 1..1000000 LOOP
                INSERT INTO "Н_ЛЮДИ" (
                    "ФАМИЛИЯ",
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
                    "ФИО"
                ) VALUES (
                             last_names[ceil(random() * array_length(last_names, 1))],
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
                             last_names[ceil(random() * array_length(last_names, 1))] || ' ' || first_names[ceil(random() * array_length(first_names, 1))] || ' ' || patronymics[ceil(random() * array_length(patronymics, 1))]
                         );
            END LOOP;
    END
$$;

DO

$$
    DECLARE
        i INT := 0;
        auditoria TEXT[] := ARRAY['A101', 'B202', 'C303', 'D404', 'E505'];
    BEGIN
        FOR i IN 1..10000000 LOOP
                INSERT INTO "Н_СЕССИЯ" (
                    "СЭС_ИД",
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
                    "КОГДА_ИЗМЕНИЛ"
                ) VALUES (
                             trunc(random() * 1000)::INT,
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
                             now()
                         );
            END LOOP;
    END
$$;

DO
$$
    DECLARE
        i INT := 0;
        чел_ид INT;
    BEGIN
        FOR i IN 16005119..17005110 LOOP
                чел_ид := i; -- Assuming IDs are sequential and start from 1 in Н_ЛЮДИ
                INSERT INTO "Н_ОБУЧЕНИЯ" (
                    "НЗК",
                    "ЧЛВК_ИД",
                    "ВИД_ОБУЧ_ИД",
                    "КТО_СОЗДАЛ",
                    "КОГДА_СОЗДАЛ",
                    "КТО_ИЗМЕНИЛ",
                    "КОГДА_ИЗМЕНИЛ"
                ) VALUES (
                             '933232',
                             чел_ид,
                             1,
                             substr(uuid_generate_v4()::text, 1, 40),
                             now(),
                             substr(uuid_generate_v4()::text, 1, 40),
                             now()
                         );
            END LOOP;
    END
$$;

DO
$$
    DECLARE
        чел_ид INT;
    BEGIN
        FOR чел_ид IN 16005119..17005110 LOOP
                INSERT INTO "Н_УЧЕНИКИ" (
                    "ЧЛВК_ИД",
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
                    "ТЕКСТ"
                ) VALUES (
                             чел_ид,
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
                             substr(md5(random()::text), 1, 200)
                         );
            END LOOP;
    END
$$;

SELECT count(*) FROM "Н_ЛЮДИ";
SELECT count(*) FROM "Н_СЕССИЯ";
SELECT count(*) FROM "Н_ОБУЧЕНИЯ";
SELECT count(*) FROM "Н_УЧЕНИКИ";