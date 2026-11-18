#!/usr/bin/env python3
"""PureShell's logo: a spiral seashell (a conch), lying on a slant, its spire up to the right and its mouth
down to the left. Creamy whites, soft warm shading, a peach blush inside the mouth, a fine taupe outline and a
faint shadow under it. Writes the SVGs here and renders the PNGs with rsvg-convert:   python3 make.py
"""
import math, os, subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
INK, CREAM = "#2a2520", "#edeae4"
LINE = "#b9ab97"           # the outline and the sutures: a soft warm taupe, not ink

# the shell is drawn along its own axis (the mouth at x = 0, the tip at x = LEN), then turned onto the slant
LEN = 380
WHORLS = [0, 150, 245, 305, 343, 366, LEN]      # where each whorl meets the next, mouth to tip


def half(x):
    """the shell's half-width at x: a cone, each whorl swelling a little in its middle"""
    base = 136 * (1 - x / (LEN + 18)) ** 0.85
    for a, b in zip(WHORLS, WHORLS[1:]):
        if a <= x <= b:
            t = (x - a) / (b - a)
            return base * (1 + 0.15 * math.sin(math.pi * t))
    return base


# the mouth: the open wide end, seen on a slant (an upright oval, narrow across)
H1, H2 = None, None
def mouth_oval(grow=0.0, rx=58, shift=0.0):
    h1, h2 = half(0), half(0) * 0.86
    cy, ry = (h2 - h1) / 2, (h1 + h2) / 2 + grow
    return [(shift + (rx + grow) * math.cos(t), cy + ry * math.sin(t)) for t in (i / 90 * 2 * math.pi for i in range(91))]


def outline():
    top = [(x, -half(x)) for x in range(0, LEN + 1, 4)]
    bot = [(x, half(x) * 0.86) for x in range(LEN, -1, -4)]      # the underside a touch flatter
    # round the wide end with the mouth's far (left) half
    h1, h2 = half(0), half(0) * 0.86
    cy, ry = (h2 - h1) / 2, (h1 + h2) / 2
    left = [(-62 * math.sin(t), cy + ry * math.cos(t)) for t in (i / 40 * math.pi for i in range(41))]
    return top + bot + left


def turn(pts, deg=-32, cx=0, cy=0, dx=0, dy=0):
    a = math.radians(deg)
    return [(dx + (x - cx) * math.cos(a) - (y - cy) * math.sin(a), dy + (x - cx) * math.sin(a) + (y - cy) * math.cos(a)) for x, y in pts]


def path(pts, close=True):
    return "M " + " L ".join(f"{x:.1f} {y:.1f}" for x, y in pts) + (" Z" if close else "")


def suture(a):
    """the line where whorl a meets the next: slanting across the shell, bowed toward the tip"""
    h1, h2 = half(a), half(a) * 0.86
    pts = []
    for i in range(21):
        t = i / 20
        y = -h1 + (h1 + h2) * t
        x = a + 26 * math.sin(math.pi * t) - 18 * t
        pts.append((x, y))
    return pts


