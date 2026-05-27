-- =====================================================
-- Триггеры для автоматизации бизнес-логики
-- =====================================================

-- Функция триггера: автоматическое создание аномалии при выходе телеметрии за пределы
CREATE OR REPLACE FUNCTION check_telemetry_limits()
RETURNS TRIGGER AS $$
DECLARE
    v_min_val DECIMAL;
    v_max_val DECIMAL;
    v_sensor_type VARCHAR;
    v_subsystem_id INT;
    v_satellite_id INT;
    v_severity VARCHAR;
    v_description TEXT;
BEGIN
    -- Получаем min/max из таблицы sensors
    SELECT min_val, max_val, sensor_type, subsystem_id 
    INTO v_min_val, v_max_val, v_sensor_type, v_subsystem_id
    FROM sensors WHERE id = NEW.sensor_id;
    
    -- Получаем ID спутника через подсистему
    SELECT satellite_id INTO v_satellite_id
    FROM subsystems WHERE id = v_subsystem_id;
    
    -- Проверяем выход за пределы
    IF v_min_val IS NOT NULL AND NEW.value < v_min_val THEN
        v_severity := CASE 
            WHEN v_sensor_type = 'temperature' AND NEW.value < v_min_val - 10 THEN 'emergency'
            WHEN v_sensor_type = 'voltage' AND NEW.value < v_min_val - 1 THEN 'critical'
            ELSE 'warning'
        END;
        
        v_description := format('Sensor %s (type: %s): value %.2f is below minimum %.2f', 
                                NEW.sensor_id, v_sensor_type, NEW.value, v_min_val);
        
        INSERT INTO anomalies (satellite_id, timestamp, severity, description)
        VALUES (v_satellite_id, NEW.timestamp, v_severity, v_description);
        
    ELSIF v_max_val IS NOT NULL AND NEW.value > v_max_val THEN
        v_severity := CASE 
            WHEN v_sensor_type = 'temperature' AND NEW.value > v_max_val + 10 THEN 'emergency'
            WHEN v_sensor_type = 'voltage' AND NEW.value > v_max_val + 0.5 THEN 'critical'
            ELSE 'warning'
        END;
        
        v_description := format('Sensor %s (type: %s): value %.2f exceeds maximum %.2f', 
                                NEW.sensor_id, v_sensor_type, NEW.value, v_max_val);
        
        INSERT INTO anomalies (satellite_id, timestamp, severity, description)
        VALUES (v_satellite_id, NEW.timestamp, v_severity, v_description);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Создаём сам триггер (срабатывает после вставки в telemetry)
DROP TRIGGER IF EXISTS trigger_check_telemetry_limits ON telemetry;
CREATE TRIGGER trigger_check_telemetry_limits
    AFTER INSERT ON telemetry
    FOR EACH ROW
    EXECUTE FUNCTION check_telemetry_limits();

-- =====================================================
-- Дополнительный триггер: автообновление resolved_at при изменении аномалии
-- =====================================================
CREATE OR REPLACE FUNCTION update_resolved_at()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.resolved = TRUE AND OLD.resolved = FALSE THEN
        NEW.resolved_at = NOW();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_resolved_at ON anomalies;
CREATE TRIGGER trigger_update_resolved_at
    BEFORE UPDATE ON anomalies
    FOR EACH ROW
    EXECUTE FUNCTION update_resolved_at();