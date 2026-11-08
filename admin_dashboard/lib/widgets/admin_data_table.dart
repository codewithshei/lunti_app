import 'package:flutter/material.dart';

import 'package:admin_dashboard/theme.dart';

/// Width at which [AdminDataTable] switches from stacked cards to a real
/// header + rows table.
const double kAdminTableWideBreakpoint = 700;

/// One column of an [AdminDataTable].
class AdminTableColumn {
  const AdminTableColumn(this.label);

  /// Header text. Rendered uppercase in the wide table and above every value
  /// in the stacked-card layout.
  final String label;
}

/// One row of an [AdminDataTable].
class AdminTableRow {
  const AdminTableRow(this.cells);

  /// Cell widgets, one per column, in the same order as the table's columns.
  ///
  /// Each cell is wrapped so it can never overflow the card in the narrow
  /// layout; in the wide layout the cell decides its own width.
  final List<Widget> cells;
}

/// Responsive table used by the orders, reviews and products pages.
///
/// On wide layouts (at least [kAdminTableWideBreakpoint] logical pixels) it
/// renders a real [DataTable] with a heading row, wrapped in a horizontal
/// [SingleChildScrollView] so a wide table scrolls instead of overflowing.
///
/// On narrow layouts the same rows become stacked cards: every value sits
/// under its column label, and each cell is clamped to the card width so long
/// content ellipsises rather than overflowing.
class AdminDataTable extends StatelessWidget {
  const AdminDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.headingRowHeight = 44,
    this.dataRowMinHeight = 64,
    this.dataRowMaxHeight = 120,
  });

  final List<AdminTableColumn> columns;
  final List<AdminTableRow> rows;

  final double headingRowHeight;
  final double dataRowMinHeight;
  final double dataRowMaxHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= kAdminTableWideBreakpoint) {
          return _AdminWideTable(
            columns: columns,
            rows: rows,
            headingRowHeight: headingRowHeight,
            dataRowMinHeight: dataRowMinHeight,
            dataRowMaxHeight: dataRowMaxHeight,
          );
        }
        return _AdminCardList(columns: columns, rows: rows);
      },
    );
  }
}

class _AdminWideTable extends StatelessWidget {
  const _AdminWideTable({
    required this.columns,
    required this.rows,
    required this.headingRowHeight,
    required this.dataRowMinHeight,
    required this.dataRowMaxHeight,
  });

  final List<AdminTableColumn> columns;
  final List<AdminTableRow> rows;
  final double headingRowHeight;
  final double dataRowMinHeight;
  final double dataRowMaxHeight;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: headingRowHeight,
        dataRowMinHeight: dataRowMinHeight,
        dataRowMaxHeight: dataRowMaxHeight,
        headingRowColor: WidgetStateProperty.all(AdminColors.surfaceAlt),
        dataRowColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.hovered)
              ? AdminColors.surfaceAlt
              : AdminColors.surface,
        ),
        dividerThickness: 1,
        horizontalMargin: 20,
        columnSpacing: 26,
        columns: [
          for (final column in columns)
            DataColumn(
              label: Text(
                column.label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w700,
                  color: AdminColors.muted,
                ),
              ),
            ),
        ],
        rows: [
          for (final row in rows)
            DataRow(cells: [for (final cell in row.cells) DataCell(cell)]),
        ],
      ),
    );
  }
}

class _AdminCardList extends StatelessWidget {
  const _AdminCardList({required this.columns, required this.rows});

  final List<AdminTableColumn> columns;
  final List<AdminTableRow> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _AdminDataCard(columns: columns, cells: rows[i].cells),
        ],
      ],
    );
  }
}

class _AdminDataCard extends StatelessWidget {
  const _AdminDataCard({required this.columns, required this.cells});

  final List<AdminTableColumn> columns;
  final List<Widget> cells;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < columns.length && i < cells.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      columns[i].label.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w700,
                        color: AdminColors.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Clamp fixed-width cells (SizedBox(width: ...)) so a long
                    // value ellipsises inside the card instead of overflowing.
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: maxWidth.isFinite
                            ? maxWidth
                            : double.infinity,
                      ),
                      child: cells[i],
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
