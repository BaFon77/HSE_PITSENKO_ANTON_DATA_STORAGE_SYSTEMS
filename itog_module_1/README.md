# Итоговое задание, модуль 1: хранилище Data Vault

Хранилище данных по датасету Sample Superstore, спроектированное методом Data Vault и реализованное в Greenplum (запускается в Docker).

Датасет: https://www.kaggle.com/datasets/roopacalistus/superstore

## Модель

| Тип | Таблицы |
|---|---|
| Хабы | `hub_sale`, `hub_ship_mode`, `hub_segment`, `hub_location`, `hub_product` |
| Линк | `lnk_sale` |
| Спутники | `sat_sale_metrics`, `sat_location_region` |
| Staging | `stg_superstore` (сырые данные из CSV и рассчитанный ключ продажи) |

## Структура

```
itog_module_1/
├── dv/
│   ├── data/SampleSuperstore.csv   исходные данные
│   └── sql/
│       ├── ddl.sql                 создание схемы dv и таблиц
│       ├── load.sql                загрузка данных из CSV в хранилище
│       └── check.sql               проверки загрузки
└── gp/
    └── docker-compose.yml          Greenplum в Docker
```

## Запуск

Из папки `gp` поднять контейнер:

```bash
docker compose up -d
```


```bash
docker exec -u gpadmin greenplum /usr/local/greenplum-db/bin/psql -d postgres -f /sql/ddl.sql
docker exec -u gpadmin greenplum /usr/local/greenplum-db/bin/psql -d postgres -f /sql/load.sql
docker exec -u gpadmin greenplum /usr/local/greenplum-db/bin/psql -d postgres -f /sql/check.sql
```


## Подключение к базе

| Параметр | Значение |
|---|---|
| Хост | `localhost` |
| Порт | `5433` |
| База | `postgres` |
| Схема | `dv` |
| Пользователь | `gpadmin` |
| Пароль | `gpadmin` |

