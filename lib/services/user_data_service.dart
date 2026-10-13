import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'location_service.dart';

/// Bulk writes/deletes on the signed-in user's Firestore subtree: the
/// Settings screen's demo-data and delete-history actions.
class UserDataService {
  UserDataService._();

  static DocumentReference<Map<String, dynamic>> _user(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid);

  static const _demoCollections = ['sentinelSamples', 'sentinelEvents', 'listenEvents'];

  /// Writes 14 days of realistic Smart Sentinel samples (one every 15 min)
  /// around the phone's current location, plus a few past Sentinel/Listen
  /// events, so the AI screens have a learned routine to show and the
  /// anomaly check has a baseline. Every doc carries `demo: true` so
  /// [clearDemoData] removes exactly these and nothing real. Contacts and
  /// SOS history are never touched — seeding either could send real SMS
  /// or re-arm an alert.
  ///
  /// Routine: Mon–Fri home → ~2 km walk to work at 8:00, back at 17:00;
  /// Sat/Sun home with a late-morning walk to a nearby market.
  static Future<int> loadDemoData(String uid) async {
    await clearDemoData(uid);
    final here = await LocationService.getCurrentPosition();
    final home = (here?.latitude ?? 31.5204, here?.longitude ?? 74.3587); // Lahore fallback
    final random = Random(42);

    final samples = _user(uid).collection('sentinelSamples');
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    var batch = FirebaseFirestore.instance.batch();
    var pending = 0;
    var written = 0;

    for (var dayBack = 14; dayBack >= 1; dayBack--) {
      final day = startOfToday.subtract(Duration(days: dayBack));
      final weekend = day.weekday >= 6;
      for (var minute = 0; minute < 24 * 60; minute += 15) {
        final (lat, lng, speed) = demoRoutineAt(minute, weekend: weekend, home: home);
        final jitter = speed > 0.5 ? 0.0001 : 0.0002;
        batch.set(samples.doc(), {
          'timestamp': Timestamp.fromDate(day.add(Duration(minutes: minute))),
          'lat': lat + (random.nextDouble() - 0.5) * jitter,
          'lng': lng + (random.nextDouble() - 0.5) * jitter,
          'speed': speed,
          'weekday': day.weekday,
          'minuteOfDay': minute,
          'demo': true,
        });
        written++;
        if (++pending == 450) {
          await batch.commit();
          batch = FirebaseFirestore.instance.batch();
          pending = 0;
        }
      }
    }

    DateTime ago(int days, int hour, int minute) =>
        startOfToday.subtract(Duration(days: days)).add(Duration(hours: hour, minutes: minute));
    final events = [
      ('sentinelEvents', 'Off route near the market', ago(2, 18, 20), 'You confirmed safe in 9 s'),
      ('sentinelEvents', 'Running pace, no workout logged', ago(6, 20, 2), 'You confirmed safe in 4 s'),
      ('sentinelEvents', 'Stopped 40 min in an unfamiliar area', ago(11, 18, 15), 'You confirmed safe in 12 s'),
      ('listenEvents', 'Loud voices', ago(1, 14, 14), 'Ignored · below threshold'),
      ('listenEvents', 'Crying, sobbing', ago(5, 23, 48), 'Ignored · not sustained'),
    ];
    for (final (collection, what, at, how) in events) {
      batch.set(_user(uid).collection(collection).doc(), {
        'what': what,
        'how': '$how · demo',
        'when': Timestamp.fromDate(at),
        'demo': true,
      });
    }
    await batch.commit();
    return written;
  }

  /// Where the demo routine puts you at [minute] of the day, as
  /// (lat, lng, speed m/s): work is ~2 km NE of [home], the market ~800 m SE.
  @visibleForTesting
  static (double, double, double) demoRoutineAt(int minute, {required bool weekend, required (double, double) home}) {
    return weekend
        ? _weekendAt(minute, home, (home.$1 - 0.006, home.$2 + 0.005))
        : _weekdayAt(minute, home, (home.$1 + 0.014, home.$2 + 0.012));
  }

  static (double, double, double) _weekdayAt(int minute, (double, double) home, (double, double) work) {
    const walk = 1.3; // m/s — ~2 km in 30 min
    if (minute >= 480 && minute < 510) return _between(home, work, (minute - 480) / 30, walk);
    if (minute >= 510 && minute < 1020) return (work.$1, work.$2, minute % 60 == 0 ? 0.3 : 0.0);
    if (minute >= 1020 && minute < 1050) return _between(work, home, (minute - 1020) / 30, walk);
    return (home.$1, home.$2, 0.0);
  }

  static (double, double, double) _weekendAt(int minute, (double, double) home, (double, double) market) {
    const walk = 1.2;
    if (minute >= 660 && minute < 675) return _between(home, market, (minute - 660) / 15, walk);
    if (minute >= 675 && minute < 765) return (market.$1, market.$2, 0.4);
    if (minute >= 765 && minute < 780) return _between(market, home, (minute - 765) / 15, walk);
    return (home.$1, home.$2, 0.0);
  }

  static (double, double, double) _between((double, double) a, (double, double) b, double t, double speed) =>
      (a.$1 + (b.$1 - a.$1) * t, a.$2 + (b.$2 - a.$2) * t, speed);

  /// Removes everything [loadDemoData] wrote — real samples/events stay.
  static Future<void> clearDemoData(String uid) async {
    for (final collection in _demoCollections) {
      await _deleteAll(_user(uid).collection(collection).where('demo', isEqualTo: true));
    }
  }

  /// SOS history plus the Sentinel/Listen event logs. The learned routine
  /// (`sentinelSamples`) is kept — wiping it would restart the 2-week
  /// learning period.
  static Future<void> clearHistory(String uid) async {
    for (final collection in ['sosHistory', 'sentinelEvents', 'listenEvents']) {
      await _deleteAll(_user(uid).collection(collection));
    }
  }

  static Future<void> _deleteAll(Query<Map<String, dynamic>> query) async {
    while (true) {
      final snap = await query.limit(450).get();
      if (snap.docs.isEmpty) return;
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }
}
