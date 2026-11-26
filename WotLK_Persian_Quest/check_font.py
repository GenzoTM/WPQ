# Usage: python check_font.py MyFont.ttf
import sys
from fontTools.ttLib import TTFont
f = TTFont(sys.argv[1]); cmap = f.getBestCmap()
rng = list(range(0xFB50, 0xFBC2)) + list(range(0xFBD3, 0xFBFF)) + list(range(0xFE70, 0xFEFD))
have = [c for c in rng if c in cmap]
key = {"yeh (ی) final/medial": [0xFBFC,0xFBFD,0xFBFE,0xFBFF], "keheh (ک)": [0xFB8E,0xFB8F,0xFB90,0xFB91],
       "peh (پ)": [0xFB56,0xFB57,0xFB58,0xFB59], "cheh (چ)": [0xFB7A,0xFB7B,0xFB7C,0xFB7D],
       "jeh (ژ)": [0xFB8A,0xFB8B], "gaf (گ)": [0xFB92,0xFB93,0xFB94,0xFB95], "alef/lam": [0xFE8D,0xFEDD]}
print("Presentation forms found: %d of %d" % (len(have), len(rng)))
for k, v in key.items():
    print(("OK      " if all(c in cmap for c in v) else "MISSING ") + k)
