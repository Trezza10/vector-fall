# Visual playground

Open `res://features/visual_lab/visual_lab.tscn`, or press F6 with that scene open.
The project's F5 entry scene is now the separate movement playground; use F6 for this lab.
The reference viewport is 1440 × 900;
the explorable playground is 2880 × 1800. It starts fullscreen.

## Navigation and exhibits

- WASD or arrows: move the camera; Shift: move faster; R: return home.
- F11: toggle fullscreen; Esc: return to a window. In Godot's embedded game view,
  use a separate game window if the editor intercepts fullscreen shortcuts.
- East: diamond, pentagon, octagon, star, cross, and three palette comparisons.
- South: eight static projectile designs with different silhouettes and proportions.
- Southeast: ion-core, expanding-pulse and scanning-shield shaders; sparks, embers and dust.
- Tune Camera2D's speed, fast multiplier and world bounds in the Inspector.
- For effects, open the reusable scenes under `visuals/effects`, or enable Editable Children
  on an instance to inspect its Field material. Shader uniforms control tint, speed,
  intensity and style. Particle nodes expose count, lifetime, spread, velocity and gradients.
- The comparison and projectile previews use Palette Override to preserve authored palettes.
  Ordinary previews continue to follow the root palette.

## Editing

- Expand `Stage/Gallery`: all 37 previews and their transforms are authored in the scene.
- Select a preview to edit its caption, shape definition, palette, and visual color role.
- Expand its ShapeDefinition to adjust radius, outline width, inset scale, or detail style.
- The main samples use inset details, the middle row uses double insets, and the small row
  removes details to test silhouette readability.
- Select the VisualLab root and assign `data/palettes/cold_terminal.tres` to compare the
  alternate palette. Restore `deep_signal.tres` for the initial look. The root distributes
  that palette to its direct gallery previews and grid in the editor and at runtime.
- Palette role names anticipate future assignments; no sample has gameplay behavior.
- Edit the palette's nested ShapeColors for fill, outline, detail, and highlight colors.
- Saved resources are shared intentionally. Use Godot's **Make Unique** before changing
  one preview independently. For an independent palette, make its nested color resources
  unique too. No runtime code modifies resource properties.
- Duplicate a ShapePreview instance in the editor and move it to add another sample.

UI labels and sample-card styling are authored directly in the scene. They currently use
fixed neutral interface colors; palette switching changes the shapes, background, and grid.
Runtime controls move only the camera. Bullet designs have no firing, combat, physics or
spawning. Shaders and particle emitters animate as isolated visual exhibits. Shape geometry
still redraws only on change.

## Acceptance review

1. Open the scene in the 2D editor: all previews should be visible without running it.
2. Move a preview; run the scene and confirm that its authored position is retained.
3. Change a definition's radius/inset: geometry updates without changing its colors.
4. Change a palette color: subscribed samples update without changing geometry.
5. Swap the root palette: all shapes and the stage update together.
6. Swap a preview definition. Editing the previously assigned definition should no longer
   redraw that preview; editing the new definition should update it.
7. Make a preview's definition unique, edit it, and confirm other samples retain theirs.
8. Inspect at play resolution, particularly the small samples, for readable silhouettes.

## Validation and commit boundary

Checked using Godot 4.7: editor import, headless scene startup, and an OpenGL rendered capture.
The restricted test environment requires a writable APPDATA location inside `.godot`.
Godot reports a system certificate-store warning, unrelated to these local visuals.
Interactive Inspector acceptance steps remain for human review.

Expansion checks passed: simulated camera movement and home reset, fullscreen/windowed
switching, 37 authored samples, preserved palette overrides, rendered captures of all four
areas, and normal D3D12 Forward+ startup. OpenGL Compatibility rendering also passed.
For manual review, navigate to each quadrant, try diagonal movement and Shift, and toggle
F11 at your normal desktop resolution. Inspect shader/particle animation while running.

Suggested commit: `Add editor-authored visual playground and reusable shape resources`.
Expansion commit boundary: `Expand visual playground with navigation and effect studies`.