def shell(place):
    """the drawing; `place` turns the shell's axis points onto the canvas"""
    body = path(place(outline()))
    # soft beige bands along each whorl, following the spiral (parallel to its suture), faint
    bands = ""
    for a, b in zip(WHORLS[1:-2], WHORLS[2:-1]):
        for f in (0.5,):
            x = a + (b - a) * f
            band = [(px + (x - a), py) for px, py in suture(a)]
            bands += (f'<path d="{path(place(band), False)}" fill="none" stroke="#d8c7ad" stroke-width="{9 * (b - a) / 100:.1f}" '
                      f'stroke-linecap="round" opacity="0.55"/>')
    # and one on the big body whorl, between the mouth and its suture
    band = [(px - 52, py) for px, py in suture(WHORLS[1])]
    bands += (f'<path d="{path(place(band), False)}" fill="none" stroke="#d8c7ad" stroke-width="12" '
              f'stroke-linecap="round" opacity="0.45"/>')
    lines = "".join(f'<path d="{path(place(suture(a)), False)}" fill="none" stroke="{LINE}" stroke-width="4" '
                    f'stroke-linecap="round" opacity="0.85"/>' for a in WHORLS[1:-1])
    # fine growth lines along the body whorl, faint
    growth = "".join(f'<path d="{path(place([(x, -half(x) * 0.93), (x - 8, half(x) * 0.8)]), False)}" '
                     f'fill="none" stroke="{LINE}" stroke-width="2" stroke-linecap="round" opacity="0.3"/>'
                     for x in range(78, 150, 18))
    # the mouth: its lip (a lighter cream ring), the peach inside, deeper toward the tip, and the curl of the
    # spiral just showing within
    lip = mouth_oval(grow=6, rx=58)
    inner = mouth_oval(grow=-16, rx=40, shift=8)
    h1, h2 = half(0), half(0) * 0.86
    cy = (h2 - h1) / 2
    curl = [(14 + 22 * math.cos(t), cy - 6 + 46 * math.sin(t)) for t in (math.pi * (0.6 + 0.9 * i / 30) for i in range(31))]
    tip = place([(LEN, 0)])[0]
    return f'''
<defs>
  <linearGradient id="body" x1="0" y1="0" x2="0.35" y2="1">
    <stop offset="0" stop-color="#fbf9f5"/>
    <stop offset="0.55" stop-color="#efe9df"/>
    <stop offset="1" stop-color="#ddd3c3"/>
  </linearGradient>
  <radialGradient id="mouth" cx="0.62" cy="0.45" r="0.7">
    <stop offset="0" stop-color="#d9a993"/>
    <stop offset="0.6" stop-color="#ecc9b7"/>
    <stop offset="1" stop-color="#f6e3d6"/>
  </radialGradient>
  <filter id="soft" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="10"/></filter>
</defs>
<ellipse cx="{place([(LEN * 0.42, 0)])[0][0]:.0f}" cy="{place([(LEN * 0.42, 0)])[0][1] + 118:.0f}" rx="190" ry="26" fill="#6b5a48" opacity="0.18" filter="url(#soft)"/>
<path d="{body}" fill="url(#body)" stroke="{LINE}" stroke-width="5" stroke-linejoin="round"/>
<clipPath id="inside"><path d="{body}"/></clipPath>
<g clip-path="url(#inside)">{bands}</g>
{lines}
<path d="{path(place(lip))}" fill="#fbf8f3" stroke="{LINE}" stroke-width="4"/>
<path d="{path(place(inner))}" fill="url(#mouth)"/>
<path d="{path(place(curl), False)}" fill="none" stroke="#c9947f" stroke-width="5" stroke-linecap="round" opacity="0.55"/>
<circle cx="{tip[0]:.1f}" cy="{tip[1]:.1f}" r="5" fill="{LINE}"/>
'''


def svg(body, w=512, h=512, bg=None, radius=0):
    back = f'<rect width="{w}" height="{h}" rx="{radius}" fill="{bg}"/>' if bg else ""
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}">{back}{body}</svg>\n'


def write(name, text, png_size=None):
    path_ = os.path.join(HERE, name)
    open(path_, "w").write(text)
    if png_size:
        subprocess.run(["rsvg-convert", "-w", str(png_size), "-o", path_.replace(".svg", ".png"), path_], check=True)


# on the slant, centred in 512 × 512
center = lambda s=1.0, ox=270, oy=236: (lambda pts: [(ox + x * s, oy + y * s) for x, y in turn(pts, -32, LEN * 0.45, 0)])
write("logo.svg", svg(shell(center())), 512)
write("logo-dark.svg", svg(shell(center())), 512)          # (cream already: it sits on dark as it is)
write("icon.svg", svg(shell(center(0.8)), bg=CREAM, radius=116), 512)
write("icon-dark.svg", svg(shell(center(0.8)), bg=INK, radius=116), 512)
word = lambda ink: svg(f'<g transform="translate(0 -28) scale(0.44)">{shell(center())}</g>'
                       f'<text x="222" y="132" font-family="Google Sans Flex" font-size="100" font-weight="600" '
                       f'letter-spacing="-2" fill="{ink}">PureShell</text>', w=760, h=200)
write("wordmark.svg", word(INK), 1520)
write("wordmark-dark.svg", word(CREAM), 1520)
print("logo: written")
