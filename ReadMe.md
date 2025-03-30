# utiluti

macOS command line utility to work with default apps.

## What it does

You can use `utiluti` to inspect and modify default apps for url schemes and file types/uniform type identifiers (UTI).

## Important notes:

- `utiluti` should run as the current user

- when you attempt to set the default app for the `http` url scheme, macOS will prompt the user for confirmation. The user has the option to reject the change. The user must make a selection for the tool to continue. Consider this when using `utiluti` for automation. (See [macadmins/default-browser](https://github.com/macadmins/default-browser/tree/main) for an alternative)

- macOS connects the `http` and `https` url schemes and the `public.html` UTI. You can only set the default app for `http`. Then the default app for `https` and the `public.html` type will be set to the same app. Attempting to change the default apps for `https` or `public.html` independently will result in an error.

## URL schemes

URL schemes are the part of the URL before the colon `:` which identify which app or protocol to use. E.g. `http`, `mailto`, `ssh`, etc.

Get the current default app for a given url scheme:

```sh
$ utiluti url mailto          
/System/Applications/Mail.app
```

Use the `--bundle-id` flag to receive the app's bundle identifier instead:

```sh
$ utiluti url mailto --bundle-id     
com.apple.mail
```

List all apps registered for a given url scheme:

```sh
$ utiluti url list mailto          
/System/Applications/Mail.app
/Applications/Microsoft Outlook.app
```

Use the `--bundle-id` flag to receive the apps' bundle identifiers instead:

```sh
$ utiluti url list mailto --bundle-id 
com.apple.mail
com.microsoft.Outlook
```

Set the default app for a given URL scheme:

```sh
$ utiluti url set mailto com.microsoft.Outlook
set com.microsoft.Outlook for mailto
```

## File Type/Uniform Type Identifiers (UTI)

[Uniform type identifiers](https://developer.apple.com/documentation/uniformtypeidentifiers/) (UTI) are how macOS maps file and mime types. `utiluti` uses UTIs. 

To get the UTI associated with a file extension, use `get-uti`:

```sh
$ utiluti get-uti txt            
public.plain-text
```

Get the default application for a UTI:

```sh
$ utiluti type public.plain-text
/System/Applications/TextEdit.app
```

List all applications registered for the given UTI:

```sh
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

```sh
$ utiluti type set public.plain-text com.barebones.bbedit
set com.barebones.bbedit for public.plain-text
```

## Getting an App's declarations

`utiluti` can list the UTIs and url schemes an app has declared in their Info.plist:

List the URL schemes for a given app with `app schemes`:

```sh
$ utiluti app schemes com.apple.safari
http
https
file
x-safari-https
```

List the UTIs and file extensions for a given app with `app types`

```sh
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

```sh
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

## Default app for specific files

macOS allows for a file to be assigned to an app different from the general default app for that file type. `utiluti` has the `file` verb to inspect or set the default app for a specific file.

Get the UTI for a given file:

```sh
$ utiluti file get-uti ReadMe.md
net.daringfireball.markdown
```

Get the app that will open the file when double-clicked:

```sh
$utiluti file app ReadMe.md
/System/Applications/TextEdit.app
```

List all apps that can open the file:

```sh
$ utiluti file list-apps ReadMe.md
/System/Applications/TextEdit.app
/Applications/Xcode.app
/Applications/Xcode.app/Contents/Applications/Instruments.app
/System/Applications/Notes.app
```

Set the default app for this file:

```sh
$ utiluti file set ReadMe.md com.apple.dt.xcode
set com.apple.dt.xcode for ReadMe.md
```
