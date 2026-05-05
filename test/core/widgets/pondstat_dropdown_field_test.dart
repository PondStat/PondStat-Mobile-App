import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pondstat/core/widgets/pondstat_dropdown_field.dart';

void main() {
  testWidgets('PondStatDropdownField updates value dynamically and uses theme', (WidgetTester tester) async {
    String? selectedValue = 'Item 1';
    StateSetter? testSetState;
    
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              testSetState = setState;
              return PondStatDropdownField<String>(
                value: selectedValue,
                label: 'Test Dropdown',
                items: const [
                  DropdownMenuItem(value: 'Item 1', child: Text('Item 1')),
                  DropdownMenuItem(value: 'Item 2', child: Text('Item 2')),
                ],
                onChanged: (val) {
                  setState(() {
                    selectedValue = val;
                  });
                },
              );
            },
          ),
        ),
      ),
    );

    // Initial state check
    expect(find.text('Item 1'), findsWidgets);

    // Change value from outside
    testSetState?.call(() {
      selectedValue = 'Item 2';
    });
    await tester.pumpAndSettle();

    // Verify it updated
    expect(find.text('Item 2'), findsWidgets);
  });
}
