# utiluti

macOS command line utility to work with default apps.

## What it does

You can use `utiluti` to inspect and modify default apps for url schemes and file types/uniform type identifiers (UTI).

## Important notes:

- `utiluti` should run as the current user

- when you attempt to set the default app for the `http` url scheme, macOS will prompt the user for confirmation. The user has the option to reject the change. The user must make a selection for the tool to continue. Consider this when using `utiluti` for automation. You should wrap the script in some other UI to prepare the user for the dialog.
  (See [macadmins/default-browser](https://github.com/macadmins/default-browser/tree/main) for an alternative solution)

- macOS connects the `http` and `https` url schemes and the `public.html` UTI. You can only set the default app for `http`. Then the default app for `https` and the `public.html` type will be set to the same app. Attempting to change the default apps for `https` or `public.html` independently will result in an error.

- many commands require the bundle identifier to specify an app. You can determine an app's bundle identifier with `utiluti` itself, `mdls`, `osascript`/AppleScript, or a GUI tool like [Apparency](https://www.mothersruin.com/software/Apparency/)

```
$ utiluti app id /Applications/Safari.app
com.apple.Safari
```

```
$ mdls -n kMDItemCFBundleIdentifier /Applications/Safari.app
kMDItemCFBundleIdentifier = "com.apple.Safari"
```

```
$ osascript -e 'id of app "Safari"'
com.apple.Safari
```

## URL schemes

URL schemes are the part of the URL before the colon `:` which identify which app or protocol to use. E.g. `http`, `mailto`, `ssh`, etc.

Get the current default app for a given url scheme:

```
$ utiluti url mailto          
/System/Applications/Mail.app
```

Use the `--bundle-id` flag to receive the app's bundle identifier instead:

```
$ utiluti url mailto --bundle-id     
com.apple.mail
```

List all apps registered for a given url scheme:

```
$ utiluti url list mailto          
/System/Applications/Mail.app
/Applications/Microsoft Outlook.app
```

Use the `--bundle-id` flag to receive the apps' bundle identifiers instead:

```
$ utiluti url list mailto --bundle-id 
com.apple.mail
com.microsoft.Outlook
```

Set the default app for a given URL scheme:

```
$ utiluti url set mailto com.microsoft.Outlook
set com.microsoft.Outlook for mailto
```

## File Type/Uniform Type Identifiers (UTI)

[Uniform type identifiers](https://developer.apple.com/documentation/uniformtypeidentifiers/) (UTI) are how macOS maps file and mime types. `utiluti` uses UTIs. 

To get the UTI associated with a file extension, use `get-uti`:

```
$ utiluti get-uti txt            
public.plain-text
```

Get the default application for a UTI:

```
$ utiluti type public.plain-text
/System/Applications/TextEdit.app
```

List all applications registered for the given UTI:

```
$ utiluti type list public.plain-text
/System/Applications/TextEdit.app
/Applications/Numbers.app
/Applications/Pages.app
/System/Applications/Utilities/Script Editor.app
/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app
/Applications/Xcode.app/Contents/Applications/Instruments.app
/Applications/Xcode.app
/System/Applications/Notes.app
```

Add the `--bundle-id` flag to receive bundle identifiers instead of paths.

Set the the default app for a given UTI:

```
$ utiluti type set public.plain-text com.barebones.bbedit
set com.barebones.bbedit for public.plain-text
```

## Getting an App's declarations and other information

`utiluti` can list the UTIs and url schemes an app has declared in their Info.plist:

List the URL schemes for a given app with `app schemes`:

```
$ utiluti app schemes com.apple.safari
http
https
file
x-safari-https
```

List the UTIs and file extensions for a given app with `app types`

```
$ utiluti app types com.apple.TextEdit
public.rtf
com.apple.rtfd
public.html
com.apple.webarchive
org.oasis-open.opendocument.text
org.openxmlformats.wordprocessingml.document
com.microsoft.word.wordml
com.microsoft.word.doc
public.text
public.plain-text
com.apple.traditional-mac-plain-text
public.data
```

Some apps declare file extensions instead of UTIs. In this case `utiluti` will prepend `file extension:`. If there is an associated UTI, it will be shown in parenthesis:

```
$ utiluti app types com.apple.safari
file extension: css (public.css)
file extension: pdf (com.adobe.pdf)
file extension: webarchive (com.apple.webarchive)
file extension: webbookmark (com.apple.safari.bookmark)
file extension: webhistory (com.apple.safari.history)
file extension: webloc (com.apple.web-internet-location)
file extension: download (com.apple.safari.download)
file extension: safariextz (com.apple.safari.extension)
file extension: gif (com.compuserve.gif)
file extension: html (public.html)
file extension: htm (public.html)
file extension: shtml (public.html)
file extension: jhtml
file extension: js (com.netscape.javascript-source)
file extension: jpg (public.jpeg)
file extension: jpeg (public.jpeg)
file extension: txt (public.plain-text)
file extension: text (public.plain-text)
file extension: png (public.png)
file extension: tiff (public.tiff)
file extension: tif (public.tiff)
file extension: url (com.microsoft.internet-shortcut)
file extension: ico (com.microsoft.ico)
file extension: xhtml (public.xhtml)
file extension: xht (public.xhtml)
file extension: xhtm (public.xhtml)
file extension: xht (public.xhtml)
file extension: xml (public.xml)
file extension: xbl
file extension: xsl (org.w3.xsl)
file extension: xslt (org.w3.xsl)
file extension: svg (public.svg-image)
file extension: avif (public.avif)
file extension: webp (org.webmproject.webp)
file extension: heic (public.heic)
file extension: jxl (public.jpeg-xl)
```

Show an app's bundle identifier:

```
$ utiluti app id /Applications/Safari.app
com.apple.Safari
```

Show an app's version:

```
$ utiluti app id /Applications/Safari.app
18.5
```

List paths to applications for a given bundle identifier: (note that the output might have multiple lines, when there are multiple copies of the app, or be empty when there are no apps matching the identifier)

```
$ utiluti app for-id com.apple.notes
/System/Applications/Notes.app
```





## Default app for specific files

macOS allows for a file to be assigned to an app different from the general default app for that file type. `utiluti` has the `file` verb to inspect or set the default app for a specific file.

Get the UTI for a given file:

```
$ utiluti file get-uti ReadMe.md
net.daringfireball.markdown
```

Get the app that will open the file when double-clicked:

```
$utiluti file app ReadMe.md
/System/Applications/TextEdit.app
```

List all apps that can open the file:

```
$ utiluti file list-apps ReadMe.md
/System/Applications/TextEdit.app
/Applications/Xcode.app
/Applications/Xcode.app/Contents/Applications/Instruments.app
/System/Applications/Notes.app
```

Set the default app for this file:

```
$ utiluti file set ReadMe.md com.apple.dt.xcode
set com.apple.dt.xcode for ReadMe.md
```

## Setting multiple defaults

The `manage` verb reads multiple default app assignments from files or from user defaults/configuration profiles.

### Reading from files

The file format is an XML Property list. You will need two separate files for assigning URL schemes (`--url-file`) and one for assigning file types/UTIs (`--type-file`).

The root object of the property list is a `dict`, each key will be the url scheme or UTI, respectively. The value is the application bundle identifier for the default app that should be set.

```
$ utiluti manage --type-file types.plist
set com.fatcatsoftware.pledpro for com.apple.property-list
set com.barebones.BBEdit for public.plain-text
set com.barebones.BBEdit for public.shell-script
```

```
$ utiluti manage --url-file urls.plist
set com.microsoft.Outlook for mailto
set com.ranchero.NetNewsWire-Evergreen for feed
```

```
$ utiluti manage --type-file types.plist --url-file urls.plist
set com.fatcatsoftware.pledpro for com.apple.property-list
set com.barebones.BBEdit for public.plain-text
set com.barebones.BBEdit for public.shell-script
set com.microsoft.Outlook for mailto
set com.ranchero.NetNewsWire-Evergreen for feed
```

You can have either the `--type-file` or the `--url-file` or both. When only file is given, `utiluti` will _not_ read additional settings from defaults.

**Note:** You can add a default app for the `http` url scheme this way, but it will show the user confirmation dialog when the default browser changes. See [the notes above](#important-notes).

Example (URL Schemes):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>feed</key>
	<string>com.ranchero.NetNewsWire-Evergreen</string>
	<key>mailto</key>
	<string>com.microsoft.Outlook</string>
</dict>
</plist>
```

Example (UTIs):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.property-list</key>
	<string>com.fatcatsoftware.pledpro</string>
	<key>public.plain-text</key>
	<string>com.barebones.BBEdit</string>
	<key>public.shell-script</key>
	<string>com.barebones.BBEdit</string>
</dict>
</plist>
```

### From defaults and managed preferences

For managed deployments, the settings can be read from a configuration profile.

```
$ utiluti manage
set com.fatcatsoftware.pledpro for com.apple.property-list
set com.barebones.BBEdit for public.plain-text
set com.barebones.BBEdit for public.shell-script
set com.microsoft.Outlook for mailto
set com.ranchero.NetNewsWire-Evergreen for feed
```

Example (configuration profile):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>PayloadContent</key>
	<array>
		<dict>
			<key>PayloadDisplayName</key>
			<string>Utiluti URL Schemes</string>
			<key>PayloadIdentifier</key>
			<string>com.scriptingosx.utiluti.url</string>
			<key>PayloadType</key>
			<string>com.scriptingosx.utiluti.url</string>
			<key>PayloadUUID</key>
			<string>C6BE539F-85CC-424B-BD10-6160A9B87507</string>
			<key>PayloadVersion</key>
			<integer>1</integer>
			<key>feed</key>
			<string>com.ranchero.NetNewsWire-Evergreen</string>
			<key>mailto</key>
			<string>com.microsoft.Outlook</string>
		</dict>
		<dict>
			<key>PayloadDisplayName</key>
			<string>Utiluti UTIs</string>
			<key>PayloadIdentifier</key>
			<string>com.scriptingosx.utiluti.type</string>
			<key>PayloadType</key>
			<string>com.scriptingosx.utiluti.type</string>
			<key>PayloadUUID</key>
			<string>21078E7C-9C38-45F8-92C1-DFF7FBD77405</string>
			<key>PayloadVersion</key>
			<integer>1</integer>
			<key>com.apple.property-list</key>
			<string>com.fatcatsoftware.pledpro</string>
			<key>public.plain-text</key>
			<string>com.barebones.BBEdit</string>
			<key>public.shell-script</key>
			<string>com.barebones.BBEdit</string>
		</dict>
	</array>
	<key>PayloadDisplayName</key>
	<string>Utiluti</string>
	<key>PayloadIdentifier</key>
	<string>com.scriptingosx.utiluti</string>
	<key>PayloadScope</key>
	<string>System</string>
	<key>PayloadType</key>
	<string>Configuration</string>
	<key>PayloadUUID</key>
	<string>E0A43215-6114-413B-BB0B-1478AB79181B</string>
	<key>PayloadVersion</key>
	<integer>1</integer>
</dict>
</plist>
```

By default, `utiluti manage` will _ignore_ unmanaged defaults, i.e. defaults that come from local settings rather than configuration profiles. You can override this behavior with the `--include-unmanaged` option.

```
$ defaults write com.scriptingosx.utiluti.type net.daringfireball.markdown com.barebones.BBEdit
$ defaults read com.scriptingosx.utiluti.type
{
    "net.daringfireball.markdown" = "com.barebones.BBEdit";
}
$ utiluti manage --include-unmanaged
set com.fatcatsoftware.pledpro for com.apple.property-list
set com.barebones.BBEdit for net.daringfireball.markdown
set com.barebones.BBEdit for public.shell-script
set com.barebones.BBEdit for public.plain-text
set com.ranchero.NetNewsWire-Evergreen for feed
set com.microsoft.Outlook for mailto
```
