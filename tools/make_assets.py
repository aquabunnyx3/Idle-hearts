#!/usr/bin/env python3
"""Generates every image in IdleHearts/Assets.xcassets.

Run from the repo root:  python3 tools/make_assets.py
Needs: Pillow, numpy, scipy, rsvg-convert (librsvg).

* Character portraits + chibis are cut from tools/source/character_sheet.png
  (the Idle Hearts character master sheet).
* Date-scene backgrounds, foreground tables, the tap heart, particles and the
  app icon are drawn as SVG here and rasterised with rsvg-convert.
"""
import json, os, random, subprocess, tempfile
import numpy as np
from PIL import Image, ImageFilter, ImageDraw
from scipy import ndimage

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "tools", "source", "character_sheet.png")
XC = os.path.join(ROOT, "IdleHearts", "Assets.xcassets")
CHARS = ["adrian", "lola", "vincent", "riley", "jamie"]


# ---------------------------------------------------------------- helpers
def imageset(name, img, scale_note="universal"):
    d = os.path.join(XC, f"{name}.imageset")
    os.makedirs(d, exist_ok=True)
    img.save(os.path.join(d, f"{name}.png"), optimize=True)
    json.dump({"images": [{"idiom": "universal", "filename": f"{name}.png"}],
               "info": {"author": "xcode", "version": 1}},
              open(os.path.join(d, "Contents.json"), "w"), indent=2)


def svg_to_png(svg, w, h):
    with tempfile.TemporaryDirectory() as t:
        p = os.path.join(t, "a.svg"); o = os.path.join(t, "a.png")
        open(p, "w").write(svg)
        subprocess.run(["rsvg-convert", "-w", str(w), "-h", str(h), p, "-o", o], check=True)
        return Image.open(o).convert("RGBA").copy()


# ---------------------------------------------------------------- portraits
PORTRAITS = {  # x0, x1, [(y0, y1) x3]  -> expressions: 1 neutral/smirk, 2 happy, 3 soft
    "adrian": (337, 455, [(230, 338), (342, 446), (450, 556)]),
    "lola": (610, 713, [(248, 346), (354, 455), (461, 560)]),
    "vincent": (875, 970, [(248, 346), (353, 455), (461, 560)]),
    "riley": (1117, 1230, [(248, 346), (353, 455), (459, 560)]),
    "jamie": (1400, 1512, [(240, 345), (350, 455), (461, 560)]),
}


