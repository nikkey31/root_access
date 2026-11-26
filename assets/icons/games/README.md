# Ретро-иконки и спрайты мини-игр (подготовлено для Сёмы)

Все изображения выполнены в стилистике **Win98 / XP** в разрешении **64×64 PNG** (пиксель-арт `32×32`, масштабированный `2x` Nearest-Neighbor без размытия, с прозрачным фоном `RGBA`).

## 1. Иконки папки и ярлыков (`assets/icons/`)
- `res://assets/icons/games_folder.png` — папка **«Игры»** (жёлтая папка Win98 с ретро-геймпадом).
- `res://assets/icons/fishing.png` — ярлык **`fishing.exe`** (озеро, поплавок, крючок, рыба).
- `res://assets/icons/chess.png` — ярлык **`chess.exe`** (шахматная доска с белым конём).
- `res://assets/icons/shadow_fight_1.png` — ярлык **`shadow_fight_1.exe`** (силуэт бойца с красной повязкой на фоне огненного додзё).

## 2. Спрайты мини-игр (`assets/icons/games/`)

### Шахматы (`assets/icons/games/chess/`)
Белые (`white_*.png`) и чёрные (`black_*.png`) фигуры в единой сетке 64×64:
- `white_king.png`, `white_queen.png`, `white_rook.png`, `white_bishop.png`, `white_knight.png`, `white_pawn.png`
- `black_king.png`, `black_queen.png`, `black_rook.png`, `black_bishop.png`, `black_knight.png`, `black_pawn.png`

### Рыбалка (`assets/icons/games/fishing/`)
- Рыбы / улов: `fish_crucian.png` (карась), `fish_perch.png` (окунь), `fish_pike.png` (щука), `fish_rare.png` (редкий трофей), `boot.png` (старый сапог)
- Снасти: `bobber.png` (поплавок), `hook.png` (крючок)

### Shadow Fight 1 (`assets/icons/games/shadow_fight/`)
- `fighter_idle.png`, `fighter_punch.png`, `fighter_kick.png`, `fighter_block.png`

Для перегенерации или доработки ассетов используйте детерминированный генератор:
`python3 tools/generate_game_icons.py`
