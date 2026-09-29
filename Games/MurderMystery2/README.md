# Murder Mystery 2: Coin Farm

Collects coins automatically during a round. It only moves your own character and does not
interact with other players, weapons, or the round itself.

## Features

- **Starts automatically.** Waits for a round, farms, and waits again for the next one.
- **Tween movement.** Moves to the nearest coin at a set speed instead of teleporting.
- **Reset on full bag.** Resets your character when your coin bag is full, so you leave the round
  instead of standing around.
- **Role-aware.** Never resets you as Murderer or Sheriff. That would end the round or drop the
  gun for everyone else.
- **Murderer avoidance.** Skips coins near the Murderer and stops moving if they get in the way.
- **Role detection.** Uses the game's own role updates, with a Knife/Gun check as a fallback when
  the script starts mid-round.
- **Stuck protection.** Skips a coin that does not register after a set number of attempts.
- **Works with event currencies.** Detects a full bag for Coins, Candy, and other event currencies.

## Usage

With the default settings:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/tygovansteenpaalwork-gif/Roblox/main/Games/MurderMystery2/CoinFarm.lua"))()
```

With your own settings: copy this, change the values you want, and run it. The values below are
the defaults. Settings you remove keep their default.

```lua
getgenv().CoinFarmConfig = {
    -- Studs per second while tweening to a coin. Walking is 16; much higher gets flagged more easily.
    TweenSpeed = 25,
    -- Coins further than this are skipped so we never cross the whole map in one go.
    MaxCoinDistance = 300,
    -- Pause after reaching a coin so the touch registers.
    DelayAfterCoin = 0.15,
    -- A coin that still is not collected after this many visits gets skipped for the rest of the round.
    MaxAttemptsPerCoin = 2,
    -- How often to check for a new round while waiting.
    IdleCheckInterval = 1,
    -- Reset when the bag is full, so you are out of the round instead of standing around.
    ResetWhenBagFull = true,
    -- Skip coins near the Murderer and abort a tween when they get close.
    AvoidMurderer = true,
    MurdererSafeDistance = 40,
    ShowNotifications = true,
}

loadstring(game:HttpGet("https://raw.githubusercontent.com/tygovansteenpaalwork-gif/Roblox/main/Games/MurderMystery2/CoinFarm.lua"))()
```

Unknown settings, wrong types, and negative numbers are ignored with a warning, and the default
is used instead.

Stop it:

```lua
getgenv().CoinFarm.stop()
```

Running the script again stops the previous instance first.

## Configuration

Set these in `getgenv().CoinFarmConfig` before loading (see above). They can also be changed while
the script is running, for example `getgenv().CoinFarm.Config.TweenSpeed = 20`.

| Setting | Default | Description |
|---|---|---|
| `TweenSpeed` | `25` | Movement speed in studs per second. Normal walking speed is 16. |
| `MaxCoinDistance` | `300` | Coins further away than this are skipped. |
| `DelayAfterCoin` | `0.15` | Pause after reaching a coin so the pickup registers. |
| `MaxAttemptsPerCoin` | `2` | Skip a coin for the rest of the round after this many failed pickups. |
| `IdleCheckInterval` | `1` | Seconds between checks while waiting for a round. |
| `ResetWhenBagFull` | `true` | Reset your character when your bag is full. |
| `AvoidMurderer` | `true` | Stay away from the Murderer. |
| `MurdererSafeDistance` | `40` | Distance in studs to keep from the Murderer. |
| `ShowNotifications` | `true` | Show status notifications in the corner of the screen. |

## Requirements

An executor that supports `getgenv`, `loadstring`, and `game:HttpGet`.
