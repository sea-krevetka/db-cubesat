-- 1. Спутники
CREATE TABLE satellites (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    norad_id INTEGER UNIQUE,
    launch_date DATE,
    status VARCHAR(50) NOT NULL CHECK (status IN (''operational'', ''maintenance'', ''safe_mode'', ''decommissioned'')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Подсистемы
CREATE TABLE subsystems (
    id SERIAL PRIMARY KEY,
    satellite_id INTEGER NOT NULL REFERENCES satellites(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    parent_subsystem_id INTEGER REFERENCES subsystems(id) ON DELETE SET NULL,
    UNIQUE(satellite_id, name)
);

-- 3. Датчики
CREATE TABLE sensors (
    id SERIAL PRIMARY KEY,
    subsystem_id INTEGER NOT NULL REFERENCES subsystems(id) ON DELETE CASCADE,
    sensor_type VARCHAR(50) NOT NULL,
    unit VARCHAR(20) NOT NULL,
    min_val DECIMAL(10,2),
    max_val DECIMAL(10,2),
    description TEXT,
    CHECK (min_val IS NULL OR max_val IS NULL OR min_val < max_val)
);

-- 4. Телеметрия
CREATE TABLE telemetry (
    id BIGSERIAL PRIMARY KEY,
    sensor_id INTEGER NOT NULL REFERENCES sensors(id) ON DELETE CASCADE,
    timestamp TIMESTAMP NOT NULL,
    value DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_telemetry_timestamp ON telemetry(timestamp DESC);
CREATE INDEX idx_telemetry_sensor_time ON telemetry(sensor_id, timestamp DESC);

-- 5. Наземные станции
CREATE TABLE ground_stations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    latitude DECIMAL(9,6) NOT NULL CHECK (latitude BETWEEN -90 AND 90),
    longitude DECIMAL(9,6) NOT NULL CHECK (longitude BETWEEN -180 AND 180),
    elevation_meters DECIMAL(8,2),
    status VARCHAR(30) DEFAULT ''active'' CHECK (status IN (''active'', ''maintenance'', ''offline''))
);

-- 6. Окна видимости
CREATE TABLE visibility_windows (
    id SERIAL PRIMARY KEY,
    satellite_id INTEGER NOT NULL REFERENCES satellites(id) ON DELETE CASCADE,
    station_id INTEGER NOT NULL REFERENCES ground_stations(id) ON DELETE CASCADE,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    max_elevation DECIMAL(5,2),
    CHECK (start_time < end_time)
);

CREATE INDEX idx_visibility_windows_start ON visibility_windows(start_time);
CREATE INDEX idx_visibility_windows_satellite ON visibility_windows(satellite_id, start_time);

-- 7. Запланированные сеансы
CREATE TABLE planned_passes (
    id SERIAL PRIMARY KEY,
    window_id INTEGER NOT NULL UNIQUE REFERENCES visibility_windows(id) ON DELETE CASCADE,
    operator_id INTEGER,
    priority INTEGER DEFAULT 1 CHECK (priority BETWEEN 1 AND 5),
    status VARCHAR(30) DEFAULT ''planned'' CHECK (status IN (''planned'', ''approved'', ''canceled'', ''completed''))
);

-- 8. Фактические сеансы
CREATE TABLE actual_passes (
    id SERIAL PRIMARY KEY,
    planned_pass_id INTEGER NOT NULL UNIQUE REFERENCES planned_passes(id) ON DELETE CASCADE,
    actual_start TIMESTAMP NOT NULL,
    actual_end TIMESTAMP NOT NULL,
    data_volume_mb DECIMAL(10,2) DEFAULT 0,
    downlink_rate_kbps DECIMAL(10,2),
    CHECK (actual_start < actual_end)
);

-- 9. Команды
CREATE TABLE commands (
    id SERIAL PRIMARY KEY,
    satellite_id INTEGER NOT NULL REFERENCES satellites(id) ON DELETE CASCADE,
    command_code VARCHAR(50) NOT NULL,
    description TEXT,
    is_critical BOOLEAN DEFAULT FALSE,
    UNIQUE(satellite_id, command_code)
);

-- 10. Журнал команд
CREATE TABLE command_log (
    id BIGSERIAL PRIMARY KEY,
    command_id INTEGER NOT NULL REFERENCES commands(id) ON DELETE CASCADE,
    planned_pass_id INTEGER REFERENCES planned_passes(id) ON DELETE SET NULL,
    sent_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    acked_at TIMESTAMP,
    status VARCHAR(30) DEFAULT ''sent'' CHECK (status IN (''sent'', ''acknowledged'', ''executed'', ''failed'')),
    result TEXT
);

CREATE INDEX idx_command_log_sent ON command_log(sent_at DESC);
CREATE INDEX idx_command_log_status ON command_log(status);

-- 11. Аномалии
CREATE TABLE anomalies (
    id BIGSERIAL PRIMARY KEY,
    satellite_id INTEGER NOT NULL REFERENCES satellites(id) ON DELETE CASCADE,
    timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    severity VARCHAR(20) NOT NULL CHECK (severity IN (''info'', ''warning'', ''critical'', ''emergency'')),
    description TEXT NOT NULL,
    resolved BOOLEAN DEFAULT FALSE,
    resolved_at TIMESTAMP,
    CHECK (resolved_at IS NULL OR resolved_at >= timestamp)
);

CREATE INDEX idx_anomalies_satellite_time ON anomalies(satellite_id, timestamp DESC);
CREATE INDEX idx_anomalies_severity ON anomalies(severity);
