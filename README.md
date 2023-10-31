# Loader
A "loader" application used in palera1n, this app will appear on the homescreen once you've jailbroken.

## Building on macOS
| Command          | Action                                     | 
| ---------------  | ------------------------------------------ |
| `make IOS=1`     | Compiles loader for iOS & creates `.dmg` for use   |
| `make TVOS=1`    | Compiles the appleTV loader varient & creates `.dmg` for use |

## Optional Flags
You can use these optional flags when compiling.

| Flag       | Description                           |
| ---------- | ------------------------------------- |
| `TIPA=1`   | Outputs as `.tipa` (if you're testing it on Trollstore), instead of `.ipa` |
| `NO_DMG=1` | Does not create `.dmg`                 |

## Contributions
Pull requests are welcome <3