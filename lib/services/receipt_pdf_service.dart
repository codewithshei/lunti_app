import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart'
    show MissingPluginException, PlatformException;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../data/mock_app_state.dart';
import '../data/sample_catalog.dart';
import 'catalog_store.dart';
import 'order_format.dart';

/// Builds and shares the printable LUNTI receipt.
///
/// [buildReceiptPdf] is pure Dart (no platform channels and no asset I/O), so
/// it also runs — and completes — inside widget tests' fake async zone. Only
/// [downloadReceipt] talks to the `printing` plugin.

// LUNTI palette, reused for the receipt so the PDF matches the app.
final PdfColor _forest = PdfColor.fromHex('#344E41');
final PdfColor _beige = PdfColor.fromHex('#DAD7CD');
final PdfColor _ink = PdfColor.fromHex('#27372D');
final PdfColor _secondary = PdfColor.fromHex('#687267');
final PdfColor _warning = PdfColor.fromHex('#9C3D2E');
final PdfColor _cancelledBg = PdfColor.fromHex('#F6E4E1');

/// The receipt uses the PDF built-in Helvetica face, which has no glyph for
/// `₱` (U+20B1), so amounts are written as `PHP 1,120` — the same convention
/// used on printed Philippine receipts.
///
/// Both bundled faces were checked and neither covers the peso sign
/// (Poppins-Regular and PlayfairDisplay-Medium both lack U+20B1 in their
/// cmaps), so embedding a TTF would not help. Embedding would also need asset
/// I/O, which never completes inside widget tests' fake async zone.
String _peso(int amount) => 'PHP $amount';

final pw.TextStyle _headerLabel = pw.TextStyle(
  fontSize: 8,
  fontWeight: pw.FontWeight.bold,
  color: _secondary,
);
final pw.TextStyle _cell = pw.TextStyle(fontSize: 9.5, color: _ink);
final pw.TextStyle _cellBold = pw.TextStyle(
  fontSize: 9.5,
  fontWeight: pw.FontWeight.bold,
  color: _ink,
);
final pw.TextStyle _cellNote = pw.TextStyle(fontSize: 8, color: _secondary);

/// One resolved receipt line: the catalog name (BagLine only stores the id),
/// the quantity and the unit price actually charged.
class _ReceiptItem {
  const _ReceiptItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.note,
  });

  final String name;
  final int quantity;
  final int unitPrice;
  final String? note;

  int get lineTotal => unitPrice * quantity;
}

/// Builds the A5 receipt for [order] and returns the PDF bytes.
///
/// Layout is a single paginated column, so long orders spill onto a second
/// page instead of overflowing. A cancelled order keeps the same structure
/// with a `CANCELLED` stamp.
Future<Uint8List> buildReceiptPdf(Order order) async {
  final isCancelled = order.status == OrderStatus.cancelled;
  final items = _resolveItems(order);
  final address = <String>[
    order.addressTitle,
    order.addressLine1,
    order.addressLine2,
  ].where((part) => part.trim().isNotEmpty).join(', ');

  final document = pw.Document(
    title: 'LUNTI receipt ${order.id}',
    author: 'LUNTI',
  );

  document.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a5,
      margin: const pw.EdgeInsets.all(32),
      build: (context) => pw.ListView(
        children: <pw.Widget>[
          _header(),
          pw.SizedBox(height: 10),
          _detailRow('Order', order.id),
          _detailRow('Date', formatOrderDateTime(order.createdAt)),
          _detailRow('Customer', order.customerName),
          _detailRow('Address', address),
          _detailRow('Phone', order.phone),
          if (isCancelled) ...<pw.Widget>[
            pw.SizedBox(height: 6),
            _cancelledStamp(),
          ],
          pw.SizedBox(height: 12),
          _itemsTable(items),
          pw.SizedBox(height: 6),
          _totals(order),
          pw.SizedBox(height: 12),
          _detailRow('Payment method', order.paymentMethod),
          if (order.paymentStatus.isNotEmpty)
            _detailRow('Payment status', order.paymentStatus),
          if (isCancelled) ...<pw.Widget>[
            pw.SizedBox(height: 4),
            pw.Text(
              'This order was cancelled; the amounts above are for reference '
              'only.',
              style: pw.TextStyle(fontSize: 8.5, color: _warning),
            ),
          ],
          _footer(),
        ],
      ),
    ),
  );

  return document.save();
}

/// Upper bound for the share sheet. If the platform never answers, the
/// button stops spinning instead of waiting forever.
const Duration _shareTimeout = Duration(seconds: 10);

/// Shares the receipt so the customer can save, download or forward it.
///
/// Safe to call from widget tests: when no printing implementation is
/// registered the platform call is ignored instead of thrown.
Future<void> downloadReceipt(Order order) async {
  final Uint8List bytes = await buildReceiptPdf(order);
  try {
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'lunti-receipt-${order.id}.pdf',
    ).timeout(_shareTimeout);
  } on MissingPluginException {
    // No printing implementation (widget tests, or a platform without the
    // plugin): the receipt is generated, there is just nowhere to show it.
  } on PlatformException {
    // The share sheet was unavailable; never crash the receipt flow.
  } on TimeoutException {
    // The platform never answered; stop the button spinner instead of
    // spinning forever.
  }
}

