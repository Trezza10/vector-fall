# VECTORFALL — Game Development Standards

**Damage-number motion variety (2026-10-27):** At the user's request, new number windows
sample bounded spawn scatter, trajectory, arc, tilt/spin and punch variation. Samples are
retained when same-source hits aggregate. Variation ranges are Inspector properties; the
hard one-second lifetime, source colors, pause behavior and editor-authored lanes are unchanged.

**Damage-number revision (2026-10-27):** The user requested hard one-second expiry,
technical typography and separate colored source totals. Each target now owns fixed
DamageNumbers lanes for typed DamageSource kinds. Same-source hits punch/aggregate without
refreshing lifetime or fade. Bullet damage is white; burn/poison are red/green. Other source
colors are configured in the scene and only appear for actual damage. DoT attribution
preserves combined tick rounding and HP clamping. This supersedes the earlier single-total,
refresh-on-hit damage-number behavior. All lanes remain editor-authored and reusable.

**Approved damage-number milestone (2026-10-27):** The user requested punchy floating
damage numbers, aggregation while visible and configurable colors with one default color.
Each target owns one editor-authored FloatingDamageNumber scene. Applied damage, including
DoT, updates that node; it punches, drifts in world space and fades. Repeated hits add to its
total and refresh animation without spawning nodes or snapping position. Colors/timing are
Inspector properties. Death leaves the number visible to finish; health reset clears it.

**Approved on-hit effects milestone (2026-10-27):** The user requested stacking Burn,
Poison, Ice, Stun and Knockback modifiers, with room for additional effects. Mark adds damage
vulnerability. Typed StatusEffectDefinition resources travel through modification copies and
projectile snapshots; TargetStatus owns short-lived enemy statuses and signals damage/push to
its owner. TargetDummy now uses CharacterBody2D only to resolve physical knockback against
walls/targets; it still has no autonomous movement or AI. Slow/stun expose future locomotion
state and visual feedback on stationary targets. Fixed status visual nodes and six additional
pickups remain editor-authored. Run-long pickup duration is separate from on-target duration.

**Pickup duration update (2026-10-27):** At the user's request, all authored pickup
modifications now last the entire run (`duration_seconds = 0`). Stacking and eight-second
pickup recharge are unchanged. Positive durations remain available as an Inspector option.

**Approved stacking-pickup milestone (2026-10-27):** The user requested collectible,
stackable modifications instead of weapon-switch hotkeys, with configurable duration set
to 30 seconds. Each editor-authored Area2D pickup supplies a typed WeaponModification;
AutoShooter owns independent per-stack lifetimes and rebuilds its working weapon from a
clean base plus active modifiers. Pickup recharge and buff duration are separate settings.
Pause freezes both. Saved presets and in-flight volley snapshots remain immutable. Fixed
pickup visuals/colliders/particles/timers are scene-authored. No loot manager or global
upgrade system is introduced. Weapon preset selection remains an authoring/test API only.

**Approved shooting/health-feedback milestone (2026-10-27):** The user requested auto fire,
expandable weapon tuning, projectile trails/hit feedback, two-layer health bars and three
20-HP targets respawning after five seconds. AutoShooter owns a typed arsenal of per-run
WeaponDefinition working copies, with nested ProjectileDefinition/shape/color copies made
explicitly. Each volley snapshots its projectile data. Projectiles sweep against world/target
layers and may pierce; no event bus or generic effect framework is introduced. Fixed shooter,
UI, target and respawn/feedback nodes remain scene-authored. Runtime instantiation is reserved
for actual bullets and short-lived impacts. Existing million-HP training targets remain;
respawning targets opt into death behavior. Targets own health, hit feedback, their bar and
respawn timer; the bar owns its chip animation. Mouse aims, controller right stick aims with
travel/last-aim fallback. Later upgrades may modify per-run resources, never shared presets.

