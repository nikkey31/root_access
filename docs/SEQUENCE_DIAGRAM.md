# UML-диаграммы последовательности (Sequence Diagrams) — «Root Access»

**Дисциплина:** Технологии разработки программного обеспечения (ТРПО)  
**Проект:** Детективный психологический ретро-симулятор «Root Access»  
**Артефакт:** UML Sequence Diagrams (Практическая работа № 4)  
**Автор:** Миша (`uhmaikl-cell`), документовед и QA команды  
**Статус:** Согласовано с архитектурой ядра (Godot 4.x / GDScript)

---

## 1. Введение и архитектурный контекст

Настоящий документ содержит спецификацию и визуальные UML-диаграммы последовательности (**Sequence Diagrams**) для ключевых сценариев взаимодействия игрока и подсистем виртуальной операционной системы Toughbook RetroOS 98 в рамках 4-й практической работы:

1. **Сценарий 1. Исследование медиа-улик и прохождение мини-игр:**
   - Папка `C:\Игры` $\rightarrow$ мини-игра «Рыбалка» (извлечение фрагмента ключа шифрования);
   - Приложение «Галерея» $\rightarrow$ просмотр экспозиции фотоархива и вызов окна EXIF-метаданных даты съемки;
   - Модальный «Аудиоплеер» $\rightarrow$ динамический эквалайзер/осциллограмма, субтитры и воспроизведение записи `record.wav`.
2. **Сценарий 2. Цепочка дешифрования криптоконтейнера `location.enc`:**
   - Ввод консольной команды `decrypt <файл> -k <ключ>` в приложении `Terminal`;
   - Парсинг флагов и аргументов командной строки;
   - Верификация контрольной суммы и ключа в `VFS` и `GameState`;
   - Генерация дешифрованного файла `record.wav`;
   - Синхронная перемотка системного времени с `02:15` на `03:40` и реакция интерфейса рабочего стола.
3. **Сценарий 3. Кризисный финал расследования (Таймер 60 секунд, Dark UX ловушки и 5 концовок):**
   - Запуск 60-секундного адреналинового таймера после окончания аудиозаписи;
   - Перехват сокета Саймона на 30-й секунде (предложение взятки $100,000, приучение к красной кнопке отмены);
   - Психологическая фишинг-ловушка через 5 секунд (провокация клика по красной кнопке продолжения);
   - Ветвление на 5 сюжетных концовок (`EndingScreen`).

Каждая диаграмма представлена в двух стандартах:
- **Mermaid (`sequenceDiagram`)** — для интерактивного отображения в веб-интерфейсе GitHub, VS Code и Godot IDE;
- **PlantUML (`@startuml ... @enduml`)** — для вставки векторных схем в официальный отчёт `ТРПОПР4.docx`.

---

## 2. Диаграмма 1. Исследование медиа-улик и прохождение мини-игр

### 2.1. Описание сценария
Детектив Ник Будхайм исследует рабочее пространство маньяка Саймона Раклина. Для раскрытия дела ему необходимо восстановить пароль от зашифрованной рабочей директории и собрать части ключа дешифрования:
1. **Мини-игра «Рыбалка» (`fishing.exe`):** В каталоге `C:\Игры` находится любимая ретро-игра Саймона. Прохождение испытания (выуживание виртуальной трофейной щуки) открывает системный рекорд и гравировку на блесне, содержащую первую часть секретного шифра (`LENINA`).
2. **Галерея (`GalleryApp`):** Просмотр 20 бытовых снимков Саймона. Обнаружение снимка грузовой фуры с бортовым номером `6752` у ворот с вывеской `Склад № 3` (`IMG_2042.jpg`), а также фотографии у ржавого пикапа (`IMG_2041.jpg`). Открытие окна свойств файла извлекает дату съемки: `24.09.2009 18:42` (день рождения брата Юджина $\rightarrow$ пароль `2409`).
3. **Аудиоплеер (`AudioPlayer`):** Открытие расшифрованного аудио `record.wav`. Запускается анимация эквалайзера (ASCII/псевдографическая волна амплитуды), тайм-код воспроизведения (8 секунд), вывод субтитров голоса Саймона и передача сигнала завершения в ядро игры.

