import 'package:admin_dashboard/theme.dart';
import 'package:admin_dashboard/widgets/admin_data_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
      theme: buildAdminTheme(),
      home: Scaffold(body: child),
    );

const List<AdminTableColumn> _columns = <AdminTableColumn>[
  AdminTableColumn('Product'),
  AdminTableColumn('Price'),
];

AdminTableRow _row(String name, String price) =>
    AdminTableRow(<Widget>[Text(name), Text(price)]);

void main() {
  testWidgets('renders a real header + rows table on wide layouts', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 900,
          child: AdminDataTable(
            columns: _columns,
            rows: [_row('Phone Speaker', '\u20B1450')],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DataTable), findsOneWidget);
    expect(find.text('PRODUCT'), findsOneWidget);
    expect(find.text('PRICE'), findsOneWidget);
    expect(find.text('Phone Speaker'), findsOneWidget);
  });

  testWidgets('renders stacked cards on narrow layouts', (tester) async {
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 480,
          child: AdminDataTable(
            columns: _columns,
            rows: [_row('Phone Speaker', '\u20B1450')],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DataTable), findsNothing);
    expect(find.text('PRODUCT'), findsOneWidget);
    expect(find.text('PRICE'), findsOneWidget);
    expect(find.text('Phone Speaker'), findsOneWidget);
  });

  testWidgets('clamps fixed-width cells so a narrow card never overflows', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 340,
          child: AdminDataTable(
            columns: const <AdminTableColumn>[
              AdminTableColumn('Comment'),
            ],
            rows: const <AdminTableRow>[
              AdminTableRow(<Widget>[
                SizedBox(
                  width: 320,
                  child: Text(
                    'A very long review comment that would overflow the card '
                    'if the cell kept its fixed width.',
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(DataTable), findsNothing);
  });
}
