# Loader
Loader application used in palera1n, this has a purpose of bootstrapping your phone after jailbreaking via command-line, similar to checkra1n, but with a lot more customizability and features.

## Notes
- When compiling for the simulator, do not have an `./apple-include` be present, this can be quickly be solved by doing `gmake clean`

- This application will only work if you've used palera1n to jailbreak, as theres special entitlements and processes it communicates with to function.
    - As well as using palera1n-s set flags to determine if you're on a rootless or rootful environment.

- When testing changes it's recommended you use [TrollStore](https://github.com/opa334/TrollStore) to test. Removing the original palera1n loader from uicache is as simple as using `uicache -u /cores/binpack/Applications/palera1nLoader.app`.
    - Rejailbreaking with palera1n will prioritize their loader and have that in cache instead of the one in TrollStore, so before testing at all you would need is to re-run the command and 'Rebuild Icon Cache'
    
- The loader retrieves its configuration from our website, so we're able to change anything about the loader in real time without any updates. This includes `Manager(s)`, `Bootstrap(s)`, and `Repositories`.
    - You're also able to make your own if you need to, that can be found below.

## Configuration
Configuration documentation can be found [here](https://github.com/palera1n/loader/blob/2.0/docs/Configuration.md).

## Building on macOS
| Command                                                    | Action                                     | 
| ---------------                                            | ------------------------------------------ |
| `gmake PLATFORM=iphoneos SCHEME=palera1nLoader package`    | Compiles loader for iOS / iPadOS           |
| `gmake PLATFORM=appletvos SCHEME=palera1nLoaderTV package` | Compiles loader for Apple TV               |

### Optional Flags
You can use these optional flags when compiling.

| Flag       | Description                           |
| ---------- | ------------------------------------- |
| `TIPA=1`   | Outputs as `.tipa` (if you're testing it on Trollstore), instead of `.ipa`  |
|`PLATFORM=?`| Specify `xcrun` platform and custom apple-include path, this is for compiling the loader without facing issues relating to "not available on *OS" |
| `SCHEME=?` | Specify which xcodeproj scheme to use when compiling |
| `clean`    | Clean build directories |

## Contributions
Localizations and general code pull requests are welcome.
