-- =====================================================
-- Демонстрация работы триггеров и функций
-- =====================================================

-- 1. Показываем текущие аномалии до теста
SELECT '=== Аномалии ДО теста ===' AS message;
SELECT id, satellite_id, severity, description, resolved 
FROM anomalies 
WHERE description LIKE '%Sensor%'
ORDER BY id DESC LIMIT 3;

-- 2. Демонстрация триггера: вставляем "плохую" телеметрию
-- (выход за пределы max_val)
DO $$
DECLARE
    temp_sensor_id INT;
BEGIN
    -- Берём датчик температуры
    SELECT s.id INTO temp_sensor_id
    FROM sensors s
    WHERE s.sensor_type = 'temperature'
    LIMIT 1;
    
    -- Вставляем критическое значение (превышает max_val)
    INSERT INTO telemetry (sensor_id, timestamp, value)
    VALUES (temp_sensor_id, NOW(), 95.0);
    
    RAISE NOTICE 'Вставлена телеметрия с температурой 95°C (триггер должен создать аномалию)';
END $$;

-- 3. Проверяем, появилась ли аномалия
SELECT '=== Аномалии ПОСЛЕ теста (должна быть новая) ===' AS message;
SELECT id, satellite_id, severity, description, resolved 
FROM anomalies 
WHERE description LIKE '%exceeds maximum%'
ORDER BY id DESC LIMIT 3;

-- 4. Демонстрация функции get_upcoming_passes
SELECT '=== Ближайшие окна видимости для CubeSat-1 ===' AS message;
SELECT * FROM get_upcoming_passes(
    (SELECT id FROM satellites WHERE name = 'CubeSat-1'),
    72
);

-- 5. Демонстрация функции get_satellite_health
SELECT '=== Состояние здоровья спутника CubeSat-1 ===' AS message;
SELECT * FROM get_satellite_health(
    (SELECT id FROM satellites WHERE name = 'CubeSat-1'),
    48
);

-- 6. Демонстрация ручного изменения аномалии (триггер update_resolved_at)
SELECT '=== Аномалия ДО отметки resolved ===' AS message;
SELECT id, severity, description, resolved, resolved_at 
FROM anomalies 
WHERE resolved = FALSE 
LIMIT 1;

DO $$
DECLARE
    anomaly_id INT;
BEGIN
    SELECT id INTO anomaly_id FROM anomalies WHERE resolved = FALSE LIMIT 1;
    IF anomaly_id IS NOT NULL THEN
        UPDATE anomalies SET resolved = TRUE WHERE id = anomaly_id;
        RAISE NOTICE 'Аномалия % помечена как resolved', anomaly_id;
    END IF;
END $$;

SELECT '=== Аномалия ПОСЛЕ отметки resolved (resolved_at должен заполниться) ===' AS message;
SELECT id, severity, description, resolved, resolved_at 
FROM anomalies 
WHERE resolved = TRUE 
ORDER BY resolved_at DESC 
LIMIT 1;