# She Secure

A women's safety app for Pakistan. It's built in Flutter, targets **Android only**, and is distributed as a **sideloaded APK** (it isn't on the Play Store).

You hold one button to send your location by SMS to up to five trusted contacts. Two on-device AI features can also send that alert for you: one notices when your day goes off its usual pattern, and the other listens for a scream.

---

## Features

| | What it does |
|---|---|
| **SOS** | Hold the button, then a 5 s cancellable countdown. After that, every trusted contact gets a **silent SMS** (sent through Android's `SmsManager`, with no compose sheet) containing a Google Maps link. While an alert is active you can call 15, record audio evidence, or share your location. |
| **Smart Sentinel** | A background service records your location and speed every 5 min and learns your weekday routine (route, pace, arrival time). When you go off-pattern, it sends a silent vibrate check-in. If you don't confirm within **30 s**, it sends the SOS on its own. Holding "I am safe" too long counts as a **duress hold** and still sends the alert. |
| **Distress Listening** | Continuous microphone capture with on-device **YAMNet** (521 AudioSet classes). A sustained, high-confidence *Screaming* or *Crying, sobbing* result sends the SOS **with no confirmation step**. |
| **Shake to alert / Power button ×3** | Shortcuts that send the SOS from the background, including with the screen locked. |
| **Trusted contacts** | Up to 5, added from the native phone contact picker or typed in manually. |
| **Live location** | MapLibre map using raw OpenStreetMap tiles (no API key), a live GPS pin, the Pakistan helpline numbers, and a shareable link. |
| **Recordings** | Video, audio and photo evidence. The files are stored **on the device only** (in `evidence/`, plus a copy in the Gallery or Music app). Firestore holds only a small reference document for each file. |
| **Fake call** | A scheduled incoming call with a real ringtone. It also rings with the screen locked. |
| Also included | Onboarding, email/password auth, password reset by email link, profile, settings, and a tutorial. |

## Tech stack

- **Flutter** 3.47 / Dart 3.12, using **Provider** for state.
- **Firebase**: Auth (email/password) and Cloud Firestore (region `asia-south1`). The project is `she-secure-pk`.
- **Native features**: `another_telephony` (SMS), `geolocator` and `maplibre_gl`, `flutter_contacts`, `flutter_background_service`, `record` and `tflite_flutter` (YAMNet), `camera`, `sensors_plus`, `screen_state_v2`, `flutter_local_notifications` and `permission_handler`.

---

## Getting started

### Prerequisites
- The Flutter SDK (stable channel) and the Android SDK (compileSdk 36).
- An Android phone with USB debugging turned on. An emulator works for the UI, but it can't send SMS or test the background features properly.

### Run it
```bash
flutter pub get
flutter run                 # on a connected phone
flutter build apk --debug   # → build/app/outputs/flutter-apk/app-debug.apk
```

The Firebase config (`lib/firebase_options.dart`, `android/app/google-services.json`) is committed on purpose. It contains a public client key, and the Firestore rules are what restrict access, not the key.

### First launch on a phone
1. **Sign up.** The app then asks for every permission it needs in one go.
2. **SMS on Android 13 and later:** Android blocks the SMS permission for sideloaded apps, and nothing in the app can unblock it. Go to *Settings → Apps → She Secure → ⋮ → Allow restricted settings*, then grant SMS. The app shows these steps if the permission isn't granted.
3. **Battery optimization:** allow "unrestricted" so Android doesn't kill Smart Sentinel or Distress Listening. This matters most on Xiaomi, Oppo, Vivo and Realme phones.
4. Add at least one **trusted contact**.

### Seeing the AI features right away
Smart Sentinel needs about 2 weeks of real samples before it can tell you anything. To see it working now:

**Settings → Demo data → Load 2 weeks of demo routine**

This writes 14 days of realistic samples (one every 15 min) around where your phone is right now. The routine is a weekday walk of about 2 km to "work" at 8:00 and back at 17:00, and on weekends a walk to a nearby market. It also adds a few past Sentinel and Listen events, all tagged `demo` in Firestore. **Remove demo data** deletes exactly those documents. It never touches your contacts or SOS history.

With the demo routine loaded:
- The **Smart Sentinel** screen shows "14 days learned", the weekday pattern strip (your commute is highlighted), your pace, your usual arrival time, your familiar places, and past events.
- If you set sensitivity to **Alert** and stay home during weekday work hours, the next sample (within 5 min) finds you about 2 km off the learned routine and starts a **real check-in**.
- The **"Show me the are-you-safe check"** and **"Simulate a detected scream"** buttons go through the same path as a real detection.

> ⚠️ **The simulate buttons send real SMS** to your trusted contacts, just as a real alert would. Test them with your own number as the only contact.

---

## Project structure

```
lib/
  main.dart, app.dart            app entry, routes, and _AuthBinder (binds each provider to the signed-in user)
  theme/                         colors, text styles, theme (dark, accent #e5527e, Inter)
  models/                        contact, SOS event, settings, profile
  providers/                     auth, contacts, sos, sentinel, listen, settings, fake_call, recordings
  services/
    sentinel_service.dart        the background service: Sentinel sampling, check-in timer, mic + YAMNet,
                                 shake and power-button detection, fake-call timer, and sending alerts
    audio_detection_service.dart YAMNet inference
    sms_service.dart             silent SMS
    location_service.dart        GPS fix and stream, plus the "share location" setting
    permission_service.dart      permission requests that work in both isolates
    user_data_service.dart       loading/clearing demo data, deleting history
    ...                          contact picker, recordings, profile photo
  screens/                       16 screens (splash, onboarding, auth, home, sos, contacts, location, …)
  widgets/                       hold-to-confirm button, status pill, logo, …
  utils/
    sentinel_heuristic.dart      anomaly check (off-route / off-pace against the learned baseline)
    routine_summary.dart         turns samples into what the Sentinel screen shows
    listen_heuristic.dart        scream confidence × consecutive-window threshold
    formatters.dart, validators.dart
assets/models/                   yamnet.tflite + yamnet_class_map.csv (Google's published files, unmodified)
test/                            unit tests for the SOS state machine and all three heuristics
firestore.rules                  users can only read and write their own users/{uid} data
firestore.indexes.json           index for Sentinel's baseline query (weekday + minuteOfDay)
```

### How the background service works
Smart Sentinel, Distress Listening, the shortcuts and the fake-call timer all run in **one Android foreground service** (`location|microphone` type). It runs in its own Dart isolate, which has no access to the app's providers. The service sends alerts itself (location fix, SMS, history record) and reports events back to the app (`checkinStarted`, `screamDetected`, `shortcutFired`, …). The providers only reflect those events in the UI. If the app was closed when an alert went out, reopening it within 30 min shows the alert as **active**.

### Firestore data
```
users/{uid}                        name, email, createdAt
  contacts/{id}                    name, relation, phone, initials
  sosHistory/{id}                  where, when, detail
  settings/preferences             features{…}, sentinelOn, sensitivity, listenOn, earSensitivity
  sentinelSamples/{id}             timestamp, lat, lng, speed, weekday, minuteOfDay  (deleted after 28 days)
  sentinelEvents/{id}              what, how, when  (check-ins: confirmed safe / alert sent)
  listenEvents/{id}                what, how, when  (detections)
  evidence/{id}                    type, localPath, timestamp, durationOrSize  (the file itself stays on the device)
```

To deploy rules or indexes: `firebase deploy --only firestore:rules,firestore:indexes`

---

## Testing

```bash
flutter analyze   # must be clean
flutter test      # SOS state machine, Sentinel heuristic + demo-routine end to end, Listen heuristic, routine summary
python tool/yamnet_eval.py <clips-dir>   # the bundled YAMNet model on real labelled audio (see the script for sources)
```

Results on real clips, run through the app's exact audio pipeline:

| alerts fired | Alert | Balanced (default) | Relaxed |
|---|---|---|---|
| 20 real screams | 17 | 13 | 7 |
| 8 crying-baby clips | 7 | 6 | 5 |
| 33 everyday sounds (speech, laughter, siren, dog, rain, traffic, typing…) | 0 | 0 | 0 |

Some things can only be checked on a real phone: silent SMS delivery, whether the background service survives OEM battery management, and real-world microphone accuracy.

## Known limitations

- **YAMNet is a general audio classifier, not a scream detector.** It misses some screams, especially short, muffled or distant ones; see the table above. A scream on TV *will* trigger it. The sensitivity setting tunes both the confidence threshold and how much sustained sound (about 1–2 s) is needed.
- **Sentinel's anomaly check is simple:** it compares you against the centroid of your usual position for that weekday and time, plus your usual speed range. It doesn't match the actual route you take, and it doesn't wrap across midnight.
- **Aggressive OEM skins** can still kill the background service even when battery optimization is disabled.
- **OpenStreetMap tiles** come straight from `tile.openstreetmap.org`, which is fine for development and light use but not for heavy production traffic.
- **Updates:** sideloaded APKs don't auto-update.
- Password reset uses Firebase's emailed link, not an in-app OTP.

## Emergency numbers (Pakistan)
Police **15** · Rescue **1122** · Edhi **115** · Chhipa **1020** · Women and Child Helpline **1043** · Madadgar **1098**. All of these can be dialled from the Location screen.
