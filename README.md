# test_kanban

Kanban-доска на Flutter с подключением к KPI-Drive API. Задачи приходят от сервера, группируются по папкам в колонки, поддерживается drag-&-drop карточек между колонками и внутри колонок, а также перетаскивание самих колонок. Изменения применяются оптимистично и сохраняются на бэкенд; при ошибке — автоматический откат и snackbar с повтором.

Тёмная тема в стиле KPI-Drive (тёмно-фиолетовая с красными акцентами).

## Возможности

- Загрузка задач `POST /_api/indicators/get_mo_indicators` с bearer-авторизацией.
- Группировка задач по `parent_id` — каждая уникальная папка становится колонкой.
- Drag-&-drop карточек:
  - Drop-зоны на половинах карточки: верхняя половина → вставить выше, нижняя → ниже.
  - Красная подсветка с glow вокруг карточки во время перетаскивания.
  - Анимированные insertion-бары между соседями.
- Drag-&-drop колонок:
  - Тянется за заголовок.
  - Floating-preview показывает полную копию колонки со всеми карточками.
  - Исходная колонка меркнет (opacity 0.3) пока её тащат.
  - Подсветка места вставки прямо на соседних колонках (левая/правая половина).
- Пакетный reindex: при перемещении задачи обе затронутые колонки перенумеровываются `0, 1, 2, …` и все изменившиеся задачи сохраняются параллельно.
- Оптимистичное обновление UI с откатом снапшота при ошибке сервера.
- Авто-скролл у края: если тянешь карточку к верху/низу колонки или колонку к левому/правому краю доски — список сам прокручивается.
- Noop-guard: если dropped в ту же позицию, ни одного запроса не отправляется.
- «Защита от дурака»: нельзя тянуть карточку во время её сохранения; индикаторы вставки не показываются в заведомо noop-зонах; кнопка refresh недоступна во время загрузки.

## Технологии

- **Flutter / Dart** — UI и вся логика. Drag-&-drop — нативный `Draggable` / `DragTarget`, без сторонних библиотек.
- **Dio** — HTTP-клиент. Единая точка настройки base URL, bearer-токена, сериализация `FormData` с повторяющимися полями (для `save_indicator_instance_field` критично — дублируются `field_name`/`field_value`).
- **flutter_bloc (Cubit)** — тонкий слой между domain и UI.
- **provider** — composition root, DI на уровне фичи через `MultiProvider`.
- **equatable** — value-equality для entity и state.

## Архитектура

**Clean Architecture + Feature-based + Interactor Pattern.**

```
lib/
├── main.dart
├── app/
│   ├── app.dart                    # MaterialApp + тёмная тема + палитра
│   └── home_screen.dart
├── core/
│   └── network/
│       └── api_client.dart         # Dio + bearer-токен + конфиг
└── features/
    └── board/
        ├── domain/
        │   ├── kanban_task.dart            # entity
        │   ├── board.dart                  # state-контейнер
        │   ├── board_source.dart           # абстрактный источник
        │   └── board_interactor.dart       # центральный stateful-координатор
        ├── data/
        │   ├── board_stub_source.dart      # in-memory заглушка
        │   └── board_http_source.dart      # реализация через Dio
        ├── presentation/
        │   ├── bloc/
        │   │   ├── board_cubit.dart
        │   │   └── board_state.dart
        │   └── widgets/
        │       ├── board_screen.dart
        │       ├── kanban_column.dart
        │       ├── kanban_card.dart
        │       ├── drag_payload.dart
        │       └── drag_auto_scroll.dart
        └── board_providers.dart            # composition root фичи
```

### Interactor Pattern

Ключевой класс архитектуры — `BoardInteractor`. Он:

- Хранит state `Board` (задачи, `columnOrder`, `savingTaskIds`, флаги загрузки/ошибки).
- Эмитит state через `StreamController<Board>.broadcast()`.
- Вычисляет производное состояние `List<BoardColumn>` — группировка по `parentId`, сортировка по `order`, резолв имён папок.
- Предоставляет действия: `moveTask`, `moveColumn`, `refresh`.

`BoardCubit` — тонкий адаптер: подписан на stream Interactor'а и переизлучает `BoardViewState` в UI. Бизнес-логики в нём нет.

### Оптимистичные апдейты

`BoardInteractor.moveTask`:

1. Сохраняет снапшот `_state`.
2. Пересобирает source- и target-колонки с плотной нумерацией `0, 1, 2, …`.
3. Сравнивает с прошлым состоянием, собирает `changed` — задачи, у которых изменился `parentId` или `order`.
4. Эмитит новое состояние, помечая все `changed` как saving.
5. Параллельно через `Future.wait` шлёт save на каждую изменившуюся задачу.
6. При ошибке — `_emit(snapshot)` + красный snackbar.

