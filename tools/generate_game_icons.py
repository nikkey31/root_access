#!/usr/bin/env python3
"""Deterministic Win98/XP 32x32 -> 64x64 pixel-art icon and sprite generator.

Generates retro desktop/Explorer icons for the Games folder and executables
(fishing.exe, chess.exe, shadow_fight_1.exe) as well as pixel-art sprites
for chess pieces, fishing catches/tackle, and shadow fighters.

Uses only the Python standard library (+ ImageMagick `magick` optionally to
overlay onto the existing `assets/icons/folder.png` base).

Run from the repository root:
    python3 tools/generate_game_icons.py
"""

from __future__ import annotations

import struct
import subprocess
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ICONS_DIR = ROOT / "assets" / "icons"
GAMES_DIR = ICONS_DIR / "games"


def hex_rgba(h: str) -> tuple[int, int, int, int]:
    h = h.lstrip("#")
    if len(h) == 6:
        return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)
    if len(h) == 8:
        return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), int(h[6:8], 16))
    raise ValueError(f"Invalid hex color: {h}")


def encode_png(pixels_rgba: list[list[tuple[int, int, int, int]]]) -> bytes:
    """Encode a 2D array [y][x] of (R, G, B, A) tuples into a valid RGBA PNG."""
    height = len(pixels_rgba)
    width = len(pixels_rgba[0]) if height > 0 else 0
    raw = bytearray()
    for row in pixels_rgba:
        raw.append(0)  # Filter type 0 (None)
        for r, g, b, a in row:
            raw.extend((r, g, b, a))

    def chunk(tag: bytes, data: bytes) -> bytes:
        crc = zlib.crc32(tag + data) & 0xFFFFFFFF
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", crc)

    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    idat = zlib.compress(bytes(raw), level=9)
    return (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", ihdr)
        + chunk(b"IDAT", idat)
        + chunk(b"IEND", b"")
    )


def upscale_2x(grid: list[list[tuple[int, int, int, int]]]) -> list[list[tuple[int, int, int, int]]]:
    out: list[list[tuple[int, int, int, int]]] = []
    for row in grid:
        doubled = []
        for px in row:
            doubled.append(px)
            doubled.append(px)
        out.append(doubled)
        out.append(list(doubled))
    return out


def render_grid(
    rows: list[str],
    palette: dict[str, tuple[int, int, int, int]],
    scale: int = 2,
) -> list[list[tuple[int, int, int, int]]]:
    assert len(rows) == 32, f"Expected 32 rows, got {len(rows)}"
    grid: list[list[tuple[int, int, int, int]]] = []
    for idx, row in enumerate(rows):
        assert len(row) == 32, f"Row {idx} length {len(row)} != 32: {row!r}"
        grid.append([palette[ch] for ch in row])
    if scale == 2:
        return upscale_2x(grid)
    return grid


def save_icon(
    path: Path,
    rows: list[str],
    palette: dict[str, tuple[int, int, int, int]],
) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    pixels = render_grid(rows, palette, scale=2)
    path.write_bytes(encode_png(pixels))
    print(f"  {path.relative_to(ROOT)}  64x64")


# Shared Win98 / retro outline palette
T = (0, 0, 0, 0)
K = hex_rgba("#181425")  # dark pixel outline
B = hex_rgba("#000000")  # pure black


def make_games_folder_icon() -> None:
    """Use existing Win98 folder.png base and overlay a crisp pixel gamepad badge."""
    base_path = ICONS_DIR / "folder.png"
    out_path = ICONS_DIR / "games_folder.png"

    # Extract 64x64 raw RGBA from folder.png via magick
    raw = subprocess.check_output(["magick", str(base_path), "-depth", "8", "rgba:-"])
    if len(raw) != 64 * 64 * 4:
        raise RuntimeError(f"Unexpected folder.png byte length: {len(raw)}")

    # Convert to 32x32 by sampling top-left of each 2x2 cell
    base_32: list[list[tuple[int, int, int, int]]] = []
    for y in range(32):
        row_px = []
        for x in range(32):
            off = ((y * 2) * 64 + (x * 2)) * 4
            row_px.append((raw[off], raw[off + 1], raw[off + 2], raw[off + 3]))
        base_32.append(row_px)

    # Gamepad badge (placed at bottom-right/center: rows 14..28, cols 9..30)
    badge = [
        "....KKKKKKKKKKKKKKK.............",  # 14 (only cols 9..28 used cleanly)
    ]
    # Better: define 32x32 transparent overlay with crisp retro SNES-style pad
    pad_rows = [
        "................................",  # 0
        "................................",  # 1
        "................................",  # 2
        "................................",  # 3
        "................................",  # 4
        "................................",  # 5
        "................................",  # 6
        "................................",  # 7
        "................................",  # 8
        "................................",  # 9
        "................................",  # 10
        "................................",  # 11
        ".................KK.............",  # 12 cord
        "................K..K............",  # 13
        "............KKKKKKKKKKKK........",  # 14 top of pad
        "..........KKLLLLLLLLLLLLKK......",  # 15
        ".........KLGGGGGGGGGGGGGGGK.....",  # 16
        "........KLGGKKGGGGGGGGGBBGGK....",  # 17 dpad + B
        "........KLGKKKKGGKKGGGBBRRBGK...",  # 18 dpad cross + start/sel + R
        "........KLGGKKGGGGGGGGBRRBBGK...",  # 19
        "........KLGGGGGGGGGGGGYBBYGGK...",  # 20 yellow/blue buttons
        "........KDDGGGGGGGGGGGGGGGGDK...",  # 21
        "........KDDDGGKKKKKKKKKKGGDDK...",  # 22 grip indent
        ".........KDDKK..........KKDDK...",  # 23
        "..........KK..............KK....",  # 24
        "................................",  # 25
        "................................",  # 26
        "................................",  # 27
        "................................",  # 28
        "................................",  # 29
        "................................",  # 30
        "................................",  # 31
    ]
    pad_pal = {
        ".": None,
        "K": K,
        "L": hex_rgba("#E4E8EE"),
        "G": hex_rgba("#A8B0BC"),
        "D": hex_rgba("#5E6673"),
        "R": hex_rgba("#E03030"),
        "B": hex_rgba("#3868D8"),
        "Y": hex_rgba("#F4C820"),
    }
    for y in range(32):
        for x in range(32):
            c = pad_pal[pad_rows[y][x]]
            if c is not None:
                base_32[y][x] = c

    out_path.write_bytes(encode_png(upscale_2x(base_32)))
    print(f"  {out_path.relative_to(ROOT)}  64x64")


