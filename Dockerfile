# Используем официальный образ PostgreSQL 14 (стабильная версия)
FROM postgres:14

# Метки для идентификации (авторы, описание)
LABEL maintainer="Team CubeSat"
LABEL description="PostgreSQL database for CubeSat telemetry monitoring system"
LABEL version="1.0"
LABEL project="CubeSat Monitoring System"

# Переменные окружения (будут использованы при инициализации)
# Их можно переопределить в docker-compose.yml
ENV POSTGRES_DB=cubesat_db
ENV POSTGRES_USER=cubesat_user
ENV POSTGRES_PASSWORD=cubesat_pass
ENV POSTGRES_INITDB_ARGS="--encoding=UTF-8 --locale=C"

# Копируем SQL-скрипты в специальную директорию инициализации
# PostgreSQL автоматически выполнит их в алфавитном порядке при первом запуске
COPY ./init/01_schema.sql /docker-entrypoint-initdb.d/01_schema.sql
COPY ./init/02_data.sql /docker-entrypoint-initdb.d/02_data.sql
COPY ./init/03_queries.sql /docker-entrypoint-initdb.d/03_queries.sql

# Копируем пользовательский конфиг PostgreSQL (опционально)
# Если нужны дополнительные настройки производительности
# COPY postgresql.conf /etc/postgresql/postgresql.conf

RUN chmod -R 755 /docker-entrypoint-initdb.d/

EXPOSE 5432
