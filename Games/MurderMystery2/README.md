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

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/tygovansteenpaalwork-gif/Roblox/main/Games/MurderMystery2/CoinFarm.lua"))()
```

Stop it:

```lua
getgenv().CoinFarm.stop()
```

Running the script again stops the previous instance first.

## Configuration

All settings are in the `Config` table at the top of the script. They can also be changed while
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