def make_portraits(sheet):
    for name, (x0, x1, ys) in PORTRAITS.items():
        for i, (y0, y1) in enumerate(ys, 1):
            m = 7  # trim the tile's rounded corners
            c = sheet.crop((x0 + m, y0 + m, x1 - m, y1 - m))
            s = min(c.size)
            c = c.crop(((c.width - s) // 2, 0, (c.width - s) // 2 + s, s))
            c = c.resize((360, 360), Image.LANCZOS).filter(ImageFilter.UnsharpMask(1.2, 60, 2))
            imageset(f"portrait_{name}_{i}", c.convert("RGB"))


# ---------------------------------------------------------------- chibis
def make_chibis(sheet):
    reg = sheet.crop((482, 690, 1125, 1000))
    a = np.asarray(reg).astype(int)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    mx, mn = a.max(2), a.min(2)
    bgc = ((mn > 200) & (mx > 225)) | ((r > 220) & (b > 180) & (g > 140) & (r - g > 25)) | \
          ((b > 205) & (r > 175) & (g > 160) & (b - g > 15) & (mn > 160))
    lbl, _ = ndimage.label(bgc)
    border = set(np.unique(np.concatenate([lbl[0], lbl[-1], lbl[:, 0], lbl[:, -1]]))) - {0}
    fg = ~np.isin(lbl, list(border))
    bounds = [(0, 128), (128, 262), (262, 393), (393, 520), (520, 643)]
    for name, (x0, x1) in zip(CHARS, bounds):
        f = fg[:, x0:x1].copy()
        fl, n = ndimage.label(f)
        if n:
            sizes = ndimage.sum(f, fl, range(1, n + 1))
            f = fl == (int(np.argmax(sizes)) + 1)
        alpha = Image.fromarray((f * 255).astype(np.uint8))
        alpha = alpha.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(0.7))
        c = reg.crop((x0, 0, x1, reg.height)).convert("RGBA")
        c.putalpha(alpha)
        c = c.crop(c.getbbox())
        c = c.resize((c.width * 3, c.height * 3), Image.LANCZOS).filter(ImageFilter.UnsharpMask(1.5, 50, 2))
        imageset(f"chibi_{name}", c)


# ---------------------------------------------------------------- scenes
W, H = 1200, 1400


def bokeh(n, x0, y0, x1, y1, colors, rmin, rmax, seed, op=(0.25, 0.7)):
    rnd = random.Random(seed)
    out = []
    for _ in range(n):
        out.append(f'<circle cx="{rnd.uniform(x0, x1):.0f}" cy="{rnd.uniform(y0, y1):.0f}" '
                   f'r="{rnd.uniform(rmin, rmax):.0f}" fill="{rnd.choice(colors)}" '
                   f'opacity="{rnd.uniform(*op):.2f}"/>')
    return "".join(out)


def wisteria(seed, x0, x1, color_a, color_b):
    rnd = random.Random(seed)
    s = []
    x = x0
    while x < x1:
        length = rnd.uniform(90, 260)
        for k in range(int(length / 14)):
            yy = k * 14 + rnd.uniform(-4, 4)
            rr = 15 - k * (10 / (length / 14))
            s.append(f'<circle cx="{x + rnd.uniform(-9, 9):.0f}" cy="{yy:.0f}" r="{max(rr, 4):.0f}" '
                     f'fill="{rnd.choice([color_a, color_b])}" opacity="{rnd.uniform(.75, 1):.2f}"/>')
        x += rnd.uniform(28, 55)
    return f'<g filter="url(#soft)">{"".join(s)}</g>'


def string_lights(y, sag, seed, colors):
    rnd = random.Random(seed)
    path = f'<path d="M -20 {y} Q 600 {y + sag} 1220 {y}" stroke="#5b3d5e" stroke-width="3" fill="none" opacity=".5"/>'
    bulbs = []
    for i in range(22):
        t = i / 21
        bx = -20 + 1240 * t
        by = (1 - t) ** 2 * y + 2 * (1 - t) * t * (y + sag) + t ** 2 * y
        c = rnd.choice(colors)
        bulbs.append(f'<circle cx="{bx:.0f}" cy="{by + 14:.0f}" r="26" fill="{c}" opacity=".35" filter="url(#glow)"/>'
                     f'<circle cx="{bx:.0f}" cy="{by + 14:.0f}" r="8" fill="{c}"/>')
    return path + "".join(bulbs)


DEFS = """
<defs>
  <filter id="soft" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="2.5"/></filter>
  <filter id="blur" x="-30%" y="-30%" width="160%" height="160%"><feGaussianBlur stdDeviation="14"/></filter>
  <filter id="glow" x="-100%" y="-100%" width="300%" height="300%"><feGaussianBlur stdDeviation="12"/></filter>
  <filter id="shadow" x="-20%" y="-20%" width="140%" height="160%"><feGaussianBlur stdDeviation="10"/></filter>
</defs>"""


def scene_cafe():
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}">{DEFS}
<linearGradient id="wall" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#f6dfe9"/><stop offset="1" stop-color="#e9cbe0"/></linearGradient>
<linearGradient id="out" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#b9a6dc"/><stop offset=".6" stop-color="#f1b9cf"/><stop offset="1" stop-color="#fbd9c9"/></linearGradient>
<rect width="{W}" height="{H}" fill="url(#wall)"/>
<!-- arched windows -->
<g>
  <path d="M110 1050 V420 a230 230 0 0 1 460 0 V1050 Z" fill="url(#out)"/>
  <path d="M630 1050 V420 a230 230 0 0 1 460 0 V1050 Z" fill="url(#out)"/>
  <g filter="url(#blur)">{bokeh(26, 120, 300, 560, 1000, ['#fff3d6', '#ffd1e3', '#ffe9b0'], 18, 46, 1)}{bokeh(26, 640, 300, 1080, 1000, ['#fff3d6', '#ffd1e3', '#ffe9b0'], 18, 46, 2)}</g>
  <g fill="#9a7ab8" opacity=".35"><rect x="150" y="760" width="70" height="290"/><rect x="230" y="700" width="90" height="350"/><rect x="340" y="800" width="60" height="250"/><rect x="420" y="730" width="110" height="320"/>
     <rect x="660" y="740" width="100" height="310"/><rect x="780" y="690" width="70" height="360"/><rect x="870" y="780" width="90" height="270"/><rect x="975" y="720" width="80" height="330"/></g>
  <g fill="none" stroke="#fff" stroke-width="16" opacity=".95">
    <path d="M110 1050 V420 a230 230 0 0 1 460 0 V1050 Z"/><path d="M630 1050 V420 a230 230 0 0 1 460 0 V1050 Z"/></g>
  <g stroke="#fff" stroke-width="8" opacity=".9"><line x1="340" y1="190" x2="340" y2="1050"/><line x1="110" y1="620" x2="570" y2="620"/>
     <line x1="860" y1="190" x2="860" y2="1050"/><line x1="630" y1="620" x2="1090" y2="620"/></g>
