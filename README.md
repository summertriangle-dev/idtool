## IDTool

A SIF account manager for jailbroken iOS devices.

#### How do I compile it?

(You used to be able to patch Xcode to make it build iOS apps without signing them,
but that trick doesn't work anymore.)

1. Open the project in Xcode.
2. Choose a new bundle ID for the app, because I'm already using
   the current one.
3. Select a team (can be a personal AppleID team, doesn't matter)
4. Build (or Run). It should succeed.

The app will crash on launch if you're not jailbroken, because (thankfully)
Apple restricts the keychain-access-groups entitlement on non-jailbroken devices.

#### How do I use it?

See [Umidah's guide](https://www.reddit.com/r/SchoolIdolFestival/comments/2mtsi9/).
Don't use the download link in the post, grab the `.deb` from the Releases page
on this repo instead.

#### How do I save a backup of my accounts file?

- If you installed IDTool from a deb file:
  copy the file `/var/mobile/Library/Preferences/totsuka.no.tsurugi.IDTool.plist`.
- If you installed IDTool as a sandboxed application:
  copy the file `/var/mobile/Containers/Data/Application/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX/Library/Preferences/totsuka.no.tsurugi.IDTool.plist`.
  - XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX is a random string that changes every
    time you update the app. A file manager like Filza will help you find the
    right one.
  - This path has changed between versions of iOS, so you might have to go hunting.

In both cases, `totsuka.no.tsurugi.IDTool` will differ if you changed the bundle ID.

#### Is there an Android equivalent app?

[SIFAM](http://caraxian.com/android/SIFAM/).
