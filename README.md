# CAYPER SM — 1.0.0

**CAYPER SM** is a mobile-first 3D Egyptian-neighborhood life simulation with a cyber-cafe management loop. It is built for **Godot 4.3+** using the Compatibility renderer and procedural low-poly geometry. The project does not require downloaded third-party assets.

## Included playable systems

- Third-person character movement, camera look, sprinting and jumping.
- Touch movement/look and on-screen interaction, jump and sprint controls.
- Procedural neighborhood block with road, sidewalks, buildings, park, trees, street lights, home, grocery shop, job board and cyber cafe.
- Day/night lighting and in-game clock.
- Moving ambient traffic cars (decorative traffic, not player-drivable).
- Four NPCs with wandering movement and dialogue interactions.
- Six interactable cyber-cafe computer stations and a cashier/management entry point.
- Cafe open/closed state, computer purchases, upgrades, repairs, employee hiring, condition wear, daily revenue/expenses and automatic day settlement.
- Personal money, XP/levels, reputation bonus, energy and hunger needs.
- Inventory with coffee, sandwiches and repair kits; usable consumables and repair kits.
- Grocery purchases and three repeatable-per-day job-board tasks.
- Daily starter quests with claimable rewards.
- Three JSON save slots, including player position, money, level, economy, inventory, needs, quests, cafe state and audio settings.
- Generated WAV UI, typing, footsteps, cash, door and cafe ambience audio; master volume settings.
- Pause menu, HUD, inventory, quest, business, shop, home, jobs and audio settings panels.

## Controls

| Action | Desktop | Android touch |
|---|---|---|
| Move | WASD / arrows | Drag on left side |
| Look | Mouse | Drag on right side |
| Sprint | Shift | On-screen Sprint |
| Jump | Space | On-screen Jump |
| Interact | E | On-screen Interact |
| Inventory | I | HUD button |
| Pause | Escape | HUD button |

## Run in Godot

1. Open Godot 4.3 or newer.
2. Import this folder using the Godot Project Manager.
3. Open `project.godot` and run the main scene.
4. For Android export, configure the Android SDK/JDK and install matching Godot export templates in the editor.

## Validation status

The project structure, resource paths, audio files and ZIP integrity are checked by the packaging process. **This environment does not have the Godot executable, so the GDScript parser, actual gameplay runtime, Android export and installation on a phone have not been run here.** The GitHub Actions validation workflow performs Godot headless import and a main-scene smoke run when pushed to GitHub. Do not treat this archive as an Android-tested APK until export and a real-device test pass.

## Scope note

Version 1.0 is the complete first playable neighborhood/cyber-cafe game loop represented by this source project. Traffic cars are ambient props, not drivable vehicles; the map is a compact neighborhood district rather than a huge streaming city; online multiplayer and external account services are not part of this offline single-player release.
