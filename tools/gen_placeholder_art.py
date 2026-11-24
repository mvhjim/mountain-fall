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

# ================================================================ scenario 2: mountain
def snow_dots(x, y):
    return (255, 255, 255) if (x * 7 + y * 13) % 23 == 0 else None


def water(x, y):
    return (150, 200, 240) if (x + y * 3) % 9 == 0 else None


def planks(x, y):
    return (120, 84, 56) if (x - y * 2) % 6 == 0 else None


mtiles = [
    tile((228, 234, 242), noise=0.03, pattern=snow_dots, seed=21),   # 0 snow
    tile((214, 222, 234), noise=0.03, seed=22),                       # 1 snow shade
    tile((150, 130, 110), noise=0.08, seed=23),                       # 2 gravel path
    tile((158, 112, 76), noise=0.03, pattern=planks, seed=24),        # 3 wooden deck
    tile((130, 132, 140), noise=0.1, seed=25),                        # 4 rock
    tile((70, 130, 190), noise=0.04, pattern=water, seed=26),         # 5 stream
    tile((120, 150, 100), noise=0.06, seed=27),                       # 6 grass patch
]
m = Image.new("RGBA", (TW * len(mtiles), TH + DEPTH), (0, 0, 0, 0))
for n, t in enumerate(mtiles):
    m.paste(t, (n * TW, 0))
m.save(TILES / "mountain_tiles.png")


def snowy_roof(img, w, d, h):
    dr = ImageDraw.Draw(img)
    ox, oy = d * TW // 2, h
    P = lambda i, j, z=0: (ox + iso(i, j)[0], oy + iso(i, j)[1] - z)
    dr.polygon([P(0, 0, h), P(w, 0, h), P(w, d, h), P(0, d, h)], fill=(240, 244, 250, 255))
    dr.line([P(0, d, h), P(w, d, h), P(w, 0, h)], fill=(190, 200, 215, 255))
    return img


snowy_roof(box(4, 3, 34, (150, 82, 52), (240, 244, 250, 255), door=2, seed=31), 4, 3, 34).save(SPRITES / "cabin.png")
snowy_roof(box(2, 2, 22, (120, 88, 60), (240, 244, 250, 255), windows=False, door=1, seed=32), 2, 2, 22).save(SPRITES / "shed.png")
snowy_roof(box(2, 2, 24, (176, 120, 80), (240, 244, 250, 255), windows=False, door=1, seed=33), 2, 2, 24).save(SPRITES / "sauna.png")

pine = Image.new("RGBA", (24, 40), (0, 0, 0, 0))
d = ImageDraw.Draw(pine)
d.ellipse([6, 35, 18, 39], fill=(0, 0, 0, 60))
d.rectangle([10, 30, 13, 37], fill=(100, 70, 46, 255))
for k, (top, half) in enumerate([(2, 5), (10, 8), (18, 11)]):
    d.polygon([(12, top), (12 - half, top + 12), (12 + half, top + 12)], fill=(46, 96, 70, 255))
    d.line([(12 - half, top + 12), (12 + half, top + 12)], fill=(240, 244, 250, 255), width=2)
pine.save(SPRITES / "pine.png")


def small(w, h, fn, name):
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    fn(ImageDraw.Draw(img))
    img.save(SPRITES / f"{name}.png")


small(14, 10, lambda d: (d.ellipse([0, 2, 13, 9], fill=(120, 124, 132, 255)), d.ellipse([2, 2, 9, 5], fill=(150, 154, 162, 255))), "stone")
small(14, 11, lambda d: (d.ellipse([0, 3, 13, 10], fill=(96, 140, 84, 255)), d.ellipse([2, 0, 5, 4], fill=(96, 140, 84, 255)),
                          d.ellipse([8, 0, 11, 4], fill=(96, 140, 84, 255)), d.point((3, 1), fill=(20, 20, 20, 255)),
                          d.point((10, 1), fill=(20, 20, 20, 255))), "frog_stone")