def make_fishing_icon() -> None:
    """fishing.exe retro icon: Win98 framed lake, bobber, and jumping golden fish."""
    pal = {
        ".": T,
        "K": K,
        "L": hex_rgba("#FFFFFF"),
        "F": hex_rgba("#C0C0C0"),
        "S": hex_rgba("#808080"),
        "N": hex_rgba("#000080"),  # Win98 title navy
        "C": hex_rgba("#3888E8"),  # bright sky
        "A": hex_rgba("#7CC4FF"),  # upper sky
        "W": hex_rgba("#185098"),  # deep water
        "U": hex_rgba("#40A8F0"),  # wave highlight
        "R": hex_rgba("#E82828"),  # red bobber top
        "O": hex_rgba("#FF9020"),  # fish orange
        "Y": hex_rgba("#FFD850"),  # fish gold highlight
        "D": hex_rgba("#B85010"),  # fish dark orange
        "H": hex_rgba("#D8E0E8"),  # hook silver
    }
    rows = [
        "................................",  # 0
        "..KKKKKKKKKKKKKKKKKKKKKKKKKKKK..",  # 1
        ".KLLLLLLLLLLLLLLLLLLLLLLLLLLLK..",  # 2
        ".KLNNNNNNNNNNNNNNNNNNNNNNNNSK...",  # 3 Win98 title bar!
        ".KLNAAAAAAAAAAAAAAAAAAAAAANSK...",  # 4
        ".KLAAAAAAAAAAAAAAAAAAAAAAANSK...",  # 5 wait - keep 32 chars exact!
    ]
    rows = [
        "................................",  # 0
        ".KKKKKKKKKKKKKKKKKKKKKKKKKKKKKK.",  # 1
        ".KLLLLLLLLLLLLLLLLLLLLLLLLLLLLK.",  # 2
        ".KLNNNNNNNNNNNNNNNNNNNNNNNNLLSK.",  # 3 titlebar
        ".KLNNNNNNNNNNNNNNNNNNNNNNNLLLLK.",  # 4
        ".KLKKKKKKKKKKKKKKKKKKKKKKKKKLSK.",  # 5 divider
        ".KLAAAAAAAAAAAAAAAAAAAAAAAAAFSK.",  # 6
        ".KLAAAAAAAAAAAAAAAAAAKKAAAAAFSK.",  # 7 fishing line
        ".KLAAAAAAAKKAAAAAAAAKAAKAAAAFSK.",  # 8
        ".KLAAAAAAKYYKAAAAAAAKRRKAAAAFSK.",  # 9 bobber top
        ".KLCCCCCKOYYOKAAAAAAKRRKCCCCFSK.",  # 10 fish head + bobber
        ".KLCCCCKOYYYYOKKAAAAKLLKCCCCFSK.",  # 11
        ".KLCCCKOOYYYYYOKOKAAKKKKCCCCFSK.",  # 12 fish body + tail
        ".KLCCCKOOYYKYYOKOKCCCCHCCCCCFSk."[0:32],  # 13 fixed below
    ]
    rows = [
        "................................",  # 0
        ".KKKKKKKKKKKKKKKKKKKKKKKKKKKKKK.",  # 1
        ".KLLLLLLLLLLLLLLLLLLLLLLLLLLLLK.",  # 2
        ".KLNNNNNNNNNNNNNNNNNNNNNNNNNNSK.",  # 3 Win98 blue bar
        ".KLKKKKKKKKKKKKKKKKKKKKKKKKKKSK.",  # 4
        ".KLAAAAAAAAAAAAAAAAAAAHAAAAAASK.",  # 5 sky + fishing line
        ".KLAAAAAAAAAAAAAAAAAAAHAAAAAASK.",  # 6
        ".KLAAAAAAAAAAAAAAAAAAKHKAAAAASK.",  # 7
        ".KLAAAAAAKKKAAAAAAAAKRRRKAAAASK.",  # 8 jumping fish + red bobber
        ".KLAAAAAKYYYKAAAAAAAKRRRKAAAASK.",  # 9
        ".KLCCCCKOOYYOKKKAAKAKLLLKCCCCSK.",  # 10
        ".KLCCCKOOOYYOKOKAAKAKLLLKCCCCSK.",  # 11
        ".KLCCCKOKOKYOKKAAKAAKKKKUCCCCSK.",  # 12
        ".KLCCCCKDDDDKAAAAAAUUCUUUCCCCSK.",  # 13
        ".KLUUUUUUUUUUUUUUUUWWUUUWWUUUSK.",  # 14 water surface ripples
        ".KLWWWWWWWWWWUUUWWWWWWWWWWUUWSK.",  # 15
        ".KLWWUUUWWWWWWWWWWWWWUUUWWWWWSK.",  # 16
        ".KLWWWWWWWWUUUWWWWWWWWWWWWWWWSK.",  # 17
        ".KLWWWWWWWWWWWWWWWWUUUWWWWWWWSK.",  # 18
        ".KLWWWWWUUWWWWWWWWWWWWWWWWWWWSK.",  # 19
        ".KLWWWWWWWWWWWWWWWHWWWWWWWWWWSK.",  # 20 underwater hook
        ".KLWWWWWWWWWWWWWWWHWWWWWWWWWWSK.",  # 21
        ".KLWWWWWWWWWWWWWWHHWWWWWWWWWWSK.",  # 22
        ".KLWWWWWWWWWWWWWWHWHWWWWWWWWWSK.",  # 23
        ".KLWWWWWWWWWWWWWWWHWWWWWWWWWWSK.",  # 24
        ".KLSSSSSSSSSSSSSSSSSSSSSSSSSSSK.",  # 25
        ".KFFFFFFFFFFFFFFFFFFFFFFFFFFFFK.",  # 26
        ".KKKKKKKKKKKKKKKKKKKKKKKKKKKKKK.",  # 27
        "................................",  # 28
        "................................",  # 29
        "................................",  # 30
        "................................",  # 31
    ]
    save_icon(ICONS_DIR / "fishing.png", rows, pal)


