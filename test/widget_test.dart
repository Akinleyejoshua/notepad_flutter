import 'package:flutter_test/flutter_test.dart';
import 'package:notepad/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NotepadApp());
    await tester.pump(const Duration(milliseconds: 100));

    // Verify the splash screen renders
    expect(find.text('Voice Notepad'), findsOneWidget);
  });
}