### 2.2. Диаграмма Mermaid

```mermaid
sequenceDiagram
    autonumber
    actor Player as Игрок (Ник Будхайм)
    participant Explorer as Проводник (explorer.gd)
    participant FishingGame as Мини-игра «Рыбалка» (fishing.exe)
    participant Gallery as Галерея (app_preview.gd)
    participant AudioPlayer as Аудиоплеер (explorer.gd:AudioOverlay)
    participant VFS as Виртуальная ФС (VFS.gd)
    participant GameState as Менеджер игры (GameState.gd)
    participant ThoughtBox as Мысли Ника (thought_box.gd)

    Note over Player, ThoughtBox: Этап 1. Исследование папки «Игры» и мини-игра «Рыбалка»
    Player->>Explorer: Двойной клик на папку «C:\Игры»
    Explorer->>VFS: list_directory("C:\\Игры")
    VFS-->>Explorer: ["рыбалка.exe", "шахматы.exe", "shadow_fight.exe", "рекорды_рыбалка.txt"]
    Explorer->>GameState: trigger_thought("game_folder_inspect")
    GameState->>ThoughtBox: show_thought("«Игры... Странно видеть пасьянс и рыбалку на ноутбуке хладнокровного мясника»")
    
    Player->>Explorer: Запуск «рыбалка.exe»
    Explorer->>FishingGame: open_app("res://scenes/apps/FishingMinigame.tscn")
    FishingGame-->>Player: Отображение озера, удочки и индикатора натяжения лески
    Player->>FishingGame: Удержание ЛКМ (балансировка поклёвки)
    FishingGame->>FishingGame: check_catch_success() == true
    FishingGame-->>Player: Улов: Трофейная щука 8.4 кг!
    FishingGame->>VFS: write_file("C:\\Игры\\рекорды_рыбалка.txt", "Рекорд: 8.4 кг (Озеро Ленина, поворот 54)")
    FishingGame->>GameState: trigger_thought("game_fishing")
    GameState->>ThoughtBox: show_thought("Ник: «Гравировка на блесне в рекордах: Озеро Ленина, поворот 54... LENINA54? Это похоже на ключ шифрования!»")

    Note over Player, ThoughtBox: Этап 2. Анализ экспозиции фотоархива в Галерее (EXIF)
    Player->>Gallery: Открытие «Галерея» с Рабочего стола
    Gallery->>VFS: load_photos_metadata("data/files.json")
    Gallery-->>Player: Отрисовка каталога (15-20 миниатюр: фура, пикап, кот, пикник)
    Player->>Gallery: Клик по «IMG_2042.jpg» (Фура 6752 у Склада № 3)
    Gallery->>GameState: set_flag("is_truck_photo_viewed", true)
    GameState->>ThoughtBox: show_thought("Ник: «Белый фургон с бортовым номером 6752 у ворот Склада № 3... Стоит запомнить»")
    
    Player->>Gallery: Клик по «IMG_2041.jpg» -> Нажатие «Свойства / Подробнее»
    Gallery->>Gallery: parse_exif_metadata()
    Gallery-->>Player: Модальное окно свойств: Дата 24.09.2009, 18:42, Canon PowerShot A590 IS
    Gallery->>GameState: set_flag("is_exif_viewed", true)
    GameState->>ThoughtBox: show_thought("Ник: «24 сентября! В переписке брат благодарил за визит на 27-летие. Пароль к папке «Работа» — 2409!»")

    Note over Player, ThoughtBox: Этап 3. Аудиоплеер: эквалайзер и аудиосообщение маньяка
    Player->>Explorer: Двойной клик на расшифрованный «record.wav»
    Explorer->>AudioPlayer: _show_audio_player()
    AudioPlayer-->>Player: Отображение модального окна (хром RetroOS, кнопка Стоп, 00:00 / 00:08)
    
    loop 8 секунд воспроизведения (_process)
        AudioPlayer->>AudioPlayer: update_playback_time(delta)
        AudioPlayer->>AudioPlayer: animate_equalizer(" ▂▃▅▆▇██▇▆▅▃▂ ")
        AudioPlayer-->>Player: Динамическая визуализация звуковой волны
    end

    AudioPlayer-->>Player: Субтитры: «...время почти вышло. Грузовик 6-7-5-2... Она останется здесь навсегда...»
    AudioPlayer->>Explorer: _on_audio_finished()
    Explorer->>GameState: mark_audio_listened()
    GameState->>GameState: is_audio_listened = true
    GameState->>GameState: start_final_timer(60.0)
    GameState->>ThoughtBox: show_thought("Ник: «Звонок из дежурной части: Саймон вышел на связь! Ровно 60 секунд на выбор точки!»")
```

