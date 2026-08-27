# Dragging Code Overview (`visual_chart_view.dart`)

The interactive chart canvas has two main behaviors that need to coexist:

- **Placing a stitch** — a short tap on empty space adds the currently selected stitch at the tap location.
- **Moving/panning** — a longer press-and-drag moves content around

There are three independent subsystems handling pointer events. They live on a single widget tree that looks roughly like this:

```
Listener
  └─ GestureDetector (onTapUp, onPanStart/Update/End)
       └─ InteractiveViewer
            └─ <the actual chart canvas>
```

Each subsystem is described in detail below.

---

## 1. `Listener` (raw pointer handlers) — middle-button canvas panning

**Location:** `visual_chart_view.dart` around lines 427–451.

A `Listener` is a low-level widget that receives *raw* pointer events before any gesture arena processing. It is used here to implement canvas panning with the **middle (or any non-left) mouse button**:

### `onPointerDown` (lines 428–433)
```dart
if (event.buttons != kPrimaryButton) {
  _middleDragPointer = event.pointer;
  _middleDragLast = event.position;
}
```
- `kPrimaryButton` is the left mouse button (value `0x01`).
- If any button other than left is pressed, it records the pointer's ID and its current position. For example:
  - Right mouse button (`kSecondaryButton`, `0x02`)
  - Middle mouse button (`kTertiaryButton`, `0x04`)

### `onPointerMove` (lines 434–445)
```dart
if (event.pointer == _middleDragPointer && _middleDragLast != null) {
  if (event.buttons != kPrimaryButton) {
    final scale = _transform.value.getMaxScaleOnAxis();
    final dx = event.position.dx - _middleDragLast!.dx;
    final dy = event.position.dy - _middleDragLast!.dy;
    _transform.value.translateByDouble(dx / scale, dy / scale, 0, 1);
    _middleDragLast = event.position;
  }
}
```
- If the pointer that went down earlier is the one moving and a non-primary button is held:
  - It computes the screen-space delta since the last event
  - Divides by the current zoom scale (so panning feels right when zoomed in/out)
  - Applies that delta to the `_transform`'s translation (the same `TransformationController` that drives `InteractiveViewer`)
  - Updates `_middleDragLast` so the next move is incremental

### `onPointerUp` (lines 446–451)
```dart
if (event.pointer == _middleDragPointer) {
  _middleDragPointer = null;
  _middleDragLast = null;
}
```
- When the tracked pointer lifts, the drag is over and tracking state is cleared.

### `onPointerSignal` (lines 452–461)
```dart
if (event is PointerScrollEvent) {
  final scale = _transform.value.getMaxScaleOnAxis();
  _transform.value.translateByDouble(
    -event.scrollDelta.dx / scale,
    -event.scrollDelta.dy / scale,
    0, 1,
  );
}
```
- The scroll wheel emits `PointerScrollEvent`s (also delivered through `Listener.onPointerSignal`).
- The scroll delta is applied as a translation (with the sign flipped so scrolling down moves the view up — the typical convention).
- This only pans; it does **not** zoom.

---

## 2. `GestureDetector` (stitch moving + tap-to-place)

**Location:** lines 462–506.

This `GestureDetector` is the bridge between user gestures and the chart model. It exposes three gesture families that all compete in the gesture arena:

### `onTapUp` (lines 463–468) — tap to place a stitch
```dart
final matrix = _transform.value;
final inverse = Matrix4.identity()..copyInverse(matrix);
final content = MatrixUtils.transformPoint(inverse, details.localPosition);
_placeStitch(content, svgSize);
```
- Fires on a quick tap (down + up without significant movement).
- `details.localPosition` is in the `GestureDetector`'s coordinate space, which is the same space as the `InteractiveViewer`'s outer box — not the inner content space.
- It builds the inverse of the current transformation matrix and uses it to convert the tap position back into content space (the coordinate space where the chart is actually drawn).
- `_placeStitch` figures out whether the tap is near the center (place a starter), on the ring (place a stitch in the current round), or elsewhere.

