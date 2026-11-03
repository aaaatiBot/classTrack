import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:classtrack/main.dart';

void main() {
  testWidgets('ClassTrack app smoke test - Login screen displays', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ClassTrackApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify ClassTrack title and sign in button are displayed
    expect(find.text('ClassTrack'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('@classtrack.app'), findsOneWidget);
  });
}
