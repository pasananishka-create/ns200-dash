import 'package:flutter_test/flutter_test.dart';
import 'package:ns200_app/main.dart';

void main() {
  testWidgets('App renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(const NS200App());
    expect(find.text('NS 200'), findsOneWidget);
  });
}
