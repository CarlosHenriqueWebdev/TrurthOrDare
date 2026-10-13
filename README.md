# Truth or Dare

A mobile-first truth-or-dare party game built in Godot 4. Menu-driven,
CSV-fed, playable on desktop or Android.

## Requirements

- Godot 4.4 or newer (4.7.2 tested)
- For Android export: OpenJDK 17 + Android SDK

## Running

1. Open the project folder in Godot.
2. Press **F5**.
3. If prompted for a main scene, pick `res://scenes/Home.tscn`.

## How it plays

1. Home screen → **START GAME**.
2. Add 2–8 players → **RANDOMIZE PLAYER ORDER** → **START GAME**.
3. Each turn shows the current player, a truth or dare, and its category.
4. **COMPLETE** advances; **FORFEIT** opens the penalty picker.
5. Non-endless mode ends when all cards in the pool have been played.

Settings (gear icon) has music/SFX toggles, an Endless Mode switch, and
CSV import for cards and penalties.

## Custom cards

Upload a CSV with columns `type,category,text`:

    type,category,text
    truth,sober,Say the name of the person you texted most recently.
    dare,drunk,Text your most recent ex an embarrassing message.

- `type`:     truth or dare
- `category`: sober, tipsy, drunk, or wasted
- `text`:     the prompt. Supports BBCode markup:
              [b]bold[/b], [i]italic[/i], [color=#c04143]red[/color].

Uploads are copied into `user://` so the original file can be moved or
deleted without breaking the game. **CLEAR** resets to the bundled default.

## Custom penalties

Upload a CSV with columns `group,label`:

    group,label
    Drink,Beer
    Drink,Wine
    Drink,Spirits
    Custom 1,Skip next turn

Rows sharing a `group` are shown together in the penalty dialog. Up to
6 groups and 6 options per group.

## Project layout

    autoload/    Global singletons (Design tokens, AudioManager,
                 DataManager, GameState, SaveManager, Navigation,
                 ToastManager, WindowManager).
    assets/      Backgrounds, fonts, icons, audio, avatars.
    data/        Default cards.csv and pass_options.csv.
    scenes/      One .tscn per screen (Home, PlayerSetup, Game).
    scripts/     Screen controllers, plus reusable UI components
                 in scripts/components/.

## Design notes

- Single-source cards: truths and dares live in one CSV with a `type`
  column, so users only manage one file.
- User uploads are copied to `user://` so the game owns its data.
- Markup uses Merienda (regular / extra-bold / light) since the default
  FugazOne face ships with a single weight.
- The deck-stack effect on the prompt card is decorative; each prompt is
  drawn from a shuffled, non-repeating pool.
