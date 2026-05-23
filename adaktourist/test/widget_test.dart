// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:adaktourist/main.dart';

void main() {
  testWidgets('Test de démarrage de l\'application', (WidgetTester tester) async {
    await tester.pumpWidget(const AppTourisme());
    expect(find.byType(AppTourisme), findsOneWidget);
  });
}