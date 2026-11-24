"""Generate simple placeholder pixel art for Mountainfall.

Run:  python tools/gen_placeholder_art.py
Writes PNGs into assets/. Replace them with real art whenever you like;
keep the same file names and sizes and the game picks them up.
Requires Pillow (pip install pillow).
"""
import random
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
TILES = ROOT / "assets" / "tiles"
SPRITES = ROOT / "assets" / "sprites"
TILES.mkdir(parents=True, exist_ok=True)
SPRITES.mkdir(parents=True, exist_ok=True)

TW, TH, DEPTH = 32, 16, 8  # isometric tile: 32x16 top, 8 px thick sides


def shade(c, f):
    return tuple(max(0, min(255, int(v * f))) for v in c[:3]) + (255,)


def iso(i, j):
    """Tile-space corner (i, j) to pixel offset from the box's top corner."""
    return ((i - j) * TW // 2, (i + j) * TH // 2)


# ---------------------------------------------------------------- tiles
def tile(top, noise=0.06, pattern=None, seed=0):
    rnd = random.Random(seed)
    img = Image.new("RGBA", (TW, TH + DEPTH), (0, 0, 0, 0))
    px = img.load()
    for y in range(TH):
        half = (y + 1) * 2 if y < TH // 2 else (TH - y) * 2
        for x in range(TW // 2 - half, TW // 2 + half):
            f = 1 + rnd.uniform(-noise, noise)
            c = top
            if pattern:
                c = pattern(x, y) or top
            px[x, y] = shade(c, f)
    side_l, side_r = shade(top, 0.62), shade(top, 0.45)
    earth_l, earth_r = (92, 70, 58, 255), (70, 52, 44, 255)
    for x in range(TW):
        if x < TW // 2:
            edge = TH // 2 + x // 2
            for d in range(1, DEPTH + 1):
                if edge + d < TH + DEPTH:
                    px[x, edge + d] = side_l if d <= 2 else earth_l
        else:
            edge = TH // 2 + (TW - 1 - x) // 2
            for d in range(1, DEPTH + 1):
                if edge + d < TH + DEPTH:
                    px[x, edge + d] = side_r if d <= 2 else earth_r
    return img


def road_line(x, y):
    # dashed centre line running along the tile's x axis
    if abs((x - 16) - (y - 8) * 2) <= 1 and 4 < x < 28 and (x // 4) % 2 == 0:
        return (230, 220, 160)
    return None


def crossing(x, y):
    return (235, 235, 235) if (x // 3) % 2 == 0 else None


tiles = [
    tile((96, 150, 88), seed=1),                 # 0 grass
    tile((104, 158, 92), seed=2),                # 1 grass light
    tile((78, 80, 92), noise=0.03, seed=3),      # 2 road
    tile((78, 80, 92), noise=0.03, pattern=road_line, seed=4),  # 3 road with line
    tile((168, 164, 156), noise=0.04, seed=5),   # 4 sidewalk
    tile((150, 120, 96), noise=0.05, seed=6),    # 5 plaza / bricks
    tile((78, 80, 92), noise=0.03, pattern=crossing, seed=7),  # 6 crossing
]
atlas = Image.new("RGBA", (TW * len(tiles), TH + DEPTH), (0, 0, 0, 0))
for n, t in enumerate(tiles):
    atlas.paste(t, (n * TW, 0))
atlas.save(TILES / "city_tiles.png")


# ---------------------------------------------------------------- boxes
def box(w, d, h, wall, roof, windows=True, door=None, seed=0):
    """Isometric box with footprint w x d tiles and height h px.
    Image origin (the box's top ground corner) is at (16*d, h)."""
    rnd = random.Random(seed)
    W = (w + d) * TW // 2
    H = (w + d) * TH // 2 + h
    img = Image.new("RGBA", (W + 1, H + 1), (0, 0, 0, 0))
    dr = ImageDraw.Draw(img)
    ox, oy = d * TW // 2, h
    P = lambda i, j, z=0: (ox + iso(i, j)[0], oy + iso(i, j)[1] - z)
    left = [P(0, d), P(w, d), P(w, d, h), P(0, d, h)]
    right = [P(w, 0), P(w, d), P(w, d, h), P(w, 0, h)]
    top = [P(0, 0, h), P(w, 0, h), P(w, d, h), P(0, d, h)]
    dr.polygon(left, fill=shade(wall, 0.85))
    dr.polygon(right, fill=shade(wall, 0.65))
    dr.polygon(top, fill=roof)
    dr.line(top + [top[0]], fill=shade(roof, 0.7))
    if windows:
        lit = (255, 222, 140, 255)
        dark = (60, 72, 96, 255)
        for floor_z in range(10, h - 6, 14):
            for k in range(w * 2):  # left wall runs along i at j=d
                t = (k + 0.5) / 2
                if door and k == door and floor_z == 10:
                    continue
                x, y = P(t, d, floor_z)
                c = lit if rnd.random() < 0.45 else dark
                dr.rectangle([x - 2, y - 5, x + 1, y], fill=c)
            for k in range(d * 2):  # right wall runs along j at i=w
                t = (k + 0.5) / 2
                x, y = P(w, t, floor_z)
                c = lit if rnd.random() < 0.45 else dark
                dr.rectangle([x - 1, y - 5, x + 2, y], fill=c)
    if door is not None:
        t = (door + 0.5) / 2
        x, y = P(t, d, 0)
        dr.rectangle([x - 3, y - 11, x + 2, y - 1], fill=(70, 48, 36, 255))
        dr.point((x + 1, y - 6), fill=(230, 200, 90, 255))
    return img


box(3, 3, 44, (196, 120, 96), (120, 70, 64, 255), door=2, seed=11).save(SPRITES / "building_maja.png")
box(3, 3, 58, (120, 144, 176), (70, 84, 110, 255), door=3, seed=12).save(SPRITES / "building_even.png")
box(2, 3, 30, (220, 206, 170), (150, 96, 80, 255), door=1, seed=13).save(SPRITES / "building_berg.png")
box(4, 2, 70, (150, 150, 160), (96, 96, 110, 255), door=None, seed=14).save(SPRITES / "building_tall.png")

# car: low box with a cabin on top
car = Image.new("RGBA", (48, 40), (0, 0, 0, 0))
body = box(2, 1, 8, (64, 156, 170), (80, 176, 190, 255), windows=False)
cabin = box(1, 1, 7, (210, 230, 240), (64, 156, 170, 255), windows=False)
car.paste(body, (0, 40 - body.height), body)
car.paste(cabin, (10, 40 - body.height - 7), cabin)
d = ImageDraw.Draw(car)
for wx, wy in [(9, 34), (22, 38), (33, 32)]:
    d.ellipse([wx - 2, wy - 2, wx + 2, wy + 2], fill=(30, 30, 36, 255))
car.save(SPRITES / "car.png")


# ---------------------------------------------------------------- people
def person(hair, jacket, pants=(52, 56, 72), skin=(240, 200, 170), hair_style="short"):
    img = Image.new("RGBA", (16, 26), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([3, 22, 12, 25], fill=(0, 0, 0, 70))           # shadow
    d.rectangle([5, 18, 6, 23], fill=pants + (255,))          # legs
    d.rectangle([9, 18, 10, 23], fill=pants + (255,))
    d.rounded_rectangle([3, 11, 12, 19], 2, fill=jacket + (255,))  # body
    d.ellipse([2, 1, 13, 12], fill=skin + (255,))             # big head
    if hair_style == "long":
        d.rectangle([2, 3, 4, 14], fill=hair + (255,))
        d.rectangle([11, 3, 13, 14], fill=hair + (255,))
    if hair_style == "bun":
        d.ellipse([5, -1, 10, 3], fill=hair + (255,))
    d.chord([2, 0, 13, 10], 180, 360, fill=hair + (255,))     # hair
    d.point((6, 7), fill=(40, 30, 30, 255))                   # eyes
    d.point((9, 7), fill=(40, 30, 30, 255))
    return img


person((120, 60, 40), (220, 90, 80), hair_style="long").save(SPRITES / "maja.png")
person((50, 40, 36), (90, 110, 170)).save(SPRITES / "even.png")
person((230, 190, 90), (90, 170, 100), hair_style="bun").save(SPRITES / "sara.png")
person((30, 26, 24), (240, 170, 60)).save(SPRITES / "tom.png")
person((210, 210, 215), (150, 100, 170), pants=(90, 80, 100), hair_style="bun").save(SPRITES / "mrs_berg.png")

# ---------------------------------------------------------------- props
tree = Image.new("RGBA", (24, 36), (0, 0, 0, 0))
d = ImageDraw.Draw(tree)
d.ellipse([6, 31, 18, 35], fill=(0, 0, 0, 70))
d.rectangle([10, 20, 13, 33], fill=(110, 76, 50, 255))
d.ellipse([1, 1, 22, 24], fill=(70, 130, 70, 255))
d.ellipse([4, 3, 16, 14], fill=(96, 160, 88, 255))
tree.save(SPRITES / "tree.png")

mailbox = Image.new("RGBA", (12, 22), (0, 0, 0, 0))
d = ImageDraw.Draw(mailbox)
d.ellipse([2, 18, 9, 21], fill=(0, 0, 0, 70))
d.rectangle([5, 10, 6, 19], fill=(80, 80, 90, 255))
d.rounded_rectangle([1, 2, 10, 11], 2, fill=(60, 110, 200, 255))
d.rectangle([3, 5, 8, 6], fill=(30, 50, 100, 255))
mailbox.save(SPRITES / "mailbox.png")

lamp = Image.new("RGBA", (10, 40), (0, 0, 0, 0))
d = ImageDraw.Draw(lamp)
d.rectangle([4, 6, 5, 38], fill=(60, 64, 76, 255))
d.ellipse([1, 1, 8, 8], fill=(255, 228, 150, 255))
lamp.save(SPRITES / "lamp.png")

marker = Image.new("RGBA", (9, 9), (0, 0, 0, 0))
d = ImageDraw.Draw(marker)
d.polygon([(0, 0), (8, 0), (4, 6)], fill=(255, 210, 80, 255), outline=(120, 80, 20, 255))
marker.save(SPRITES / "marker.png")

# ---------------------------------------------------------------- item icons (16x16)
def icon(draw_fn, name):
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    draw_fn(ImageDraw.Draw(img))
    img.save(SPRITES / f"item_{name}.png")


icon(lambda d: (d.ellipse([1, 4, 8, 11], outline=(220, 190, 70, 255), width=2),
                d.rectangle([8, 7, 14, 8], fill=(220, 190, 70, 255)),
                d.rectangle([12, 9, 13, 11], fill=(220, 190, 70, 255))), "car_keys")
icon(lambda d: (d.rectangle([1, 3, 14, 12], fill=(245, 240, 225, 255), outline=(150, 140, 120, 255)),
                d.line([(1, 3), (7, 8), (14, 3)], fill=(150, 140, 120, 255))), "post")
print("Placeholder art written to", ROOT / "assets")