small(22, 16, lambda d: [d.ellipse([x, y, x + 6, y + 6], fill=(150, 104, 66, 255), outline=(110, 74, 46, 255))
                         for x, y in [(0, 9), (7, 9), (14, 9), (3, 4), (10, 4), (7, 0)]], "woodpile")
small(10, 12, lambda d: (d.rectangle([0, 0, 9, 11], fill=(170, 170, 160, 255), outline=(90, 90, 90, 255)),
                         d.polygon([(5, 2), (3, 6), (6, 6), (4, 10)], fill=(240, 200, 40, 255))), "fusebox")
small(14, 10, lambda d: (d.rectangle([0, 2, 13, 9], fill=(60, 130, 200, 255)), d.rectangle([0, 0, 13, 3], fill=(240, 240, 240, 255))), "cooler")
small(20, 12, lambda d: (d.rectangle([0, 3, 19, 6], fill=(140, 96, 60, 255)), d.rectangle([1, 6, 2, 11], fill=(100, 70, 46, 255)),
                         d.rectangle([17, 6, 18, 11], fill=(100, 70, 46, 255))), "bench")
small(20, 12, lambda d: (d.polygon([(10, 0), (19, 5), (10, 10), (0, 5)], fill=(90, 64, 44, 255), outline=(50, 36, 26, 255)),
                         d.line([(5, 3), (14, 8)], fill=(50, 36, 26, 255)), d.rectangle([8, 4, 11, 6], fill=(200, 40, 40, 255))), "cellar_hatch")
small(12, 16, lambda d: (d.rectangle([1, 2, 10, 15], fill=(120, 84, 56, 255), outline=(80, 56, 36, 255)),
                         d.rectangle([1, 5, 10, 6], fill=(70, 70, 76, 255)), d.rectangle([1, 11, 10, 12], fill=(70, 70, 76, 255))), "barrel")
small(14, 22, lambda d: (d.rectangle([2, 8, 11, 21], fill=(50, 50, 56, 255)), d.rectangle([5, 0, 8, 8], fill=(60, 60, 66, 255)),
                         d.rectangle([4, 13, 9, 17], fill=(90, 40, 30, 255))), "stove")
small(8, 8, lambda d: d.ellipse([0, 0, 7, 7], fill=(255, 255, 255, 255)), "smoke")
small(12, 14, lambda d: (d.rectangle([5, 4, 6, 13], fill=(110, 80, 50, 255)), d.rectangle([0, 0, 11, 6], fill=(230, 220, 190, 255), outline=(110, 80, 50, 255))), "sign")

person((90, 60, 40), (200, 60, 60), pants=(200, 60, 60), skin=(236, 190, 160), hair_style="short").save(SPRITES / "gutten_base.png")
g = Image.open(SPRITES / "gutten_base.png")
d = ImageDraw.Draw(g)
for yy in (13, 16):                      # knitted pattern on the old ski suit
    for xx in range(4, 12, 2):
        d.point((xx, yy), fill=(240, 240, 240, 255))
d.rectangle([4, 9, 11, 10], fill=(110, 80, 60, 255))  # stubble
d.point((5, 7), fill=(200, 60, 60, 255)); d.point((10, 7), fill=(200, 60, 60, 255))  # red eyes from no sleep
d.rectangle([12, 13, 14, 17], fill=(200, 170, 60, 255))  # beer can
d.line([(2, 10), (0, 10)], fill=(250, 250, 250, 255))   # cigarette
d.point((0, 9), fill=(255, 120, 40, 255))
g.save(SPRITES / "gutten.png")
(SPRITES / "gutten_base.png").unlink()

icon(lambda d: (d.ellipse([1, 4, 7, 10], outline=(180, 140, 70, 255), width=2), d.rectangle([7, 6, 14, 8], fill=(180, 140, 70, 255)),
                d.rectangle([11, 8, 12, 11], fill=(180, 140, 70, 255))), "cabin_key")
icon(lambda d: (d.polygon([(3, 5), (12, 5), (11, 14), (4, 14)], fill=(150, 150, 160, 255)), d.arc([3, 0, 12, 10], 180, 360, fill=(90, 90, 100, 255))), "bucket")
icon(lambda d: (d.polygon([(3, 5), (12, 5), (11, 14), (4, 14)], fill=(150, 150, 160, 255)), d.rectangle([4, 5, 11, 7], fill=(80, 150, 220, 255)),
                d.arc([3, 0, 12, 10], 180, 360, fill=(90, 90, 100, 255))), "bucket_full")
