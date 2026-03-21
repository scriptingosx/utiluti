# Change Log – utiluti

## v1.6

(2026-xx-yy)

- added `app utis` and `app urls` as synonyms for `app types` and `app schemes`


## v1.5

(2026-03-15)

- `type` subcommands now have a `--extension/-e` flag to provide a file extension instead of a type identifier (#9)
- set default apps for file extensions in type-files and managed preferences with an `extension:` prefix
- added more info to `type info`
- fixed version initialization in pkgAndNotarize script (#8)
- updated to swift-argument-parser 1.7.0 and Swift 6.2 (#7)

## v1.4

(2026-03-12)

- app type list no longer drops types without a name


## v1.3
(2025-08-01)

- improved concurrency code (#3, thank you @davedelong)
- added verbs to get an app's bundle identifier and version
- utiluti now has a man page

## v1.2

(2025-07-04)

- new `manage` verb which sets multiple default apps from either files or managed preferences

## v1.1

(2025-03-30)

- new `app` verb which lists types and url schemes associated with an app
- new `file` verb to inspect and set default apps for specific files

## v1.0

first release