def make_chess_icon() -> None:
    """chess.exe retro icon: Win98 4x4 checkerboard + crisp white knight silhouette."""
    pal = {
        ".": T,
        "K": K,
        "W": hex_rgba("#F4EFE6"),  # light board tile
        "B": hex_rgba("#3B4856"),  # dark slate board tile
        "F": hex_rgba("#D4C4A8"),  # wood bezel light
        "D": hex_rgba("#785838"),  # wood bezel dark
        "H": hex_rgba("#FFFFFF"),  # knight piece pure white
        "G": hex_rgba("#C8D0DC"),  # knight piece shading
        "E": hex_rgba("#181425"),  # knight outline/eye
    }
    rows = [
        "................................",  # 0
        ".KKKKKKKKKKKKKKKKKKKKKKKKKKKKKK.",  # 1
        ".KFFFFFFFFFFFFFFFFFFFFFFFFFFFFK.",  # 2
        ".KFKKKKKKKKKKKKKKKKKKKKKKKKKKDK.",  # 3
        ".KFKWWWWWWBBBBBBWWWWWWBBBBBBKDK.",  # 4
        ".KFKWWWWWWBBBBBBWWWWWWBBBBBBKDK.",  # 5
        ".KFKWWWWWWBBBBBBWWWWWWBBBBBBKDK.",  # 6
        ".KFKWWWWWWBBBBBBWWWWWWBBBBBBKDK.",  # 7
        ".KFKWWWWWWBBKKWWBBBBWWBBBBBBKDK.",  # 8
        ".KFKBBBBBKHHHHHKBBBBBBWWWWWWKDK.",  # 9 knight head
        ".KFKBBBBKHHHHHHHKBBBBBWWWWWWKDK.",  # 10
        ".KFKBBBBKHHKEHHHKBBBBBWWWWWWKDK.",  # 11 eye
        ".KFKBBBKHHHHHHGGGKBBBBWWWWWWKDK.",  # 12 muzzle
        ".KFKBBBKHHKKHHGGGKBBBBWWWWWWKDK.",  # 13
        ".KFKWWWWWWKKHHGGGKWWWWBBBBBBKDK.",  # 14 neck
        ".KFKWWWWWWKHHHGGGKWWWWBBBBBBKDK.",  # 15
        ".KFKWWWWWKHHHHGGGKWWWWBBBBBBKDK.",  # 16
        ".KFKBBBBKHHHHGGGGKBBBBWWWWWWKDK.",  # 17
        ".KFKBBBBKHHHHHHHHKBBBBWWWWWWKDK.",  # 18
        ".KFKBBBKHHHHHHHHGGKBBBWWWWWWKDK.",  # 19 base
        ".KFKBBBKGGGGGGGGGGKBBBWWWWWWKDK.",  # 20
        ".KFKBBBBKKKKKKKKKKBBBBWWWWWWKDK.",  # 21
        ".KFKWWWWWWBBBBBBWWWWWWBBBBBBKDK.",  # 22
        ".KFKWWWWWWBBBBBBWWWWWWBBBBBBKDK.",  # 23
        ".KFKWWWWWWBBBBBBWWWWWWBBBBBBKDK.",  # 24
        ".KFKKKKKKKKKKKKKKKKKKKKKKKKKKDK.",  # 25
        ".KDDDDDDDDDDDDDDDDDDDDDDDDDDDDK.",  # 26
        ".KKKKKKKKKKKKKKKKKKKKKKKKKKKKKK.",  # 27
        "................................",  # 28
        "................................",  # 29
        "................................",  # 30
        "................................",  # 31
    ]
    save_icon(ICONS_DIR / "chess.png", rows, pal)


