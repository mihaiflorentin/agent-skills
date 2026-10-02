#!/usr/bin/env python3
"""Tile screenshots into one image so a visual review costs one image read instead of many.

    contact-sheet.py OUT.png [--cols 2] [--width 900] IMG [IMG ...]

Pass before/after pairs in order (before1 after1 before2 after2 ...) with --cols 2 to compare side by side.
"""
import argparse
from PIL import Image

ap = argparse.ArgumentParser()
ap.add_argument("out"); ap.add_argument("images", nargs="+")
ap.add_argument("--cols", type=int, default=2); ap.add_argument("--width", type=int, default=900)
a = ap.parse_args()
ims = [Image.open(p).convert("RGB") for p in a.images]
ims = [i.resize((a.width, max(1, int(i.height * a.width / i.width)))) for i in ims]
h = max(i.height for i in ims); rows = (len(ims) + a.cols - 1) // a.cols
sheet = Image.new("RGB", (a.cols * a.width, rows * h), "white")
for k, i in enumerate(ims):
    sheet.paste(i, ((k % a.cols) * a.width, (k // a.cols) * h))
sheet.save(a.out)
print(f"{a.out}: {len(ims)} images, {a.cols}x{rows}")
