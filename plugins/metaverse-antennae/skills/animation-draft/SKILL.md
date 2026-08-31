---
name: animation-draft
description: Generate a standard R15-style body motion, retarget it to the MW Cartoon character currently active in the action editor, and exactly verify the persistent BonesEdit draft. Use for waving, running, nodding, bowing, or cheering; do not use for character appearance conversion, video mocap, fingers, or facial animation.
---

# Animation Draft

Turn the user's motion request directly into a compact `ActionSpecV1`, then call `animation_draft_create`. Do not ask the user to copy a prompt into another model or paste JSON from a web demo.

Read [references/action-spec.md](references/action-spec.md) before authoring the spec. It contains the supported joints, units, motion guidance, and examples. For running, also read [references/run-cycle.md](references/run-cycle.md); do not author a run from only two mirrored extreme poses.

## Completion boundary

- Default to persistence only: do not preview, load, or autoplay after creation.
- If the user explicitly asks to load or preview the new draft, set `preview=true` and keep `autoplay=false` unless they also explicitly ask for automatic playback.
- Set `autoplay=true` only when the user explicitly asks to play automatically after generation.
- Report persistence only when the tool returns `outcome=succeeded_verified` and `verified=true`.
- Include the real `draftId`, draft name, frame count, bone count, and separate preview status.
- If the tool reports an unknown timeout outcome, do not call it again. Ask the user to inspect the named draft in the action editor.

The `ActionSpecV1` always describes motion in the standard R15 I-Pose coordinate convention. The UGC runtime then applies its fixed R15-to-MW retarget profile to the MW Cartoon character currently active in the action editor. It changes motion data only and never changes that character's model, materials, body shape, or appearance. If the user says the scene character is “anime-style” or “二次元”, treat that as the target-character context; do not automatically exaggerate the motion unless the user separately requests exaggerated timing or poses.
