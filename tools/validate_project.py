from pathlib import Path
import re
import wave

ROOT = Path(__file__).resolve().parents[1]
errors = []

required = [
    "project.godot",
    "scenes/main/Main.tscn",
    "scripts/main.gd",
    "scripts/player/player_controller.gd",
    "scripts/autoload/game_manager.gd",
    "scripts/autoload/economy_manager.gd",
    "scripts/autoload/save_manager.gd",
]
for rel in required:
    if not (ROOT / rel).is_file():
        errors.append(f"Missing required file: {rel}")

for path in ROOT.rglob("*"):
    if not path.is_file() or path.suffix not in {".gd", ".tscn", ".godot", ".cfg"}:
        continue
    text = path.read_text(encoding="utf-8", errors="replace")
    for ref in re.findall(r"res://[^\"'\s)]+", text):
        target = ROOT / ref.removeprefix("res://")
        if not target.exists():
            errors.append(f"Broken resource reference in {path.relative_to(ROOT)}: {ref}")

# Every audio file used by AudioManager must exist and be a readable WAV.
audio_manager = (ROOT / "scripts/autoload/audio_manager.gd").read_text(encoding="utf-8")
for rel in re.findall(r'"(res://assets/audio/[^" ]+\.wav)"', audio_manager):
    target = ROOT / rel.removeprefix("res://")
    if not target.is_file():
        errors.append(f"Missing audio resource: {rel}")
        continue
    try:
        with wave.open(str(target), "rb") as audio:
            audio.getparams()
            if audio.getnframes() <= 0:
                errors.append(f"Empty audio resource: {rel}")
    except Exception as exc:
        errors.append(f"Unreadable WAV {rel}: {exc}")

if errors:
    print("VALIDATION FAILED")
    print("\n".join(f"- {item}" for item in errors))
    raise SystemExit(1)
print("Static project validation passed.")
print("Note: this does not replace Godot parsing, gameplay testing, or Android device testing.")