</g>
<!-- awning hint / wisteria -->
{wisteria(7, -20, 1220, '#c9a3e6', '#e5c7f2')}
<!-- pendant lamps -->
<g>
  <line x1="350" y1="0" x2="350" y2="250" stroke="#6d4a6b" stroke-width="4"/>
  <circle cx="350" cy="300" r="120" fill="#ffd9a0" opacity=".35" filter="url(#glow)"/>
  <path d="M300 250 h100 l30 60 h-160 Z" fill="#7a4f74"/><circle cx="350" cy="318" r="18" fill="#fff4cf"/>
  <line x1="870" y1="0" x2="870" y2="210" stroke="#6d4a6b" stroke-width="4"/>
  <circle cx="870" cy="262" r="120" fill="#ffd9a0" opacity=".35" filter="url(#glow)"/>
  <path d="M820 210 h100 l30 60 h-160 Z" fill="#7a4f74"/><circle cx="870" cy="278" r="18" fill="#fff4cf"/>
</g>
<!-- floor / back counter -->
<rect x="0" y="1040" width="{W}" height="360" fill="#d9b2cf"/>
<rect x="0" y="1030" width="{W}" height="22" fill="#c79bbd"/>
<!-- potted plants -->
<g><path d="M30 1040 l20 -110 h90 l20 110 Z" fill="#b57f9f"/><g fill="#8fb39a"><ellipse cx="70" cy="900" rx="40" ry="70" transform="rotate(-20 70 900)"/><ellipse cx="120" cy="890" rx="38" ry="76" transform="rotate(18 120 890)"/><ellipse cx="96" cy="860" rx="30" ry="80"/></g></g>
<g><path d="M1040 1040 l20 -110 h90 l20 110 Z" fill="#b57f9f"/><g fill="#8fb39a"><ellipse cx="1080" cy="900" rx="40" ry="70" transform="rotate(-20 1080 900)"/><ellipse cx="1130" cy="890" rx="38" ry="76" transform="rotate(18 1130 890)"/><ellipse cx="1106" cy="860" rx="30" ry="80"/></g></g>
</svg>"""


def scene_hotel():
    rnd = random.Random(5)
    towers = []
    x = 0
    while x < W:
        w = rnd.randint(60, 140); h = rnd.randint(250, 700)
        towers.append(f'<rect x="{x}" y="{1050 - h}" width="{w}" height="{h}" fill="#3b2a5e"/>')
        for wy in range(1050 - h + 20, 1040, 34):
            for wx in range(x + 10, x + w - 14, 22):
                if rnd.random() < .45:
                    towers.append(f'<rect x="{wx}" y="{wy}" width="10" height="16" fill="#ffd99a" opacity="{rnd.uniform(.4, .95):.2f}"/>')
        x += w + rnd.randint(4, 20)
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}">{DEFS}
<linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2b1f4f"/><stop offset=".55" stop-color="#7b4c8f"/><stop offset="1" stop-color="#f19bb5"/></linearGradient>
<rect width="{W}" height="{H}" fill="url(#sky)"/>
{bokeh(70, 0, 0, W, 520, ['#ffffff'], 1, 3, 9, (.4, .9))}
<circle cx="930" cy="240" r="70" fill="#fff1d8"/><circle cx="930" cy="240" r="150" fill="#fff1d8" opacity=".25" filter="url(#glow)"/>
<g opacity=".55">{''.join(towers)}</g>
<g filter="url(#blur)">{bokeh(20, 0, 600, W, 1050, ['#ffb3d0', '#ffe2a8', '#c9b2ff'], 14, 34, 3)}</g>
<!-- floor-to-ceiling window frame -->
<g fill="#21173a"><rect x="0" y="0" width="{W}" height="60"/><rect x="0" y="0" width="40" height="1060"/><rect x="1160" y="0" width="40" height="1060"/>
<rect x="390" y="0" width="22" height="1060"/><rect x="790" y="0" width="22" height="1060"/></g>
<!-- curtains -->
<path d="M0 0 h150 c-30 300 30 700 -10 1060 h-140 Z" fill="#8c4f8f"/><path d="M1200 0 h-150 c30 300 -30 700 10 1060 h140 Z" fill="#8c4f8f"/>
<path d="M40 0 c20 330 -10 700 30 1060" stroke="#a96aa8" stroke-width="10" fill="none" opacity=".6"/>
<path d="M1160 0 c-20 330 10 700 -30 1060" stroke="#a96aa8" stroke-width="10" fill="none" opacity=".6"/>
<rect x="0" y="1040" width="{W}" height="360" fill="#3a2650"/><rect x="0" y="1030" width="{W}" height="22" fill="#55396f"/>
</svg>"""


