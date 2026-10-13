# Releasing Brain Dump

## One-time setup

### 1. Make the upload key

Each app gets its own upload key. Make it once, on your own computer:

```sh
keytool -genkeypair -v -keystore brain-dump-upload.jks -storetype JKS \
  -alias upload -keyalg RSA -keysize 2048 -validity 10000
```

Keep the `.jks` file and its password backed up somewhere safe (a password
manager works), and never commit it. With Play App Signing, Google holds the key
that signs what people install, so a lost upload key can be reset from the Play
Console. Direct-download APKs from GitHub, though, are signed with this key.

### 2. Add the repository secrets

GitHub → Settings → Secrets and variables → Actions → New repository secret:

| Secret | Value |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | `base64 -w0 brain-dump-upload.jks` (macOS: `base64 -i brain-dump-upload.jks`) |
| `ANDROID_KEYSTORE_PASSWORD` | the keystore password |
| `ANDROID_KEY_ALIAS` | `upload` |
| `ANDROID_KEY_PASSWORD` | the key password (the same as the keystore password unless you chose another) |

The release workflow stops with an error if the key is missing, and checks
that nothing it publishes is signed with the debug key.

### Signing local builds

For a signed release build on your own machine, create `android/key.properties`
(git-ignored):

```
storeFile=/absolute/path/to/brain-dump-upload.jks
storePassword=...
keyAlias=upload
keyPassword=...
```

Without it, `flutter build` falls back to the debug key, which is fine for
testing but can't be uploaded to Google Play.

## Cutting a release

1. Bump `version:` in `pubspec.yaml`, e.g. from `1.0.0+1` to `1.0.1+2`. The
   number after `+` is the Play version code and must go up with every upload.
   Write the release notes first, in `docs/releases/<tag>.md`; the workflow fails without them.
2. Commit, then tag and push: `git tag v1.0.1 && git push origin v1.0.1`,
   or start the **Release** workflow by hand from the Actions tab.
3. The workflow analyzes, tests, builds the signed APKs and `BrainDump-<version>-play.aab`,
   checks the signatures and publishes a GitHub release.

Upload the `.aab` to Google Play. Share the arm64 APK for direct installs.

### Earlier APKs

Releases before the upload key were signed with a debug key. Android won't
update a debug-signed install with a release-signed APK, so anyone who
installed one of those has to uninstall it once (their data goes with it)
before installing a new release or the Play Store version.

## Identifiers

The application ID is `com.kidyoh.brain_dump`. It can't change after the first
upload to Google Play.

## Store listing

The Play Store text, graphics and screenshots live in
`fastlane/metadata/android/`, and the answers for the Play Console forms are in
[docs/play-store.md](docs/play-store.md).