icon(lambda d: [d.ellipse([x, y, x + 6, y + 6], fill=(150, 104, 66, 255), outline=(110, 74, 46, 255)) for x, y in [(1, 8), (8, 8), (4, 3)]], "firewood")
icon(lambda d: (d.rectangle([2, 4, 13, 12], fill=(200, 60, 50, 255)), d.rectangle([4, 6, 11, 10], fill=(240, 220, 160, 255))), "matches")
icon(lambda d: (d.rectangle([5, 3, 10, 14], fill=(210, 170, 60, 255)), d.rectangle([5, 6, 10, 9], fill=(250, 250, 250, 255)),
                d.rectangle([6, 1, 9, 3], fill=(180, 180, 180, 255))), "beer")
icon(lambda d: (d.rectangle([3, 4, 12, 13], fill=(240, 240, 240, 255), outline=(120, 120, 120, 255)), d.rectangle([3, 4, 12, 7], fill=(60, 110, 60, 255)),
                d.rectangle([6, 1, 7, 4], fill=(250, 250, 250, 255)), d.rectangle([9, 2, 10, 4], fill=(230, 180, 120, 255))), "cigarettes")
# ================================================================ scenario 3: challenges
# lookout: a little flag pole with a coin telescope
small(16, 30, lambda d: (d.rectangle([3, 4, 4, 29], fill=(110, 80, 50, 255)), d.polygon([(5, 4), (15, 8), (5, 12)], fill=(220, 60, 60, 255)),
                         d.rectangle([9, 20, 10, 29], fill=(70, 70, 76, 255)), d.rectangle([7, 16, 14, 20], fill=(90, 110, 140, 255))), "lookout")
small(16, 12, lambda d: (d.ellipse([0, 2, 15, 11], fill=(54, 100, 70, 255)), d.ellipse([3, 0, 12, 7], fill=(66, 120, 84, 255)),
                         [d.point(pt, fill=(70, 90, 170, 255)) for pt in [(4, 5), (8, 3), (11, 6), (6, 8), (12, 9)]]), "bush")
small(30, 22, lambda d: (d.rectangle([1, 2, 2, 21], fill=(110, 80, 50, 255)), d.rectangle([27, 2, 28, 21], fill=(110, 80, 50, 255)),
                         d.line([(2, 4), (27, 4)], fill=(200, 200, 200, 255)), d.rectangle([5, 4, 10, 12], fill=(90, 120, 200, 255)),
                         d.rectangle([14, 4, 18, 14], fill=(200, 50, 60, 255)), d.rectangle([14, 6, 18, 7], fill=(250, 250, 250, 255))), "clothesline")
small(16, 10, lambda d: (d.ellipse([0, 2, 15, 9], fill=(250, 252, 255, 255), outline=(200, 210, 225, 255)), d.ellipse([4, 0, 11, 5], fill=(250, 252, 255, 255))), "snowpile")
small(16, 28, lambda d: (d.ellipse([1, 14, 14, 27], fill=(250, 252, 255, 255), outline=(190, 200, 215, 255)),
                         d.ellipse([3, 4, 12, 15], fill=(250, 252, 255, 255), outline=(190, 200, 215, 255)),
                         d.rectangle([3, 12, 12, 14], fill=(200, 50, 60, 255)), d.point((6, 8), fill=(30, 30, 30, 255)), d.point((9, 8), fill=(30, 30, 30, 255)),
                         d.polygon([(7, 10), (8, 10), (12, 11)], fill=(240, 130, 40, 255)),
                         [d.point((7, y), fill=(30, 30, 30, 255)) for y in (18, 21, 24)]), "snowman")
icon(lambda d: (d.rectangle([1, 5, 14, 13], fill=(60, 60, 70, 255)), d.rectangle([4, 3, 8, 5], fill=(60, 60, 70, 255)),
                d.ellipse([5, 6, 11, 12], fill=(140, 180, 220, 255), outline=(30, 30, 40, 255))), "camera")