### Авто-скролл

`DragAutoScrollRegion` — обёртка со своим `Listener`, который:

- Слушает `PointerMoveEvent` (фирится только при зажатой кнопке/пальце → автоматически drag-only).
- Считает расстояние курсора до грани.
- Запускает `Timer.periodic(16ms)` со скоростью, пропорциональной близости к краю.
- Останавливается на `PointerUp`/`PointerCancel`.

`HitTestBehavior.translucent` обеспечивает, что Listener не перехватывает события у вложенных `Draggable`/`DragTarget` — drop-логика работает как раньше.

## API

### Загрузка задач

```
POST https://api.dev.kpi-drive.ru/_api/indicators/get_mo_indicators
Authorization: Bearer <YOUR_TOKEN>
Content-Type: multipart/form-data

period_start=2026-04-01
period_end=2026-04-30
period_key=month
requested_mo_id=42
behaviour_key=task,kpi_task
with_result=false
response_fields=name,indicator_to_mo_id,parent_id,order
auth_user_id=40
```

### Сохранение позиции задачи

```
POST https://api.dev.kpi-drive.ru/_api/indicators/save_indicator_instance_field
Authorization: Bearer <YOUR_TOKEN>
Content-Type: multipart/form-data

period_start=2026-04-01
period_end=2026-04-30
period_key=month
indicator_to_mo_id=<id>
auth_user_id=40
field_name=parent_id    field_value=<newParentId>
field_name=order        field_value=<newOrder>
```

Bearer-токен и `auth_user_id` — в [lib/core/network/api_client.dart](lib/core/network/api_client.dart).

## Запуск

```bash
flutter pub get
```

### macOS / Windows / Linux / Android / iOS

Просто:

```bash
flutter run -d macos          # или android, ios, windows, linux
```

Без CORS-проблем — это не браузер.

### Web (Chrome)

Бэкенд отдаёт `Access-Control-Allow-Origin: https://admin.dev.kpi-drive.ru`, поэтому из браузера с `localhost` запросы блокируются политикой Same-Origin. Для dev-режима запусти Chrome с выключенной веб-безопасностью (отдельный профиль):

```bash
flutter run -d chrome \
  --web-browser-flag=--disable-web-security \
  --web-browser-flag=--user-data-dir=/tmp/flutter_chrome_dev
```

Chrome покажет жёлтый бар «вы используете неподдерживаемый флаг» — игнорируй. В этом профиле **не** заходи в почту/банки, вся защита между сайтами выключена.

Нативный запуск (macOS и т.п.) этой проблемы не имеет.

## Переключение источника данных

В [lib/features/board/board_providers.dart](lib/features/board/board_providers.dart) подменяется реализация `BoardSource`:

- `BoardHttpSource` — продовый, ходит на KPI-Drive.
- `BoardStubSource` — in-memory моки, имитирует задержку. Удобно для разработки UI без сервера и CORS.

## Палитра

Все цвета — в `AppColors` ([lib/app/app.dart](lib/app/app.dart)):

| Роль | Цвет |
|---|---|
| Фон доски | `#0F0B1E` |
| AppBar | `#1A1432` |
| Фон колонки | `#1C1830` |
| Карточка | `#2A2544` |
| Карточка при перетаскивании | `#E53935` (красный с glow) |
| Акцент пурпур | `#7C3AED` (иконки, кнопки) |
| Акцент красный | `#E53935` (drag, индикаторы, ошибки) |

## Логи

Интерактор пишет в канал `BoardInteractor` через `dart:developer`:

```
[BoardInteractor] moveTask: task=318005 "Получить оплату..." from board=318192 position=0 (order=2) to board=318198 position=3; reindex saves 5 task(s)
[BoardInteractor] moveTask OK: saved 5 task(s)
[BoardInteractor] moveColumn: board=318192 from index=1 to index=3
[BoardInteractor] moveTask noop: task=X already at board=Y position=N
```

Видно в DevTools (вкладка Logs) или в терминале `flutter run`.

## Что бы доработал

- Сохранение `columnOrder` локально через `shared_preferences` — сейчас теряется при перезапуске, потому что на бэке нет эндпоинта для порядка папок.
- Unit-тесты `BoardInteractor.moveTask` (noop / same-column / cross-column / rollback).
- Виртуализация через `ListView.builder` для колонок с сотнями задач.
- Инлайн-редактирование имени карточки.
