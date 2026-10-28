# Vector Fall

A Godot 4.7 technical-interface action playground with smooth movement, charge-based
dash upgrades, automatic weapons, stackable effects, seven enemy archetypes and player health.

**Play:** https://Trezza10.github.io/vector-fall/

Keyboard/mouse and controllers work on desktop. Phones get independent MOVE and AIM
sticks plus DASH, PAUSE and RESET. Landscape is recommended. The Play screen also offers
**Use touch controls** for previewing the phone controls on desktop. Browser audio starts
with interaction; settings persist per browser/device when storage is allowed.

## Development cycle

1. Open `project.godot` with Godot **4.7 stable**; F5 runs the playground.
2. Edit scenes/resources locally and test the changes.
3. Commit and push to `main`.
4. GitHub Actions runs the checks, exports the web game and publishes GitHub Pages.
5. Open the stable Play link on your phone. The build revision appears at the bottom.

Pull requests run the same build/checks but do not deploy. Only pushes/manual runs on
`main` publish. No hosting credentials or personal tokens are stored in the repository.
GitHub's short-lived workflow token handles deployment.

## Build and preview locally

Requires Python **3.11+** (CI uses 3.12), Git and Godot 4.7 stable. If Godot is not on PATH,
set `GODOT_BIN` to its console/editor executable. The helper otherwise downloads the
pinned official editor and web templates and verifies their published SHA-512 checksums.
Tools/templates/user data remain in ignored `.godot/` folders.

```powershell
$env:GODOT_BIN = 'C:/path/to/Godot_v4.7-stable_win64_console.exe'
python tools/web_build.py
python tools/serve_web.py
```

Open `http://127.0.0.1:8765/`. Opening exported files with `file://` will not work.
Generated output under `build/web/` is ignored and is not committed to the source repo.

Optional all-in-one publishing helper (stages **all non-ignored project changes**):

```powershell
./tools/publish.ps1 -Message 'Describe the change' -PythonBin 'C:/path/to/python.exe' -GodotBin 'C:/path/to/Godot_v4.7-stable_win64_console.exe'
```

The helper checks/builds before committing and never force-pushes. Work on branches and
merge to `main` when a change should go live. Previous revisions remain in Git history.

## Hosting configuration

The Pages source is **GitHub Actions**, configured in repository Settings > Pages.
The workflow is `.github/workflows/pages.yml`. The Web export is single-threaded using
Compatibility/WebGL 2, so it needs no custom isolation headers. Native desktop rendering
stays unchanged. Relative asset paths support the `/vector-fall/` Pages subdirectory.

The stable launcher fetches uncached build metadata and opens revision-named game assets.
PWA/service-worker caching is disabled for the development build. Bookmark the stable Play
link. The in-game browser Quit button reloads the latest build instead of closing the tab.

GitHub Pages is public hosting. Source visibility is a separate repo setting; Pages from
a private personal repository requires an eligible plan such as GitHub Pro. Source can
be recovered from downloadable browser builds to some degree, as with all web games.

## Engineering notes

Fixed gameplay/UI nodes and split-enemy fragments are scene-authored. Resource-driven
configuration and shared components are described in `docs/GAME_DEV_STANDARDS.md` and the
feature docs. CI currently checks web/touch controls, player health, enemy behavior and
damage/healing feedback. The larger `tests/` folder contains additional regression checks.

Phone compatibility still needs playtesting on physical devices, especially iOS/Safari.
Web builds use Godot's sample audio path; desktop-only audio bus effects such as the hard
limiter do not apply there. No accounts, server multiplayer or native mobile package are
required to play this build.
