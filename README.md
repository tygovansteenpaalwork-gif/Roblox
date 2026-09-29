# Roblox

A collection of client-side Luau scripts for Roblox, organised in one repository.

## Structure

| Folder | Contents |
|---|---|
| [`Games/`](Games) | Scripts built for one specific game. Each game has its own folder. |
| [`Universal/`](Universal) | Scripts that work in any game. |
| [`Features/`](Features) | Reusable building blocks that other scripts can load. |

## Games

| Game | Script | Description |
|---|---|---|
| [Murder Mystery 2](Games/MurderMystery2) | `CoinFarm.lua` | Automatic coin farm with murderer avoidance |

## Loading a script

Every script can be loaded straight from this repository:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/tygovansteenpaalwork-gif/Roblox/main/<folder>/<script>.lua"))()
```

Scripts with settings read them from `getgenv()` before loading. See the README in each script's
folder for the exact settings.

## Disclaimer

Using third-party scripts breaks the Roblox Terms of Use and the rules of most games.
Your account can be banned. Use these scripts at your own risk, preferably on an alt account.
