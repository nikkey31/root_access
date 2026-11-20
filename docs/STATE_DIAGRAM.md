# Диаграмма состояний (State Machine Diagram) — Root Access

Данный документ содержит спецификацию автомата состояний игрового процесса детективного триллера **«Root Access»** в соответствии с нотацией UML State Machine. 

---

## 1. Общее описание автомата состояний

Автомат состояний игры управляется центральным синглтоном `GameState` (`res://scripts/core/GameState.gd`), виртуальной файловой системой `VFS` (`res://scripts/core/VFS.gd`) и оконным менеджером `Desktop` (`res://scripts/desktop/desktop.gd`).

Игровой процесс разделен на три последовательные фазы:
1. **Фаза расследования (Investigation Phase):** Игрок исследует виртуальную ОС ноутбука, собирает улики в Заметках, Галерее (зум фуры 6752), Браузере и Аудиоплеере (`record.wav`), разгадывает ПИН-код папки «Работа» (`2409`) и расшифровывает секретный архив в Терминале (`LENINA54`).
2. **Фаза картографического выбора (Tactical Choice Phase):** Сопоставление расшифрованных координат с интерактивной картой города и выбор финальной точки для направления оперативной группы полиции (Пирс № 4).
3. **Кризисная фаза финала (Crisis Countdown Phase):** Запуск 60-секундного обратного отсчета дежурной части, перехват управления модальными диалогами взятки ($100k) и фишинговой ловушки Юджина (Dark UX паттерн), приводящий к одной из **5 сюжетных концовок**.

---

## 2. UML-диаграмма состояний (State Machine Diagram)

```mermaid
stateDiagram-v2
    [*] --> DesktopIdle: Загрузка ОС / Инициализация VFS

    state "Desktop Idle (Рабочий стол)" as DesktopIdle {
        [*] --> IdleReady
        IdleReady: Ожидание действий детектива
        IdleReady: Рендеринг CRT-шейдера и панели задач
    }

    state "VFS Investigation (Файловый анализ)" as VFSInvestigation {
        BrowseDrives: Обход дисков A:, C:, D:
        ReadNotes: Анализ заметок (пароли.txt)
        TrashInspect: Осмотр Корзины
    }

    state "Media Forensics (Медиа-улики)" as MediaForensics {
        GalleryZoom: Зум фото (фура 6752)
        ReadEXIF: Извлечение даты съемки (24.09)
        ListenTape: Воспроизведение record.wav
        BrowserHistory: Чтение переписки мессенджера
    }

    state "Directory Unlocked (Папка 'Работа')" as DirUnlocked {
        AccessWork: Доступ к рабочим логам
        TimeAdvance: Перемотка времени (02:15 -> 03:40)
        FindEncrypted: Обнаружение архива location.enc
    }

    state "CLI Decryption (Дешифрование)" as CLIDecrypt {
        RunTerminal: Ввод decrypt -k LENINA54
        ProgressBar: Анимация прогресса дешифровки
        LogExtracted: Получение координат (Пирс № 4)
    }

    state "Map Coordinate Select (Выбор цели)" as MapSelect {
        InspectPOIs: Анализ 18 точек на карте
        ConfirmTarget: Подтверждение целеуказания
    }

    state "Crisis Countdown (Обратный отсчет 60с)" as CrisisCountdown {
        TimerRunning: Ежесекундный декремент таймера
        CheckThresholds: Мониторинг порогов (30с, 5с, 0с)
    }

    state "Crisis Interception (Модальный кризис)" as CrisisModal {
        BribeOffer: Предъявление взятки $100k (Симон)
        PhishingTrap: Ловушка фишинга геометки (Dark UX)
    }

    state "Ending 1: Триумф детектива" as Ending1
    state "Ending 2: Сделка с совестью" as Ending2
    state "Ending 3: В тупике (Ошибка)" as Ending3
    state "Ending 4: Незваный гость (Хоррор)" as Ending4
    state "Ending 5: Провал операции" as Ending5

    %% Переходы состояний
    DesktopIdle --> VFSInvestigation: Открытие Проводника / Заметок
    DesktopIdle --> MediaForensics: Открытие Галереи / Браузера / Плеера
    VFSInvestigation --> MediaForensics: Перекрестный анализ улик
    MediaForensics --> VFSInvestigation: Проверка гипотез

    VFSInvestigation --> DirUnlocked: Ввод ПИН-кода [pin == '2409']
    MediaForensics --> DirUnlocked: Ввод ПИН-кода по EXIF-дате [pin == '2409']

    DirUnlocked --> CLIDecrypt: Запуск Терминала и команды decrypt
    CLIDecrypt --> MapSelect: Открытие Карты с координатами

    MapSelect --> CrisisCountdown: Подтверждение координат -> старт 60с таймера

    CrisisCountdown --> CrisisModal: timer <= 30s [bribe_triggered]
    CrisisModal --> Ending2: Принятие взятки [accept_bribe()]
    CrisisModal --> CrisisModal: Отмена взятки -> таймер 5с [phishing_triggered]
    CrisisModal --> Ending4: Нажатие «Продолжить» [Dark UX Geolocation Leak]

    CrisisCountdown --> Ending1: Таймер истек [target == Pier_4]
    CrisisCountdown --> Ending3: Таймер истек [target != Pier_4]
    CrisisCountdown --> Ending5: Таймаут без выбора координат [time == 0]

    Ending1 --> [*]
    Ending2 --> [*]
    Ending3 --> [*]
    Ending4 --> [*]
    Ending5 --> [*]
```

