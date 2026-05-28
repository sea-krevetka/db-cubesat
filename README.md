# 🛰️ CubeSat Telemetry Monitoring System

Система мониторинга телеметрии спутника CubeSat на базе PostgreSQL 14. Предназначена для сбора, хранения и анализа данных с бортовых систем наноспутника.

## 🎯 Описание проекта

Проект реализует базу данных для системы мониторинга телеметрии спутника формата CubeSat. База данных хранит:
```

## 💻 Требования

- **Docker** >= 20.10.0
- **Docker Compose** >= 2.0.0
- **Git** (опционально, для клонирования)

## 🚀 Установка и запуск

### 1. Клонирование репозитория

```bash
git clone https://github.com/your-username/cubesat-monitoring.git
cd cubesat-monitoring
```

### 2. Структура проекта

Убедитесь, что структура соответствует:

```
cubesat-monitoring/
├── Dockerfile
├── docker-compose.yml
├── .dockerignore
├── .env.example
├── init/
│   ├── 01_schema.sql
│   ├── 02_data.sql
│   └── 03_queries.sql
└── README.md
```

### 3. Настройка окружения

Создайте файл `.env` для переопределения паролей:

```bash
cp .env.example .env
```

Отредактируйте `.env` при необходимости:

```env
POSTGRES_DB=cubesat_db
POSTGRES_USER=cubesat_user
POSTGRES_PASSWORD=YOUR_STRONG_PASSWORD_HERE
```

### 4. Сборка и запуск

```bash
# Собрать образ и запустить контейнер
docker compose up -d --build

# Проверить, что контейнер запустился
docker compose ps

# Посмотреть логи
docker compose logs -f
```

### 5. Проверка работоспособности

```bash
# Проверить подключение к БД
docker exec -it cubesat_monitoring pg_isready -U cubesat_user

# Посмотреть список таблиц
docker exec -it cubesat_monitoring psql -U cubesat_user -d cubesat_db -c "\dt"

# Выполнить проверочные запросы
docker exec -it cubesat_monitoring psql -U cubesat_user -d cubesat_db -f /docker-entrypoint-initdb.d/03_queries.sql
```

## Использование

### Подключение к базе данных

#### Через psql внутри контейнера

```bash
docker exec -it cubesat_monitoring psql -U cubesat_user -d cubesat_db
```

#### Через внешний клиент (например, DBeaver, pgAdmin)

- **Host**: `localhost`
- **Port**: `5432`
- **Database**: `cubesat_db`
- **User**: `cubesat_user`
- **Password**: `cubesat_pass` (или что указали в `.env`)

### Основные операции

#### Вставка телеметрии

```sql
INSERT INTO telemetry (timestamp, subsystem, parameter, value, unit)
VALUES 
    (NOW(), 'EPS', 'voltage', 8.4, 'V'),
    (NOW(), 'EPS', 'current', 1.2, 'A'),
    (NOW(), 'COM', 'rssi', -65, 'dBm');
```

#### Просмотр последних данных

```sql
-- Последние 10 записей телеметрии
SELECT * FROM telemetry ORDER BY timestamp DESC LIMIT 10;

-- Текущий статус всех подсистем
SELECT * FROM subsystem_status;
```

#### Анализ данных

```sql
-- Средняя температура за последний час
SELECT 
    subsystem,
    AVG(value) as avg_temp,
    MIN(value) as min_temp,
    MAX(value) as max_temp
FROM telemetry 
WHERE parameter = 'temperature' 
    AND timestamp > NOW() - INTERVAL '1 hour'
GROUP BY subsystem;
```

### Оптимизации

- **Индексы** на `telemetry.timestamp` и `telemetry.subsystem`
- **Партиционирование** таблицы `telemetry` по месяцам
- **Автовакуум** для автоматической очистки
- **Триггеры** для обновления статистики

## Бэкап и восстановление

### Создание бэкапа

```bash
# Бэкап всей базы данных
docker exec -t cubesat_monitoring pg_dump -U cubesat_user cubesat_db > backup_$(date +%Y%m%d_%H%M%S).sql

# Бэкап только схемы (без данных)
docker exec -t cubesat_monitoring pg_dump -U cubesat_user -s cubesat_db > schema_backup.sql

# Бэкап только данных
docker exec -t cubesat_monitoring pg_dump -U cubesat_user -a cubesat_db > data_backup.sql
```

### Восстановление из бэкапа

```bash
# Восстановление из SQL-дампа
cat backup.sql | docker exec -i cubesat_monitoring psql -U cubesat_user cubesat_db

# Сначала очистить БД (ОСТОРОЖНО!)
docker exec -i cubesat_monitoring psql -U cubesat_user cubesat_db -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
cat backup.sql | docker exec -i cubesat_monitoring psql -U cubesat_user cubesat_db
```

## Устранение неполадок

### Контейнер не запускается

```bash
# Проверить логи
docker compose logs postgres

# Проверить свободное место на диске
df -h

# Перезапустить с очисткой
docker compose down -v
docker compose up -d --build
```

### Не удаётся подключиться к БД

```bash
# Проверить, что контейнер слушает порт
netstat -an | grep 5432

# Проверить файрвол
sudo ufw status

# Проверить, что PostgreSQL принимает подключения
docker exec cubesat_monitoring netstat -an | grep 5432
```.