### 2.3. Спецификация PlantUML (для отчёта ТРПОПР4.docx)

```plantuml
@startuml
autonumber
skinparam style strictuml
skinparam sequenceMessageAlign center
skinparam monochrome false
skinparam responseMessageBelowArrow true

actor "Игрок (Ник Будхайм)" as Player
participant "Проводник\n(explorer.gd)" as Explorer
participant "Рыбалка\n(fishing.exe)" as FishingGame
participant "Галерея\n(app_preview.gd)" as Gallery
participant "Аудиоплеер\n(AudioOverlay)" as AudioPlayer
participant "Виртуальная ФС\n(VFS.gd)" as VFS
participant "Менеджер игры\n(GameState.gd)" as GameState
participant "Мысли Ника\n(thought_box.gd)" as ThoughtBox

== Этап 1. Исследование папки «Игры» и мини-игра «Рыбалка» ==
Player -> Explorer : Открыть папку "C:\\Игры"
Explorer -> VFS : list_directory("C:\\Игры")
VFS --> Explorer : ["рыбалка.exe", "шахматы.exe", "shadow_fight.exe", "рекорды_рыбалка.txt"]
Explorer -> GameState : trigger_thought("game_folder_inspect")
GameState -> ThoughtBox : show_thought("Странно видеть игры на Toughbook маньяка...")

Player -> Explorer : Запуск "рыбалка.exe"
Explorer -> FishingGame : open_app(FishingMinigame)
FishingGame --> Player : Отрисовка озера и лески
Player -> FishingGame : Заброс и подсечка рыбы
FishingGame -> FishingGame : check_catch_success()
FishingGame --> Player : Трофейная щука 8.4 кг!
FishingGame -> VFS : write_file("рекорды_рыбалка.txt", "Озеро Ленина, 54")
FishingGame -> GameState : trigger_thought("game_fishing")
GameState -> ThoughtBox : show_thought("Подсказка к шифру: LENINA54!")

== Этап 2. Анализ фотоархива в Галерее (EXIF) ==
Player -> Gallery : Запуск Галереи
Gallery -> VFS : load_photos_metadata()
Gallery --> Player : Отображение 20 фото
Player -> Gallery : Клик по "IMG_2042.jpg" (Фура 6752)
Gallery -> GameState : set_flag("is_truck_photo_viewed", true)
GameState -> ThoughtBox : show_thought("Бортовой номер 6752 у Склада № 3...")

Player -> Gallery : Клик по "IMG_2041.jpg" -> "Свойства"
Gallery -> Gallery : parse_exif_metadata()
Gallery --> Player : Окно свойств: Дата 24.09.2009 18:42
Gallery -> GameState : set_flag("is_exif_viewed", true)
GameState -> ThoughtBox : show_thought("ДР Юджина — 24.09! Пароль: 2409")

== Этап 3. Аудиоплеер: эквалайзер и запуск таймера ==
Player -> Explorer : Открыть "record.wav"
Explorer -> AudioPlayer : _show_audio_player()
AudioPlayer --> Player : Окно плеера, старт аудио

loop 8 секунд
    AudioPlayer -> AudioPlayer : animate_equalizer()
    AudioPlayer --> Player : Осциллограмма волны
end

AudioPlayer --> Player : Субтитры: "Грузовик 6-7-5-2..."
AudioPlayer -> Explorer : _on_audio_finished()
Explorer -> GameState : mark_audio_listened()
GameState -> GameState : start_final_timer(60.0)
GameState -> ThoughtBox : show_thought("60 секунд на спасение Мишель!")
@enduml
```