icon(lambda d: (d.line([(1, 15), (14, 1)], fill=(150, 104, 66, 255), width=2), d.line([(14, 1), (14, 12)], fill=(220, 220, 220, 255)),
                d.ellipse([3, 10, 6, 13], fill=(70, 70, 76, 255))), "fishing_rod")
icon(lambda d: (d.rectangle([3, 6, 12, 14], fill=(120, 90, 60, 255)), [d.arc([x, 3, x + 4, 9], 180, 360, fill=(220, 120, 140, 255)) for x in (3, 7)]), "worms")
icon(lambda d: (d.ellipse([1, 5, 11, 11], fill=(150, 170, 190, 255)), d.polygon([(10, 8), (15, 4), (15, 12)], fill=(150, 170, 190, 255)),
                d.point((4, 7), fill=(20, 20, 20, 255)), d.line([(3, 10), (9, 10)], fill=(220, 120, 120, 255))), "fish")
icon(lambda d: [d.ellipse([x, y, x + 6, y + 5], fill=(190, 150, 90, 255), outline=(140, 100, 60, 255)) for x, y in [(1, 8), (8, 8), (4, 3)]], "potatoes")
icon(lambda d: (d.line([(8, 15), (8, 4)], fill=(60, 110, 60, 255)), [d.ellipse([x, y, x + 4, y + 3], fill=(80, 150, 80, 255)) for x, y in [(3, 4), (9, 6), (4, 9), (9, 10)]]), "herbs")
icon(lambda d: (d.polygon([(2, 3), (6, 1), (14, 13), (12, 15)], fill=(240, 130, 40, 255)), d.line([(2, 3), (0, 0)], fill=(70, 150, 60, 255), width=2)), "carrot")
icon(lambda d: [d.ellipse([x, y, x + 5, y + 5], fill=(40, 40, 46, 255)) for x, y in [(2, 9), (9, 9), (5, 3)]], "coal")
icon(lambda d: (d.rectangle([2, 2, 13, 6], fill=(200, 50, 60, 255)), d.rectangle([9, 6, 13, 14], fill=(200, 50, 60, 255)),
                d.line([(2, 4), (13, 4)], fill=(250, 250, 250, 255))), "scarf")
# ================================================================ scenario 1: the road
# the hidden bottles: a silvery bottle with a blue label
icon(lambda d: [(d.rectangle([x, 5, x + 3, 14], fill=(215, 220, 228, 255), outline=(150, 156, 170, 255)),
                 d.rectangle([x + 1, 2, x + 2, 5], fill=(215, 220, 228, 255)), d.rectangle([x, 8, x + 3, 10], fill=(40, 80, 170, 255)),
                 d.point((x + 1, 1), fill=(200, 40, 40, 255))) for x in (1, 6, 11)], "smirnoff_ice")
small(6, 12, lambda d: (d.rectangle([1, 4, 4, 11], fill=(215, 220, 228, 255), outline=(150, 156, 170, 255)),
                        d.rectangle([2, 0, 3, 4], fill=(215, 220, 228, 255)), d.rectangle([1, 6, 4, 8], fill=(40, 80, 170, 255))), "bottle")
small(14, 30, lambda d: (d.rectangle([6, 8, 7, 29], fill=(90, 90, 100, 255)), d.ellipse([1, 0, 12, 11], fill=(240, 200, 40, 255), outline=(120, 90, 20, 255)),
                         d.rectangle([4, 4, 9, 7], fill=(40, 120, 60, 255))), "bus_stop")
small(16, 24, lambda d: (d.rectangle([7, 10, 8, 23], fill=(110, 80, 50, 255)), d.polygon([(0, 2), (13, 2), (15, 6), (13, 10), (0, 10)], fill=(40, 120, 70, 255), outline=(230, 230, 230, 255)),
                         d.polygon([(4, 8), (7, 4), (10, 8)], fill=(240, 244, 250, 255))), "road_sign")
print("Placeholder art written to", ROOT / "assets")
