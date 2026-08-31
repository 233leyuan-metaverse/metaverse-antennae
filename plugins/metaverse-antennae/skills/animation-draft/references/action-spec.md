# ActionSpecV1

Generate a sparse semantic motion plan, not baked animation data.

## Shape

```json
{
  "version": 1,
  "label": "右手挥手",
  "durationSec": 1.6,
  "loop": false,
  "holdEnd": false,
  "keys": [
    { "t": 0, "pose": {} },
    { "t": 1, "pose": {} }
  ]
}
```

- `durationSec`: `0.15..8`; most gestures work best at `0.8..3` seconds.
- `t`: normalized `0..1`. The first key must be `0`; use unique times and at least two keys.
- `pose`: sparse joint-to-`[x,y,z]` XYZ Euler rotations in radians. Omitted joints use I-Pose zero at that key.
- Each component is limited to `-3.5..3.5` radians. Keep ordinary motion mostly below `2.6`.
- Optional `holdEnd=true` appends a 0.3-second recovery to I-Pose. Prefer an explicit final empty pose when the recovery timing matters.
- Optional `spinYaw` / `spinPitch`: total root spin in radians, limited to ±`4π`.
- Optional `dipPeaks`: up to four `{at, amount, width}` root dips. `at` and `width` use normalized time; `amount` is meters in `-0.8..0.8`. Positive `amount` moves the MW pelvis downward; use positive values for crouching and landing compression.

## Supported joints

`Hips`, `UpperTorsoJoint`, `Neck`, `RightShoulder`, `RightElbow`, `RightWrist`, `LeftShoulder`, `LeftElbow`, `LeftWrist`, `RightHip`, `RightKnee`, `RightAnkle`, `LeftHip`, `LeftKnee`, `LeftAnkle`.

Right and left are the character's sides. Never mirror the requested side.

## R15 local joint coordinates

Every `[x,y,z]` rotates that joint in its own R15 local frame relative to its parent. These are not MW bone axes; the runtime performs the fixed proper basis conversion afterward. At the all-zero I-Pose the character faces `-Z`, `+Y` is up, and `+X` is the character's right.

| Joint group | Local X | Local Y | Local Z |
|---|---|---|---|
| `Hips`, `UpperTorsoJoint`, `Neck` | `+X` leans/pitches forward; `-X` backward | turn or axial twist; keep subtle | side tilt/roll; keep subtle |
| `RightShoulder`, `RightHip` | `+X` swings forward; `-X` backward | axial twist | `+Z` abducts outward |
| `LeftShoulder`, `LeftHip` | `+X` swings forward; `-X` backward | axial twist | `-Z` abducts outward |
| `RightElbow`, `LeftElbow` | `+X` bends the forearm forward | axial twist, normally near zero | side bend, normally near zero |
| `RightKnee`, `LeftKnee` | `-X` folds the lower leg backward; positive X is hyperextension and should normally be avoided | normally near zero | normally near zero |
| `RightWrist`, `LeftWrist` | forward/back bend relative to the forearm | twist | side deviation |
| `RightAnkle`, `LeftAnkle` | `+X` points the toes; `-X` lifts the toes | twist, normally small | foot roll, normally small |

- Local axes follow their parent after parent rotation. Do not reinterpret values as world-space directions.
- Treat elbows and knees primarily as X-axis hinges. Do not add Y/Z noise merely to make a pose look complex.
- Never flip the knee sign to compensate for the MW target. A normal bent knee is negative R15 X; the runtime's existing leg basis converts it correctly.

## Retargeting semantics

- Author only a standard R15 motion. The all-zero pose is the R15 natural-hang I-Pose.
- The runtime converts that R15 motion to the currently active MW Cartoon character with its fixed bone map, proper axis bases, and MW IPos/Hang calibration.
- “Anime-style” or “二次元” normally describes the existing target character, not a request to exaggerate motion. Do not alter timing or amplitude for that phrase alone.
- Retargeting changes bone motion only; it does not convert the character model, materials, body shape, or appearance.

## Motion composition

- Give the action a readable silhouette. Use large proximal joints for the main pose and smaller distal joints for rhythm.
- Stagger preparation, action, accent, and recovery. Avoid changing every joint at once.
- Keep torso and neck motion subtle unless the user's action explicitly centers on them.
- The runtime samples deterministically at 30 FPS with eased sparse-key interpolation.

## Right-hand wave

```json
{
  "version": 1,
  "label": "右手挥手",
  "durationSec": 1.6,
  "keys": [
    { "t": 0, "pose": {} },
    {
      "t": 0.22,
      "pose": {
        "UpperTorsoJoint": [0, 0.08, -0.08],
        "Neck": [0, -0.05, 0.05],
        "RightShoulder": [1.2, 0.1, 0.15],
        "RightElbow": [1.1, 0, 0]
      }
    },
    {
      "t": 0.42,
      "pose": {
        "UpperTorsoJoint": [0, 0.08, -0.08],
        "Neck": [0, -0.05, 0.05],
        "RightShoulder": [1.2, 0.1, 0.15],
        "RightElbow": [1.1, 0, 0],
        "RightWrist": [0, 0, 0.55]
      }
    },
    {
      "t": 0.62,
      "pose": {
        "UpperTorsoJoint": [0, 0.08, -0.08],
        "Neck": [0, -0.05, 0.05],
        "RightShoulder": [1.2, 0.1, 0.15],
        "RightElbow": [1.1, 0, 0],
        "RightWrist": [0, 0, -0.55]
      }
    },
    {
      "t": 0.8,
      "pose": {
        "RightShoulder": [1.05, 0.08, 0.1],
        "RightElbow": [1, 0, 0],
        "RightWrist": [0, 0, 0.42]
      }
    },
    { "t": 1, "pose": {} }
  ]
}
```

Send the object as `action_spec`; never expand it into skeleton transforms or frame arrays.

## In-place run cycle

For running, read [run-cycle.md](run-cycle.md) before authoring the ActionSpec. It contains the required four-phase structure and a verified high-quality sparse example. Do not reduce a run to two mirrored extreme poses.