### `onPanStart` (lines 469–491) — begin dragging a stitch along its ring
```dart
if (editState.mode != EditMode.stitch || positioned == null) return;
// ... convert to content space ...
double bestDist = 20;
for (int ri = 0; ri < positioned.length; ri++) {
  for (int si = 0; si < positioned[ri].length; si++) {
    final p = positioned[ri][si];
    final d = sqrt(
      (p.x - (content.dx - half)) * (p.x - (content.dx - half)) +
      (p.y - (content.dy - half)) * (p.y - (content.dy - half)));
    if (d < bestDist) {
      bestDist = d;
      _dragRoundIdx = ri;
      _dragStitchIdx = si;
    }
  }
}
if (_dragRoundIdx != null) {
  _dragBaseAngle = positioned[_dragRoundIdx!][_dragStitchIdx!].angle
      - (positioned[_dragRoundIdx!][_dragStitchIdx!].stitch.angleOffset ?? 0);
}
```
- Only activates in stitch mode.
- Converts the pointer's local position to content space (`half = svgSize / 2`), so the resulting point is relative to the chart's center.
- Iterates over every placed stitch in `positioned` (which is the output of `_layout`) and finds the one within `bestDist = 20` content-pixels of the pointer.
- If a stitch is found:
  - Records which round/stitch it is via `_dragRoundIdx` and `_dragStitchIdx`
  - Computes the **base angle** of that stitch (the angle computed by `_layout`, *before* the user-applied `angleOffset` is added). This is `_PosStitch.angle - stitch.angleOffset`. Storing the base angle lets each subsequent move just compute `newAngle - baseAngle`.
- If no stitch is within 20px (i.e. the drag is on empty space), `_dragRoundIdx` remains `null` and subsequent `onPanUpdate` calls will bail out — meaning **dragging empty space in stitch mode is currently a no-op**.

### `onPanUpdate` (lines 492–502) — move the grabbed stitch
```dart
if (_dragRoundIdx == null || _dragStitchIdx == null) return;
// ... convert to content space ...
final dx = content.dx - half;
final dy = content.dy - half;
final angle = atan2(dy, dx);
_setStitchAngleOffset(_dragRoundIdx!, _dragStitchIdx!, angle - _dragBaseAngle);
```
- Bails out if no stitch was grabbed.
- Computes the angle from the chart center to the pointer.
- The new `angleOffset` is `angle - _dragBaseAngle`. Because `_dragBaseAngle` was captured **at drag start**, the offset is always relative to the original computed position.
- `_setStitchAngleOffset` walks the chart model, finds the corresponding stitch (counting through `expandStitches` so the right expanded sibling is targeted), applies `angleOffset: offset` via `copyWith`, runs `assignConnections`, and replaces the chart via the notifier. The state update triggers a rebuild of `_layout`, which applies the offset in all three placement paths (anchored, unanchored-regular, unanchored-slip), so the stitch appears at its new angle.

### `onPanEnd` (lines 503–506)
```dart
_dragRoundIdx = null;
_dragStitchIdx = null;
```
- Clears the drag state. (Note: the model was already updated live during `onPanUpdate`, so nothing needs to be flushed here.)

---

## 3. `InteractiveViewer` built-in pan — Pan tool

**Location:** lines 507–513.

```dart
InteractiveViewer(
  transformationController: _transform,
  minScale: 0.25,
  maxScale: 6,
  panEnabled: editState.mode == EditMode.pan,
  constrained: false,
  boundaryMargin: const EdgeInsets.all(double.infinity),
  ...
)
```

- `InteractiveViewer` has its own internal `GestureDetector` driven by a `ScaleGestureRecognizer`.
- When `panEnabled: true` (Pan mode selected), it accepts left-button drags and translates the canvas via the same `_transform` controller.
- When `panEnabled: false` (stitch mode), the recognizer rejects single-pointer drags, leaving the field open for the outer `GestureDetector`'s `onPan*` to win them.
- This is why the **Pan tool** still works with left-drag — it's the `InteractiveViewer` doing it, not our `GestureDetector`.