**Approved target-dummy milestone (2026-10-27):** The user requested stationary grey
targets with 1,000,000 HP, ready for later shooting and damage effects. TargetDummy is a
small StaticBody2D scene owning per-instance health and a typed damage command/signal.
It has no movement, AI, death/removal, HP bar, shooting or hit-feedback behavior. Three
instances are authored in the movement playground. This is a training-target contract,
not a general enemy/combat component architecture. The shared renderer remains visual-only.

**Approved dash milestone (2026-10-27):** The user requested a smooth player dash with
particle/shader/tween feedback. Player owns the fixed-physics dash curve and cooldown;
DashFeedback owns an editor-authored trail, spark emitter and pulse shader. Movement input
selects direction, with aim/last direction as idle fallbacks. Dash stops at walls, has no
invulnerability or damage behavior, and pauses with gameplay. Temporary animation changes
node transforms and a per-instance shader material, never shared authored shape/color data.

**Version:** 1.0 (baseline, 2026-10-27)  
**Status:** Approved architecture for the Visual Lab; changes require an explicit decision.  
**Current phase:** Visual foundation only. No player movement, AI, projectiles, damage, particles, or upgrade logic yet.

**Approved scope update (2026-10-27):** Following review of the static gallery, the user
requested fullscreen, WASD/arrow navigation, additional shapes/colors, bullet visual samples,
shaders and particles. The playground now permits runtime camera panning and animated visual
effect exhibits. Bullet samples remain visual studies, with no firing, damage or collisions.
Fixed samples and effects remain authored scene instances. This explicitly supersedes the
earlier exclusions of camera movement, shaders and VFX for this playground expansion.
The one-renderer contract extends with appended geometry enum values; scene-local camera
input stays separate from rendering. Comparison samples may opt into an authored palette
override. Runtime camera updates and shader/particle animation do not require shape redraws.

**Approved movement milestone (2026-10-27):** The user requested a separate basic playground
for smooth player movement. This authorizes a reusable CharacterBody2D player with a circular
collider, acceleration/braking, directional visual rotation, fixed arena walls/obstacles,
and a following camera. The player owns input and locomotion; ShapeVisual remains render-only.
This supersedes earlier player-movement/physics exclusions for this isolated scene. Combat,
enemy behavior and projectile simulation remain deferred. All fixed nodes are editor-authored.
The movement playground becomes the default entry scene; the visual lab remains separate.

**Approved pause/settings milestone (2026-10-27):** The user requested Resume, Settings
and Quit, persistent controls, disabled WIP sound/graphics tabs, cursor steering and controllers.
The playground owns a ControlPreferences object using `user://settings.cfg`; no autoload is
introduced. A scene-authored pause UI continues processing while gameplay is paused and emits
the selected control mode after a successful save. Player input supports directional keyboard,
W-to-cursor steering, analog/D-pad movement and right-stick aim. Menu input uses Godot focus
navigation with explicit A/B and Start bindings. Sound and graphics settings remain deferred.

## 1. Project goals and non-goals

VECTORFALL is a small, top-down, shape-based auto-shooter inspired by survivor-style gameplay. The initial deliverable is **Visual Lab**, a Godot scene where we can compare geometric silhouettes, coordinated palettes, outlines, and details before building behaviors.

**Goals**
- Make authored shapes feel intentional, cohesive, and reusable in gameplay.
- Make visual iterations primarily Inspector/Resource changes, not code rewrites.
- Make every implementation straightforward for a human engineer to understand and modify.
- Preserve an easy route to Godot web export by using **strongly typed GDScript**.
- Keep every incremental change small and verifiable.

**Non-goals for the Visual Lab**
- Entity-component-system (ECS), dependency injection, service locator, global event bus.
- Gameplay entities, physics, enemies, combat, procedural spawning, or upgrades.
- General-purpose renderer framework or a subclass for every primitive shape.
- Production asset pipeline, shaders, VFX, sound, animation, networking, save/load.

