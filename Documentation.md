# loader.json

> Only package managers and bootstraps will be available on palera1n b8, higher is fully supported.

This is a json that the palera1n loader application will try to retrieve when opening the app, this config will tell the loader where to download from, for example package managers, bootstraps, and repositories. 

You can change the configuration by typing the URL in the uitextfield inside of the loader app, its located in the `Options` page. If you're on b8 loader build then you would need to triple tap the palera1n icon inside of the main view.

https://github.com/palera1n/loader/assets/97859147/b5c6442f-993c-453a-896a-d0addced464d

Reminder: it needs to be vaild json.

---

## Table of Contents

<!--ts-->
   * [loader.json](#loader.json)
      * [`bootstraps` object](#bootstraps-object)
        * [bootstraps information](#bootstraps-information)
      * [`managers` object](#managers-object)
        * [applcation information](#application-information)
      * [`assets` object](#assets-object)
        * [repository information](#repository-information)
   * [Example](#example)
<!--te-->

---






## `bootstraps` object

> Main bootstrap loader would install

| Property                   | Description                                         |
| -------------------------- | --------------------------------------------------- |
| Bootstrap Label (`label`)  | Either `Rootless` or `Rootful`                      |
| Bootstrap Info (`items`)   | Holds an array of information on each bootstrap     |

### Bootstrap Information 

> Depending on your iOS version your CoreFoundation version may be different.

(i.e, iOS 15 is cfver `1800`, iOS 16 is `1900`, iOS 17.0 `2000`), this is how the loader gets cf version:

```swift
Int(floor(kCFCoreFoundationVersionNumber / 100) * 100)
```

This is how the loader determines the cf version its supposed to fetch, its simplified for convenience.

**Important to know**: the CoreFoundation version is higher than the provided json the loader will go to the last item available, if it's lower then it will say unable to fetch bootstraps as there is no available working bootstrap provided in the config. This is due to apples recent changes with how they change their CoreFoundation versions for iOS 17+


| Property in `items` array  | Description                                         |
| -------------------------- | --------------------------------------------------- |
| CFBundleVersion (`cfver`)  | CoreFoundation Version of the bootstrap             |
| Download URI (`uri`)       | URI to download the bootstrap                       |


---




## `managers` object

> Package Managers / Applications that loader would install from a URL

| Property                   | Description                                         |
| -------------------------- | --------------------------------------------------- |
| Bootstrap Label (`label`)  | Either `Rootless` or `Rootful`                      |
| Bootstrap Info (`items`)   | Holds an array of information on each app           |

### Application Information 

> `name` and `icon` will be displayed on the loader app for you to press onto to start the entire bootstrap process.

The loader will check if any of the `filePaths` exist and change what it will prompt when you press on a cell, if they exist it will prompt to re-install the application instead of bootstrapping.

| Property in `items` array                 | Description                                         |
| --------------------------                | --------------------------------------------------- |
| App Name (`name`)                         | Name for application                                |
| Download URI (`uri`)                      | URI to download the `<app>.deb`                     |
| Application icon image (`icon`)           | `.png` url for application                          |
| Application install path (`filePaths`)    | Simple array for application filepaths              |




---



## `assets` object

> Packages / Repos loader would add to bootstrap installation

| Property                          | Description                                         |
| --------------------------        | --------------------------------------------------- |
| Bootstrap Label (`label`)         | Either `Rootless` or `Rootful`                      |
| Repository Info (`repositories`)  | Holds an array of information for each repo         |
| Packages to install (`packages`)  | Simple array for packages to install with APT       |

### Repository Information 

> This information will be written to ${prefix}/etc/apt/sources.list.d/palera1n.sources

| Property in `repositories` array      | Description                                         |
| --------------------------            | --------------------------------------------------- |
| Repository URL (`uri`)                | URL to repository                                   |
| Repository suites (`suite`)           | Suite(s) for repository                             |
| Repository components (`component`)   | Component(s) for repository                         |

The following properties are optional:
| Optional property in `repositories` array | Description                                    |
| --------------------------                | ---------------------------------------------- |
| Repository types (`types`)                | Type(s) of repository. Set to `deb` if absent  |
| Repository options (`options`)            | Extra repository options                       |

The extra options takes the form of an object, whose keys and values are described in `sources.list(5)`.
Deb822 keys and values are accepted.

---

## Example

Example JSON:
```json
{
    "bootstraps": [
        {
            "label": "Rootful",
            "items": [
                {
                    "cfver": "1800",
                    "uri": "https://static.palera.in/bootstrap-1800.tar.zst"
                }
            ]
        },
        {
            "label": "Rootless",
            "items": [
                {
                    "cfver": "1800",
                    "uri": "https://apt.procurs.us/bootstraps/1800/bootstrap-ssh-iphoneos-arm64.tar.zst"
                }
            ]
        }
    ],
    "managers": [
        {
            "label": "Rootful",
            "items": [
                {
                    "name": "Sileo",
                    "uri": "https://static.palera.in/sileo.deb",
                    "icon": "https://palera.in/sileo.png",
                    "filePaths": [
                        "/Applications/Sileo.app"
                    ]
                }
            ]
        },
        {
            "label": "Rootless",
            "items": [
                {
                    "name": "Sileo",
                    "uri": "https://static.palera.in/rootless/sileo.deb",
                    "icon": "https://palera.in/sileo.png",
                    "filePaths": [
                        "/var/jb/Applications/Sileo.app"
                    ]
                }
            ]
        }
    ],
    "assets":[
        {
            "label": "Rootful",
            "repositories": [
                {
                    "types": "deb",
                    "uri": "https://repo.palera.in",
                    "suite": "./",
                    "component": "",
                    "options": {
                            "Signed-by": "/etc/apt/trusted.gpg.d/palera1n.sources"
                        }
                }
            ],
            "packages": [
                "foo"
            ]
        },
        {
            "label": "Rootless",
            "repositories": [
                {
                    "types": "deb",
                    "uri": "https://repo.palera.in",
                    "suite": "./",
                    "component": "",
                    "options": {
                            "Signed-by": "/etc/apt/trusted.gpg.d/palera1n.sources"
                        }
                }
            ],
            "packages": [
                "foo"
            ]
        }
    ]
}

```