---

## 3. Диаграмма 2. Цепочка дешифрования криптоконтейнера `location.enc`

### 3.1. Описание сценария
1. **Ввод команды:** Игрок открывает консоль `Terminal` и вводит команду:
   ```bash
   decrypt location.enc -k LENINA54
   ```
2. **Парсинг аргументов:** Класс `TerminalApp` проверяет наличие аргументов, флагов (`-k` или `--key`), выделяет имя целевого файла (`location.enc`) и переданный токен ключа (`LENINA54`).
3. **Визуализация прогресса:** Терминал эмулирует работу процессора 2009 года, последовательно выводя ретро-прогрессбар с дискретным шагом:
   ```text
   [░░░░░░░░░░░░░░░░]   0%
   [████░░░░░░░░░░░░]  25%
   [████████░░░░░░░░]  50%
   [████████████░░░░]  75%
   [████████████████] 100% COMPLETE
   ```
4. **Криптографическая проверка в VFS:**
   - Вызывается метод `VFS.decrypt_file("location.enc", "LENINA54")`.
   - Проверяется статус шифрования узла (`node.get("is_encrypted", false) == true`).
   - Ключ приводится к верхнему регистру без пробелов: `entered_key == expected_key` (`"LENINA54"`).
5. **Создание дешифрованного объекта:**
   - `VFS` создает новую запись для файла `record.wav` (размер 820 КБ, дата `02.10.2009 03:40`, тип `Звуковой файл WAV`).
   - Файл связывается с путями `C:\ROOT_ACCESS\Работа\record.wav` и `C:\ROOT_ACCESS\record.wav`.
6. **Уведомление ядра и перемотка времени:**
   - `VFS` вызывает `GameState.verify_decryption("location.enc", "LENINA54")`.
   - `GameState` устанавливает флаг `is_location_decrypted = true`.
   - `GameState` испускает сигнал `story_time_jump_requested(3, 40, true)`.
   - Рабочий стол `Desktop` перехватывает сигнал, накладывает кратковременные ЭЛТ-помехи и переводит системные часы с `02:15` на `03:40`.
   - `Explorer` обновляет список файлов в открытой директории и отображает незаблокированную иконку динамика для `record.wav`.
   - `Terminal` выводит зелёное системное подтверждение дешифровки.

### 3.2. Диаграмма Mermaid

```mermaid
sequenceDiagram
    autonumber
    actor Player as Игрок (Ник Будхайм)
    participant Terminal as Терминал (terminal.gd)
    participant VFS as Виртуальная ФС (VFS.gd)
    participant GameState as Менеджер игры (GameState.gd)
    participant Desktop as Рабочий стол (desktop.gd)
    participant Explorer as Проводник (explorer.gd)
    participant ThoughtBox as Мысли Ника (thought_box.gd)

    Player->>Terminal: Ввод: "decrypt location.enc -k LENINA54"
    Terminal->>Terminal: _on_command_submitted(raw_text)
    Terminal->>Terminal: _cmd_decrypt(args)
    Terminal->>Terminal: Извлечение filename="location.enc", key="LENINA54"
    
    Terminal-->>Player: Вывод: "[CYAN] Запуск дешифрования криптоконтейнера: location.enc..."
    loop Симуляция прогресса дешифрования
        Terminal-->>Player: [░░░░░░░░░░░░░░░░]   0%
        Terminal-->>Player: [████░░░░░░░░░░░░]  25%
        Terminal-->>Player: [████████░░░░░░░░]  50%
        Terminal-->>Player: [████████████░░░░]  75%
        Terminal-->>Player: [████████████████] 100% COMPLETE
    end

    Terminal->>VFS: decrypt_file("location.enc", "LENINA54")
    VFS->>VFS: _resolve_path("location.enc")
    VFS->>VFS: node = files_database[resolved]
    VFS->>VFS: verify key ("LENINA54" == node.key) == true
    
    Note over VFS: Создание ноды дешифрованного файла record.wav
    VFS->>VFS: files_database["C:\\ROOT_ACCESS\\Работа\\record.wav"] = record_node
    VFS->>VFS: append "record.wav" into target_dirs items
    
    VFS->>GameState: verify_decryption("location.enc", "LENINA54")
    GameState->>GameState: is_location_decrypted = true
    
    par Оповещение подсистем RetroOS
        GameState->>GameState: emit_signal("location_decrypted")
        GameState->>GameState: emit_signal("story_time_jump_requested", 3, 40, true)
        GameState->>ThoughtBox: trigger_thought("Аудиофайл. Девять секунд. Надо послушать.")
    end

    Desktop->>Desktop: _on_story_time_jump_requested(3, 40, true)
    Desktop->>Desktop: play_crt_glitch_fx()
    Desktop->>Desktop: update_taskbar_clock("03:40")
    Desktop-->>Player: Визуальный эффект перемотки времени (02:15 -> 03:40)

    Explorer->>Explorer: _on_location_decrypted()
    Explorer->>VFS: list_directory(current_dir)
    Explorer-->>Player: Появление файла «record.wav» с иконкой аудиокассеты

    ThoughtBox-->>Player: «Аудиофайл. Девять секунд. Надо послушать.»
    
    VFS-->>Terminal: {"success": true, "unlocked_file": "record.wav"}
    Terminal-->>Player: "[GREEN] [УСПЕХ] Файл 'location.enc' расшифрован.\nСоздан медиафайл: 'record.wav' (820 КБ)"
```

