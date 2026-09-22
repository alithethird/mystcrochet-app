# Remaining Tasks & Roadmap (MystCrochet App)

This document details the tasks that are currently pending, as well as completed features from recent updates.

---

## 📋 Outstanding Tasks (To Do)

### 1. Polygon Drawing for Rounds (Hexagon Bug)
- **Issue**: When Hexagon (or custom polygon round geometry) is selected, a tiny artifact circle appears in the bottom-left corner.
- **Goal**: Clean up polygon path calculation and rendering logic for non-circular rounds to ensure crisp geometry without origin artifacts.

### 2. Anchor Grouping Rules (`ch` and `sl st`)
- **Issue**: `ch` (chain) and `sl st` (slip stitch) currently get grouped to anchors alongside vertical stitches like `dc` (double crochet).
- **Goal**: Exclude `ch` and `sl st` from anchor grouping logic so they remain independent and properly positioned.

### 3. Procedural Yarn 3D / 2D Rendering Enhancements
- **Thread Connections**: Implement inter-stitch thread loop connection curves in 3D (Bezier/catenary curves connecting stitch tops and bases).
- **Multi-color Yarns**: Support gradient, variegated, and multi-color yarn presets in `YarnRenderConfig`.
- **Export Options**: Add ability to export rendered 3D models to `.gltf`/`.obj` or high-resolution PNG snapshots.

### 4. Expansion of Starter Stitches
- **Foundation Chains**: Add additional foundation chain configurations and custom starter helpers to `assets/stitches.json`.

---

## ✅ Completed Tasks (Recent Session Summary)

1. **3D & 2D Procedural Yarn Engine**:
   - Added `ProceduralYarn3DEngine` and `ProceduralYarn2DEngine`.
   - Created `RealisticYarn3DView` with interactive 3D orbit and 2D pan/zoom controls, lighting, twist, and fiber fuzziness.
   - Fixed redundant gesture recognizer issue by consolidating into `ScaleGestureRecognizer`.
2. **Expansion of `ch-4` Starter Stitches**:
   - Derived `ch-4 picot`, `ch-4 pic`, `ch-4 sc pic`, and `ch-4 open pic` from 3-chain equivalents in `assets/stitches.json`.
   - Categorized turning chains (`t-ch3`, `t-ch4`) under the `starters` category.
3. **Search Bar Character Deletion Fix**:
   - Resolved root issue in `main.dart` where `CallbackShortcuts` intercepted `Backspace` and `Delete` keys globally.
   - Now text fields (`TextField`/`EditableText`) handle `Backspace` and `Delete` natively.
4. **Toolbar Overflow Fix**:
   - Wrapped chart title display in `Flexible` with text truncation to prevent mobile `RenderFlex` overflows.
