-- =====================================================
-- Схема БД: Система мониторинга телеметрии CubeSat
-- =====================================================

-- Удаляем таблицы, если есть (для чистой инициализации)
DROP TABLE IF EXISTS command_log CASCADE;
DROP TABLE IF EXISTS actual_passes CASCADE;
DROP TABLE IF EXISTS planned_passes CASCADE;
DROP TABLE IF EXISTS visibility_windows CASCADE;
DROP TABLE IF EXISTS telemetry CASCADE;
DROP TABLE IF EXISTS sensors CASCADE;
DROP TABLE IF EXISTS subsystems CASCADE;
DROP TABLE IF EXISTS anomalies CASCADE;
DROP TABLE IF EXISTS commands CASCADE;
DROP TABLE IF EXISTS ground_stations CASCADE;
DROP TABLE IF EXISTS satellites CASCADE;

-- 1. Спутники
CREATE TABLE satellites (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    norad_id INTEGER UNIQUE NOT NULL,
    launch_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('operational', 'degraded', 'safe_mode', 'dead'))
);

-- 2. Подсистемы 
CREATE TABLE subsystems (
    id SERIAL PRIMARY KEY,
    satellite_id INTEGER NOT NULL REFERENCES satellites(id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL,
    UNIQUE(satellite_id, name)
);

-- 3. Датчики
CREATE TABLE sensors (
    id SERIAL PRIMARY KEY,
    subsystem_id INTEGER NOT NULL REFERENCES subsystems(id) ON DELETE CASCADE,
    sensor_type VARCHAR(30) NOT NULL CHECK (sensor_type IN ('temp', 'voltage', 'current', 'orientation', 'battery')),
    unit VARCHAR(10) NOT NULL,
    min_val REAL,
    max_val REAL,
    UNIQUE(subsystem_id, sensor_type)
);

-- 4. Телеметрия
CREATE TABLE telemetry (
    id BIGSERIAL PRIMARY KEY,
    sensor_id INTEGER NOT NULL REFERENCES sensors(id) ON DELETE CASCADE,
    timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    value REAL NOT NULL
);

-- 5. Наземные станции
CREATE TABLE ground_stations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    latitude DECIMAL(10,7) NOT NULL CHECK (latitude BETWEEN -90 AND 90),
    longitude DECIMAL(10,7) NOT NULL CHECK (longitude BETWEEN -180 AND 180),
    elevation_meters INTEGER NOT NULL DEFAULT 0
);

-- 6. Окна видимости
CREATE TABLE visibility_windows (
    id BIGSERIAL PRIMARY KEY,
    satellite_id INTEGER NOT NULL REFERENCES satellites(id) ON DELETE CASCADE,
    station_id INTEGER NOT NULL REFERENCES ground_stations(id) ON DELETE CASCADE,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    max_elevation_deg REAL NOT NULL CHECK (max_elevation_deg BETWEEN 0 AND 90),
    CHECK (end_time > start_time)
);

-- 7. Плановые сеансы
CREATE TABLE planned_passes (
    id BIGSERIAL PRIMARY KEY,
    window_id BIGINT NOT NULL REFERENCES visibility_windows(id) ON DELETE CASCADE,
    operator_name VARCHAR(50) NOT NULL,
    priority INTEGER DEFAULT 1 CHECK (priority BETWEEN 1 AND 5),
    status VARCHAR(20) DEFAULT 'planned' CHECK (status IN ('planned', 'cancelled', 'completed', 'failed'))
);

-- 8. Фактические сеансы
CREATE TABLE actual_passes (
    id BIGSERIAL PRIMARY KEY,
    planned_pass_id BIGINT NOT NULL REFERENCES planned_passes(id) ON DELETE CASCADE,
    actual_start TIMESTAMP NOT NULL,
    actual_end TIMESTAMP NOT NULL,
    data_volume_mb DECIMAL(10,2) DEFAULT 0,
    CHECK (actual_end > actual_start)
);

-- 9. Команды
CREATE TABLE commands (
    id SERIAL PRIMARY KEY,
    satellite_id INTEGER NOT NULL REFERENCES satellites(id) ON DELETE CASCADE,
    command_code VARCHAR(20) NOT NULL,
    description TEXT,
    is_critical BOOLEAN DEFAULT FALSE,
    UNIQUE(satellite_id, command_code)
);

-- 10. Журнал команд
CREATE TABLE command_log (
    id BIGSERIAL PRIMARY KEY,
    command_id INTEGER NOT NULL REFERENCES commands(id) ON DELETE CASCADE,
    planned_pass_id BIGINT REFERENCES planned_passes(id) ON DELETE SET NULL,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    acked_at TIMESTAMP,
    status VARCHAR(20) DEFAULT 'sent' CHECK (status IN ('sent', 'acked', 'failed')),
    CHECK (acked_at IS NULL OR acked_at >= sent_at)
);

-- 11. Аномалии
CREATE TABLE anomalies (
    id BIGSERIAL PRIMARY KEY,
    satellite_id INTEGER NOT NULL REFERENCES satellites(id) ON DELETE CASCADE,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    severity VARCHAR(10) NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    description TEXT NOT NULL,
    resolved BOOLEAN DEFAULT FALSE
);

-- Индексы для производительности
CREATE INDEX idx_telemetry_timestamp ON telemetry(timestamp);
CREATE INDEX idx_telemetry_sensor_id ON telemetry(sensor_id);
CREATE INDEX idx_visibility_windows_time ON visibility_windows(start_time, end_time);
CREATE INDEX idx_anomalies_satellite_time ON anomalies(satellite_id, timestamp);