### 3.3. Спецификация PlantUML (для отчёта ТРПОПР4.docx)

```plantuml
@startuml
autonumber
skinparam style strictuml
skinparam sequenceMessageAlign center
skinparam monochrome false

actor "Игрок (Ник)" as Player
participant "Терминал\n(terminal.gd)" as Terminal
participant "Виртуальная ФС\n(VFS.gd)" as VFS
participant "Менеджер игры\n(GameState.gd)" as GameState
participant "Рабочий стол\n(desktop.gd)" as Desktop
participant "Проводник\n(explorer.gd)" as Explorer
participant "Мысли Ника\n(thought_box.gd)" as ThoughtBox

Player -> Terminal : "decrypt location.enc -k LENINA54"
activate Terminal

Terminal -> Terminal : _cmd_decrypt(args)
Terminal --> Player : Старт криптографического процесса...

loop 0% -> 25% -> 50% -> 75% -> 100%
    Terminal --> Player : Отрисовка полосы прогресса
end

Terminal -> VFS : decrypt_file("location.enc", "LENINA54")
activate VFS

VFS -> VFS : Сверка ключа ("LENINA54" == node.key)
VFS -> VFS : Создание record.wav в files_database

VFS -> GameState : verify_decryption("location.enc", "LENINA54")
activate GameState

GameState -> GameState : is_location_decrypted = true
GameState -> GameState : emit_signal("location_decrypted")
GameState -> GameState : emit_signal("story_time_jump_requested", 3, 40, true)
GameState -> ThoughtBox : trigger_thought("Аудиофайл. Девять секунд...")

GameState -> Desktop : _on_story_time_jump_requested(03:40)
Desktop -> Desktop : ЭЛТ-помехи, перевод часов: 02:15 -> 03:40
Desktop --> Player : Обновление системных часов панели задач

GameState -> Explorer : _on_location_decrypted()
Explorer -> Explorer : Обновление списка файлов
Explorer --> Player : Иконка "record.wav" доступна для открытия

deactivate GameState
VFS --> Terminal : {"success": true, "unlocked_file": "record.wav"}
deactivate VFS

Terminal --> Player : "[УСПЕХ] Файл расшифрован: record.wav"
deactivate Terminal
@enduml
```

---

## 4. Диаграмма 3. Кризисный финал расследования (Таймер 60 секунд, ловушки и 5 концовок)

