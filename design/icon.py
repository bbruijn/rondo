#!/usr/bin/env python3
"""Tekent het Rondo-icoon: een cirkelpartituur van vijf rondes.

Vijf arbeidsbogen (dik) en vier rustbogen (dun), in de stijl van de ring in
de app en op het web: ronde uiteinden, bot op inkt, en de eerste arbeidsboog
in puls — de training is net begonnen. De kleuren komen uit BRAND.md.

    python3 design/icon.py          # schrijft de iconen voor iOS en de Watch
    python3 design/icon.py --web    # schrijft ook de iconen in web/icons

Let op: web/ staat live. Nieuwe webiconen gaan uit zodra ze op main staan.

Vereist Pillow (pip install pillow).
"""
import math
import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent

INK = (0x10, 0x12, 0x17)
BONE = (0xF2, 0xEF, 0xE8)
PULS = (0xFF, 0x2E, 0x63)

# Een training die ook op 60 pixels leesbaar blijft: 60 s arbeid, 30 s rust,
# 5 rondes. De laatste rust vervalt, net als in de app — daarom staan bovenaan
# twee arbeidsbogen naast elkaar.
WORK, REST, ROUNDS = 60, 30, 5

# Maten als deel van de zijde. De ring blijft binnen de ronde uitsnede van de
# Watch en binnen de veilige zone van een maskeerbaar webicoon.
RADIUS = 0.335
WIDTH = {"work": 0.072, "rest": 0.028}
GAP = 1.6          # graden lucht tussen twee bogen
SOFT = 0.5         # dekking van bot voor de bogen die nog komen
SCALE = 4          # tekenen op 4× en verkleinen, voor gladde randen


def blend(top, bottom, alpha):
    return tuple(round(t * alpha + b * (1 - alpha)) for t, b in zip(top, bottom))


def segments():
    out = []
    for _ in range(ROUNDS):
        out += [("work", WORK), ("rest", REST)]
    return out[:-1]


def draw_arc(draw, size, start, end, width, colour):
    """Een boog met ronde uiteinden. Hoeken in graden, 0 = boven, met de klok mee."""
    c = size / 2
    r = RADIUS * size
    w = width * size
    box = [c - r - w / 2, c - r - w / 2, c + r + w / 2, c + r + w / 2]
    draw.arc(box, start - 90, end - 90, fill=colour, width=round(w))
    for angle in (start, end):
        a = math.radians(angle - 90)
        x, y = c + r * math.cos(a), c + r * math.sin(a)
        draw.ellipse([x - w / 2, y - w / 2, x + w / 2, y + w / 2], fill=colour)


def render(size):
    big = size * SCALE
    image = Image.new("RGB", (big, big), INK)
    draw = ImageDraw.Draw(image)
    soft = blend(BONE, INK, SOFT)

    total = sum(d for _, d in segments())
    at = 0.0
    for i, (phase, duration) in enumerate(segments()):
        start = at / total * 360
        at += duration
        end = at / total * 360
        # Inkorten met het ronde uiteinde, zodat buren elkaar niet raken.
        cap = math.degrees(WIDTH[phase] / 2 / RADIUS)
        pad = cap + GAP / 2
        draw_arc(draw, big, start + pad, end - pad, WIDTH[phase], PULS if i == 0 else soft)

    return image.resize((size, size), Image.LANCZOS)


def main():
    targets = [
        (ROOT / "ios/Rondo/iOS/Assets.xcassets/AppIcon.appiconset/icon-1024.png", 1024),
        (ROOT / "ios/Rondo/Watch/Assets.xcassets/AppIcon.appiconset/icon-1024.png", 1024),
    ]
    if "--web" in sys.argv:
        targets += [
            (ROOT / "web/icons/icon-180.png", 180),
            (ROOT / "web/icons/icon-192.png", 192),
            (ROOT / "web/icons/icon-512.png", 512),
            (ROOT / "web/icons/icon-maskable-512.png", 512),
        ]
    if "--preview" in sys.argv:
        targets = [(Path(sys.argv[sys.argv.index("--preview") + 1]), 1024)]
    for path, size in targets:
        render(size).save(path, optimize=True)
        print(f"{size:>5}  {path.relative_to(ROOT) if path.is_relative_to(ROOT) else path}")


if __name__ == "__main__":
    main()