def scene_festival():
    lanterns = []
    rnd = random.Random(11)
    for i in range(9):
        x = 70 + i * 135 + rnd.randint(-20, 20); y = 120 + rnd.randint(0, 140)
        c = rnd.choice(['#ff8fb1', '#ffb36b', '#ffd36b', '#f98ad8'])
        lanterns.append(f'<line x1="{x}" y1="0" x2="{x}" y2="{y - 40}" stroke="#5b3d5e" stroke-width="3"/>'
                        f'<ellipse cx="{x}" cy="{y}" rx="70" ry="80" fill="{c}" opacity=".45" filter="url(#glow)"/>'
                        f'<ellipse cx="{x}" cy="{y}" rx="36" ry="46" fill="{c}"/>'
                        f'<rect x="{x - 18}" y="{y - 52}" width="36" height="10" rx="3" fill="#6b3f52"/>'
                        f'<rect x="{x - 18}" y="{y + 42}" width="36" height="10" rx="3" fill="#6b3f52"/>'
                        f'<ellipse cx="{x - 10}" cy="{y - 10}" rx="9" ry="20" fill="#fff" opacity=".35"/>')
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}">{DEFS}
<linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3d2a63"/><stop offset=".6" stop-color="#a55f9a"/><stop offset="1" stop-color="#f4a6a8"/></linearGradient>
<linearGradient id="river" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#6c5a9e"/><stop offset="1" stop-color="#3b2d63"/></linearGradient>
<rect width="{W}" height="{H}" fill="url(#sky)"/>
{bokeh(60, 0, 0, W, 600, ['#ffffff'], 1, 3, 4, (.4, .9))}
<!-- far hills + bridge -->
<path d="M0 820 Q 300 700 600 790 T 1200 760 V 900 H0 Z" fill="#5b3f7a" opacity=".8"/>
<path d="M120 860 Q 600 640 1080 860" stroke="#3a2650" stroke-width="22" fill="none"/>
<g stroke="#3a2650" stroke-width="8">{''.join(f'<line x1="{x}" y1="{860 - (220 * (1 - ((x - 600) / 480) ** 2)):.0f}" x2="{x}" y2="880"/>' for x in range(180, 1080, 60))}</g>
<rect x="0" y="870" width="{W}" height="180" fill="url(#river)"/>
<g filter="url(#blur)">{bokeh(26, 0, 880, W, 1040, ['#ffb36b', '#ff8fb1', '#ffd36b'], 10, 26, 6, (.4, .8))}</g>
{''.join(lanterns)}
{string_lights(420, 120, 3, ['#ffe7a3', '#ffc1d9', '#ffffff'])}
<rect x="0" y="1040" width="{W}" height="360" fill="#4a3160"/><rect x="0" y="1030" width="{W}" height="22" fill="#6b4880"/>
</svg>"""


def scene_restaurant():
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}">{DEFS}
<linearGradient id="wall" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#4a2341"/><stop offset="1" stop-color="#7b3b5f"/></linearGradient>
<rect width="{W}" height="{H}" fill="url(#wall)"/>
<!-- wainscot panels -->
<g fill="none" stroke="#a45f84" stroke-width="5" opacity=".55">{''.join(f'<rect x="{40 + i * 290}" y="560" width="250" height="440" rx="10"/>' for i in range(4))}</g>
<rect x="0" y="540" width="{W}" height="14" fill="#b5729a" opacity=".6"/>
<!-- chandelier -->
<circle cx="600" cy="210" r="260" fill="#ffcf8a" opacity=".22" filter="url(#glow)"/>
<line x1="600" y1="0" x2="600" y2="140" stroke="#d7a76a" stroke-width="5"/>
<path d="M440 210 Q 600 300 760 210" stroke="#d7a76a" stroke-width="8" fill="none"/>
<g fill="#fff0c9">{''.join(f'<circle cx="{x}" cy="{y}" r="12"/>' for x, y in [(440, 200), (520, 236), (600, 248), (680, 236), (760, 200)])}</g>
<g fill="#ffd27a" opacity=".55" filter="url(#glow)">{''.join(f'<circle cx="{x}" cy="{y}" r="30"/>' for x, y in [(440, 200), (520, 236), (600, 248), (680, 236), (760, 200)])}</g>
<!-- framed art -->
<rect x="130" y="250" width="200" height="240" rx="8" fill="#2f1730" stroke="#d7a76a" stroke-width="10"/>
<circle cx="230" cy="360" r="60" fill="#e48aa8" opacity=".7"/>
<rect x="870" y="250" width="200" height="240" rx="8" fill="#2f1730" stroke="#d7a76a" stroke-width="10"/>
<path d="M900 450 Q 970 300 1040 450 Z" fill="#a679c9" opacity=".7"/>
<g filter="url(#blur)">{bokeh(16, 0, 600, W, 1000, ['#ffcf8a', '#ff9fc0'], 14, 34, 8, (.25, .55))}</g>
<rect x="0" y="1040" width="{W}" height="360" fill="#3a1a33"/><rect x="0" y="1030" width="{W}" height="22" fill="#5e2b4f"/>
</svg>"""


