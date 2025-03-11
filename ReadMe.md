# utiluti

macOS command line utility to work with default apps.

## What it does

You can use `utiluti` to inspect and modify default apps for url schemes and file types/uniform type identifiers (UTI).

## Important notes:

- `utiluti` should be run as the current user

- when you attempt to set the default app for the `http` url scheme, macOS will prompt the user for confirmation. The user has the option to reject the change. The user must make a selection for the tool to continue. Consider this when using `utiluti` for automation.

- macOS connects the `http` and `https` url schemes and the `public.html` UTI. You can only set the default app for `http` and the default app for `https` and the `public.html` type will be set to the same app. Attempting to change the default apps for `https` or `public.html` will result in an error.

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

[Uniform type identifiers](https://developer.apple.com/documentation/uniformtypeidentifiers/) (UTI) are how macOS maps file and mime type. `utiluti` uses UTIs. 

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

