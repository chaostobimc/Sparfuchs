#!/usr/bin/env python3
"""Generates PNG textures (pure Python, no deps) for The Diplomat Peak.
Run:  python3 scripts/texture_gen.py
Output: assets/textures/*.png (RGBA, 256x256)
"""
import struct, zlib, math, random, os

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "textures")
os.makedirs(OUT, exist_ok=True)
random.seed(7)

def write_png(name, w, h, data):
    path = os.path.join(OUT, name + ".png")
    sig = b'\x89PNG\r\n\x1a\n'
    def chunk(typ, d):
        c = typ + d
        return struct.pack(">I", len(d)) + c + struct.pack(">I", zlib.crc32(c) & 0xffffffff)
    ihdr = struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)
    raw = bytearray()
    for y in range(h):
        raw.append(0)
        for x in range(w):
            px = data[y * w + x]
            raw += bytes((max(0, min(255, int(px[0]))),
                          max(0, min(255, int(px[1]))),
                          max(0, min(255, int(px[2]))),
                          max(0, min(255, int(px[3])))))
    idat = zlib.compress(bytes(raw), 9)
    with open(path, "wb") as f:
        f.write(sig + chunk(b'IHDR', ihdr) + chunk(b'IDAT', idat) + chunk(b'IEND', b''))
    print("wrote", path)

def value_noise(w, h, scale, seed):
    r = random.Random(seed)
    gx = r.randint(0, scale)
    gy = r.randint(0, scale)
    grid = {}
    def gv(x, y):
        return r.random()
    pts = {}
    for ix in range(-1, w // scale + 2):
        for iy in range(-1, h // scale + 2):
            pts[(ix, iy)] = r.random()
    out = []
    for y in range(h):
        for x in range(w):
            fx = x / scale
            fy = y / scale
            x0 = int(math.floor(fx)); y0 = int(math.floor(fy))
            tx = fx - x0; ty = fy - y0
            def smooth(t): return t * t * (3 - 2 * t)
            tx = smooth(tx); ty = smooth(ty)
            a = pts.get((x0, y0), 0.0)
            b = pts.get((x0 + 1, y0), 0.0)
            c = pts.get((x0, y0 + 1), 0.0)
            d = pts.get((x0 + 1, y0 + 1), 0.0)
            out.append((a * (1 - tx) + b * tx) * (1 - ty) + (c * (1 - tx) + d * tx) * ty)
    return out

def gen(name, w, h, base, fn):
    data = []
    for y in range(h):
        for x in range(w):
            data.append(fn(x, y))
    write_png(name, w, h, data)

# --- concrete ---
def concrete(x, y):
    n = random.random() * 0.12
    g = 0.42 + n - 0.06
    return (int(g*255), int(g*255), int(g*255*0.98), 255)
gen("concrete", 256, 256, None, concrete)

# --- wood (planks) ---
def wood(x, y):
    plank = (y // 32) % 2
    base = 0.30 if plank == 0 else 0.24
    n = random.random() * 0.08
    grain = math.sin((y // 4) * 1.5) * 0.04
    r = int((base + n + grain) * 255)
    g = int((base * 0.7 + n * 0.7) * 255)
    b = int((base * 0.45 + n * 0.4) * 255)
    return (r, g, b, 255)
gen("wood", 256, 256, None, wood)

# --- wallpaper (green, peeling) ---
def wallpaper(x, y):
    # vertical peel streaks
    peel = 0.0
    if (x % 64) < 8 and random.random() < 0.3:
        peel = -0.15
    n = random.random() * 0.06
    r = int((0.13 + n + peel) * 255)
    g = int((0.19 + n + peel) * 255)
    b = int((0.15 + n + peel) * 255)
    return (r, g, b, 255)
gen("wallpaper", 256, 256, None, wallpaper)

# --- metal ---
def metal(x, y):
    n = random.random() * 0.1
    brush = math.sin(y * 0.3) * 0.04
    v = 0.22 + n + brush
    return (int(v*255), int(v*255), int(v*255*1.05), 255)
gen("metal", 256, 256, None, metal)

# --- fabric (dark red velvet) ---
def fabric(x, y):
    n = random.random() * 0.1
    weave = (math.sin(x * 0.5) + math.sin(y * 0.5)) * 0.03
    r = int((0.30 + n + weave) * 255)
    g = int((0.07 + n * 0.5 + weave) * 255)
    b = int((0.10 + n * 0.5 + weave) * 255)
    return (r, g, b, 255)
gen("fabric", 256, 256, None, fabric)

# --- paper ---
def paper(x, y):
    n = random.random() * 0.06
    v = 0.74 + n
    return (int(v*255), int(v*255*0.97), int(v*255*0.9), 255)
gen("paper", 256, 256, None, paper)

# --- dirt ---
def dirt(x, y):
    n = random.random() * 0.12
    r = int((0.16 + n) * 255)
    g = int((0.11 + n * 0.8) * 255)
    b = int((0.07 + n * 0.6) * 255)
    return (r, g, b, 255)
gen("dirt", 256, 256, None, dirt)

# --- fern ---
def fern(x, y):
    n = random.random() * 0.1
    r = int((0.18 + n) * 255)
    g = int((0.42 + n) * 255)
    b = int((0.16 + n * 0.7) * 255)
    return (r, g, b, 255)
gen("fern", 256, 256, None, fern)

print("DONE")
