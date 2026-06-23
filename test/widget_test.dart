// Basic smoke test: the app builds and shows the discovery screen.

import 'package:flutter_test/flutter_test.dart';

import 'package:wailscast_remote/main.dart';

void main() {
  testWidgets('App builds and shows the remote title', (tester) async {
    await tester.pumpWidget(const WailsCastRemoteApp());
    await tester.pump();

    expect(find.text('WailsCast Remote'), findsOneWidget);
  });
}
