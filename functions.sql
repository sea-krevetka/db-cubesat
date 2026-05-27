-- =====================================================
-- Хранимые функции для анализа и планирования
-- =====================================================

-- Функция 1: Возвращает ближайшие окна видимости для спутника
CREATE OR REPLACE FUNCTION get_upcoming_passes(
    p_satellite_id INT,
    p_hours_ahead INT DEFAULT 24
)
RETURNS TABLE(
    window_id INT,
    station_name VARCHAR,
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    max_elevation DECIMAL,
    duration_minutes DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        vw.id AS window_id,
        gs.name AS station_name,
        vw.start_time,
        vw.end_time,
        vw.max_elevation,
        EXTRACT(EPOCH FROM (vw.end_time - vw.start_time)) / 60 AS duration_minutes
    FROM visibility_windows vw
    JOIN ground_stations gs ON vw.station_id = gs.id
    WHERE vw.satellite_id = p_satellite_id
      AND vw.start_time > NOW()
      AND vw.start_time < NOW() + (p_hours_ahead || ' hours')::INTERVAL
    ORDER BY vw.start_time ASC;
END;
$$ LANGUAGE plpgsql;

-- Функция 2: Здоровье спутника (агрегированные метрики)
CREATE OR REPLACE FUNCTION get_satellite_health(
    p_satellite_id INT,
    p_hours_back INT DEFAULT 24
)
RETURNS TABLE(
    satellite_name VARCHAR,
    avg_temperature_celsius DECIMAL,
    max_temperature_celsius DECIMAL,
    min_voltage_volts DECIMAL,
    anomaly_count BIGINT,
    health_status VARCHAR
) AS $$
DECLARE
    v_avg_temp DECIMAL;
    v_max_temp DECIMAL;
    v_min_volt DECIMAL;
    v_anomaly_count BIGINT;
    v_sat_name VARCHAR;
    v_status VARCHAR;
BEGIN
    -- Получаем имя спутника
    SELECT name INTO v_sat_name FROM satellites WHERE id = p_satellite_id;
    
    -- Средняя и максимальная температура
    SELECT 
        AVG(t.value),
        MAX(t.value)
    INTO v_avg_temp, v_max_temp
    FROM telemetry t
    JOIN sensors s ON t.sensor_id = s.id
    JOIN subsystems sub ON s.subsystem_id = sub.id
    WHERE sub.satellite_id = p_satellite_id
      AND s.sensor_type = 'temperature'
      AND t.timestamp > NOW() - (p_hours_back || ' hours')::INTERVAL;
    
    -- Минимальное напряжение
    SELECT MIN(t.value)
    INTO v_min_volt
    FROM telemetry t
    JOIN sensors s ON t.sensor_id = s.id
    JOIN subsystems sub ON s.subsystem_id = sub.id
    WHERE sub.satellite_id = p_satellite_id
      AND s.sensor_type = 'voltage'
      AND t.timestamp > NOW() - (p_hours_back || ' hours')::INTERVAL;
    
    -- Количество аномалий
    SELECT COUNT(*)
    INTO v_anomaly_count
    FROM anomalies
    WHERE satellite_id = p_satellite_id
      AND timestamp > NOW() - (p_hours_back || ' hours')::INTERVAL
      AND severity IN ('warning', 'critical', 'emergency');
    
    -- Определяем статус здоровья
    IF v_max_temp > 60 THEN
        v_status := 'CRITICAL_TEMP';
    ELSIF v_min_volt < 6.0 THEN
        v_status := 'LOW_VOLTAGE';
    ELSIF v_anomaly_count > 5 THEN
        v_status := 'MANY_ANOMALIES';
    ELSIF v_anomaly_count > 0 THEN
        v_status := 'DEGRADED';
    ELSE
        v_status := 'NOMINAL';
    END IF;
    
    RETURN QUERY
    SELECT 
        v_sat_name,
        COALESCE(v_avg_temp, 0),
        COALESCE(v_max_temp, 0),
        COALESCE(v_min_volt, 0),
        COALESCE(v_anomaly_count, 0),
        v_status;
END;
$$ LANGUAGE plpgsql;