## 2. Architectural decisions (locked for v1)

| Decision | Standard | Rationale |
| --- | --- | --- |
| Language | Godot 4, strongly typed GDScript | Godot-native workflow, approachable maintenance, potential web deployment |
| Organization | Feature-first for scenes; shared visual primitives isolated | Avoid global folders full of unrelated scripts |
| Composition | Scenes assemble nodes; scripts coordinate their owned children | Scene tree remains a useful source of truth |
| Visual rendering | **One `ShapeVisual`** with `_draw()` and private geometry-specific methods | Four simple geometries do not justify a renderer hierarchy |
| Configuration | `Resource` definitions plus Inspector editing | Data-driven without runtime dictionaries of ad hoc settings |
| Data ownership | Shared presets are authored data, not mutable runtime state | Prevents surprising cross-instance changes |
| Communication | Direct calls for commands; signals for events | Explicit dependencies, minimal indirection |
| Globals | No autoloads or service registries by default | Keep ownership discoverable |
| Structure | Simple and deliberate; no speculative abstraction | Minimize learning and maintenance cost |

The words *layer* and *component* describe responsibilities, not a requirement to create abstract base classes, generic interfaces, managers, or extra files.

## 3. Resource contracts

### 3.1 `ShapeDefinition` (`Resource`)

**Owns:** geometry and proportion; never gameplay stats or palette colors.

Initial fields:

| Property | Type | Notes |
| --- | --- | --- |
| `display_name` | `String` | Friendly label for debugging/gallery |
| `geometry` | `Geometry` enum | `CIRCLE`, `TRIANGLE`, `SQUARE`, `HEXAGON` |
| `radius` | `float` | Size in local units, validated > 0 |
| `outline_width` | `float` | Nonnegative; should remain visually proportional |
| `inner_scale` | `float` | Normalized interior detail scale (0.0–1.0) |
| `detail_style` | `DetailStyle` enum | `NONE`, `INSET`, `RING`; visuals may adapt per geometry |

Default geometries are centered on the local origin. Triangles point along local **negative Y**; squares are axis-aligned; hexagons are point-up. Scene transforms control external rotation and positioning. The visual geometry is **not** collision geometry.

Avoid adding arbitrary vertex editing, per-geometry resource subclasses, or an extensible decorations DSL until a concrete design requires them.

### 3.2 `ShapeColors` (`Resource`)

**Owns:** the four visual color roles used by one shape; never geometry, movement, or effects.

| Property | Type |
| --- | --- |
| `fill` | `Color` |
| `outline` | `Color` |
| `detail` | `Color` |
| `highlight` | `Color` |

Color selection must be fully data driven. The renderer must not branch on enemy identity to choose colors.

### 3.3 `PaletteDefinition` (`Resource`)

**Owns:** coherent theme colors for the stage and named visual roles. It has no gameplay knowledge.

| Property | Type |
| --- | --- |
| `background` | `Color` |
| `grid` | `Color` |
| `player` | `ShapeColors` |
| `enemy_common` | `ShapeColors` |
| `enemy_fast` | `ShapeColors` |
| `enemy_heavy` | `ShapeColors` |

Use a small `ColorRole` enum such as `PLAYER`, `ENEMY_COMMON`, `ENEMY_FAST`, `ENEMY_HEAVY` for role selection. A typed `colors_for(role)` accessor on `PaletteDefinition` is acceptable data lookup, not game behavior. Do **not** use string-keyed dictionaries for these fixed roles in v1.

The roles are visual and descriptive, not enemy classes. More roles are added only when designs need them.

### 3.4 Resource ownership and editing

