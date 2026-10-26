[简体中文](./README.md) | English

# App Settings Launcher

A tiny Android launcher APK: opening it **jumps straight to Xiaomi's "Application
settings" screen**, then closes itself. No background residue, no entry in Recents.

Jump target:

```
package  com.miui.securitycenter
activity com.miui.appmanager.AppManagerMainActivity
```

It exists to act as a bridge for the system's automated tasks — those can usually
only "launch an app" and cannot start a specific Activity directly. Once this APK is
installed, "launch App Settings Launcher" is equivalent to opening
**Settings → Application settings**.

---

## Download

Grab the latest `AppSettingsLauncher.apk` from the
[Releases page](https://github.com/MXDexRazero/app-settings-launcher/releases/latest)
and install it on your phone.

About **9 KB**, no permissions requested, no network access, no data collection.

> **On signing**: release APKs are built by GitHub Actions. If no formal signing key
> is configured, each build uses a throwaway self-signed certificate, which means
> **signature mismatches will block over-install** — uninstall the old build first.
> For consistent signatures across versions, add these repo secrets under
> Settings → Secrets: `SIGNING_KEYSTORE_BASE64`, `SIGNING_KEYSTORE_PASSWORD`,
> `SIGNING_KEY_ALIAS`, `SIGNING_KEY_PASSWORD`.

## Typical use: scheduled "Security service" update rollback

Combined with the
**[gkd_subscription](https://github.com/MXDexRazero/gkd_subscription)** subscription,
the whole flow can run in a chosen time window:

```
Automated task launches this APK on schedule
      ↓
Settings → Application settings opens
      ↓
GKD takes over: tap Security service → Uninstall updates → OK → exit Settings
```

See that repo's README for setup steps.

## Required setup on Xiaomi / HyperOS

Otherwise GKD behaves intermittently:

1. Long-press GKD in Recents → **Lock** it
2. Settings → Apps → GKD → Battery saver **No restrictions** + enable **Autostart**
3. Battery → App settings → GKD → No restrictions
4. HyperOS recycles idle third-party accessibility services; when rules stop firing,
   go to **Additional settings → Accessibility → Downloaded services** and tap GKD once

## Build it yourself

**Option 1 — locally** (needs JDK 21 plus `platforms;android-34` and
`build-tools;34.0.0`):

```shell
bash build.sh
```

Output lands at `out/AppSettingsLauncher.apk`. The script auto-detects `ANDROID_HOME`
and the installed build-tools version.

**Option 2 — GitHub Actions**

Push a tag starting with `v` and it builds and publishes to Releases automatically:

```shell
git tag v1
git push origin v1
```

You can also trigger `Build and Release APK` manually from the Actions tab.

> JDK 21 emits class major version 65 by default, which d8 rejects — the script
> pins `javac --release 8`. Do not remove that flag.

## Project layout

```
.
├── AndroidManifest.xml                       # manifest, translucent no-title theme
├── java/com/mxd/launcher/MainActivity.java   # the only source file, the jump logic
├── build.sh                                  # cross-platform packaging script
└── .github/workflows/release.yml             # build and publish release
```

## Related project

- **[gkd_subscription](https://github.com/MXDexRazero/gkd_subscription)**
  — the companion GKD subscription that handles every tap after the
  Application settings screen is open

---

[→ Go to gkd_subscription (subscription repo)](https://github.com/MXDexRazero/gkd_subscription)
