#!/usr/bin/env python3
"""NaviCore Android simgelerini navicore/res/scalable.svg kaynagindan uretir -> navicore/android/res/.
Beyaz kart zemini cikarilir (seffaf isaret): uyarlanabilir simgenin zemini ic_launcher_background (#ffffff),
bildirim simgesi isaretin silueti. Gerekli: rsvg-convert, Pillow.
Kullanim (repo kokunden): python3 navicore/android/gen_icons.py
Boyutlar upstream flutter/android/app/src/main/res/mipmap-* ile ayni (her dosya upstream'de olmali)."""
import io, subprocess
from pathlib import Path
from PIL import Image
svg = open("navicore/res/scalable.svg", encoding="utf-8").read()
CARD = '<g clip-path="url(#card)"><rect width="256" height="256" fill="#ffffff"/></g>'
assert svg.count(CARD) == 1, "scalable.svg kart zemini degismis"
png = subprocess.run(["rsvg-convert", "-w", "1024", "-h", "1024"], input=svg.replace(CARD, "").encode(),
                     capture_output=True, check=True).stdout
SRC = Image.open(io.BytesIO(png)).convert("RGBA")
SRC = SRC.crop(SRC.getchannel("A").getbbox())  # isareti kenarlara kadar kirp (olcekler isarete gore)
UP = Path("flutter/android/app/src/main/res"); OUT = Path("navicore/android/res")
DPI = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
def fit(img, size, scale):  # logoyu size x size seffaf tuvale 'scale' oraninda ortala
    s = round(size * scale); tile = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    tile.alpha_composite(img.resize((s, s), Image.LANCZOS), ((size - s) // 2, (size - s) // 2)); return tile
for d, k in DPI.items():
    o = OUT / f"mipmap-{d}"; o.mkdir(parents=True, exist_ok=True)
    for name, size in [("ic_launcher.png", 48), ("ic_launcher_round.png", 48), ("ic_launcher_foreground.png", 108), ("ic_stat_logo.png", 24)]:
        assert (UP / f"mipmap-{d}" / name).exists(), f"upstream'de yok: mipmap-{d}/{name}"
        px = round(size * k)
        if name == "ic_launcher_foreground.png":
            img = fit(SRC, px, 66 / 108)          # uyarlanabilir simge guvenli alani 66dp/108dp
        elif name == "ic_stat_logo.png":          # bildirim simgesi: beyaz siluet (Android yalniz alfa kanalini kullanir)
            a = fit(SRC, px, 0.92).getchannel("A"); img = Image.new("RGBA", (px, px), (255, 255, 255, 0)); img.putalpha(a)
        else:                                     # eski launcher: beyaz zemin + logo (round: daire maske)
            img = Image.new("RGBA", (px, px), (255, 255, 255, 255)); img.alpha_composite(fit(SRC, px, 0.86))
            if name == "ic_launcher_round.png":
                m = Image.new("L", (px * 4, px * 4), 0)
                from PIL import ImageDraw; ImageDraw.Draw(m).ellipse((0, 0, px * 4 - 1, px * 4 - 1), fill=255)
                img.putalpha(m.resize((px, px), Image.LANCZOS))
        img.save(o / name, optimize=True)
print("uretildi:", OUT)