---

## The conflict between subsystems

Even though `Listener` is *outside* the `GestureDetector`, this does **not** guarantee middle-button pans are received — the reason is the **gesture arena**, not the widget order.

### The gesture arena

In Flutter, raw pointer events (`onPointerDown`/`Move`/`Up` on `Listener`) hit **every** `Listener` on the hit path, regardless of gesture arena resolution. So `Listener.onPointerMove` *should* in principle fire for middle-button drags.

However, when a gesture recognizer (the inner `GestureDetector`'s pan recognizer) **wins** the arena for that pointer, Flutter optionally calls `handleEvent` with a `PointerExitEvent`/synthetic-cancel that stops subsequent `PointerMoveEvent`s from being routed through the pointer router to listeners — depending on the platform plugin's pointer capture behavior. On Linux (both X11 and Wayland), the GTK/SDL backend can **seat-grab** the pointer once a drag gesture is recognized, which prevents `Listener.onPointerMove` from receiving subsequent move events for that pointer.

### Why middle-button drag specifically gets starved

When you press the middle mouse button:
1. `Listener.onPointerDown` fires — since `event.buttons != kPrimaryButton`, it records the pointer.
2. The inner `GestureDetector`'s `PanGestureRecognizer` *also* receives the `PointerDownEvent` and starts a gesture arena competition.
3. When you move the mouse, the inner pan recognizer reaches its slop threshold and **claims the arena**. Once it wins, the platform stops routing `PointerMoveEvent`s to raw listeners for that pointer — so `Listener.onPointerMove` never fires.
4. The `GestureDetector.onPanStart`/`onPanUpdate` do run, but in stitch mode with no nearby stitch they bail out, and in pan mode the `InteractiveViewer` intercepts the gesture.

End result: **middle-button drag does nothing visible**, whether in stitch mode or pan mode.

### Why left-button drag in Pan mode works

Pan mode sets `InteractiveViewer.panEnabled = true`, so its `ScaleGestureRecognizer` wins left-button drags and pans the canvas directly. The outer `Listener` is skipped for left-button events anyway (`event.buttons != kPrimaryButton` is false), but the inner `InteractiveViewer` already covers that case natively.

### Why scroll-wheel *rotation* still works

`PointerScrollEvent` events are **signals**, not gesture arena participants — they are never part of a drag recognizer competition. `Listener.onPointerSignal` receives them unconditionally, which is why scrolling the wheel pans the canvas regardless of mode or selected tool.

---

## Summary table

| Action                          | Consumed by                | Works? |
|---------------------------------|----------------------------|--------|
| Left-click tap                  | `onTapUp`                  | yes    |
| Left-click drag (Pan mode)      | `InteractiveViewer`        | yes    |
| Left-click drag (Stitch mode, near stitch) | `onPanStart`/`onPanUpdate` | yes (moves the stitch) |
| Left-click drag (Stitch mode, empty space)| `onPanStart` (bails)      | no-op  |
| Middle-click drag               | `Listener` intended; actual: `GestureDetector` wins arena → no-op | **no** |
| Wheel rotation                  | `Listener.onPointerSignal` | yes    |

---

## Possible approaches going forward

1. **Make `GestureDetector.onPanUpdate` also pan the canvas when no stitch was grabbed.** This unifies all dragging through the gesture arena — no separate `Listener` code path. Middle-button detection (`event.buttons != kPrimaryButton` → pan; else → move stitch if near) can still be done inside `onPanStart`/`onPanUpdate` via a `PointerDetector`-style reach-around, or by storing `RawMouseEvent` data on down.
2. **Disable the inner `PanGestureRecognizer` for non-primary buttons** so it doesn't compete. This needs a custom recognizer — verbose.
3. **Move canvas panning off the middle button entirely** (e.g., spacebar + drag, or the Pan tool only) — least work, no gesture conflict at all.

All three would eliminate the arena-induced starvation of the `Listener` middle-button handler.