def scene_rooftop():
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}">{DEFS}
<linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#6d7fd6"/><stop offset=".45" stop-color="#e59ac0"/><stop offset=".8" stop-color="#ffc79b"/><stop offset="1" stop-color="#ffe0b8"/></linearGradient>
<rect width="{W}" height="{H}" fill="url(#sky)"/>
<circle cx="600" cy="880" r="170" fill="#fff0cf"/><circle cx="600" cy="880" r="320" fill="#ffd9a8" opacity=".45" filter="url(#glow)"/>
<g fill="#ffffff" opacity=".6"><ellipse cx="240" cy="260" rx="160" ry="34"/><ellipse cx="330" cy="236" rx="100" ry="30"/><ellipse cx="930" cy="380" rx="180" ry="30"/><ellipse cx="1010" cy="356" rx="90" ry="26"/></g>
<path d="M0 900 h80 v-160 h70 v100 h60 v-220 h90 v280 h70 v-140 h60 v-60 h80 v200 h60 v-120 h70 v-260 h80 v380 h60 v-160 h80 v100 h70 v-200 h90 v260 h80 V1060 H0 Z" fill="#8b5c8f" opacity=".85"/>
{string_lights(140, 140, 5, ['#fff1c2', '#ffd0e4'])}
<!-- railing -->
<g stroke="#fff" stroke-width="7" opacity=".8"><line x1="0" y1="930" x2="{W}" y2="930"/>{''.join(f'<line x1="{x}" y1="930" x2="{x}" y2="1040"/>' for x in range(20, W, 60))}</g>
<rect x="0" y="1040" width="{W}" height="360" fill="#b27a9d"/><rect x="0" y="1030" width="{W}" height="22" fill="#c98eb2"/>
</svg>"""


def scene_park():
    rnd = random.Random(21)
    petals = "".join(f'<ellipse cx="{rnd.uniform(0, W):.0f}" cy="{rnd.uniform(0, 1040):.0f}" rx="9" ry="5" '
                     f'transform="rotate({rnd.uniform(0, 180):.0f} 0 0)" fill="#ffc4da" opacity=".0"/>' for _ in range(1))
    blossoms = bokeh(160, -60, -60, 520, 360, ['#ffb7d0', '#ffd1e1', '#f79bbd', '#fff'], 18, 46, 13, (.7, 1)) + \
               bokeh(160, 700, -60, 1260, 300, ['#ffb7d0', '#ffd1e1', '#f79bbd', '#fff'], 18, 46, 14, (.7, 1))
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}">{DEFS}
<linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#bcd9f7"/><stop offset="1" stop-color="#f7e3f1"/></linearGradient>
<rect width="{W}" height="{H}" fill="url(#sky)"/>
<path d="M0 760 Q 300 640 620 740 T 1200 700 V1060 H0 Z" fill="#b9d8b0"/>
<path d="M0 860 Q 400 760 800 850 T 1200 820 V1060 H0 Z" fill="#9cc79a"/>
<path d="M180 1060 C 200 700 160 500 120 300" stroke="#7a5263" stroke-width="40" fill="none"/>
<path d="M1040 1060 C 1020 700 1060 480 1100 260" stroke="#7a5263" stroke-width="40" fill="none"/>
<g filter="url(#soft)">{blossoms}</g>
{petals}
<rect x="0" y="1040" width="{W}" height="360" fill="#e6c6d8"/><rect x="0" y="1030" width="{W}" height="22" fill="#d7aec6"/>
</svg>"""


