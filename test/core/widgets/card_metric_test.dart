import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/card_metric.dart';

void main() {
  testWidgets(
    'CardMetric displays label, value, and respects customization options',
    (WidgetTester tester) async {
      const String label = 'Quantity';
      const String value = '150 kg';
      const Color customColor = Colors.teal;

      // 1. Test standard rendering (non-highlighted, no custom color)
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CardMetric(
              label: label,
              value: value,
            ),
          ),
        ),
      );

      expect(find.text(label), findsOneWidget);
      expect(find.text(value), findsOneWidget);

      var labelText = tester.widget<Text>(find.text(label));
      expect(labelText.style?.fontSize, 10);
      expect(labelText.style?.fontWeight, FontWeight.w800);

      var valueText = tester.widget<Text>(find.text(value));
      expect(valueText.style?.fontSize, 13);
      expect(valueText.style?.fontWeight, FontWeight.w700);
      
      final context = tester.element(find.text(value));
      final expectedColor = Theme.of(context).colorScheme.onSurface;
      expect(valueText.style?.color, expectedColor);

      // 2. Test highlighted rendering with custom color
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CardMetric(
              label: label,
              value: value,
              isHighlighted: true,
              valueColor: customColor,
            ),
          ),
        ),
      );

      valueText = tester.widget<Text>(find.text(value));
      expect(valueText.style?.fontWeight, FontWeight.w900);
      expect(valueText.style?.color, customColor);
    },
  );
}