1. Saved `.tres` files are the **source of truth** for authored presets.
2. Reusing a saved Resource means sharing the same object/reference. Changing it intentionally in the Inspector edits the authored asset and can affect all referencing instances.
3. Temporary runtime/editor experiments must operate on separate working copies or per-instance overrides; never silently mutate saved presets.
4. When copying composite Resources, explicitly verify that nested `ShapeColors` resources are isolated too. Do not assume a shallow duplicate is sufficient.
5. Missing required Resources are configuration errors, surfaced clearly (without noisy editor spam). No silent substitute geometry/colors.
6. Custom Resource property changes used by live previews must trigger `emit_changed()` via appropriate setters. A parent Resource does **not** automatically guarantee change forwarding from all nested custom Resources.

## 4. Node and scene boundaries

### `ShapeVisual` — reusable `Node2D`

- **Input:** one `ShapeDefinition`, one `ShapeColors`.
- **Responsibility:** render only, in local coordinates.
- **Core implementation:** `_draw()` routes by geometry to `_draw_circle_shape()`, `_draw_triangle_shape()`, `_draw_square_shape()`, `_draw_hexagon_shape()` plus a small shared detail helper where it actually reduces duplication.
- **Public API:** exported references for authored defaults; `configure(new_definition: ShapeDefinition, new_colors: ShapeColors) -> void` for deliberate changes.
- **May:** validate input, subscribe/unsubscribe to referenced Resource `changed` signals, `queue_redraw()` on relevant updates.
- **Must not:** access gallery nodes; interpret enemy types; own health, physics, state machines, AI, targeting, or spawn logic.
- **Draw performance:** redraw on change. No per-frame redraw unless later animations explicitly require it.

### `ShapePreview` — sandbox-only `Node2D` scene

- **Responsibility:** present one `ShapeVisual` in a gallery with a label/selection treatment and a designated `ColorRole`.
- **Owns:** its immediate visual and label children, and which shape definition it previews.
- **Public API:** `apply_palette(palette: PaletteDefinition) -> void` (resolves its role and forwards colors to its `ShapeVisual`).
- **Must not:** draw geometry itself or manage the global gallery.

### `GridBackground` — reusable `Node2D`

- **Responsibility:** draw the arena technical grid/background using supplied palette colors.
- **Must not:** know about shapes or selection state.

### `VisualLabPanel` — sandbox-only `Control`

- **Responsibility:** show Inspector-like runtime controls when needed and emit user intent.
- **Communication:** emits typed signals, e.g. `palette_selected(palette: PaletteDefinition)`; does not directly reach into shape previews.
- **Do not build this extensively before the static gallery is usable.** Inspector-driven tuning is the first milestone.

### `VisualLab` — sandbox root `Node2D`

- **Responsibility:** coordinate the immediate gallery and UI, apply a selected palette, manage preview selection when later implemented.
- **May:** use typed references to fixed immediate children and call their public methods.
- **Must not:** implement drawing logic, search arbitrary scene descendants, or become a generic application manager.

## 5. Initial scene hierarchy

```text
VisualLab (Node2D)                      # sandbox/visual_lab.tscn
├── Stage (Node2D)
│   ├── GridBackground (Node2D)         # shared grid scene
│   └── Gallery (Node2D)
│       ├── PlayerPreview (ShapePreview instance)
│       ├── GruntPreview (ShapePreview instance)
│       ├── StrikerPreview (ShapePreview instance)
│       └── TankPreview (ShapePreview instance)
├── Camera2D
└── CanvasLayer
	└── VisualLabPanel (Control)        # add minimal controls after gallery

ShapePreview (Node2D)
├── ShapeVisual (Node2D)                # shared visual scene
├── SelectionIndicator (Node2D)        # optional; only when selection exists
└── NameLabel (Label)
```

**Scene rules**
- Fixed composition, preview instances, and authored positions live in `.tscn` files.
- Runtime creation is for truly dynamic objects (future enemies/projectiles), not a way to avoid authoring a simple scene.
- A scene coordinates its **owned children** using typed references/public methods. Do not traverse into unrelated scenes with brittle paths such as `../../Gallery/...`.
- Use a signal when a child announces something; use a direct call when a parent asks a child to do something.
- A scene's private details remain private to its owner. Do not expose every descendant as a global dependency.
- Avoid reparenting or deleting editor-owned nodes in `@tool` scripts.