### 4.1. Описание сценария
1. **Старт обратного отсчёта:** После завершения аудиозаписи `record.wav` синглтон `GameState` активирует глобальный 60-секундный таймер (`start_final_timer(60.0)`). Виджет `FinalTimerBar` в панели задач начинает пульсировать красным цветом.
2. **Событие 1 (30-я секунда — Взятка $100,000):**
   - При `time_remaining <= 30.0` срабатывает событие `bribe_triggered`.
   - `Desktop` разворачивает поверх всех окон модальный диалог `CrisisDialog` в режиме `BRIBE`.
   - Саймон предлагает $100,000 наличными за ввод команды `wipe --force` в консоли.
   - **Формирование рефлекса:** Кнопка «Отмена» подсвечена ярко-красной рамкой (2 px red border). Игрок запоминает паттерн «красная кнопка = безопасное закрытие спама».
   - Нажатие «Отмена» эмитирует `bribe_cancelled` и запускает 5-секундный скрытый таймер отложенного фишинга (`phishing_delay_remaining = 5.0`).
3. **Событие 2 (Через 5 секунд после отмены взятки — Dark UX фишинг):**
   - Срабатывает сигнал `phishing_triggered`.
   - `CrisisDialog` открывается в режиме `PHISHING` («Служба безопасности RetroOS: подтверждение сертификата и геометки устройства»).
   - **Психологическая ловушка:** Красной рамкой теперь выделена кнопка **«Продолжить»**, а кнопка «Отмена» сделана незаметной серой.
4. **Развилки на 5 концовок:**
   - **Исход 1: Концовка 4 «Незваный гость» (HORROR).** Игрок кликает по красной кнопке на автомате $\rightarrow$ подтверждается передача геометки $\rightarrow$ брат маньяка Юджин врывается в квартиру детектива.
   - **Исход 2: Концовка 1 «Идеальное спасение» (SALVATION).** Игрок закрывает фишинг серой кнопкой, открывает Карту и кликает по истинной улике **«Склад № 3»** (подтвержденной накладной из корзины и фото фуры 6752).
   - **Исход 3: Концовка 2 «Ложный след» (FALSE_TRAIL).** Игрок выбирает поверхностную ловушку **«Бокс № 6752»** на Карте $\rightarrow$ группа захвата штурмует пустой гараж.
   - **Исход 4: Концовка 3 «Время вышло» (TIMEOUT).** Таймер достигает `00:00` $\rightarrow$ спасательная операция сорвана.
   - **Исход 5: Концовка 5 «Сделка с дьяволом» (CORRUPTION).** Игрок поверил Саймону и ввел в Терминале `wipe --force` $\rightarrow$ улики уничтожены, детектив продался.

### 4.2. Диаграмма Mermaid

