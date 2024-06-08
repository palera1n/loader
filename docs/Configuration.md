# Overview

Depending on the data received the loader will change functionality. The default path of where it obtains said data is from https://palera.in/loader.json, in the form of a self-hosted JSON file containing data to determine what OS you're on, platform, and the environment you've chosen when you used palera1n.

> [!NOTE]
> The configuration was updated as of [June 5th 2024](https://github.com/palera1n/loader/commit/10b6006175603d9d1487fec2d20352781382e299), previous documentation on lower beta versions of palera1n can be found in older commits.

Example JSON thats valid and used by default inside the app: https://palera.in/loaderv2.json


## Instructions

1. Create the file, and make sure its in a JSON format.

2. Make sure the file is hosted on a secure server or webpage, to easily host somewhere with no extra cost look into making sites via Cloudflare or Github pages.

3. Follow the documentation carefully.

## Table of Contents

<!--ts-->
   * [Root](#basic) - `Loader`
      * [`Contents`](#contents) - `Base`
        * [`Environments`](#environment) - `Rootless`
            * [`Bootstraps`](#bootstraps) - `Procursus`
            * [`Managers`](#managers) - `Sileo`
            * [`Repositories`](#repositories) - `repo.palera.in`
<!--te-->



## Metadata

When making a configuration it is recommended you consider possibilities of what palera1n version they're using, platform, and iOS they would be running.

---

### Basic

```json
{
    "min_loader_version": "2.1", 
    "palera1n_version_with_min_loader": "2.0",
    "min_bridge_bootstrapper_version": "1.0",
    "footer_notice": "Example footer notice",
    "contents": []
}
```

`min_loader_version` **(string)** <sup>required</sup>

Minimum loader version that the configuration supports. -- If the app version is lower than minimum required then it will tell you to update to the latest palera1n version with an alert.

`palera1n_version_with_min_loader` **(string)** <sup>required</sup>

The minimum loader version the latest version of palera1n supports. -- As of the versions after `beta 9`, only 2.0+ is supported.

`min_bridge_bootstrapper_version` **(string)** <sup>optional</sup>

`footer_notice` **(string)** <sup>required</sup>

Message displayed in a section footer. -- Usually used as a means of telling users emergency or important messages related to palera1n/jailbreaking in general.

- Any link added will not be clickable, requiring the user to manually type in the url in their browser.

- Anything more than 40+ characters is not recommended, as it would seem overwhelming to the user trying to bootstrap. (No information overload!)

- `""` is valid, so if you need it empty then thats what you should be doing.

`contents` **(array)** <sup>required</sup>

---

### Contents

```json
"contents": [
    {
        "platform": 3,
        "rootful": {}
        "rootless": {}
    }
]
```

`platform` **(int)** <sup>required</sup>

The device platform type.

Uses `dyld_get_active_platform() -> UInt32` to determine what platform you're on.

```yml
1:  macOS
2:  iOS
3:  tvOS / HomePod
5:  bridgeOS
6:  macCatalyst
0:  Unknown
```

For simulated device types, they're not listed and are considered `unknown` according to the app, so the app will attempt to go to a default of iOS or tvOS, if not, it will stay as `0`.

`rootful` **(nested)** <sup>optional</sup>

Rootful environment type specified from CLI. -- `(flags & (1 << 0)) != 0`

`rootless` **(nested)** <sup>optional</sup>

Rootless environment type specified from CLI. -- `(flags & (1 << 1)) != 0`

- Jbroot prefix would be `/var/jb`

---

### Environment

```json
"rootful": {
    "dotfile": "/.procursus_strapped",
    "bootstraps": [],
    "managers": [],
    "repositories": []
}
```

`dotfile` **(string)** <sup>unused</sup>

`bootstraps` **(array)** <sup>required</sup>

`managers` **(array)** <sup>required</sup>

`repositories` **(array)** <sup>required</sup>

---

### Bootstraps

```json
{
    "cfver": 1800,
    "uri": "https://static.palera.in/bootstraps/appletvos-arm64/1800/tvbootstrap-1800.tar.zst",
    "bootstrap-debs": [
        "https://static.palera.in/bootstraps/appletvos-arm64/1800/autosign_2.0.3_appletvos-arm64.deb",
        "https://static.palera.in/bootstraps/appletvos-arm64/1800/dhinakg-keyring_2023.04.02_all.deb",
        "https://static.palera.in/bootstraps/appletvos-arm64/1800/ellekit_1.1.2-palera1n_appletvos-arm64.deb",
        "https://static.palera.in/bootstraps/appletvos-arm64/1800/ldid_2.1.5-procursus7_appletvos-arm64.deb",
        "https://static.palera.in/bootstraps/appletvos-arm64/1800/libkrw0-tfp0_1.1.1_appletvos-arm64.deb",
        "https://static.palera.in/bootstraps/appletvos-arm64/1800/libplist3_2.2.0+git20230130.4b50a5a_appletvos-arm64.deb"
    ]
}
```

`cfver` **(int)** <sup>required</sup>

OS CoreFoundation version. -- Uses `Int(floor(kCFCoreFoundationVersionNumber / 100) * 100)`.

```yml
...
1700: 14.x
1800: 15.x
1900: 16.x
2000: 17.0
2100: 17.1
2200: 17.2
2300: 17.3
2400: 17.4
2500: 17.5
...
```

Depending on your OS, the loader will determine what bootstrap will be most appropriate for you, for example, if you're on iOS 18 then it will choose the latest available bootstrap (that normally would be for iOS 16, but instead be able to use it on iOS 18). The reverse will not work, being on iOS 13 will show bootstraps being unavailable.

```swift
// How its determined if you have a matching bootstrap
let sortedItems = basePath?.bootstraps.sorted { $0.cfver > $1.cfver }
    guard let bootstrapDetails = sortedItems!.first(where: { $0.cfver == corefoundationVersionShort }) ?? sortedItems!.first(where: { $0.cfver < corefoundationVersionShort }) else {
        // This will make an alert appear, telling the user that they are unable to use the configuration.
        log(type: .fatal, msg: "No matching bootstrap found.")
        return
}
```

`uri` **(string)** <sup>required</sup>

Main bootstrap URL. -- Needs to be either a `tar` or `tar.gz` file.

`bootstrap-debs` **(Array)** <sup>required</sup>

Bootstrap array that contains strings to debs. -- These are force installed using `dpkg -i`.

> [!NOTE]
> `libkrw0-tfp0` is required to be installed when bootstrapping, if its missing then the provided managers will yell at you.

---

### Managers

```json
{
    "name": "PurePKG",
    "uri": "https://github.com/Lrdsnow/PurePKG/releases/latest/download/uwu.lrdsnow.purepkg_appletvos-arm64.deb",
    "icon": "https://github.com/Lrdsnow/PurePKG/raw/215b3f4b0b3c86a7637d8013305c58da9d08d4a8/PurePKG/Assets.xcassets/AppIcon.appiconset/Untitled%20drawing-29-2.png",
    "filePath": "/Applications/PurePKG.app"
}
```

`name` **(string)** <sup>required</sup>

Package manager name (i.e. `Sileo`, `Zebra`).

`uri` **(string)** <sup>required</sup>

Debian package path.

`icon` **(string)** <sup>required</sup>

Valid image file that is displayed in the table.

- `""` is also valid, as the app will show a default icon

`filePath` **(string)** <sup>required</sup>

This is so the loader determines if you have the package manager installed. Although, its very pointless in reality, as all it does is change a string showing that its installed. It will be force installed the same way as if its not installed.


---

### Repositories

```json
{
    "Types": "deb",
    "URIs": "https://repo.palera.in",
    "Suites": "./",
    "Components": ""
}
```

These are written to a hardcoded sources path, being:
```swift
"\(prefix)/etc/apt/sources.list.d/palera1n.sources"
```

Contents:
```md
Types: deb
URIs: https://repo.palera.in
Suites: ./
Components:

...
```


`Types` **(string)** <sup>required</sup>

`URIs` **(string)** <sup>required</sup>

`Suites` **(string)** <sup>required</sup>

`Components` **(string)** <sup>required</sup>

--- 

Welcome to the end :D