---

## 3. Спецификация состояний автомата

### 1. `DesktopIdle` (Начальное состояние)
* **Описание:** Рабочий стол виртуальной ОС Toughbook загружен, CRT-эффект активен, оконный менеджер готов к запуску приложений.
* **Entry Action:** `VFS.init_filesystem()`, `GameState.reset_investigation()`.
* **Do Action:** Отрисовка рабочего стола, панели задач, часов реального времени (02:15).
* **Exit Action:** Запуск первого выбранного приложения игрока.

### 2. `VFSInvestigation` (Исследование файловой структуры)
* **Описание:** Игрок просматривает дерево каталогов виртуальной ОС (диски A:, C:, D:) и читает открытые заметки.
* **Do Action:** Чтение `список_дел.txt`, нахождение скрытого файла `пароли.txt` в середине списка, поиск удаленной накладной в Корзине.
* **Trigger:** Попытка входа в директорию `C:\ROOT_ACCESS\Работа` активирует модальное окно ввода 4-значного ПИН-кода.

### 3. `MediaForensics` (Медиа-криминалистика)
* **Описание:** Анализ фотоматериалов, аудиозаписей и сетевых следов подозреваемого.
* **Do Action:** 
  * Масштабирование снимка склада в Галерее (зум до 4x) и выявление бортового номера фуры **6752**.
  * Чтение даты съемки **24.09** из инспектора EXIF-свойств.
  * Прослушивание аудиозаписи переговоров `record.wav` на кассетном плеере.
  * Анализ истории посещений браузера и чтение скрытого веб-мессенджера.

### 4. `DirectoryUnlocked` (Папка «Работа» разблокирована)
* **Описание:** Успешная авторизация к защищенному разделу преступника.
* **Entry Action:** `GameState.unlock_work_folder()`, перемотка времени расследования на **03:40**.
* **Do Action:** Открытие доступа к скрытым файлам накладных и зашифрованному архиву `location.enc`.

### 5. `CLIDecryption` (Дешифрование архива в Терминале)
* **Описание:** Использование командной строки для дешифровки ключевой улики.
* **Entry Action:** `Terminal.run_command("decrypt location.enc -k LENINA54")`.
* **Do Action:** Отрисовка пошагового текстового прогресс-бара `[====>    ] 100%`.
* **Exit Action:** Вывод расшифрованного лога с целеуказанием на объект «Пирс № 4».

### 6. `MapCoordinateSelect` (Картографический анализ)
* **Описание:** Сопоставление сведений из расшифрованного архива с картой города.
* **Do Action:** Инспекция 18 меток (POI), выбор сектора «Пирс № 4», подтверждение отправки оперативной группы.
* **Exit Action:** Генерация сигнала `GameState.coordinates_confirmed`.

### 7. `CrisisCountdown` (Критический обратный отсчет 60 секунд)
* **Описание:** Дежурный координатор передает ориентировку спецназу, начинается 60-секундный штурмовой таймер.
* **Entry Action:** `GameState.start_crisis_timer(60.0)`.
* **Do Action:** Ежесекундное уменьшение времени `time_remaining`, тревожная анимация индикатора.