```mermaid
sequenceDiagram
    autonumber
    actor Player as Игрок (Ник Будхайм)
    participant GameState as Менеджер игры (GameState.gd)
    participant FinalTimerBar as Таймер (final_timer_bar.gd)
    participant Desktop as Рабочий стол (desktop.gd)
    participant CrisisDialog as Кризисный диалог (crisis_dialog.gd)
    participant MapApp as Карта (map_preview.gd)
    participant Terminal as Терминал (terminal.gd)
    participant EndingScreen as Экран концовок (ending_screen.gd)

    Note over GameState, FinalTimerBar: Старт 60-секундного адреналинового отсчета
    GameState->>FinalTimerBar: emit_signal("timer_started", 60.0)
    loop Тик каждого кадра (_process)
        GameState->>FinalTimerBar: emit_signal("timer_updated", time_remaining)
        FinalTimerBar-->>Player: Отображение прогресса таймера (красный бегунок)
    end

    Note over GameState, CrisisDialog: 30-я секунда (Осталось <= 30.0 с) — Взятка Саймона
    GameState->>Desktop: emit_signal("bribe_triggered")
    Desktop->>CrisisDialog: show_bribe()
    CrisisDialog-->>Player: Пейджер Саймона: «Предлагаю $100 000 за ввод wipe --force»
    Note over CrisisDialog, Player: Тёмный паттерн: Красная рамка у кнопки «Отмена»
    Player->>CrisisDialog: Клик по красной кнопке «Отмена»
    CrisisDialog->>Desktop: emit_signal("bribe_cancelled")
    Desktop->>GameState: cancel_bribe()
    GameState->>GameState: phishing_delay_remaining = 5.0

    Note over GameState, CrisisDialog: Через 5 секунд — Фишинг геолокации RetroOS
    GameState->>GameState: phishing_delay_remaining <= 0
    GameState->>Desktop: emit_signal("phishing_triggered")
    Desktop->>CrisisDialog: show_phishing()
    CrisisDialog-->>Player: «Запрос подтверждения геометки устройства [Квартира Ника]»
    Note over CrisisDialog, Player: Тёмный паттерн: Красная рамка ПЕРЕМЕЩЕНА на «Продолжить»!

    alt Исход A: Игрок нажал на автомате красную «Продолжить» (Ловушка)
        Player->>CrisisDialog: Клик по красной «Продолжить»
        CrisisDialog->>Desktop: emit_signal("phishing_accepted")
        Desktop->>GameState: trigger_ending(Ending.HORROR, {"reason": "phishing_accepted"})
        GameState->>EndingScreen: emit_signal("game_ended", HORROR)
        EndingScreen-->>Player: Концовка 4 «Незваный гость»: Юджин выследил Ника по геометке
    
    else Исход B: Игрок распознал обман, нажал «Отмена» и выбрал «Склад № 3»
        Player->>CrisisDialog: Клик по серой «Отмена»
        CrisisDialog-->>Player: Диалог закрыт, доступна Карта
        Player->>MapApp: Клик по точке «Склад № 3» (улика: фура 6752)
        MapApp->>GameState: select_location("Склад № 3")
        GameState->>GameState: trigger_ending(Ending.SALVATION, {"point": "Склад № 3"})
        GameState->>EndingScreen: emit_signal("game_ended", SALVATION)
        EndingScreen-->>Player: Концовка 1 «Идеальное спасение»: Мишель Юхнова освобождена!

    else Исход C: Игрок поддался поверхностной ловушке цифр «Бокс № 6752»
        Player->>MapApp: Клик по точке «Бокс № 6752»
        MapApp->>GameState: select_location("Бокс № 6752")
        GameState->>GameState: trigger_ending(Ending.FALSE_TRAIL, {"point": "Бокс № 6752"})
        GameState->>EndingScreen: emit_signal("game_ended", FALSE_TRAIL)
        EndingScreen-->>Player: Концовка 2 «Ложный след»: Пустой гараж, маньяки скрылись

    else Исход D: Время вышло (time_remaining <= 0.0)
        GameState->>GameState: emit_signal("timer_expired")
        GameState->>GameState: trigger_ending(Ending.TIMEOUT, {"reason": "time_expired"})
        GameState->>EndingScreen: emit_signal("game_ended", TIMEOUT)
        EndingScreen-->>Player: Концовка 3 «Время вышло»: Спецназ опоздал

    else Исход E: Игрок ввел «wipe --force» в консоли
        Player->>Terminal: Ввод: "wipe --force"
        Terminal->>GameState: trigger_ending(Ending.CORRUPTION, {"reason": "wipe_force"})
        GameState->>EndingScreen: emit_signal("game_ended", CORRUPTION)
        EndingScreen-->>Player: Концовка 5 «Сделка с дьяволом»: Взятка $100k, улик нет
    end
```

### 4.3. Спецификация PlantUML (для отчёта ТРПОПР4.docx)