def make_shadow_fight_icon() -> None:
    """shadow_fight_1.exe retro icon: fiery orange dojo frame + silhouette martial artist."""
    pal = {
        ".": T,
        "K": K,
        "B": hex_rgba("#0A0810"),  # pure shadow silhouette
        "R": hex_rgba("#E02020"),  # crimson headband
        "O": hex_rgba("#FF6810"),  # fiery orange sky
        "Y": hex_rgba("#FFC428"),  # bright sun core
        "D": hex_rgba("#701010"),  # dark crimson dojo
        "M": hex_rgba("#C0C0C0"),  # silver retro border
        "S": hex_rgba("#606060"),  # frame shadow
        "W": hex_rgba("#E8EEF8"),  # katana glint
    }
    rows = [
        "................................",  # 0
        ".KKKKKKKKKKKKKKKKKKKKKKKKKKKKKK.",  # 1
        ".KMMMMMMMMMMMMMMMMMMMMMMMMMMMMS.",  # 2
        ".KMKKKKKKKKKKKKKKKKKKKKKKKKKKMK.",  # 3
        ".KMKDDDDDDDDDDDDDDDDDDDDDDDDKMK.",  # 4
        ".KMKDDDDOOOOOOOOOOOOOOOODDDDKMK.",  # 5
        ".KMKDDOOOOOYYYYYYYYYYOOOOODDKMK.",  # 6
        ".KMKDOOOOYYYYYYYYYYYYYYOOOODKMK.",  # 7
        ".KMKDOOOYYYYYBBBBBBYYYYYOOODKMK.",  # 8 head
        ".KMKDOOOYYYYRRRRRRRRRYYYOOODKMK.",  # 9 red headband
        ".KMKDOOOYYYYBBBBBBYYRRYRYOODKMK.",  # 10 streaming tails
        ".KMKDOOOOYYYYBBBBYYYYYRYROODKMK.",  # 11 neck
        ".KMKDOOOOOYYBBBBBBYYYYWOOOODKMK.",  # 12 shoulders + katana tip
        ".KMKDOOOBBBBBBBBBBBWWOOOOOODKMK.",  # 13 sword arm + blade
        ".KMKDOOBBYYBBBBBBWWYYYYOOOODKMK.",  # 14 guard hand
        ".KMKDOOOOYYBBBBBBYYYYYYOOOODKMK.",  # 15 waist
        ".KMKDOOOOOBBBBBBBBYYYYOOOOODKMK.",  # 16 legs
        ".KMKDOOOOBBBBYYBBBBBOOOOOOODKMK.",  # 17
        ".KMKDOOOBBBBYYYYBBBBBOOOOOODKMK.",  # 18
        ".KMKDOOBBBBYYYYYYBBBBBOOOOODKMK.",  # 19
        ".KMKDOOBBBYYYYYYYYBBBBBOOOODKMK.",  # 20 wide stance
        ".KMKDDDDDDDDDDDDDDDDDDDDDDDDKMK.",  # 21 dojo floor
        ".KMKBBBBBBBBBBBBBBBBBBBBBBBBKMK.",  # 22
        ".KMKBBBBBBBBBBBBBBBBBBBBBBBBKMK.",  # 23
        ".KMKKKKKKKKKKKKKKKKKKKKKKKKKKMK.",  # 24
        ".KSSSSSSSSSSSSSSSSSSSSSSSSSSSSK.",  # 25
        ".KKKKKKKKKKKKKKKKKKKKKKKKKKKKKK.",  # 26
        "................................",  # 27
        "................................",  # 28
        "................................",  # 29
        "................................",  # 30
        "................................",  # 31
    ]
    save_icon(ICONS_DIR / "shadow_fight_1.png", rows, pal)


# ---------------------------------------------------------------------------
# Chess piece sprites (64x64 transparent pixel-art)
# ---------------------------------------------------------------------------

def _chess_pal(is_white: bool) -> dict[str, tuple[int, int, int, int]]:
    if is_white:
        return {
            ".": T,
            "K": K,
            "M": hex_rgba("#F4EFE6"),  # ivory main
            "H": hex_rgba("#FFFFFF"),  # highlight
            "S": hex_rgba("#B8B4AC"),  # shadow
            "A": hex_rgba("#D8A828"),  # gold trim accent
        }
    return {
        ".": T,
        "K": hex_rgba("#0D0C14"),  # dark outline
        "M": hex_rgba("#2F333E"),  # obsidian charcoal
        "H": hex_rgba("#646D80"),  # slate highlight
        "S": hex_rgba("#1A1C24"),  # deep shadow
        "A": hex_rgba("#D04040"),  # crimson/dark-gold accent
    }


