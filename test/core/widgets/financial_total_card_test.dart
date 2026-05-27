import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/financial_total_card.dart';

void main() {
  testWidgets(
    'FinancialTotalCard displays label, amount with currency symbol, and uses specified colors',
    (WidgetTester tester) async {
      const String label = 'Total Revenue';
      const double amount = 12500.75;
      const Color textColor = Colors.teal;
      const Color backgroundColor = Colors.white;
      const Color borderColor = Colors.grey;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FinancialTotalCard(
              label: label,
              amount: amount,
              textColor: textColor,
              backgroundColor: backgroundColor,
              borderColor: borderColor,
            ),
          ),
        ),
      );

      // Verify label is displayed
      expect(find.text(label), findsOneWidget);

      // Verify formatted currency amount is displayed
      // Expected formatted value: ₱12,500.75
      expect(find.text('₱12,500.75'), findsOneWidget);

      // Verify styling and colors
      final containerFinder = find.byType(Container);
      expect(containerFinder, findsOneWidget);

      final Container containerWidget = tester.widget<Container>(containerFinder);
      final BoxDecoration decoration = containerWidget.decoration as BoxDecoration;

      expect(decoration.color, backgroundColor);
      expect(decoration.border?.isUniform, true);
      expect(decoration.border?.top.color, borderColor);
      expect(decoration.borderRadius, BorderRadius.circular(20));

      final labelText = tester.widget<Text>(find.text(label));
      expect(labelText.style?.color, textColor);
      expect(labelText.style?.fontWeight, FontWeight.w800);
      expect(labelText.style?.fontSize, 16);

      final amountText = tester.widget<Text>(find.text('₱12,500.75'));
      expect(amountText.style?.color, textColor);
      expect(amountText.style?.fontWeight, FontWeight.w900);
      expect(amountText.style?.fontSize, 24);
    },
  );
}
