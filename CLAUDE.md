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

### Phase 1 — Scaffold + design system + navigation
- [ ] `flutter create` (Android-only platform target)
- [ ] Port theme: colors, fonts, spacing from the design canvas
- [ ] Build all 16 screens as real widgets
- [ ] Provider state machines mirroring the canvas's `Component` class
      (screen enum, onboarding index, sos idle/counting/armed, fake-call
      phases, settings toggles, etc.), using local/in-memory data only —
      no Firebase or native plugins yet
- Verify: `flutter analyze` clean, `flutter build` succeeds; the user tests
  manually on their own device/emulator after the phase — no need to launch
  an emulator as part of this phase's own verification

### Phase 2 — Firebase
- [ ] `flutterfire configure` (needs the user's own `firebase login` + a
      Firebase project — hand off exact commands, don't attempt account-bound
      steps autonomously)
- [ ] Real email/password auth wired to the login/signup screens
- [ ] Move contacts/history/settings from local seed data to Firestore
- Verify: `flutter analyze`/`flutter build` clean; the user tests sign up,
  sign in, and the Firestore round-trip manually

### Phase 3 — Native device integrations
- [ ] `flutter_contacts` picker on the Trusted Contacts screen
- [ ] `geolocator` + `maplibre_gl` live-location map with a pulsing marker
- [ ] Real silent SMS send (`SmsManager`) wired into the SOS hold flow
- [ ] `permission_handler` prompts for location/contacts/SMS
- [ ] `url_launcher` for `tel:` and YouTube links
- Verify: `flutter analyze`/`flutter build` clean; the user tests location,
  contact picker, and SMS send manually on their own device

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
