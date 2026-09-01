# She Secure

A women's safety app for the Pakistan, built in **Flutter**,
targeting **Android only**, distributed as a **sideloaded APK** (not
published to Play Store).

## Design source of truth

The UI/UX spec is a Claude Design canvas project (`She Secure.dc.html`,
project id `95734c9b-84c9-4740-b6c6-6df37780f980`) — 16 screens, fully
detailed copy/layout/colors, and a class-based click-through state machine.
Its visual language: dark theme, background `#161826`, accent `#e5527e`
(with a full tint/shade ramp), Inter font, Phosphor-style icons. Every
screen's copy, layout, and interaction should port faithfully into Flutter
— this file records decisions and phases, not the screen-by-screen content
itself.

The 16 screens: Splash, Onboarding, Login/Signup, Forgot Password, Home,
SOS, Trusted Contacts, Location, Recordings, Fake Call, Tutorial, Settings,
Profile, Smart Sentinel, Are-you-safe Check-in, Distress Listening.

## Decisions locked in

- **State management**: Provider.
- **Backend**: Firebase — `firebase_auth` (email/password) + `cloud_firestore`
  (contacts, SOS history, settings).
- **AI features are real, not simulated**:
  - **Smart Sentinel**: background location + motion tracking, a
    route/time/pace baseline built from ~2 weeks of samples, anomaly →
    silent vibrate check-in → 30s auto-escalate to SOS if unconfirmed
    (hold-to-confirm vs. duress-hold-still-fires).
  - **Distress Listening**: continuous mic capture, on-device YAMNet
    classification (521 AudioSet classes, includes "Screaming" and "Crying,
    sobbing"), auto-fires SOS with no confirmation on a sustained
    high-confidence hit.
- **SMS delivery**: real silent auto-send via Android's `SmsManager` (no
  compose sheet, no user tap) to every trusted contact. Safe to do without
  Play Store's Permissions Declaration Form because this app is
  APK-sideload only. iOS is not a target (Apple forbids silent SMS
  outright, so this feature has no iOS equivalent).
- **Map**: MapLibre (`maplibre_gl`) rendering raw OpenStreetMap tiles
  directly from `tile.openstreetmap.org`. That endpoint forbids
  production/heavy traffic, but this app is dev/light-use only, so no
  commercial tile provider or API key is used.
- **Contacts**: native OS contact picker via `flutter_contacts`.
- **Evidence storage (Recordings)**: video/audio/photo files captured by
  the app are saved **locally only**, under a top-level app documents
  subfolder named `evidence/` (never uploaded to Firebase Storage or
  anywhere else). Firestore only ever holds a lightweight **reference**
  document per capture — type, local file path, timestamp, and
  duration/size — never the media itself.

## Package list (`pubspec.yaml`)

| Concern | Package(s) |
|---|---|
| State | `provider` |
| Backend | `firebase_core`, `firebase_auth`, `cloud_firestore` (via `flutterfire configure`) |
| Contacts | `flutter_contacts` |
| Location/map | `geolocator`, `maplibre_gl` (raw OSM tiles, no key) |
| Motion | `sensors_plus` |
| Background execution | `flutter_background_service` |
| SMS | `another_telephony` (maintained fork of the archived `telephony`) for `SmsManager`-based silent send |
| Audio detection | `record` (raw PCM mic capture) + `tflite_flutter` with a bundled YAMNet `.tflite` model |
| Notifications | `flutter_local_notifications` (silent, vibrate-only check-in ping) |
| Recordings | `camera`, `path_provider` (local video/audio/photo storage under an `evidence/` subfolder) |
| Permissions | `permission_handler` |
| Misc | `url_launcher` (`tel:`, YouTube links), `image_picker` (profile photo) |

## Folder structure

```
lib/
  main.dart, app.dart
  theme/            app_colors.dart, app_theme.dart, app_text_styles.dart
  models/           contact.dart, sos_event.dart, app_settings.dart, user_profile.dart
  services/         auth_service, firestore_service, sms_service, location_service,
                     contact_picker_service, sentinel_service, audio_detection_service,
                     notification_service, recording_service
  providers/        auth_provider, contacts_provider, sos_provider, sentinel_provider,
                     listen_provider, settings_provider, fake_call_provider, recordings_provider
  screens/          splash, onboarding, auth/{auth_screen,forgot_password_screen}, home, sos,
                     contacts, location, recordings, fake_call, tutorial, settings, profile,
                     sentinel, checkin, listen
  widgets/          hold_button.dart, toggle_switch.dart, segmented_control.dart,
                     shield_logo.dart, drawer_menu.dart, pill_tag.dart
  utils/            formatters.dart
```

## Firestore schema