def foreground(top, edge, items):
    """Table across the bottom of the scene; drawn ABOVE the characters."""
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}">{DEFS}
<ellipse cx="600" cy="1150" rx="640" ry="70" fill="#000" opacity=".18" filter="url(#shadow)"/>
<path d="M-40 1130 Q 600 1060 1240 1130 V1400 H-40 Z" fill="{edge}"/>
<path d="M-40 1110 Q 600 1040 1240 1110 V1170 Q 600 1110 -40 1170 Z" fill="{top}"/>
<path d="M-40 1110 Q 600 1040 1240 1110" stroke="#fff" stroke-width="5" fill="none" opacity=".55"/>
{items}
</svg>"""


def cup(x, y, s=1.0, c="#ffffff"):
    return (f'<g transform="translate({x} {y}) scale({s})">'
            f'<ellipse cx="0" cy="40" rx="78" ry="16" fill="#000" opacity=".12"/>'
            f'<ellipse cx="0" cy="34" rx="70" ry="14" fill="{c}"/>'
            f'<path d="M-46 -30 h92 l-8 58 q-38 14 -76 0 Z" fill="{c}"/>'
            f'<path d="M44 -14 q30 0 26 20 q-4 18 -30 14" stroke="{c}" stroke-width="10" fill="none"/>'
            f'<ellipse cx="0" cy="-30" rx="46" ry="11" fill="#b77a52"/>'
            f'<path d="M-10 -32 q10 -10 20 0 q-10 8 -20 0" fill="#f6dccb"/></g>')


def flowers(x, y):
    rnd = random.Random(int(x))
    blooms = "".join(f'<circle cx="{x + rnd.uniform(-60, 60):.0f}" cy="{y - 70 + rnd.uniform(-40, 30):.0f}" r="{rnd.uniform(12, 20):.0f}" '
                     f'fill="{rnd.choice(["#ff9fc4", "#ffc6dc", "#f37fae", "#ffe1ee"])}"/>' for _ in range(26))
    return (f'<g><path d="M{x - 34} {y - 30} h68 l-10 76 h-48 Z" fill="#ffffff" opacity=".55"/>'
            f'<g filter="url(#soft)">{blooms}</g></g>')


def candle(x, y):
    return (f'<g><circle cx="{x}" cy="{y - 70}" r="60" fill="#ffcf7a" opacity=".45" filter="url(#glow)"/>'
            f'<rect x="{x - 26}" y="{y - 50}" width="52" height="80" rx="10" fill="#fff6ea" opacity=".9"/>'
            f'<path d="M{x} {y - 86} q14 18 0 30 q-14 -12 0 -30" fill="#ffd27a"/></g>')


def glass(x, y):
    return (f'<g opacity=".9"><path d="M{x - 30} {y - 120} h60 q0 70 -30 80 q-30 -10 -30 -80 Z" fill="#ffffff" opacity=".45"/>'
            f'<path d="M{x - 26} {y - 80} h52 q-4 34 -26 40 q-22 -6 -26 -40 Z" fill="#c2335f" opacity=".85"/>'
            f'<line x1="{x}" y1="{y - 40}" x2="{x}" y2="{y + 20}" stroke="#ffffff" stroke-width="6" opacity=".6"/>'
            f'<ellipse cx="{x}" cy="{y + 22}" rx="30" ry="8" fill="#ffffff" opacity=".5"/></g>')


SCENES = {
    "cafe": (scene_cafe, ("#f2e6ee", "#c99ab8", cup(300, 1130) + cup(900, 1130) + flowers(600, 1150))),
    "hotel": (scene_hotel, ("#2c2140", "#1b1229", glass(380, 1140) + glass(820, 1140) + candle(600, 1150))),
    "festival": (scene_festival, ("#e9c79e", "#a4734c", cup(320, 1130, .9, '#ffe3ec') + cup(880, 1130, .9, '#e9f2ff') + candle(600, 1150))),
    "restaurant": (scene_restaurant, ("#fdf4f6", "#b98aa5", glass(360, 1140) + glass(840, 1140) + candle(600, 1150) + flowers(600, 1120))),
    "rooftop": (scene_rooftop, ("#fff7f1", "#d29bbd", glass(330, 1140) + glass(870, 1140) + flowers(600, 1150))),
    "park": (scene_park, ("#f3dfc4", "#c49b72", cup(320, 1130, .9, '#fff') + cup(880, 1130, .9, '#ffe3ec') + flowers(600, 1150))),
}


def make_scenes():
    for name, (bg, (top, edge, items)) in SCENES.items():
        imageset(f"scene_{name}", svg_to_png(bg(), W, H).convert("RGB"))
        imageset(f"scene_{name}_fg", svg_to_png(foreground(top, edge, items), W, H))


# ---------------------------------------------------------------- heart, particles, icon
HEART_PATH = "M256 448 C 120 350 32 268 32 168 C 32 98 86 48 152 48 C 196 48 234 72 256 110 C 278 72 316 48 360 48 C 426 48 480 98 480 168 C 480 268 392 350 256 448 Z"


def heart_svg(size=512, glow=True):
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="-64 -64 640 640">
<defs>
 <radialGradient id="g" cx=".35" cy=".3" r=".85"><stop offset="0" stop-color="#ffb8da"/><stop offset=".45" stop-color="#ff5fa8"/><stop offset="1" stop-color="#d42a7c"/></radialGradient>
 <linearGradient id="hl" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity=".9"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>
 <filter id="glow" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="22"/></filter>
</defs>
{'<path d="' + HEART_PATH + '" fill="#ff6fb5" opacity=".65" filter="url(#glow)"/>' if glow else ''}
<path d="{HEART_PATH}" fill="url(#g)"/>
<path d="{HEART_PATH}" fill="none" stroke="#fff" stroke-opacity=".55" stroke-width="10"/>
<ellipse cx="160" cy="140" rx="70" ry="44" fill="url(#hl)" transform="rotate(-28 160 140)"/>
<circle cx="345" cy="120" r="16" fill="#fff" opacity=".75"/>
</svg>"""