## 6. Proposed filesystem layout

```text
res://
├── features/
│   └── visual_lab/
│       ├── visual_lab.tscn
│       ├── visual_lab.gd
│       ├── shape_preview.tscn
│       ├── shape_preview.gd
│       ├── visual_lab_panel.tscn       # when needed
│       └── visual_lab_panel.gd         # when needed
├── visuals/
│   ├── shapes/
│   │   ├── shape_visual.tscn
│   │   ├── shape_visual.gd
│   │   ├── shape_definition.gd
│   │   ├── shape_colors.gd
│   │   └── palette_definition.gd
│   └── grid/
│       ├── grid_background.tscn
│       └── grid_background.gd
├── data/
│   ├── shapes/                        # authored shape .tres files
│   └── palettes/                      # authored palette .tres files
└── docs/
	└── GAME_DEV_STANDARDS.md
```

We may omit not-yet-used files from the initial commit. Avoid parallel `scripts/` vs `features/` organizing systems and a blanket `managers/` folder.

## 7. Strongly typed GDScript style

| Concern | Rule |
| --- | --- |
| Types | Explicit member, parameter, return and node-reference types. Functions returning nothing use `-> void`. |
| Inference | `:=` only where type is unambiguous; avoid accidental `Variant`. |
| Names | Files/functions/variables/signals `snake_case`; `class_name`/named types `PascalCase`; constants `UPPER_SNAKE_CASE`. |
| Visibility | Prefix internal fields and helpers with `_`. Do not pretend it enforces access control. |
| Class registration | Use `class_name` for types shared across scenes/resources; not every scene-local script. |
| Methods | Small, intention-revealing methods; descriptive parameters; avoid multipurpose `update_everything()`. |
| Export | `@export` for designer-tunable properties; no magic values buried in rendering branches. |
| Validation | Validate meaningful ranges and required references; surface programming errors rather than hiding them. |
| Formatting | Follow Godot style: tabs, LF, trailing newline, prefer lines under 100 characters. |
| Comments | Explain *why*, constraints, and counterintuitive engine behavior; avoid narrating obvious code. |
| Signals | Prefer past-tense events such as `palette_selected`; typed parameters where applicable. |
| Warnings | Enable useful GDScript warnings; fix warnings before accepting a slice, except documented exceptions. |
| Tests | Require manual acceptance steps for every slice; add automated tests only when they buy us meaningful confidence. |

Code organization within a script: class annotation/declaration, signals, enums/constants, exports, internal state, lifecycle callbacks, public API, private helpers, signal handlers. Keep a consistent ordering; don't create extra class files just to satisfy this ordering.

## 8. Editor execution and change propagation

- Use `@tool` only for scripts required to render/update in the editor (`ShapeVisual` and its supporting editable custom Resource types, and grid drawing if previewed there).
- Keep tool-mode logic side-effect-light: draw, validate, and refresh. **No editor scene-tree construction, reparenting, deletion, or file writes** without a separately reviewed editor tool.
- Subscribe to the currently assigned `ShapeDefinition.changed` and `ShapeColors.changed` signals, and disconnect old subscriptions when swapped or exiting the tree.
- `queue_redraw()` refreshes cached custom draw commands when data changes; do not assume `_draw()` runs continuously.
- `PaletteDefinition` top-level changes can drive stage/grid refresh; nested `ShapeColors` changes are watched directly by the `ShapeVisual` using them. This avoids relying on automatic nested change bubbling.
- If a setter fires before the node enters the scene tree, keep the assigned reference and refresh when ready.

## 9. Visual design rules — Tech Interface direction