```
users/{uid}                        name, email, age?, city?, photoUrl?, createdAt
users/{uid}/contacts/{id}          name, relation, phone, initials
users/{uid}/sosHistory/{id}        where, whenTimestamp, detail, status
users/{uid}/settings (doc)         features{...}, sentinelOn, listenOn, sens, earSens
users/{uid}/sentinelSamples/{id}   timestamp, lat, lng, speed  — pruned after ~4 weeks
users/{uid}/evidence/{id}          type (video/audio/photo), localPath, timestamp,
                                    durationOrSize  — metadata only, the file itself
                                    stays on-device under evidence/
```

## Honest caveats

- YAMNet is a general-purpose audio classifier, not scream-specific —
  expect some false positives (loud TV, laughter) and false negatives
  (screams under wind/traffic noise). Ship with a tunable
  confidence+duration threshold, not a hard accuracy promise.
- Background survival is a known Android pain point on aggressive OEM
  skins (Xiaomi/Oppo/etc. killing background services); users on those
  devices may need to disable battery optimization for the app.
- APK-sideload distribution means no Play Store auto-updates.

---

## Phases

Edit this section freely — add/remove/reorder items per phase before each
one starts. Each phase should end in a build that runs and can be exercised
end to end.

### Phase 1 — Scaffold + design system + navigation ✅ done
- [x] `flutter create` (Android-only platform target)
- [x] Port theme: colors, fonts, spacing from the design canvas
- [x] Build all 16 screens as real widgets
- [x] Provider state machines mirroring the canvas's `Component` class
      (sos idle/counting/armed, fake-call phases, settings toggles, sentinel
      check-in escalation, listen detection, etc.), using local/in-memory
      data only — no Firebase or native plugins yet. Onboarding index,
      auth tab, and forgot-password step are local widget state instead of
      providers, since nothing else needs to read them. Screen-to-screen
      navigation uses Flutter's real `Navigator`/named routes rather than a
      single global "current screen" variable — more idiomatic than the
      canvas's own approach, which was a workaround for not having a router.
- [x] One deliberate behavior change from the canvas: there, every "back"
      button force-reset the SOS alert to idle regardless of which screen
      it led to, because `go()` was one function for both navigation and
      SOS reset. That's a real bug for a safety app (leaving the SOS screen
      by accident would silently cancel an active alert with no
      confirmation) — back buttons here are plain navigation only; SOS
      state is untouched by navigating away.
- Verify: `flutter analyze` clean, `flutter test` (3 SOS state-machine
  tests) passes, `flutter build apk --debug` succeeds. User tests manually
  on their own device/emulator from here.

### Phase 2 — Firebase ✅ done
- [x] `flutterfire configure` — project `she-secure-pk` (Firestore in
      `asia-south1`/Mumbai, closest available region to Pakistan), Android
      app registered, `lib/firebase_options.dart` +
      `android/app/google-services.json` generated and committed (these
      hold a public client API key restricted by the Firestore rules
      below, not a secret — standard practice to commit for mobile apps)
- [x] Firestore security rules (`firestore.rules`, deployed): a signed-in
      user may only read/write their own `users/{uid}` subtree
- [x] Email/Password sign-in enabled in Firebase Auth (manual one-time
      console toggle — not exposed by the Firebase CLI)
- [x] Real email/password auth wired to login/signup/logout, with
      inline error messages and a loading state on submit
- [x] Forgot-password: adapted from the canvas's fake in-app 6-digit-code
      flow to Firebase Auth's real (link-based) password reset — a true
      in-app OTP flow isn't something Firebase Auth supports natively
      without a custom Cloud Function backend, and a fake code screen
      that doesn't actually verify anything would be worse than not
      having it. Same visual language, now asks for email once and
      confirms the reset link was sent, instead of pretending to check a
      code that was never real.
- [x] Contacts, settings (feature toggles), Sentinel/Listen
      on-off+sensitivity, and SOS history all moved from local seed data
      to `users/{uid}/...` in Firestore, live-updating via snapshot
      listeners bound/unbound on sign-in/out (`_AuthBinder` in `app.dart`)
- [x] "Add manually" on Trusted Contacts now actually writes to
      Firestore (a simple dialog) — the native phone-contact picker is
      still Phase 3, but manual entry needed no native plugin so it
      shipped now rather than staying a fake button
- [x] New accounts are seeded with the same 4 demo trusted contacts the
      canvas used, written to Firestore on sign-up, so a fresh account
      isn't a blank slate
- Verify: `flutter analyze` clean, `flutter test` passing, `flutter build
  apk --debug` succeeds. User tests sign up, sign in, sign out, and the
  Firestore round-trip (contacts persist across a logout/login) manually.

### Phase 3 — Native device integrations ✅ done
- [x] `flutter_contacts` picker on the Trusted Contacts screen — "From
      phone" opens the real native OS picker (`FlutterContacts.native.showPicker`)