```plantuml
@startuml
autonumber
skinparam style strictuml
skinparam sequenceMessageAlign center
skinparam monochrome false

actor "Игрок (Ник)" as Player
participant "Менеджер игры\n(GameState.gd)" as GameState
participant "Таймер\n(final_timer_bar)" as TimerBar
participant "Рабочий стол\n(desktop.gd)" as Desktop
participant "Кризис-диалог\n(crisis_dialog.gd)" as CrisisDialog
participant "Карта\n(map_preview.gd)" as MapApp
participant "Терминал\n(terminal.gd)" as Terminal
participant "Экран концовки\n(ending_screen.gd)" as EndingScreen

== Старт финального таймера (60 сек) ==
GameState -> TimerBar : emit_signal("timer_started", 60.0)
loop 60 секунд
    GameState -> TimerBar : timer_updated(time_remaining)
end

== 30-я секунда: Взятка Саймона ==
GameState -> Desktop : emit_signal("bribe_triggered")
Desktop -> CrisisDialog : show_bribe()
CrisisDialog --> Player : Предложение $100,000 (Красная кнопка "Отмена")
Player -> CrisisDialog : Нажатие красной кнопки "Отмена"
CrisisDialog -> Desktop : bribe_cancelled
Desktop -> GameState : cancel_bribe()

== 5 секунд спустя: Тёмный паттерн UX (Фишинг) ==
GameState -> Desktop : emit_signal("phishing_triggered")
Desktop -> CrisisDialog : show_phishing()
CrisisDialog --> Player : Запрос геометки (Красная кнопка "Продолжить"!)

alt Исход A: Клик по красной кнопке (Ловушка)
    Player -> CrisisDialog : Нажатие "Продолжить"
    CrisisDialog -> GameState : trigger_ending(Ending.HORROR)
    GameState -> EndingScreen : show_ending(HORROR)
    EndingScreen --> Player : Концовка 4 «Незваный гость»

else Исход B: Истинная точка на Карте ("Склад № 3")
    Player -> MapApp : Выбор "Склад № 3"
    MapApp -> GameState : trigger_ending(Ending.SALVATION)
    GameState -> EndingScreen : show_ending(SALVATION)
    EndingScreen --> Player : Концовка 1 «Идеальное спасение»

else Исход C: Ложная точка на Карте ("Бокс № 6752")
    Player -> MapApp : Выбор "Бокс № 6752"
    MapApp -> GameState : trigger_ending(Ending.FALSE_TRAIL)
    GameState -> EndingScreen : show_ending(FALSE_TRAIL)
    EndingScreen --> Player : Концовка 2 «Ложный след»

else Исход D: Истечение таймера (00:00)
    GameState -> GameState : trigger_ending(Ending.TIMEOUT)
    GameState -> EndingScreen : show_ending(TIMEOUT)
    EndingScreen --> Player : Концовка 3 «Время вышло»

else Исход E: Ввод "wipe --force"
    Player -> Terminal : "wipe --force"
    Terminal -> GameState : trigger_ending(Ending.CORRUPTION)
    GameState -> EndingScreen : show_ending(CORRUPTION)
    EndingScreen --> Player : Концовка 5 «Сделка с дьяволом»
end
@enduml
```

---

## 5. Сводная таблица программных сигналов и методов подсистем

| Подсистема / Класс | Тип события | Сигнал / Метод | Принимающая сторона | Назначение в сценарии |
| :--- | :--- | :--- | :--- | :--- |
| `explorer.gd` | Метод | `_show_audio_player()` | `AudioOverlay` | Открытие модального окна проигрывателя `record.wav` |
| `explorer.gd` | Метод | `_on_audio_finished()` | `GameState.gd` | Фиксация завершения аудио и триггер `mark_audio_listened()` |
| `GameState.gd` | Сигнал | `timer_started(duration)` | `final_timer_bar.gd` | Инициализация и показ прогресс-бара 60 секунд |
| `GameState.gd` | Сигнал | `bribe_triggered()` | `desktop.gd` | Отображение окна взятки Саймона на 30-й секунде |
| `GameState.gd` | Сигнал | `phishing_triggered()` | `desktop.gd` | Отображение фишинг-ловушки с подменой красной кнопки |
| `GameState.gd` | Сигнал | `story_time_jump_requested(h, m, anim)` | `desktop.gd` | Синхронный перевод часов на 03:40 с ЭЛТ-помехами |
| `GameState.gd` | Сигнал | `game_ended(ending_id, details)` | `ending_screen.gd` | Отображение титров и газетных вырезок одной из 5 концовок |
| `terminal.gd` | Метод | `_cmd_decrypt(args)` | `VFS.gd` | Парсинг ключа дешифрования и запуск крипто-процесса |
| `VFS.gd` | Метод | `decrypt_file(path, key)` | `GameState.gd` | Валидация ключа `LENINA54` и распаковка аудиофайла |
| `crisis_dialog.gd` | Сигнал | `phishing_accepted` | `desktop.gd` | Фиксация срабатывания тёмного паттерна (Концовка 4) |
| `crisis_dialog.gd` | Сигнал | `bribe_cancelled` | `GameState.gd` | Запуск 5-секундного таймера до показа фишинг-диалога |