CHESS_SHAPES: dict[str, list[str]] = {
    "pawn": [
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        ".............KKKKKK.............",
        "............KHHMMMKK............",
        "...........KHHMMMMSSK...........",
        "...........KHMMMMMSSK...........",
        "...........KMMMMMMSSK...........",
        "............KMMMMSSK............",
        ".............KKKKKK.............",
        "............KHHHHSSK............",
        ".............KMMSSK.............",
        ".............KMMSSK.............",
        "............KHMMMSSK............",
        "............KHMMMSSK............",
        "...........KHHMMMMSSK...........",
        "...........KHHMMMMSSK...........",
        "..........KHHHMMMMMSSK..........",
        ".........KHHHHMMMMMMSSK.........",
        ".........KSSSSSSSSSSSSK.........",
        ".........KKKKKKKKKKKKKK.........",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
    ],
    "rook": [
        "................................",
        "................................",
        "................................",
        "........KKKK..KKKK..KKKK........",
        "........KHHK..KMMK..KSSK........",
        "........KHHKKKKMMKKKKSSK........",
        "........KHHHMMMMMMMMMSSK........",
        "........KHHHMMMMMMMMMSSK........",
        ".........KSSSSSSSSSSSSK.........",
        "..........KHHMMMMMMSSK..........",
        "..........KHHMMMMMMSSK..........",
        "..........KHHMMMMMMSSK..........",
        "..........KHHMMMMMMSSK..........",
        "..........KHHMMMMMMSSK..........",
        "..........KHHMMMMMMSSK..........",
        "..........KHHMMMMMMSSK..........",
        "..........KHHMMMMMMSSK..........",
        ".........KHHHMMMMMMMSSK.........",
        ".........KHHHMMMMMMMSSK.........",
        "........KHHHHMMMMMMMMSSK........",
        "........KHHHHMMMMMMMMSSK........",
        ".......KHHHHHMMMMMMMMMSSK.......",
        ".......KSSSSSSSSSSSSSSSSK.......",
        ".......KKKKKKKKKKKKKKKKKK.......",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
    ],
    "knight": [
        "................................",
        "................................",
        ".............KKKKKK.............",
        "...........KKHHMMMKK............",
        "..........KHHHMMMMSSK...........",
        ".........KHHHMMKMMMSSK..........",
        "........KHHHMMMKMMMSSK..........",
        ".......KHHHHMMMMMMMSSK..........",
        ".......KHHHHMMMMMMMMSSK.........",
        ".......KSSKKHHMMMMMMSSK.........",
        "........KK.KHHMMMMMMSSK.........",
        "...........KHHHMMMMMSSK.........",
        "..........KHHHHMMMMMSSK.........",
        ".........KHHHHHMMMMMSSK.........",
        ".........KHHHHMMMMMMSSK.........",
        "........KHHHHHMMMMMMSSK.........",
        "........KHHHHMMMMMMMSSK.........",
        "........KHHHMMMMMMMMSSK.........",
        "........KHHHMMMMMMMMSSK.........",
        ".......KHHHHMMMMMMMMMSSK........",
        ".......KHHHHMMMMMMMMMSSK........",
        ".......KSSSSSSSSSSSSSSSK........",
        ".......KKKKKKKKKKKKKKKKK........",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
    ],
    "bishop": [
        "................................",
        "................................",
        "...............KK...............",
        "..............KAAK..............",
        "...............KK...............",
        ".............KKKKKK.............",
        "............KHHMMMKK............",
        "...........KHHMMKMMSSK..........",
        "..........KHHMMKMMMMSSK.........",
        "..........KHMMKMMMMMSSK.........",
        "..........KHHMMMMMMMSSK.........",
        "...........KHHMMMMMSSK..........",
        "............KHHHHSSSK...........",
        "............KHHMMMSSK...........",
        "............KHHMMMSSK...........",
        "...........KHHHMMMSSSK..........",
        "...........KHHHMMMSSSK..........",
        "..........KHHHHMMMMSSSK.........",
        "..........KHHHHMMMMSSSK.........",
        ".........KHHHHHMMMMMSSSK........",
        "........KHHHHHHMMMMMMSSSK.......",
        "........KSSSSSSSSSSSSSSSK.......",
        "........KKKKKKKKKKKKKKKKK.......",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
    ],
    "queen": [
        "................................",
        "................................",
        "......KK......KKKK......KK......",
        "......KAK.....KAAK.....KAK......",
        ".......KK..KK..KK..KK..KK.......",
        ".......KHK.KK.KHHK.KK.KHK.......",
        "........KHKHK.KMMK.KHKHK........",
        "........KHHMKKHMMKKMSSKK........",
        ".........KHHMMMMMMMMSSK.........",
        ".........KHHHMMMMMMMSSK.........",
        "..........KHHAAAAAAASK..........",
        "..........KHHMMMMMMSSK..........",
        "...........KHHMMMMSSK...........",
        "...........KHHMMMMSSK...........",
        "...........KHHMMMMSSK...........",
        "..........KHHHMMMMMSSK..........",
        "..........KHHHMMMMMSSK..........",
        ".........KHHHHMMMMMMSSK.........",
        ".........KHHHHMMMMMMSSK.........",
        "........KHHHHHMMMMMMMSSK........",
        "........KHHHHHMMMMMMMSSK........",
        ".......KSSSSSSSSSSSSSSSSK.......",
        ".......KKKKKKKKKKKKKKKKKK.......",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
    ],
    "king": [
        "................................",
        "...............KK...............",
        "..............KAAK..............",
        "............KKKAAKKK............",
        "............KAAAAAAK............",
        "............KKKAAKKK............",
        "..............KAAK..............",
        ".........KKKKKKAAKKKKKK.........",
        "........KHHMMKKAAKKMSSSK........",
        ".......KHHHMMMMMMMMMMSSSK.......",
        ".......KHHHMMMMMMMMMMSSSK.......",
        "........KHHMMMMMMMMMMSSK........",
        ".........KHHAAAAAAAAASK.........",
        "..........KHHMMMMMMSSK..........",
        "..........KHHMMMMMMSSK..........",
        "..........KHHMMMMMMSSK..........",
        ".........KHHHMMMMMMMSSK.........",
        ".........KHHHMMMMMMMSSK.........",
        "........KHHHHMMMMMMMMSSK........",
        "........KHHHHMMMMMMMMSSK........",
        ".......KHHHHHMMMMMMMMMSSK.......",
        ".......KSSSSSSSSSSSSSSSSK.......",
        ".......KKKKKKKKKKKKKKKKKK.......",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
    ],
}