### 8. `CrisisInterception` (Модальный кризис и атака Dark UX)
* **Описание:** Попытка антагонистов сорвать операцию через всплывающие диалоговые окна `CrisisDialog.tscn`.
* **Substates:**
  * **Взятка Симона ($100k):** Появляется на 30-й секунде. Кнопка «Принять» дает $100,000 на офшор. Красная кнопка «Отмена» обучает рефлексу закрытия.
  * **Фишинг Юджина (Dark UX):** Срабатывает через 5 секунд после отмены взятки. Под видом системной проверки геопозиции выводится диалог, где красная кнопка — **«Продолжить»**. Нажатие на нее передает координаты Юджину.

---

## 4. Спецификация финальных состояний (Концовки)

| Финальное состояние | Название концовки | Условие достижения (Guard Condition) | Игровой исход |
| :--- | :--- | :--- | :--- |
| **`Ending 1`** | **Триумф детектива** *(Каноническая победа)* | Координаты подтверждены как `Пирс № 4`, взятка отклонена, фишинг отменен, таймер истек. | Спецназ перехватывает фуру 6752 на пирсе, Юджин Рейвенс арестован, улики спасены. |
| **`Ending 2`** | **Сделка с совестью** | Нажата кнопка «Принять $100,000» в диалоге взятки Симона. | Детектив берет деньги, архивы стираются командой `wipe`, маньяк бежит за границу. |
| **`Ending 3`** | **В тупике (Ошибка)** | Выбраны неверные координаты (Северный склад или Перекресток), таймер истек. | Спецназ штурмует пустое здание, время упущено, преступник скрывается. |
| **`Ending 4`** | **Незваный гость** *(Хоррор Юджина)* | Нажата красная кнопка «Продолжить» в окне фишинга геометки. | Юджин вычисляет местоположение детектива по IP, вламывается в кабинет, экран гаснет под звук выстрела. |
| **`Ending 5`** | **Провал операции** *(Таймаут)* | Время 60с истекло без подтверждения координат штурма. | Защитная система ноутбука активирует аварийное стирание секторов, расследование сорвано. |

---

## 5. Матрица переходов состояний (Transition Matrix)

| Исходное состояние | Событие / Сигнал | Guard-условие | Результирующее действие | Целевое состояние |
| :--- | :--- | :--- | :--- | :--- |
| `DesktopIdle` | `open_app("computer")` | VFS смонтирована | Открытие Проводника | `VFSInvestigation` |
| `DesktopIdle` | `open_app("gallery")` | VFS смонтирована | Открытие Галереи | `MediaForensics` |
| `VFSInvestigation` | `pin_submitted` | `pin == "2409"` | Смена времени на 03:40 | `DirectoryUnlocked` |
| `MediaForensics` | `pin_submitted` | `pin == "2409"` | Разблокировка папки | `DirectoryUnlocked` |
| `DirectoryUnlocked` | `command_executed` | `cmd == "decrypt"` | Запуск прогресс-бара | `CLIDecryption` |
| `CLIDecryption` | `decrypt_finished` | `key == "LENINA54"` | Вывод координат Пирса | `MapCoordinateSelect` |
| `MapCoordinateSelect` | `confirm_target` | `target != null` | Старт таймера 60.0с | `CrisisCountdown` |
| `CrisisCountdown` | `timer_tick` | `time_remaining <= 30.0` | Показ окна взятки $100k | `CrisisInterception` |
| `CrisisInterception` | `bribe_accepted` | Нажата «Принять» | Вызов `GameState.trigger_ending(2)` | `Ending 2` |
| `CrisisInterception` | `bribe_cancelled` | Нажата «Отмена» | Запуск задержки 5.0с фишинга | `CrisisInterception` |
| `CrisisInterception` | `phishing_clicked` | Нажата «Продолжить» | Вызов `GameState.trigger_ending(4)` | `Ending 4` |
| `CrisisCountdown` | `timer_expired` | `target == "Пирс № 4"` | Вызов `GameState.trigger_ending(1)` | `Ending 1` |
| `CrisisCountdown` | `timer_expired` | `target != "Пирс № 4"` | Вызов `GameState.trigger_ending(3)` | `Ending 3` |
| `CrisisCountdown` | `timer_expired` | `target == null` | Вызов `GameState.trigger_ending(5)` | `Ending 5` |
