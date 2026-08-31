# Ability overlay policy

The packaged inventory is generated from the complete `ugc-ability-sync` scan report. Every production Ability property remains visible in the inventory with one exposure classification:

- `edit_time`: literal `showInProperty: true` or `canBeSetVisibleInProperty: true`.
- `runtime_only`: command-visible but not edit-time visible.
- `hidden`: neither edit-time nor command-visible.

Only production, registered, edit-time properties can become local overlay candidates. The generator additionally blocks likely events and controls (`onXxx`, `*Instruction`, `*Event`, `*Listener`, `*Delegate`, `*Btn`, preview/simulation controls), the whole `preciseEdit` family, known internal entity references, duplicate paths, and any property whose flags are ambiguous.

The local policy explicitly restores `HotWeaponAbility`, `MeleeWeaponAbility`, `Pickup`, and `vehicle` to official Buildmode-only routing. Their source-scanned properties remain visible for audit, and paths already present in the live Contract still route to `official_buildmode`, but missing paths are not exposed through `local_overlay`.

At runtime the MCP intersects this source inventory with the editor's live `inspectSemanticCatalog`:

- Present in live catalog: `official_buildmode`; never shadow it.
- Present with a source-proven type conflict and an explicit dedicated codec: `ugc_authoritative_overlay`; only the catalog-named dedicated tool may write it.
- Absent and locally writable: `local_overlay`.
- Runtime/hidden/event/control/duplicate: `unsupported` with a reason.

The inventory proves exposure and spelling, not arbitrary value codecs. The writer therefore supports only scalar and explicit vector/rotation/color/transform shapes, performs a pre-read, uses the existing buildmode-editor connection and editor-advertised semantic operation hash, and always performs an independent exact readback. It does not start another MCP or websocket bridge.

## CurrencyInfo exception

`ItemAbility.saleCurrency` is the sole UGC-authoritative exception currently enabled. UGC source declares `CurrencyInfo`, while the live Contract declares `string`. The dedicated codec is grounded in these source facts:

- `CurrencyInfo.type` is a serializable string whose option source is the user currency key catalog.
- `CurrencyInfo.count` is a serializable integer with range `[0, 99999999]`.
- The editor property command accepts nested paths, so the companion writes `ItemAbility.saleCurrency.type` and `ItemAbility.saleCurrency.count` instead of replacing the parent instance with a plain JSON object.
- A currency key is eligible only when fresh `inspectUserData` evidence reports that exact `uuid` with `type: CustomCurrency`.

The dedicated route is active only while the live official type conflicts with the UGC source type. If the official catalog changes to `CurrencyInfo`, the companion refuses the dedicated route and returns control to official Buildmode. Exact independent readback of both leaves is mandatory. A runtime test is still required so `ItemTemplateComponent.awake` resynchronizes the derived `SellCurrencyName` and `SellPrice` state.
