## ChineseChase — Banqi (Dark/Blind Chess)

A Swift/SpriteKit implementation of Banqi (also called Dark Chess or Blind Chess). The app targets iPhone and iPad in landscape mode only.

### Platforms

- **Devices**: iPhone, iPad
- **Orientation**: Landscape only
- **Minimum iOS**: 15+
- **Frameworks**: SpriteKit, UIKit

## Game Overview

Banqi is a quick, tactical game derived from Xiangqi, played on a 4×8 grid with 32 Xiangqi pieces placed face‑down and revealed during play. See the Wikipedia article for background and variants: [Banqi — Wikipedia](https://en.wikipedia.org/wiki/Banqi).

## Rules (default set used in this project)

- **Board**: 4 columns × 8 rows (all 32 squares filled at start).
- **Pieces (per color, total 32)**: 1 General, 2 Advisors, 2 Elephants, 2 Chariots, 2 Horses, 2 Cannons, 5 Soldiers.
- **Setup**: Shuffle all pieces and place face‑down randomly. The first player’s first action is to flip one piece; that piece’s color becomes the first player’s color.
- **Turn options** (one action per turn):
  - Flip one face‑down piece.
  - Move one of your face‑up pieces one square orthogonally into an empty square.
  - Capture by moving onto an opponent’s face‑up piece, following capture rules.
- **Movement**:
  - All pieces move one square orthogonally (no diagonals, no jumping) except the Cannon when capturing (see below).
- **Capture/Rank**:
  - A piece may capture an opponent piece of equal or lower rank.
  - Default rank (high → low): General > Advisor > Elephant > Chariot > Horse > Cannon > Soldier.
  - Exception: **Soldier captures General**; **General cannot capture Soldier**.
- **Cannon (special capture)**:
  - To capture, a Cannon must jump over exactly one intervening piece (of any color, face‑up or face‑down) along the same row or column to land on and capture the first opponent piece beyond it.
  - A Cannon’s non‑capturing move is still one square orthogonally.
- **End of game**: The player who cannot make a legal move on their turn loses (typical because all pieces are captured or blocked). Stalemate/draw rules may be added as an option in Settings (see Variants).

### Popular Variants (toggle in Settings later)

- Cannon may or may not capture Cannons.
- Alternate rank orders (e.g., swapping Chariot/Horse/Elephant/Advisor strength).
- Repetition/threefold rules.

Our default follows the commonly cited Wikipedia rules with Cannon able to capture any rank using a single screen and the Soldier–General exception.

## Project Structure

- `ChineseChase/AppDelegate.swift` — App lifecycle
- `ChineseChase/GameViewController.swift` — Landscape SpriteKit host
- `ChineseChase/GameScene.swift` — Core board rendering, input handling
- `ChineseChase/GameScene.sks` / `Actions.sks` — SpriteKit scene/assets
- `ChineseChaseTests/` — Unit tests

## Implementation Plan

### Milestone 1 — Core Offline Play (local pass‑and‑play)

- Board model: 4×8 grid, piece enum, color, face‑up/face‑down state
- Shuffled initial layout with deterministic seed support
- Turn system: flip / move / capture; legal‑move generator (incl. Cannon screen rule)
- Win detection: no legal move
- Basic UI: touch to flip/move, highlight legal moves, capture animations, move log
- Landscape‑only layout for iPhone/iPad

### Milestone 2 — Quality & UX

- Undo/redo, settings (sound, hints, variants)
- Visual polish: piece art, board themes, accessibility labels
- Tutorial: interactive first‑time guide
- (Optional, low priority) Settings toggle for board and piece styles

### Milestone 3 — AI & Online (optional)

- AI opponent (heuristics + Monte Carlo playouts)
- Game Center or custom real‑time/turn‑based multiplayer
- Analysis/replay viewer

## UI/UX & Visual Quality Guidelines

- **Visual style**: Clean, modern board with subtle texture, high contrast between red/black sides, and clear state for face‑down vs face‑up pieces. Avoid noisy backgrounds; favor soft shadows and gentle gradients.
- **Layout**: Board centered in landscape with consistent safe‑area padding. Maintain a fixed 4×8 grid; keep at least 16–24 pt margins around edges. Keep controls minimal; prioritize direct manipulation (tap to flip/move).
- **Touch targets**: Minimum 44×44 pt for all tappable regions (board cells, buttons).
- **Feedback**: Immediate visual feedback on tap/drag; highlight selected piece and legal moves; short capture animations with easing.
- **Motion**: Keep animations snappy (0.18–0.30 s for selection/highlights, 0.25–0.35 s for moves/captures). Use ease‑in‑out; avoid long interpolations.
- **Color & typography**: sRGB palette; default iOS San Francisco typeface for any overlays. Keep text minimal and high contrast.
- **Accessibility (baseline)**: Clear color/shape distinction between sides; consider color‑blind safe hues. Ensure readable contrast for labels and move logs.
- **Performance**: Use texture atlases to minimize draw calls; reuse nodes/textures; avoid oversized textures. Target a steady 60 FPS on the iPad simulator.

## Asset Specifications (High‑DPI/Retina)

- **Preferred format**: Vector PDF in `Assets.xcassets` with “Preserve Vector Data”. Single‑scale asset catalogs will rasterize appropriately for all densities.
- **Alternative (raster)**: Provide PNGs at `@1x`, `@2x`, `@3x` scales.
  - Recommended base design size for a piece: 200 pt square → export 200/400/600 px PNGs.
  - Use PNG for UI with transparency; JPEG only for large photo backgrounds (not currently used).
- **Board**: Provide a vector board background; if raster, supply at least 2732×2048 px (landscape iPad Pro) and keep max dimension ≤ 4096 px for broad compatibility.
- **Pieces (default: Chinese character images)**: Provide one sprite per piece type per color using Chinese characters (image‑based, not runtime text). Consider a subtle drop shadow for depth.
- **Atlases**: Group sprites into `Pieces.atlas` and (optionally) `Board.atlas` or place into `Assets.xcassets`. Keep consistent naming; avoid spaces.
- **Color management**: Export in sRGB (embed profile). Avoid color shifts by keeping a single working color space.
- **QA checklist (visual)**:
  - Crisp edges on all iPad simulators (9th/10th gen, iPad Pro 11‑inch). No blurriness at normal zoom.
  - No visible seams at board tile edges; no compression artifacts.
  - Icons and overlays remain legible on all supported iPad sizes.

### Chinese Character Piece Set (Default)

- **Approach**: Use image assets that depict Chinese characters for each piece. Do not render text at runtime; provide vector PDFs (preferred) or high‑res PNGs.
- **Character mapping (Red → Black)**:
  - General: `帥` → `將`
  - Advisor: `仕` → `士`
  - Elephant: `相` → `象`
  - Chariot: `俥` (alt `車`) → `車`
  - Horse: `傌` (alt `馬`) → `馬`
  - Cannon: `炮` → `砲` (some sets use `炮` for both)
  - Soldier: `兵` → `卒`
- **Files to provide (14 total)**:
  - Red: `general`, `advisor`, `elephant`, `chariot`, `horse`, `cannon`, `soldier`
  - Black: `general`, `advisor`, `elephant`, `chariot`, `horse`, `cannon`, `soldier`
- **Naming (suggested)**:
  - `piece_char_<type>_red.pdf/png` and `piece_char_<type>_black.pdf/png`
  - Examples: `piece_char_general_red.pdf`, `piece_char_cannon_black.pdf`
- **Sizing & padding** (design at 200 pt base):
  - Inner padding: 12–16% of the square to avoid edge clipping.
  - Stroke weight: ~8–10 pt at 200 pt base (scales with asset).
  - Corners/ink: favor clean vector paths with minimal nodes to avoid raster artifacts.
- **Colors**:
  - Red pieces: fill `#D92D2D` (or system red equivalent), outline `#7A0F0F` optional.
  - Black pieces: fill `#1D1D1F` (or near‑black), outline `#000000` optional.
  - Background inside piece tile should be transparent; rely on board tile contrast.
- **Back (face‑down) tile**:
  - Provide `piece_back.pdf/png` with neutral design that contrasts with both sides.
  - Include a simple symbol or pattern (no text) to avoid localization issues.
- **Atlases/Assets**:
  - Place all in `Assets.xcassets` as vector PDFs (Preserve Vector Data). If using PNGs, include `@1x/@2x/@3x`.
  - Group alternatives (e.g., `俥` vs `車`) in a subfolder for optional styles.

### Optional: Board & Piece Style Settings

- **Scope (optional, low priority)**: Let players choose a board theme and a piece style.
- **Example styles**:
  - Board: `classic-wood`, `slate`, `parchment`, `dark`.
  - Pieces: `character-ink` (Chinese characters), `figurine`, `high-contrast`.
- **Asset organization**:
  - Use `Assets.xcassets` with clear names, e.g., `board/classic`, `board/slate`.
  - Pieces as `piece_<type>_<color>_<style>` (e.g., `piece_general_red_character-ink`).
  - Prefer vector PDFs; group bitmaps in atlases if rasterized.
- **Persistence (suggested)**: Store selection in `UserDefaults` keys `boardStyle` and `pieceStyle`.
- **UX**:
  - Simple in‑app Settings overlay (toggle list or segmented controls).
  - Apply changes immediately; no restart required.
  - Keep text minimal; preview swatches if feasible.
- **Performance**:
  - Preload textures for the selected style; lazy‑load alternatives on demand.
  - Avoid runtime scaling; provide correctly sized assets.
- **Acceptance (if implemented)**:
  - Style toggles persist between launches and update visuals immediately.
  - All assets remain crisp on iPad simulators; no frame drops on theme switch.

## Build & Run

1. Open `ChineseChase.xcodeproj` in Xcode 15+.
2. From the scheme/device picker, select an iPad simulator (e.g., "iPad (10th generation)" or "iPad Pro (11‑inch)"). The app runs in landscape only.
3. Build and run. The app locks to landscape orientation.

### Run on the iPad Simulator

Preferred target: iPad simulator. We test exclusively in landscape mode.

1. In Xcode’s device picker, choose an iPad simulator (e.g., "iPad (10th generation)" or "iPad Pro (11‑inch)").
2. Press Run. The app launches in landscape. If needed, rotate the simulator using Hardware → Rotate Left/Right.
3. Verify a game can start, flip a piece, move, and capture without crashes.

CLI (optional):

```bash
xcodebuild -project ChineseChase.xcodeproj \
  -scheme ChineseChase \
  -destination "platform=iOS Simulator,name=iPad (10th generation)" build
```

## Definition of Done

For any task in this project, consider it complete only after:

- The project compiles with no errors or new warnings.
- The app runs on an iPad simulator in landscape and passes basic smoke tests:
  - Launches to the main scene in landscape
  - New game can be started
  - Flip, move, and capture actions work
  - No crashes in a 2–3 minute play session
- Visual quality checks pass:
  - Assets are vector or include `@3x` raster variants and appear crisp (no scaling artifacts).
  - Minimum 44 pt touch targets for interactive elements.
  - Selection/move/capture animations are responsive (≤ ~350 ms) and consistent.
  - Performance is smooth (target 60 FPS) on the iPad simulator; no obvious jank or frame spikes.
- Unit tests (if any) pass locally: `⌘U` in Xcode or `xcodebuild test`.

## Assets & Licensing

- Placeholder art is for development only. Replace with properly licensed assets before distribution.
- Maintain original source files (e.g., Figma/Sketch/AI) alongside exported assets for future edits.
- Ensure all third‑party assets comply with licenses for redistribution in an open‑source or shipped app.

## References

- [Banqi — Wikipedia](https://en.wikipedia.org/wiki/Banqi)


