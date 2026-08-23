from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


LEGACY_ICON_SIZES: dict[str, int] = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

ADAPTIVE_ICON_SIZES: dict[str, tuple[int, int]] = {
    "mipmap-mdpi": (108, 72),
    "mipmap-hdpi": (162, 108),
    "mipmap-xhdpi": (216, 144),
    "mipmap-xxhdpi": (324, 216),
    "mipmap-xxxhdpi": (432, 288),
}


def parse_arguments() -> argparse.Namespace:
    parser: argparse.ArgumentParser = argparse.ArgumentParser(
        description="Generate Clock Rhythm launcher icons from the audited source PNG."
    )
    parser.add_argument("source", type=Path)
    parser.add_argument("workspace", type=Path)
    return parser.parse_args()


def resized(source: Image.Image, size: int) -> Image.Image:
    return source.resize((size, size), Image.Resampling.LANCZOS)


def adaptive_foreground(
    source: Image.Image,
    canvas_size: int,
    image_size: int,
) -> Image.Image:
    foreground: Image.Image = Image.new(
        "RGBA",
        (canvas_size, canvas_size),
        (0, 0, 0, 0),
    )
    icon: Image.Image = resized(source, image_size)
    offset: int = (canvas_size - image_size) // 2
    foreground.alpha_composite(icon, (offset, offset))
    return foreground


def generate_android_icons(source: Image.Image, workspace: Path) -> None:
    resource_root: Path = workspace / "android" / "app" / "src" / "main" / "res"
    for density, size in LEGACY_ICON_SIZES.items():
        destination: Path = resource_root / density
        destination.mkdir(parents=True, exist_ok=True)
        icon: Image.Image = resized(source, size)
        icon.save(destination / "ic_launcher.png", format="PNG", optimize=True)
        icon.save(destination / "ic_launcher_round.png", format="PNG", optimize=True)

    for density, sizes in ADAPTIVE_ICON_SIZES.items():
        destination = resource_root / density
        foreground: Image.Image = adaptive_foreground(source, sizes[0], sizes[1])
        foreground.save(
            destination / "ic_launcher_foreground.png",
            format="PNG",
            optimize=True,
        )


def generate_windows_icon(source: Image.Image, workspace: Path) -> None:
    destination: Path = workspace / "windows" / "runner" / "resources" / "app_icon.ico"
    destination.parent.mkdir(parents=True, exist_ok=True)
    source.save(
        destination,
        format="ICO",
        sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64)],
    )


def main() -> int:
    arguments: argparse.Namespace = parse_arguments()
    source_path: Path = arguments.source.resolve(strict=True)
    workspace: Path = arguments.workspace.resolve(strict=True)
    if not (workspace / "pubspec.yaml").is_file():
        raise ValueError(f"Not a Flutter workspace: {workspace}")

    with Image.open(source_path) as opened_image:
        source: Image.Image = opened_image.convert("RGBA")
        if source.width != source.height:
            raise ValueError("Launcher icon source must be square.")
        generate_android_icons(source, workspace)
        generate_windows_icon(source, workspace)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
