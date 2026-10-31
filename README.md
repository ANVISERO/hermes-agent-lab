# Hermes Agent Lab — P1

Практическая работа: развернуть автономного агента на отдельном зарубежном VPS, подключить Telegram и доказать автономность и ограничение доступа.

**Статус:** VPS уже арендован в **AdminVPS, Нидерланды**. ОС, ресурсы и SSH-доступ ещё предстоит проверить; настройка Telegram, LLM и запуск агента в рамках этой работы пока не подтверждены. Выполнение отмечается в [чек-листе](docs/evidence-checklist.md).

Агент — [Hermes Agent](https://github.com/NousResearch/hermes-agent). Планируемый LLM-провайдер — OpenRouter с моделью, поддерживающей tools и контекст ≥64K; при использовании бесплатной модели учитывать её квоты. Стоимость аренды VPS и расход LLM учитываются отдельно.

**Следующий шаг:** открыть [план развёртывания](docs/deployment.md) и начать с SSH-подключения к уже арендованному серверу. Все этапы после аренды собраны в этом файле.

## Архитектура

```mermaid
flowchart LR
    User[Владелец] <--> Telegram[Telegram Bot API]
    Telegram <-->|исходящий polling| Agent[Hermes gateway в Docker]
    Agent <--> LLM[OpenRouter API]
    Agent --> Data[Данные и память /opt/data]
    Agent --> Workspace[Рабочие файлы /workspace]
    Cron[Планировщик Hermes] --> Agent
    Docker[Docker restart unless-stopped] --> Agent
```

Порты контейнера наружу не публикуются. В контейнер передаются только `data/` и `workspace/`. Терминальные инструменты работают внутри контейнера. Изменение рабочего каталога само по себе не является изоляцией.

## Структура

```text
hermes-agent-lab/
├── .env.example                         # пример настроек Compose без секретов
├── .gitignore                           # исключения для секретов и runtime-файлов
├── README.md                            # описание проекта и быстрый старт
├── compose.yaml                         # образ, mounts, restart и Docker-логи
├── docs/
│   ├── debugging-log.md                 # журнал реальных ошибок
│   ├── deployment.md                    # пошаговое развёртывание и эксперименты
│   ├── evidence-checklist.md            # чек-лист доказательств P1
│   ├── report.md                        # шаблон отчёта
│   └── security.md                      # настройки и границы защиты
├── evidence/
│   └── .gitkeep                         # сохраняет каталог в Git
├── scripts/
│   ├── bootstrap-host.sh                # подготовка Ubuntu, Docker и firewall
│   ├── check-local.sh                   # локальные проверки проекта
│   ├── check_access.py                  # проверка Telegram allowlist
│   ├── collect-evidence.sh              # сбор логов и состояния для отчёта
│   ├── create-demo-cron.sh              # одноразовая задача автономности
│   ├── cron-list.sh                     # задания и состояние планировщика
│   ├── harden-ssh.sh                    # настройка SSH по ключу
│   ├── hermes.sh                        # команды Hermes внутри контейнера
│   ├── init.sh                          # UID/GID, каталоги и digest образа
│   ├── lib.sh                           # общие функции скриптов
│   ├── logs.sh                          # просмотр логов gateway
│   ├── redact-evidence.py               # скрытие токенов в собранных логах
│   ├── restart.sh                       # перезапуск контейнера
│   ├── setup.sh                         # настройка LLM, Telegram и памяти
│   ├── smoke-test.sh                    # проверка terminal, files и web
│   ├── start.sh                         # запуск gateway
│   ├── status.sh                        # состояние контейнера и процессов
│   ├── stop.sh                          # остановка контейнера
│   ├── test-skill.sh                    # проверка собственного навыка
│   └── verify.sh                        # проверки конфигурации P1
├── skills/
│   └── research-source-review/
│       └── SKILL.md                     # собственный навык проверки источников
├── templates/
│   └── memories/
│       ├── MEMORY.md                    # начальный контекст лабораторной
│       └── USER.md                      # предпочтения пользователя
├── tests/
│   ├── test_access.py                   # тесты ограничения доступа
│   └── test_redaction.py                # тесты скрытия секретов
└── workspace/
    └── .gitkeep                         # сохраняет каталог в Git
```

В дереве перечислены все 36 файлов репозитория. При настройке дополнительно создаются локальный `.env` и каталог `data/` с конфигурацией, секретами и состоянием Hermes. Они исключены из Git; в `evidence/` и `workspace/` отслеживаются только `.gitkeep`, а собранные доказательства и рабочие файлы остаются приватными.

## Первый запуск

Сначала пройти подготовку SSH и пользователя, перенос файлов и установку Docker по [плану](docs/deployment.md). Скрипты рассчитаны на Ubuntu 22.04+; для новой установки предпочтительна Ubuntu 24.04 LTS. Не переустанавливать уже используемый сервер без сохранения данных.

После подготовки хоста следующие команды выполняются **на VPS** из каталога `~/hermes-agent-lab` под обычным пользователем с sudo:

```bash
bash scripts/init.sh
bash scripts/setup.sh
bash scripts/start.sh
bash scripts/verify.sh
```

До `setup.sh` подготовить Telegram-бота, свой числовой ID, API-ключ LLM и установить лимит расходов у провайдера. При настройке разрешить **только свой ID**. `init.sh` сохраняет digest образа и UID/GID в `.env`; Hermes записывает ключи отдельно в `data/.env`.

Скрипт `verify.sh` проверяет часть конфигурации, но не заменяет реальный диалог, отказ постороннему аккаунту, проверку навыков и эксперимент после reboot. Полная последовательность: [развёртывание](docs/deployment.md).

## Проверки и управление

```bash
bash scripts/status.sh
bash scripts/logs.sh
bash scripts/smoke-test.sh
bash scripts/test-skill.sh https://hermes-agent.nousresearch.com/
bash scripts/create-demo-cron.sh YOUR_PRIVATE_CHAT_ID
bash scripts/cron-list.sh
bash scripts/hermes.sh cron runs JOB_ID --limit 5
bash scripts/collect-evidence.sh first-start
bash scripts/restart.sh
bash scripts/stop.sh
```

Демо cron одноразовый, через 10 минут. Он получает фактическое время и состояние окружения, сохраняет результат в `/workspace/autonomy-check.log` и отправляет его владельцу. Перед опытом закрыть Telegram на своих устройствах и отключить SSH. Не запускать задачу вручную вместо проверки расписания.

Для reboot: работающий контейнер → `collect-evidence.sh before-reboot` → `sudo reboot` → повторный вход → `status.sh` и `collect-evidence.sh after-reboot` **без ручного запуска контейнера**.

## Локальные проверки проекта

Не требуют VPS, API-ключей, LLM или запущенного Docker daemon:

```bash
bash scripts/check-local.sh
```

Это проверка файлов и защитных функций. Она не доказывает, что агент развёрнут.

## Источники и самостоятельная часть

Архитектурный ориентир — [работа Дмитрия Леденцова](https://github.com/DmitryLedentsov/web-eco-task-2), ревизия `343299bee37f49b0107103c85f77266ae408bbea`. Здесь написаны собственные скрипты и навык; чужие логи, скриншоты и результаты не используются как собственные. Отдельное задание T3 в этот проект не включено.

Команды и настройки Hermes сверялись с [официальным Docker workflow](https://hermes-agent.nousresearch.com/docs/user-guide/docker), [Telegram](https://hermes-agent.nousresearch.com/docs/user-guide/messaging/telegram) и [cron](https://hermes-agent.nousresearch.com/docs/user-guide/features/cron). Образ и квоты провайдеров меняются: при развёртывании сохранить фактические версии, digest и лимиты.
