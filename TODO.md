# Release verification checklist

This is a verification checklist, not a list of missing source features. Complete it in Godot and on the target Android phone before publishing:

- [ ] Godot 4.3+ headless import succeeds with no script parse errors.
- [ ] Main scene starts and player can move, look, jump and interact.
- [ ] Cafe computer, NPC, grocery, home and job-board interactions work.
- [ ] Business purchases, upgrades, repairs, hiring and daily settlement work.
- [ ] Inventory, needs, jobs and quests update correctly.
- [ ] Save/load works in all three slots, including after app restart.
- [ ] Audio loops and effects play; volume controls work.
- [ ] Android export succeeds and APK installs on the target phone.
- [ ] Touch controls and UI layout are usable on the target phone.
- [ ] A 10-minute device playtest shows no crash, softlock or major performance issue.

Known scope boundaries are documented in README.md: traffic cars are not drivable, the map is a compact district, and the release is offline single-player.