- Shapes are the actual visual asset, **not placeholder sprites**.
- Dark graphite/teal arena, precise geometric outlines, restrained accents, subtle technical grid.
- Individual shape silhouettes must remain distinguishable in grayscale and at small on-screen sizes.
- Fill/outline/detail/highlight are distinct purposeful roles, with controlled contrast.
- Never use random colors per instance as a substitute for palette design.
- Use coherent ratios for inset details and outlines, not arbitrary per-enemy drawing hacks.
- Avoid large uniform neon bloom; any later glow, hit flashes, or particles should follow the same restrained visual language.
- UI styling should reuse palette vocabulary and stay subordinate to gameplay readability.

## 10. Implementation sequence (not started)

**Slice 0 — Repository skeleton**
- Set up versioned project, `.gitignore`, project settings, standards file, blank entry scene.
- Acceptance: opens with no parser errors and a known default scene; initial commit.

**Slice 1 — Reusable geometry**
- Implement `ShapeDefinition`, `ShapeColors`, `ShapeVisual` and four shapes with editor-visible authoring.
- Acceptance: independent geometry/color selection, correct local anchoring, validated properties, no gameplay code.

**Slice 2 — Static gallery and palettes**
- Implement four fixed `ShapePreview` instances, `GridBackground`, `VisualLab`, at least two authored palettes.
- Acceptance: all previews visible, look coherent at play resolution, palette changes affect expected roles, no shared-resource bleed.

**Slice 3 — Visual Lab controls and polish**
- Implement minimal `VisualLabPanel` for palette switching and comparison, plus selection/preview adjustments only if needed.
- Acceptance: visual editing is easy in the Inspector and run-time palette switching works; no bullets, effects, or enemy behaviors.

Stop after each slice for a short human review. Later features get separate architecture decisions, not implied acceptance under this document.

## 11. Definition of done for the Visual Lab

- [ ] Circle, triangle, square, and hexagon render from the **same** `ShapeVisual` class.
- [ ] Renderer has no enemy/player behavior and no knowledge of the sandbox.
- [ ] Altering a `ShapeDefinition` changes silhouette/proportions without editing colors.
- [ ] Altering a `ShapeColors` changes visual palette without editing geometry.
- [ ] Switching the active `PaletteDefinition` updates the whole gallery and stage.
- [ ] Saved authored presets are unaffected by temporary experimental overrides.
- [ ] A shared Resource edited intentionally in the Inspector refreshes all subscribed previews.
- [ ] Swapping a Resource detaches the old change subscription and attaches the new one.
- [ ] Adding another `ShapePreview` scene instance does not require modifying rendering logic.
- [ ] All fixed previews are present in the scene tree and visible/editable in the editor.
- [ ] No parser/runtime errors, no unexplained warnings, no unnecessary per-frame redraws.
- [ ] A teammate can adjust colors, geometry, and labels without requesting generated code.

## 12. Collaboration contract for AI-generated changes

Before code changes, provide:
1. **Intent:** the one behavior or capability being added.
2. **Files affected:** new/modified files and why each is necessary.
3. **Contracts:** public API, required scenes/resources, and data flow.
4. **Tradeoffs:** anything new or surprising about design choices.
5. **Acceptance:** explicit steps to verify the change in Godot.

During code generation:
- Respect this file; do not silently introduce a new architecture.
- No unsolicited renames, refactors, class hierarchies, event buses, singletons, or managers.
- Never invent missing files or assume paths in an existing project; inspect what exists.
- Keep changes feature-scoped and human-reviewable; prefer diffs to wholesale replacement.
- No large monolithic `_ready()` scene construction and no reliance on AI to maintain the project.
- Don't mark work as tested if it hasn't actually been run/checked.

After changes, provide:
- What changed and why; any API or scene-tree changes.
- How to run it, what to inspect, expected visual result, and known limitations.
- A suggested Git commit boundary.