def make_chess_sprites() -> None:
    out_dir = GAMES_DIR / "chess"
    for color_name, is_white in [("white", True), ("black", False)]:
        pal = _chess_pal(is_white)
        for piece_name, rows in CHESS_SHAPES.items():
            save_icon(out_dir / f"{color_name}_{piece_name}.png", rows, pal)


# ---------------------------------------------------------------------------
# Fishing sprites (64x64 transparent pixel-art)
# ---------------------------------------------------------------------------

def make_fishing_sprites() -> None:
    out_dir = GAMES_DIR / "fishing"

    # 1. Golden Crucian (Карась)
    crucian_pal = {
        ".": T,
        "K": K,
        "O": hex_rgba("#D88820"),
        "Y": hex_rgba("#F8C840"),
        "L": hex_rgba("#FFF2A0"),
        "D": hex_rgba("#8C5010"),
        "F": hex_rgba("#E04828"),
        "W": hex_rgba("#FFFFFF"),
    }
    crucian_rows = [
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "..............KKKKK.............",
        ".............KFFFFK.............",
        "..........KKKKKKKKKKKK..........",
        "........KKDDDDDDDDDDDDKK........",
        "...KK..KOOYYYYYYYYYYYYOOK.......",
        "..KFFKKOOYYYYLLLLLLYYYYWWK......",
        "..KFFKOOYYYLLLLLLLLLLYYWKK......",
        "..KFFKOOYYYYLLLLLLYYYYYOK.......",
        "...KKKOOYYYYYYYYYYYYYYOOK.......",
        "..KFFKOOYYYYYYYYYYYYYYOOK.......",
        "..KFFKOOYYYYYYYYYYYYOOK.........",
        "...KK..KDDDDFFFFDDDDKK..........",
        "........KKKKKKKKKKKK............",
        ".............KFFK...............",
        "..............KK................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
    ]
    save_icon(out_dir / "fish_crucian.png", crucian_rows, crucian_pal)

    # 2. Striped Perch (Окунь)
    perch_pal = {
        ".": T,
        "K": K,
        "G": hex_rgba("#588C38"),
        "L": hex_rgba("#9CD058"),
        "S": hex_rgba("#2B4820"),
        "R": hex_rgba("#E03028"),
        "W": hex_rgba("#FFFFFF"),
        "Y": hex_rgba("#E8D890"),
    }
    perch_rows = [
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "............KKKKKKKK............",
        "...........KRRRRRRRRK...........",
        ".........KKKKKKKKKKKKKK.........",
        ".......KKGGGGGGGGGGGGGGKK.......",
        "..KK..KGGSSGGSSGGSSGGGGGGK......",
        ".KRRKKGGGSSGGSSGGSSGGGGWWGK.....",
        ".KRRKLLLLSSLLSSLLSSLLLLWKKK.....",
        ".KRRKLLLLSSLLSSLLSSLLLLLLGK.....",
        "..KKKGGGGSSGGSSGGSSGGGGGGK......",
        ".KRRKYYYYYYYYYYYYYYYYYYKK.......",
        "..KKKYYYYYYYYYYYYYYYYKK.........",
        ".....KKKKKKKRRRKKKKKK...........",
        "...........KRRK.................",
        "............KK..................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
    ]
    save_icon(out_dir / "fish_perch.png", perch_rows, perch_pal)

    # 3. Pike (Щука — длинная зелёная)
    pike_pal = {
        ".": T,
        "K": K,
        "G": hex_rgba("#38783C"),
        "L": hex_rgba("#6EB85C"),
        "S": hex_rgba("#1E4622"),
        "Y": hex_rgba("#D8E078"),
        "W": hex_rgba("#FFFFFF"),
    }
    pike_rows = [
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "..KK.....KKKKKKKKKKKKKK.........",
        ".KSSK...KSSSSSSSSSSSSSSKK.......",
        ".KGGKK..KGGGGGGGGGGGGGGGGKK.....",
        ".KGGLLKKGGGGYYYYGGGGYYYYWGGK....",
        "..KKGGGGGLLYYYYLLYYYYLLWWKGGKK..",
        "...KKGGGGGGGGGGGGGGGGGGWWKKKKK..",
        "..KKGGLLLLLLLLLLLLLLLLGGGGKK....",
        ".KGGKKGGSSGGGGGGSSGGKKKKKK......",
        ".KSSK...KKKKKKKKKKKK............",
        "..KK............................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
    ]
    save_icon(out_dir / "fish_pike.png", pike_rows, pike_pal)

    # 4. Rare / Glitchy Trophy Fish (Редкий трофей / секретный улов)
    rare_pal = {
        ".": T,
        "K": K,
        "C": hex_rgba("#20D8C8"),
        "B": hex_rgba("#1878A0"),
        "H": hex_rgba("#A8FFF8"),
        "A": hex_rgba("#FFD030"),
        "W": hex_rgba("#FFFFFF"),
    }
    rare_rows = [
        "................................",
        "................................",
        "................................",
        "..............KK................",
        ".............KAAK...............",
        "............KAAAAK..............",
        ".............KKKK...............",
        "...........KKKKKKKKKK...........",
        ".........KKBBBBBBBBBBKK.........",
        ".......KKCCCCCCCCCCCCCCKK.......",
        "...KK.KCCCHHHHHHHHHHCCCCCK......",
        "..KAAKKCCHHHHHHHHHHHHHCCWWK.....",
        "..KAAKCCHHHHAAAAAAHHHHCCWKK.....",
        "..KAAKCCHHHHHHHHHHHHHHCCCCK.....",
        "...KKKCCCCBBBBBBBBBBCCCCCCK.....",
        "..KAAKCCCCCCCCCCCCCCCCCCKK......",
        "...KK.KKBBBBBBBBBBBBBBKK........",
        "........KKKKKKKKKKKKKK..........",
        ".............KAAK...............",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
    ]
    save_icon(out_dir / "fish_rare.png", rare_rows, rare_pal)

    # 5. Old Boot (Старый сапог)
    boot_pal = {
        ".": T,
        "K": K,
        "B": hex_rgba("#6A482A"),
        "L": hex_rgba("#8C623E"),
        "D": hex_rgba("#442C18"),
        "S": hex_rgba("#282828"),
    }
    boot_rows = [
        "................................",
        "................................",
        "................................",
        "................................",
        ".........KKKKKKKKKKK............",
        "........KLLLLLLLLLLLK...........",
        "........KLBBBBBBBBBDK...........",
        "........KLBBBBBBBBBDK...........",
        "........KLBBBBBBBBBDK...........",
        "........KLBBBBBBBBBDK...........",
        "........KLBBBBBBBBBDK...........",
        "........KLBBBBBBBBBDK...........",
        "........KLBBBBBBBBBDK...........",
        "........KLBBBBBBBBBDK...........",
        "........KLBBBBBBBBBBKKKKKK......",
        "........KLBBBBBBBBBBBBBBBBKK....",
        "........KLBBBBBBBBBBBBBBBBBBK...",
        "........KLBBBBBBBBBBBBBBBBBBK...",
        "........KDDDDDDDDDDDDDDDDDDDK...",
        "........KSSSSSSSSSSSSSSSSSSSK...",
        "........KSSSSSSKKKKSSSSSSSSSK...",
        "........KKKKKKKKKKKKKKKKKKKKK...",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
    ]
    save_icon(out_dir / "boot.png", boot_rows, boot_pal)

    # 6. Bobber (Поплавок)
    bobber_pal = {
        ".": T,
        "K": K,
        "R": hex_rgba("#E82828"),
        "H": hex_rgba("#FF7868"),
        "W": hex_rgba("#F4F4F4"),
        "G": hex_rgba("#C4C8D0"),
        "Y": hex_rgba("#FFD030"),
    }
    bobber_rows = [
        "................................",
        "...............KK...............",
        "..............KYYK..............",
        "..............KYYK..............",
        "..............KRRK..............",
        "..............KRRK..............",
        ".............KRRRRK.............",
        "............KHHMMMMK............"[0:32],
    ]
    bobber_rows = [
        "................................",
        "...............KK...............",
        "..............KYYK..............",
        "..............KYYK..............",
        "..............KRRK..............",
        "..............KRRK..............",
        ".............KRRRRK.............",
        "............KHRRRRRK............",
        "...........KHHRRRRRRK...........",
        "..........KHHRRRRRRRRK..........",
        "..........KHHRRRRRRRRK..........",
        "..........KHHRRRRRRRRK..........",
        "..........KWWWWWWWWWWK..........",
        "..........KWWWWWWWWGGK..........",
        "..........KWWWWWWWWGGK..........",
        "...........KWWWWWWGGK...........",
        "............KWWWWGGK............",
        ".............KWWGGK.............",
        "..............KGGK..............",
        "..............KGGK..............",
        "...............KK...............",
        "...............KK...............",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
    ]
    save_icon(out_dir / "bobber.png", bobber_rows, bobber_pal)

    # 7. Hook (Рыболовный крючок)
    hook_pal = {
        ".": T,
        "K": K,
        "S": hex_rgba("#A8B4C4"),
        "H": hex_rgba("#E8F0F8"),
        "D": hex_rgba("#586474"),
    }
    hook_rows = [
        "................................",
        "...............KKKK.............",
        "..............KHSSK.............",
        "..............KSSDK.............",
        "...............KKKK.............",
        "................KSHK............",
        "................KSDK............",
        "................KSDK............",
        "................KSDK............",
        "................KSDK............",
        "................KSDK............",
        "................KSDK............",
        ".........KK.....KSDK............",
        "........KHKK....KSDK............",
        "........KSHK....KSDK............",
        "........KSDK....KSDK............",
        "........KSDK....KSDK............",
        "........KSDKK..KKSDK............",
        ".........KSSKKKKSSK.............",
        "..........KSSSSSSK..............",
        "...........KKKKKK...............",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
    ]
    save_icon(out_dir / "hook.png", hook_rows, hook_pal)


