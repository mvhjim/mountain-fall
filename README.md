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
| Combine items (in the inventory: pick one, C, pick another, C) | C | `combine` |
| Back, close | Esc | `cancel` |
| Pick a dialogue answer | Up/Down + Enter, or 1-9 | |

Mouse: click the ground to walk there, click a person or object to walk to it and use it, click to continue dialogue.
Menus use Godot's built-in `ui_*` actions (arrows, Enter, Esc).

## Folders

```
core/                  shared by all scenarios
  game_state.gd        names, falls (deaths), scores, story flags   (autoload GameState)
  inventory.gd         items the active friend carries              (autoload Inventory)
  item.gd              the Item resource (id, name, description, icon)
  player/              the controllable friend: walking, clicking, falling off edges
  interactable/        add as a child to anything you can talk to or use
  ui/                  name entry screen, HUD, inventory window, dialogue box
scenarios/
  s1_city/             scenario 1: Maja collects the friends (single player intro)
    s1_city.tscn       the map (open this in the editor)
    s1_city.dialogue   all conversations, plain text
    s1_city.gd         scenario logic called from dialogue ($> even_joins())
    items/             items for this scenario
  s2_cabin/            scenario 2: arrival at the cabin, one turn per friend, scoring
core/gutten/           Gutten, the hidden fifth friend, and the SafeZone he gives up at
assets/                tiles, sprites (placeholders for now), fonts, audio
addons/                Dialogue Manager 4.2.0 by Nathan Hoad (MIT)
tests/                 automated playthrough
tools/                 placeholder art generator (Python, not part of the game)
```

## Editing the game

- **Map:** open `scenarios/s1_city/s1_city.tscn`. Select `Floor` to paint tiles (TileMap panel at the bottom). Objects live under `World`; drag them around. `World` sorts by height on screen, so things lower on screen draw in front.
- **Dialogue:** open the **Dialogue** tab at the top of the editor, or edit `s1_city.dialogue` in any text editor. Use `{{maja}}`, `{{even}}`, `{{sara}}`, `{{tom}}` for the friends' names (players choose them). Don't name variables in scenario scripts `maja`, `even`, `sara` or `tom`, or dialogue will pick those up instead.
- **People and objects you can use:** give them an `Interactable` child (see `MrsBerg` in the scene). Set its name, verb ("Talk to"), dialogue file and cue (the `~ cue` in the dialogue file).
- **Items:** in the FileSystem dock, right-click `items/` > New Resource > Item. Register new items in the scenario script's `ITEMS` list.

## Turns, points and Gutten (scenario 2)

- Each friend gets one turn with one task. A "Maja's turn!" card comes up between turns, so it works for one player or four players sharing a keyboard.
- Points: task done +100, speed bonus up to +50, fall -20, finding Gutten +50 (once per friend), escaping him +75. Change the numbers at the top of `s2_cabin.gd` and in `core/gutten/gutten.gd`.
- Gutten wakes up when you open the cellar hatch, or combine beer and cigarettes in the inventory. He needs 2 seconds to wake up, then he chases you. Reach the sauna or survive 25 seconds. If he catches you, he drags you off the edge, which counts as a fall.
- New triggers: in dialogue, call `$> wake_gutten("NodeName")`. For item combos, use `Inventory.add_recipe("a", "b", some_function)` in the scenario script.

## Tests

```
godot --headless --path . res://tests/playthrough_s1.tscn
godot --headless --path . res://tests/playthrough_s2.tscn
```

Each one plays a scenario from start to end and prints PASS/FAIL for each step. Scenario 1 covers falling off an edge, getting the keys, convincing Even and driving off. Scenario 2 covers all four turns, Gutten from the cellar and from beer + cigarettes, and the scoreboard.

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