- [x] `geolocator` + `maplibre_gl` live-location map with a pulsing marker —
      the raw-OSM raster style is built inline (no key), camera centers on
      a real GPS fix, and the "pulsing marker" is a Flutter-animated dot
      pinned to the map's (always-recentered) center rather than a native
      map annotation — same visual as the canvas, simpler to build and
      keep centered on a live-updating fix
- [x] Real silent SMS send (`SmsManager`, via `another_telephony`) wired
      into `SosProvider.arm()` — fetches a real location fix, writes it
      (as `lat, lng` — no `geocoding` package in the locked list, so no
      reverse-geocoded street address) to the SOS history doc, and sends
      every trusted contact a real SMS with a Google Maps link
- [x] `permission_handler` prompts for location/contacts/SMS — Settings'
      "Device permissions" section now reads real OS permission status and
      its "Allow" buttons actually request permission
- [x] `url_launcher` for `tel:` — wired on the SOS screen's "Call 15" and
      every Location-screen helpline row. YouTube links in the Tutorial
      screen are left as still-fake placeholders since their `src` values
      aren't real URLs yet (the screen's own copy already says as much) —
      wiring `url_launcher` there is a one-line change once real links
      exist
- **Android/Gradle fallout from this being a very new toolchain** (AGP
  9.0.1 + Gradle 9.1 + Kotlin 2.3.20, whatever the current Flutter
  template scaffolds) that three plugins in this phase haven't fully
  caught up to yet — each fixed once, in `android/build.gradle.kts` or
  `pubspec.yaml`, rather than worked around per-build:
  - `maplibre_gl` only applies the classic Kotlin Gradle Plugin when
    AGP < 9, assuming AGP 9's built-in Kotlin provides the `kotlin {}`
    extension it needs otherwise — but this project's `gradle.properties`
    (set by the Flutter template itself) has that built-in support turned
    off, so the extension never existed. Fixed with a `subprojects` block
    that applies KGP to just that module.
  - `another_telephony` pins its own Kotlin compilation to JVM 1.8 but
    leaves its Java compilation on the toolchain's default (11), which AGP
    rejects as inconsistent. Fixed the same way, forcing that module's
    Java `compileOptions` down to 1.8 to match.
  - `permission_handler_android` 14.0.0 requires Android SDK Platform 37,
    and the copy Android's SDK manager auto-installed on this machine
    doesn't match the exact `android-37` target hash Gradle looks for (a
    preview/point-release naming mismatch, not something fixable from this
    repo). Pinned to the prior stable `permission_handler_android: 13.0.1`
    via `dependency_overrides` in `pubspec.yaml`, which targets the
    already-working compileSdk 36 — remove the override once SDK Platform
    37 installs cleanly on a given machine, or a fixed release ships.
- Verify: `flutter analyze` clean, `flutter test` passing, `flutter build
  apk --debug` succeeds. User tests location, contact picker, and SMS send
  manually on their own device.

### Phase 4 — Smart Sentinel
- [ ] `flutter_background_service` loop logging periodic location+speed
      samples
- [ ] Baseline/anomaly heuristic (off-route distance + arrival-time window
      + speed threshold)
- [ ] Silent vibrate check-in notification, 30s auto-escalate timer,
      hold-to-confirm vs. duress-hold-fires-anyway interaction
- Verify: `flutter analyze`/`flutter build` clean; the user tests manually
  on a real device — background survival across OEM battery optimization
  can only really be judged on real hardware over real time, not a quick
  check

### Phase 5 — Distress Listening
- [ ] Continuous mic capture via `record`
- [ ] YAMNet inference via `tflite_flutter`
- [ ] Confidence + sustained-duration window before auto-firing SOS
- Verify: `flutter analyze`/`flutter build` clean; the user tests
  real-world mic accuracy manually on their own device

### Phase 6 — Recordings + Fake Call
- [ ] Local video/audio/photo capture via `camera`/`path_provider`, saved
      under the `evidence/` folder with a Firestore reference doc per file
- [ ] Fake-call screen sequence (setup → waiting → ringing → in-call) as
      local UI + timers, no real telephony interception needed
- Verify: `flutter analyze`/`flutter build` clean; the user tests
  camera/mic capture and the fake-call flow manually

---

## Verification (applies every phase)

- `flutter analyze` must be clean before a phase is considered done, and
  `flutter build apk --debug` should succeed.
- One `flutter test` smoke test per phase for genuinely non-trivial logic
  (SOS state machine transitions, the Sentinel anomaly heuristic) — no
  framework-heavy widget test suite, just enough to catch a broken
  transition.
- No emulator/device run as part of a phase's own completion — the user
  tests each phase manually on their own device/emulator afterward and
  reports back.
