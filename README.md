# Loader
A "loader" application used in palera1n, this app will appear on the homescreen once you've jailbroken.

## Notes
- When compiling for the simulator, do not have an apple-include be present, or else there will be issues
- AppleTV simulator would need you to remove the `IOKit.tbd` from the frameworks list, make sure to add it back when you're finished.

## Documentation
Online configuration documentation can be found [here](https://github.com/palera1n/loader/blob/2.0/Documentation.md).

## Building on macOS
| Command                                                    | Action                                     | 
| ---------------                                            | ------------------------------------------ |
| `gmake PLATFORM=iphoneos SCHEME=palera1nLoader package`    | Compiles loader for iOS / iPadOS           |
| `gmake PLATFORM=appletvos SCHEME=palera1nLoaderTV package` | Compiles loader for Apple TV               |

## Optional Flags
You can use these optional flags when compiling.

| Flag       | Description                           |
| ---------- | ------------------------------------- |
| `TIPA=1`   | Outputs as `.tipa` (if you're testing it on Trollstore), instead of `.ipa`  |
|`PLATFORM=?`| Specify `xcrun` platform and custom apple-include path, this is for compiling the loader without facing issues relating to "not available on *OS" |
| `SCHEME=?` | Specify which xcodeproj scheme to use when compiling |
| `clean`    | Clean build directories |

## Contributions
Localizations and general code pull requests are welcome.