List<_ReceiptItem> _resolveItems(Order order) {
  final catalog = <String, SampleProduct>{
    for (final product in CatalogStore.instance.products.value)
      product.id: product,
  };

  final items = <_ReceiptItem>[];
  for (final line in order.items) {
    final product = catalog[line.productId];
    items.add(
      _ReceiptItem(
        name: product?.name ?? line.productId,
        quantity: line.quantity,
        unitPrice:
            product == null ? 0 : BagPricing.unitPrice(product, line),
        note: _itemNote(line),
      ),
    );
  }
  return items;
}

String? _itemNote(BagLine line) {
  final engraving = line.engravingText?.trim() ?? '';
  if (engraving.isNotEmpty) return 'Engraved: "$engraving"';
  return line.variant;
}

pw.Widget _header() {
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: <pw.Widget>[
      pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            pw.Text(
              'LUNTI',
              style: pw.TextStyle(
                fontSize: 26,
                fontWeight: pw.FontWeight.bold,
                color: _forest,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              'Handcrafted bamboo goods',
              style: pw.TextStyle(fontSize: 9, color: _secondary),
            ),
          ],
        ),
      ),
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _forest, width: 1),
          borderRadius: pw.BorderRadius.circular(2),
        ),
        child: pw.Text(
          'RECEIPT',
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: _forest,
          ),
        ),
      ),
    ],
  );
}

pw.Widget _cancelledStamp() {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: pw.BoxDecoration(
      color: _cancelledBg,
      border: pw.Border.all(color: _warning, width: 1.2),
      borderRadius: pw.BorderRadius.circular(3),
    ),
    child: pw.Text(
      'CANCELLED',
      style: pw.TextStyle(
        fontSize: 14,
        fontWeight: pw.FontWeight.bold,
        color: _warning,
      ),
    ),
  );
}

pw.Widget _itemsTable(List<_ReceiptItem> items) {
  return pw.Column(
    children: <pw.Widget>[
      pw.Row(
        children: <pw.Widget>[
          pw.Expanded(child: pw.Text('ITEM', style: _headerLabel)),
          pw.SizedBox(
            width: 32,
            child: pw.Text('QTY', style: _headerLabel, textAlign: pw.TextAlign.right),
          ),
          pw.SizedBox(
            width: 60,
            child: pw.Text('UNIT', style: _headerLabel, textAlign: pw.TextAlign.right),
          ),
          pw.SizedBox(
            width: 60,
            child: pw.Text('TOTAL', style: _headerLabel, textAlign: pw.TextAlign.right),
          ),
        ],
      ),
      pw.Divider(thickness: 0.8, color: _beige),
      if (items.isEmpty)
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 6),
          child: pw.Text('No items recorded', style: _cellNote),
        ),
      for (final item in items) ...<pw.Widget>[
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 5),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: <pw.Widget>[
                    pw.Text(item.name, style: _cellBold),
                    if (item.note != null)
                      pw.Text(item.note!, style: _cellNote),
                  ],
                ),
              ),
              pw.SizedBox(
                width: 32,
                child: pw.Text(
                  '${item.quantity}',
                  style: _cell,
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.SizedBox(
                width: 60,
                child: pw.Text(
                  _peso(item.unitPrice),
                  style: _cell,
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.SizedBox(
                width: 60,
                child: pw.Text(
                  _peso(item.lineTotal),
                  style: _cell,
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        pw.Divider(thickness: 0.4, color: _beige),
      ],
    ],
  );
}

pw.Widget _totals(Order order) {
  return pw.Column(
    children: <pw.Widget>[
      _totalRow('Subtotal', _peso(order.subtotal)),
      _totalRow('Shipping', _peso(order.shippingFee)),
      _totalRow('Total', _peso(order.total), emphasised: true),
    ],
  );
}

pw.Widget _totalRow(String label, String value, {bool emphasised = false}) {
  final style = emphasised ? _cellBold : _cell;
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 3),
    child: pw.Row(
      children: <pw.Widget>[
        pw.Expanded(child: pw.Text(label, style: style)),
        pw.Text(value, style: style),
      ],
    ),
  );
}

pw.Widget _detailRow(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.SizedBox(width: 92, child: pw.Text(label, style: _cellNote)),
        pw.Expanded(
          child: pw.Text(value.isEmpty ? '—' : value, style: _cell),
        ),
      ],
    ),
  );
}

pw.Widget _footer() {
  return pw.Column(
    children: <pw.Widget>[
      pw.SizedBox(height: 16),
      pw.Divider(thickness: 0.8, color: _beige),
      pw.SizedBox(height: 8),
      pw.Text(
        'Salamat! Thank you for supporting handcrafted bamboo goods.',
        style: pw.TextStyle(fontSize: 9, color: _secondary),
        textAlign: pw.TextAlign.center,
      ),
      pw.SizedBox(height: 2),
      pw.Text(
        'LUNTI · Cardona, Rizal, Philippines',
        style: pw.TextStyle(fontSize: 8, color: _secondary),
        textAlign: pw.TextAlign.center,
      ),
    ],
  );
}