# ---------------------------------------------------------------------------
# Shadow Fight 1 silhouette sprites (64x64 transparent pixel-art)
# ---------------------------------------------------------------------------

def make_shadow_fight_sprites() -> None:
    out_dir = GAMES_DIR / "shadow_fight"
    pal = {
        ".": T,
        "B": hex_rgba("#0E0C14"),
        "S": hex_rgba("#221E2E"),
        "R": hex_rgba("#D82020"),
    }
    idle_rows = [
        "................................",
        "................................",
        ".............BBBB...............",
        "............BBBBBB..............",
        "............RRRRRRR.............",
        "..........RRBBBBBB..............",
        "............BBBB................",
        "...........BBBBBBB..............",
        ".........BBBBBBBBBBB............",
        "........BBBB..BBBBBBBB..........",
        ".......BBBB...BBBBBBBBBB........",
        "..............BBBBBB.BBB........",
        "..............BBBBBB............",
        "..............BBBBBB............",
        ".............BBBBBBBB...........",
        "............BBBB..BBBB..........",
        "...........BBBB....BBBB.........",
        "..........BBBB......BBBB........",
        ".........BBBB........BBBB.......",
        "........BBBB..........BBBB......",
        "........BBB............BBB......",
        ".......BBBB............BBBB.....",
        "......BBBBB............BBBBB....",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
    ]
    punch_rows = [
        "................................",
        "................................",
        ".............BBBB...............",
        "............BBBBBB..............",
        "........RRRRRRRRRRR.............",
        ".......RR...BBBBBB..............",
        ".............BBBB...............",
        "............BBBBBBB.............",
        "...........BBBBBBBBBBBBBBBBBB...",
        "..........BBBB..BBBBBBBBBBBBB...",
        ".........BBBB...BBBBBB..........",
        "................BBBBBB..........",
        "................BBBBBB..........",
        "...............BBBBBBB..........",
        "..............BBBB..BBBB........",
        ".............BBBB....BBBB.......",
        "............BBBB......BBBB......",
        "...........BBBB........BBBB.....",
        "..........BBBB..........BBBB....",
        ".........BBBB............BBBB...",
        "........BBBB..............BBB...",
        ".......BBBBB.............BBBBB..",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
    ]
    kick_rows = [
        "................................",
        "................................",
        "...........BBBB.................",
        "..........BBBBBB................",
        ".....RRRRRRRRRRR................",
        "....RR....BBBBBB................",
        "...........BBBB.................",
        "..........BBBBBBB...............",
        ".........BBBBBBBBBB.............",
        "........BBBB..BBBB..............",
        "........BBB...BBBB........BBBB..",
        "..............BBBB......BBBBBB..",
        ".............BBBBBB...BBBBBB....",
        ".............BBBBBBBBBBBB.......",
        ".............BBBBBBBBBB.........",
        "............BBBB.BBBB...........",
        "...........BBBB.................",
        "..........BBBB..................",
        ".........BBBB...................",
        "........BBBB....................",
        "........BBBB....................",
        ".......BBBBB....................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
    ]
    block_rows = [
        "................................",
        "................................",
        ".............BBBB...............",
        "............BBBBBB..............",
        "...........RRRRRRRR.............",
        ".........RR.BBBBBB..............",
        ".............BBBB...............",
        "............BBBBBBB.............",
        "..........BBBBBBBBBBB...........",
        ".........BBBBBBBBBBBBBB.........",
        "........BBBB.BBBBBBBBBB.........",
        "........BBBBBBBBBBBBBBB.........",
        "...........BBBBBBBBBBB..........",
        "............BBBBBBBB............",
        "............BBBBBBBB............",
        "...........BBBB..BBBB...........",
        "..........BBBB....BBBB..........",
        ".........BBBB......BBBB.........",
        ".........BBB........BBB.........",
        "........BBBB........BBBB........",
        "........BBBB........BBBB........",
        ".......BBBBB........BBBBB.......",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
    ]
    save_icon(out_dir / "fighter_idle.png", idle_rows, pal)
    save_icon(out_dir / "fighter_punch.png", punch_rows, pal)
    save_icon(out_dir / "fighter_kick.png", kick_rows, pal)
    save_icon(out_dir / "fighter_block.png", block_rows, pal)


def main() -> None:
    print("Generating retro Win98/XP game icons (64x64)...")
    make_games_folder_icon()
    make_fishing_icon()
    make_chess_icon()
    make_shadow_fight_icon()

    print("Generating mini-game sprite packs (64x64)...")
    make_chess_sprites()
    make_fishing_sprites()
    make_shadow_fight_sprites()
    print("Done!")


if __name__ == "__main__":
    main()
