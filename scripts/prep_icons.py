"""One-off helper: derive icon/splash source images from the two supplied
logo assets (assets/logo/logo_transparent.png, assets/logo/logo_white.jpeg).

Run once with `python scripts/prep_icons.py`, then delete/ignore — the
generated files under assets/logo/generated/ are committed so
flutter_launcher_icons / flutter_native_splash can consume them without
requiring Pillow at build time.
"""

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
LOGO_DIR = ROOT / "assets" / "logo"
OUT_DIR = LOGO_DIR / "generated"
OUT_DIR.mkdir(parents=True, exist_ok=True)

CANVAS = 1024


def trim_transparent(img: Image.Image) -> Image.Image:
    """Crop to the bounding box of non-transparent pixels."""
    alpha = img.getchannel("A")
    bbox = alpha.getbbox()
    return img.crop(bbox) if bbox else img


def square_canvas(img: Image.Image, size: int, margin_ratio: float, bg=(0, 0, 0, 0)) -> Image.Image:
    """Paste `img` centered onto a square canvas of `size`, leaving
    `margin_ratio` of the canvas as empty border on every side."""
    usable = int(size * (1 - 2 * margin_ratio))
    scale = min(usable / img.width, usable / img.height)
    new_w, new_h = int(img.width * scale), int(img.height * scale)
    resized = img.resize((new_w, new_h), Image.LANCZOS)

    canvas = Image.new("RGBA", (size, size), bg)
    x = (size - new_w) // 2
    y = (size - new_h) // 2
    canvas.paste(resized, (x, y), resized if resized.mode == "RGBA" else None)
    return canvas


# --- source images -----------------------------------------------------
transparent = Image.open(LOGO_DIR / "logo_transparent.png").convert("RGBA")
transparent_trimmed = trim_transparent(transparent)

white_flat = Image.open(LOGO_DIR / "logo_white.jpeg").convert("RGB")

# 1. App icon (iOS / default Android) — flattened, opaque, small margin.
icon_bg = (254, 249, 241, 255)  # warm cream, matches --background token
icon_source = square_canvas(transparent_trimmed, CANVAS, margin_ratio=0.08, bg=icon_bg)
icon_source.convert("RGB").save(OUT_DIR / "icon_source.png")

# 2. Android adaptive icon foreground — extra padding so the mark survives
#    the circle/squircle/rounded-square system masks.
adaptive_fg = square_canvas(transparent_trimmed, CANVAS, margin_ratio=0.22, bg=(0, 0, 0, 0))
adaptive_fg.save(OUT_DIR / "icon_adaptive_foreground.png")

# 3. Splash logo — transparent, modest size, generous padding (native
#    splash centers it on a solid background color).
splash_logo = square_canvas(transparent_trimmed, CANVAS, margin_ratio=0.30, bg=(0, 0, 0, 0))
splash_logo.save(OUT_DIR / "splash_logo.png")

print("Generated:")
for f in sorted(OUT_DIR.iterdir()):
    print(" -", f.relative_to(ROOT))
