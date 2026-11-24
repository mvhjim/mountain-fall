# Mountainfall

An isometric, dialogue-driven browser game made with Godot. Four friends leave the city for a cabin in the mountains, and a guest nobody invited is hiding somewhere.

Plan and design notes: https://claude.ai/artifact/DStM5Pa9yYNTLuwPHxqYng

## Engine version

**Godot 4.7.2 stable, standard build (not .NET).** Everyone working on the project uses this exact version. The .NET build can't export to the web.

Download: https://godotengine.org/download/archive/4.7.2-stable/

## Getting started (Windows)

1. Download Godot 4.7.2 (standard), unzip it anywhere and run the `.exe`.
2. Install [GitHub Desktop](https://desktop.github.com/) and clone `mvhjim/mountain-fall`.
3. In Godot's Project Manager, click **Import** and select `project.godot` in the cloned folder.
4. Press **F5** to run the game in a window.
5. To try the web version: in the editor top bar, click the **Remote Debug / Run in browser** button (the screen icon with a globe). The first time, Godot asks you to download export templates; accept.

Don't open `index.html` by double-clicking. A web build has to be served by a web server, which "Run in browser" does for you.

## Controls

Everything works with the keyboard alone. Mouse support is added on top.

| Action | Keys | Input Map name |
| --- | --- | --- |
| Walk | WASD or arrow keys | `move_up`, `move_down`, `move_left`, `move_right` |
| Interact, talk, pick up | E, Space, Enter | `interact` |
| Cycle nearby targets | Tab | `cycle_target` |
| Inventory | I | `inventory` |
| Combine items | C | `combine` |
| Back, close, menu | Esc | `cancel` |

Menus use Godot's built-in `ui_*` actions (arrows, Enter, Esc).

## Folders

```
core/         shared by all scenarios: player, interactables, UI, global state
scenarios/    one folder per scenario: map, dialogue, items
assets/       tiles, sprites, fonts, audio
addons/       third-party Godot add-ons (Dialogue Manager comes later)
```

## How we work

- `main` is always playable. Each change comes in as a pull request with a short "how to test" note.
- Only one person edits a given scene (`.tscn`) at a time, because scene files are hard to merge. Scripts and dialogue files merge fine.
- Commit the `.uid` files that Godot creates next to scripts. Never commit the `.godot/` folder (it's in `.gitignore`).

## Web build

Every push to `main` builds the game and publishes it to GitHub Pages (see `.github/workflows/pages.yml`).

One-time setup: in the repo on GitHub, go to **Settings → Pages** and set **Source** to **GitHub Actions**.

The game will then be at https://mvhjim.github.io/mountain-fall/

## Art and audio

Placeholder art comes from free sources such as Kenney.nl. Record the source and license of every asset in `assets/CREDITS.md` when you add it.

## License

Code: GPL-3.0 (see `LICENSE`). Third-party assets keep their own licenses.