When a new requirement contradicts this document: **call out the conflict, propose a modification, and update the standards only with agreement**. Exceptions should be explicit and documented.

## 13. Deferred decisions

Not yet established and **not** to be silently decided by implementation:
- Animation/update model for moving shapes, rotating details, glow and later shader effects.
- Combat/gameplay component design, damage, physics collisions, pooling, enemy spawning.
- Upgrade definition model and runtime build-state ownership.
- Profiling strategy for large enemy counts.
- Automated test framework and CI.

## 14. Godot references

- [Resource reference — changed signals and duplication](https://docs.godotengine.org/en/stable/classes/class_resource.html)
- [Custom drawing in 2D — `_draw()` and `queue_redraw()`](https://docs.godotengine.org/en/stable/tutorials/2d/custom_drawing_in_2d.html)
- [Running code in the editor — `@tool` cautions](https://docs.godotengine.org/en/stable/tutorials/plugins/running_code_in_the_editor.html)
- [GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
- [GDScript warnings](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/warning_system.html)

---

**Architecture checkpoint:** We are ready to implement **Slice 0** when requested; there is no Visual Lab implementation in this deliverable.


**Approved action audio (2026-10-27):** The user requested basic action sounds and
persistent sound settings. This enables the Sound tab. Fixed scene-owned audio players
use original synthesized WAV cues, bounded polyphony and retrigger intervals.
Master/Combat/Effects/UI volumes and mute save with controls. Preview is reversible;
gameplay pauses its audio and menu audio remains active. Graphics stays WIP.


**Dash upgrade milestone (2026-10-27):** The user requested +1 dash and reduced-cooldown
pickups. The existing modifier resource/stack lifetime owner now also aggregates two dash
bonuses; the player owns charge capacity, sequential recharge and cooldown progress.
Run-long +1-charge and -10%-of-base-recharge pickups are editor-authored. Capacity caps at
eight; cooldown reduction caps at 80% and minimum recharge is 0.2s. Added capacity grants
only its new slots, and speed changes preserve the fraction of a pending recharge. Reset
refills current capacity. No movement/weapon preset data is mutated by upgrades.


**Enemy archetype milestone (2026-10-27):** The user requested seven active enemy types:
slow tank, fast fragile runner, evasive dasher, alternating radial shooter, spiral shooter,
telegraphed charger and death splitter. PlaygroundEnemy extends the current TargetDummy
health/status feedback contract; EnemyDefinition holds tunable archetype behavior. Fixed
instances and three dormant fragments are authored in EnemyField; splitting activates those
children rather than constructing enemies. Only hostile projectiles instantiate at runtime.
Hostile movement and attacks honor stun/chill, pause and reset. Player contact/projectile
hits currently provide grace-limited flash, sound and a counter; player HP/death remains a
later scope decision. R resets this encounter while preserving collected upgrades.


**Player health milestone (2026-10-27):** The user requested player health and damage
sounds with component reuse. Player owns configurable HP and accepts contact/projectile
damage through the existing grace-limited receive_enemy_hit API. The HUD instances the
existing DamageHealthBar, now optionally showing current/max and stretching to its width.
IncomingHitSound and ActionSound are reused; depletion reuses the kill cue. Zero HP blocks
movement/dash/firing/collection until R restores the encounter; existing upgrades and
chosen auto-fire preference remain intact. No game-over menu or health persistence added.


**Damage emphasis and repair pickups (2026-10-28):** The user requested stronger camera,
flash and damage indicators, followed by healing pickups with a green bar tween. An
editor-authored PlayerDamageFeedback handles bounded camera offset, directional edge
flash, a short-lived HP-loss label and a health-bar pulse. Player damage_taken supplies
the optional source direction while existing hit_received keeps its signature. The
player reuses the target hit shader. Repair pickups reuse UpgradePickup visuals/audio/
recharge in an optional healing mode; Player.heal clamps HP and emits health_changed.
DamageHealthBar optionally animates healing with a green pulse. Pausing freezes effects;
reset restores camera/bar state. No timescale changes, camera zoom or runtime fixed nodes.


**Web/mobile delivery cycle (2026-10-28):** The user requested recovery of the browser
hosting conversation and GitHub/Pages setup for Trezza10/vector-fall. A pinned Godot 4.7
single-threaded Web preset and checked Actions workflow publish main. PR builds do not
deploy. Workspace-only tools/templates are downloaded from official releases and checksum
verified. Desktop renderer stays unchanged; web overrides use Compatibility. Revision-named
assets and a stable launcher avoid service-worker stale builds. Editor-authored dual touch
sticks and dash/pause/reset buttons make phone play possible; existing desktop inputs remain.
This authorizes Git initialization and publishing this project to the provided repository,
without changing its existing public visibility. No recurring automation is introduced.

**Camera zoom (2026-10-28):** User requested a saved zoom setting and a closer default. Graphics now exposes an editor-authored 0–100% slider (camera scale 1–2, default 50% / 1.5x). Existing preferences own persistence; the pause menu emits preview values and restores saved zoom on Back/Resume. The playground applies camera zoom only; HUD/touch sizing stays independent. This supersedes the disabled Graphics tab for this setting.

**Silencer and portrait milestone (2026-10-28):** User requested a temporary shooting-block enemy and vertical phone support. EnemyDefinition appends SILENCER with tunable radius/duration; PlaygroundEnemy reuses authored warning/audio nodes for a 0.9-second escapable windup and pulse. AutoShooter owns the independent, pause-aware silence countdown and gates both automatic/direct volleys; player reset clears it without changing death blocking or auto-fire preference. A fixed HUD label displays remaining silence. The eighth enemy is authored in EnemyField. The playground switches viewport design dimensions on orientation changes, preserving saved zoom while moving portrait health above bottom touch controls. Existing authored pause UI fits the portrait design. Verification covers telegraph evasion, hit/expiry, pause/reset, firing/dash independence and orientation bounds.

**One-hand mobile controls (2026-10-28):** User requested combined aim/move touch steering and a one-hand dash. The authored mobile UI now has one bottom-centered pad; its vector feeds both touch movement and aim. Release brakes while retaining last aim. A lift/retouch within an Inspector-tunable 0.28 seconds arms one dash, triggered only once a meaningful direction is supplied. Pause/reset/orientation clear gesture state. This supersedes the dual-stick mobile layout; desktop/controller schemes are unchanged. Checks cover steering/aim, other-finger rejection, retouch dash direction, single charge per touch, and reset/pause.

**Floating steering and dash button revision (2026-10-28):** User rejected retouch dash and requested fullscreen joystick control plus a bottom-left mobile dash button. TouchStick now owns one finger across a fullscreen authored Control, samples its floating origin at touch-down and reuses fixed Base/Thumb nodes for feedback. Authored button NodePaths reserve dash/pause/reset rectangles; extra fingers cannot steal steering. PlaygroundTouchControls routes the restored authored Dash button to the existing player action and displays charges. Retouch gestures are removed. Release/cancel, pause, reset and orientation changes clear input/visuals. Checks include real viewport button input during steering, button-zone exclusion and repositioning. This supersedes the earlier retouch-dash milestone.

**Minimal mobile HUD (2026-10-28):** User requested an icon-only dash button, removal of reset/dash meters/hints, and fullscreen in Graphics settings. The authored Dash texture is now a vector chevron icon with availability dimming; Reset and its reserved touch zone are removed. Mobile hides dash telemetry, health hints and the silence HUD countdown; health/pause/dash remain. The browser fullscreen/version overlays are removed; an authored Graphics button invokes the existing DisplayServer fullscreen API. Fixed scene nodes remain editor-authored. Checks cover icon/reset structure, mobile HUD visibility and existing steering/button behavior.
