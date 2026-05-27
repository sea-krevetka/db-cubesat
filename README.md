# Система мониторинга телеметрии и планирования сеансов связи для группировки малых космических аппаратов (CubeSat)

## Авторы
Команда из 2 человек  
Группа: [указать группу]  
СибГУТИ, кафедра ТС и ВС

## Вариант выполнения
**Вариант А: Контейнеризация и автоматическая инициализация (Docker)**

## Описание предметной области
Проект реализует базу данных для Центра управления полётами (ЦУП) группировки малых космических аппаратов формата CubeSat. Система позволяет:
- Отслеживать телеметрию с датчиков
- Планировать сеансы связи с наземными станциями
- Фиксировать фактические сеансы и объёмы данных
- Вести журнал команд
- Регистрировать аномалии

## Технологии
- Docker & Docker Compose
- PostgreSQL 14 (официальный образ `postgres:14-alpine`)
- pgAdmin 4 (опционально, для визуального управления)

## Структура таблиц (11 таблиц)
1. satellites — спутники
2. subsystems — подсистемы
3. sensors — датчики
4. telemetry — телеметрия
5. ground_stations — наземные станции
6. visibility_windows — окна видимости
7. planned_passes — запланированные сеансы
8. actual_passes — фактические сеансы
9. commands — команды
10. command_log — журнал команд
11. anomalies — аномалии

## Индексы
- `idx_telemetry_timestamp` — на временные выборки
- `idx_telemetry_sensor_time` — для фильтрации по датчикам
- `idx_visibility_windows_start` — для поиска окон
- `idx_anomalies_satellite_time` — для аналитики аномалий
- `idx_command_log_sent` — для журнала команд

## Ограничения (CHECK, UNIQUE, NOT NULL)
- Статусы спутников: operational/maintenance/safe_mode/decommissioned
- Диапазоны широты/долготы для станций (-90..90, -180..180)
- Приоритет сеансов от 1 до 5
- Типы аномалий: info/warning/critical/emergency
- Уникальность: имя спутника, norad_id

## Тестовые данные
- **Всего записей: 100+** (соответствует требованию ≥30)
- Спутники: 5
- Подсистемы: 15
- Датчики: 20
- Телеметрия: 60
- Наземные станции: 4
- Окна видимости: 12
- Плановые сеансы: 10
- Фактические сеансы: 5
- Команды: 8
- Журнал команд: 8
- Аномалии: 8

## Запуск проекта

### 1. Установка Docker и Docker Compose
```bash
# Установка Docker (Ubuntu/Debian)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Установка Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose