# CAYPER SM 1.0.0 — Build status

## Implemented in source

- Playable third-person controller and mobile touch controls.
- Procedural neighborhood and cyber cafe scene generation.
- Interactable NPCs, computers, shop, home, job board and cashier.
- Cafe management and daily accounting loop.
- Inventory, needs, jobs, quests, money, XP, reputation and progression.
- Three-slot save/load with extra gameplay state and audio settings.
- Procedural sound assets and audio controls.

## Checks performed for this archive

- Project and scene entry points exist.
- Every audio path referenced by AudioManager exists.
- WAV assets can be opened and decoded by Python's WAV reader.
- No references remain to removed TimeManager/camera-controller/touch-joystick scripts.
- ZIP archive integrity is checked after packaging.

## Not verified in this environment

Godot 4 is not installed in the build environment. Therefore these checks have **not** been performed locally:

- GDScript parsing by Godot.
- Main-scene runtime smoke test.
- Collision and interaction testing while playing.
- Android export, APK installation or FPS measurement on a phone.

The repository CI workflow runs a Godot headless import and main-scene smoke test. A passing CI run and a real Android-device test are required before calling this build runtime-verified.
