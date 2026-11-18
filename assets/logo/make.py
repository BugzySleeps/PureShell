#!/usr/bin/env python3
"""PureShell's logo: a scallop seashell. A soft fan with a scalloped top edge, ribs running out from the hinge, and
the two little ears at its base. Charcoal on cream (and the cream on charcoal for dark). Writes the SVGs here and
renders the PNGs with rsvg-convert:   python3 make.py
"""
import math, os, subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
INK, CREAM = "#2a2520", "#edeae4"

N = 9                      # ribs
CX, CY = 256, 418          # the hinge
R, LOBE = 232, 15          # the fan's reach, and how deep its scallops go
SPAN = (32, 148)           # the fan, in degrees (0 = right, 90 = up)


def edge_r(t):
    """the scalloped edge's radius at angle t (degrees): a round lobe at every rib's end"""
    a0, a1 = SPAN
    f = (t - a0) / (a1 - a0) * N                  # 0 … N across the fan
    lobe = abs(math.sin(math.pi * f))             # 0 at the grooves, 1 mid-lobe
    tall = 1 + 0.16 * math.sin(math.radians(t))   # rounder and taller than a fan
    return R * tall + LOBE * (lobe ** 0.6) - LOBE


def pt(t, r):
    a = math.radians(t)
    return CX + r * math.cos(a), CY - r * math.sin(a)


def shell(fill, groove):
    a0, a1 = SPAN
    # the body: the scalloped edge, then down its sides to the ears
    edge = [pt(a0 + (a1 - a0) * i / 720, edge_r(a0 + (a1 - a0) * i / 720)) for i in range(721)]
    body = "M %.1f %.1f " % (CX, CY + 6) + " ".join("L %.1f %.1f" % p for p in edge) + " Z"
    # the ears: a softly rounded band across the hinge, wider than its base
    ears = (f"M {CX - 74} {CY - 34} Q {CX - 82} {CY + 4} {CX - 50} {CY + 12} "
            f"L {CX + 50} {CY + 12} Q {CX + 82} {CY + 4} {CX + 74} {CY - 34} "
            f"L {CX + 30} {CY - 52} L {CX - 30} {CY - 52} Z")
    # the grooves: between the lobes, from near the hinge to just short of the edge, widening outward
    grooves = []
    for k in range(1, N):
        t = a0 + (a1 - a0) * k / N
        x0, y0 = pt(t, 46)
        r1 = edge_r(t) - 14
        a = math.radians(t)
        nx, ny = math.sin(a), math.cos(a)         # across the groove
        x1, y1 = pt(t, r1)
        w0, w1 = 1.5, 6.5
        grooves.append(f"M {x0 - nx * w0:.1f} {y0 - ny * w0:.1f} L {x1 - nx * w1:.1f} {y1 - ny * w1:.1f} "
                       f"Q {x1:.1f} {y1:.1f} {x1 + nx * w1:.1f} {y1 + ny * w1:.1f} L {x0 + nx * w0:.1f} {y0 + ny * w0:.1f} Z")
    # a groove under the ears, where they meet the fan
    seam = f"M {CX - 66} {CY - 28} Q {CX} {CY - 16} {CX + 66} {CY - 28}"
    return (f'<path d="{body}" fill="{fill}"/>'
            f'<path d="{ears}" fill="{fill}"/>'
            + "".join(f'<path d="{g}" fill="{groove}"/>' for g in grooves)
            + f'<path d="{seam}" fill="none" stroke="{groove}" stroke-width="5" stroke-linecap="round"/>')


def svg(body, w=512, h=512, bg=None, radius=0):
    back = f'<rect width="{w}" height="{h}" rx="{radius}" fill="{bg}"/>' if bg else ""
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}">{back}{body}</svg>\n'


def write(name, text, png_size=None):
    path = os.path.join(HERE, name)
    open(path, "w").write(text)
    if png_size:
        subprocess.run(["rsvg-convert", "-w", str(png_size), "-o", path.replace(".svg", ".png"), path], check=True)


# the shell alone (charcoal), and for dark (the cream)
write("logo.svg", svg(shell(INK, CREAM)), 512)
write("logo-dark.svg", svg(shell(CREAM, INK)), 512)
# an app icon: the shell on a cream squircle (and the reverse)
icon = lambda f, g, bg: svg(f'<g transform="translate(64 44) scale(0.75)">{shell(f, g)}</g>', bg=bg, radius=116)
write("icon.svg", icon(INK, CREAM, CREAM), 512)
write("icon-dark.svg", icon(CREAM, INK, INK), 512)
# the wordmark: the shell and the name
word = lambda f, g: svg(f'<g transform="translate(10 18) scale(0.36)">{shell(f, g)}</g>'
                        f'<text x="212" y="140" font-family="Google Sans Flex" font-size="104" font-weight="600" '
                        f'letter-spacing="-2" fill="{f}">PureShell</text>', w=760, h=200)
write("wordmark.svg", word(INK, CREAM), 1520)
write("wordmark-dark.svg", word(CREAM, INK), 1520)
print("logo: written")