def make_misc():
    imageset("tap_heart", svg_to_png(heart_svg(), 640, 640))
    imageset("particle_heart", svg_to_png(
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512"><path d="{HEART_PATH}" fill="#fff"/></svg>', 64, 64))
    imageset("particle_sparkle", svg_to_png(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="-50 -50 100 100"><path d="M0 -48 C 6 -10 10 -6 48 0 C 10 6 6 10 0 48 C -6 10 -10 6 -48 0 C -10 -6 -6 -10 0 -48 Z" fill="#fff"/></svg>', 64, 64))
    # app icon (no alpha allowed)
    icon = f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">
<defs>
 <radialGradient id="bg" cx=".5" cy=".38" r=".8"><stop offset="0" stop-color="#a15fd0"/><stop offset=".6" stop-color="#5b2d86"/><stop offset="1" stop-color="#2c1547"/></radialGradient>
 <radialGradient id="g" cx=".35" cy=".3" r=".85"><stop offset="0" stop-color="#ffc4e0"/><stop offset=".45" stop-color="#ff5fa8"/><stop offset="1" stop-color="#cf2477"/></radialGradient>
 <linearGradient id="hl" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity=".9"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>
 <filter id="glow" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="40"/></filter>
</defs>
<rect width="1024" height="1024" fill="url(#bg)"/>
{bokeh(40, 40, 40, 984, 984, ['#ffffff', '#ffc4e0'], 2, 6, 31, (.3, .8))}
<g transform="translate(152 190) scale(1.40625)">
  <path d="{HEART_PATH}" fill="#ff5fae" opacity=".7" filter="url(#glow)"/>
  <path d="{HEART_PATH}" fill="url(#g)"/>
  <path d="{HEART_PATH}" fill="none" stroke="#fff" stroke-opacity=".6" stroke-width="12"/>
  <ellipse cx="160" cy="140" rx="74" ry="46" fill="url(#hl)" transform="rotate(-28 160 140)"/>
</g>
<g fill="#fff"><path transform="translate(790 230) scale(1.6)" d="M0 -48 C 6 -10 10 -6 48 0 C 10 6 6 10 0 48 C -6 10 -10 6 -48 0 C -10 -6 -6 -10 0 -48 Z"/>
<path transform="translate(230 760) scale(.8)" d="M0 -48 C 6 -10 10 -6 48 0 C 10 6 6 10 0 48 C -6 10 -10 6 -48 0 C -10 -6 -6 -10 0 -48 Z" opacity=".85"/></g>
</svg>"""
    d = os.path.join(XC, "AppIcon.appiconset"); os.makedirs(d, exist_ok=True)
    svg_to_png(icon, 1024, 1024).convert("RGB").save(os.path.join(d, "AppIcon.png"))
    json.dump({"images": [{"filename": "AppIcon.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"}],
               "info": {"author": "xcode", "version": 1}}, open(os.path.join(d, "Contents.json"), "w"), indent=2)
    # accent color
    d = os.path.join(XC, "AccentColor.colorset"); os.makedirs(d, exist_ok=True)
    json.dump({"colors": [{"idiom": "universal", "color": {"color-space": "srgb", "components":
              {"red": "0.937", "green": "0.333", "blue": "0.604", "alpha": "1.000"}}}],
               "info": {"author": "xcode", "version": 1}}, open(os.path.join(d, "Contents.json"), "w"), indent=2)
    # launch screen
    d = os.path.join(XC, "LaunchBackground.colorset"); os.makedirs(d, exist_ok=True)
    json.dump({"colors": [{"idiom": "universal", "color": {"color-space": "srgb", "components":
              {"red": "0.231", "green": "0.141", "blue": "0.322", "alpha": "1.000"}}}],
               "info": {"author": "xcode", "version": 1}}, open(os.path.join(XC, "LaunchBackground.colorset", "Contents.json"), "w"), indent=2)
    imageset("LaunchLogo", svg_to_png(heart_svg(), 240, 240))
    json.dump({"info": {"author": "xcode", "version": 1}}, open(os.path.join(XC, "Contents.json"), "w"), indent=2)


if __name__ == "__main__":
    os.makedirs(XC, exist_ok=True)
    sheet = Image.open(SRC).convert("RGB")
    make_portraits(sheet)
    make_chibis(sheet)
    make_scenes()
    make_misc()
    print("assets written to", XC)
