// Smoke test for the SOS state machine — the app's most safety-critical
// non-trivial logic. Runs inside testWidgets purely to get flutter_test's
// fake-clock control over the Timers SosProvider uses internally; no
// widget tree is needed.

import 'package:flutter_test/flutter_test.dart';
import 'package:she_secure/providers/contacts_provider.dart';
import 'package:she_secure/providers/sos_provider.dart';

void main() {
  testWidgets('SOS: countdown then arm, with contact-ack timeline', (tester) async {
    final sos = SosProvider(contacts: ContactsProvider());
    addTearDown(sos.dispose);

    sos.beginCountdown();
    expect(sos.state, SosState.counting);
    expect(sos.count, 5);

    // 5 one-second ticks brings the countdown to zero and arms the alert.
    await tester.pump(const Duration(seconds: 5));
    expect(sos.state, SosState.armed);
    expect(sos.elapsed, 0);
    expect(sos.acked, 0);

    await tester.pump(const Duration(seconds: 3));
    expect(sos.acked, 1);
    await tester.pump(const Duration(seconds: 3));
    expect(sos.acked, 2);
    await tester.pump(const Duration(seconds: 5));
    expect(sos.acked, 3);

    // Stop the still-running elapsed timer before the test ends — flutter_test
    // asserts no timers are left pending when a test finishes.
    sos.cancel();
  });

  testWidgets('SOS: cancelling during countdown returns to idle without arming', (tester) async {
    final sos = SosProvider(contacts: ContactsProvider());
    addTearDown(sos.dispose);

    sos.beginCountdown();
    await tester.pump(const Duration(seconds: 2));
    expect(sos.state, SosState.counting);

    sos.cancel();
    expect(sos.state, SosState.idle);
    expect(sos.count, 5);

    // The original countdown timer must actually be cancelled, not just
    // masked by the state flip — advancing well past when it would have
    // armed proves that.
    await tester.pump(const Duration(seconds: 10));
    expect(sos.state, SosState.idle);
  });

  testWidgets('SOS: arm() fires immediately, bypassing hold/countdown (AI escalation path)', (tester) async {
    final sos = SosProvider(contacts: ContactsProvider());
    addTearDown(sos.dispose);

    sos.arm();
    expect(sos.state, SosState.armed);

    sos.cancel();
    expect(sos.state, SosState.idle);
  });
}
