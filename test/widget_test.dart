import 'package:flutter_test/flutter_test.dart';
import 'package:movil/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AuxiaApp());
    expect(find.text('AUXIA'), findsOneWidget);
  });
}
