# TODO

## Milestone 1 — Core Offline Play (pass-and-play)
- [x] Board model parity: verify 4×8, shuffle, face-up/face-down, deterministic seed toggle in UI
- [x] Turn system completeness: flip / move / capture; enforce Soldier↔General exception
- [x] Cannon capture screen logic: unit tests for edge cases (multiple screens, face-down screens)
- [x] Win detection: side to move has no legal actions → opponent wins; endgame banner
- [x] Input/UI: tap to flip/move, reliable hit-testing, legal-move highlights, capture animation polish
- [x] Move log: compact two-line display with coordinates; add clear button

## Player Experience & UI Enhancements
- [x] Remove tutorial dialog on startup
- [x] Add Player 1 (Red) and Player 2 (Black) labels
- [x] Show current player turn clearly in UI
- [x] Add sound effects for capture and move actions
- [x] Add enhanced capture animation
- [x] Make all animations more smooth and polished
- [x] Add selection border around selected chess piece
- [x] Make player labels more professional game-style ("RED ARMY" / "BLACK ARMY")
- [x] Add captured pieces display area at bottom of board

## Visuals & Assets
- [ ] Replace placeholders with high-quality assets in `Assets.xcassets`
  - [ ] `piece_char_<type>_red` and `piece_char_<type>_black` for: general, advisor, elephant, chariot, horse, cannon, soldier
  - [ ] `piece_back` for face-down tile
- [ ] Ensure vector PDFs or @1x/@2x/@3x PNGs; sRGB profile preserved
- [x] Board theme: finalize beige theme + borders; verify crisp grid on all iPads
- [x] Tune piece shadow/lighting intensity

## Milestone 2 — Quality & UX
- [x] Undo/redo stack with animation reversal
- [x] Settings (sound, hints, variants) scaffold
- [x] Accessibility labels for pieces and cells; VoiceOver hints
- [x] Tutorial/first-run overlay
- [x] (Optional) Style toggles: board themes and piece styles; persist via `UserDefaults`

## Milestone 3 — AI & Online (optional)
- [ ] Simple AI (heuristics + Monte Carlo playouts)
- [ ] Online (Game Center or custom): real-time/turn-based
- [ ] Analysis/replay viewer

## Build & Platform
- [x] Enforce landscape-only (project set); re-verify on iPad simulators
- [x] Scene scaling: `.resizeFill` confirmed; safe-area layout checked
- [x] Performance target: steady 60 FPS; profile and optimize draw calls

## Tests
- [x] Unit tests for: legal moves, capture rank rules, cannon screens, win detection
- [x] Snapshot/regression tests for setup/deterministic seeding
