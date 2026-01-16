import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:szybka_fucha/main.dart';

void main() {
  testWidgets('Welcome screen displays correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: SzybkaFuchaApp(),
      ),
    );

    // Verify the headline is displayed
    expect(find.text('Pomoc jest bliżej niż myślisz'), findsOneWidget);

    // Verify buttons are present
    expect(find.text('Szukam pomocy'), findsOneWidget);
    expect(find.text('Chcę pomagać i zarabiać'), findsOneWidget);

    // Verify the footer text
    expect(
      find.textContaining('Dołączając, akceptujesz'),
      findsOneWidget,
    );
  });
}
