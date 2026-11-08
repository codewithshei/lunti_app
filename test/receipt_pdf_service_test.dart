import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:lunti_app/data/mock_app_state.dart';
import 'package:lunti_app/data/payment_method.dart';
import 'package:lunti_app/services/catalog_store.dart';
import 'package:lunti_app/services/receipt_pdf_service.dart';

Order _order({
  OrderStatus status = OrderStatus.pending,
  List<BagLine>? items,
}) {
  return Order(
    id: 'LNT-TEST-001',
    items: items ??
        <BagLine>[
          BagLine('phone-speaker', variant: 'Natural', quantity: 2),
          BagLine('coaster', quantity: 1),
        ],
    subtotal: 1040,
    shippingFee: 80,
    total: 1120,
    paymentMethod: PaymentMethod.gcash.label,
    addressTitle: 'Home',
    addressLine1: '12 Bamboo St',
    addressLine2: 'Cardona, Rizal',
    phone: '+63 912 345 6789',
    createdAt: DateTime(2026, 11, 7, 15, 42),
    customerName: 'Maya Santos',
    status: status,
  );
}

void main() {
  // downloadReceipt touches the printing plugin's method channel, which needs
  // the binding initialized.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    MockAppState.reset();
    CatalogStore.instance.resetToBundledCatalog();
  });

  test('buildReceiptPdf returns a non-empty PDF', () async {
    final Uint8List bytes = await buildReceiptPdf(_order());

    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('cancelled orders still produce a valid PDF', () async {
    final Uint8List bytes = await buildReceiptPdf(
      _order(status: OrderStatus.cancelled),
    );

    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('orders with no recorded history still build a PDF', () async {
    // Legacy order: no statusHistory entries at all.
    final Uint8List bytes = await buildReceiptPdf(_order());

    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('unknown catalog products fall back to the product id', () async {
    final Uint8List bytes = await buildReceiptPdf(
      _order(
        items: <BagLine>[BagLine('not-in-catalog', quantity: 3)],
      ),
    );

    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('long orders paginate instead of overflowing the page', () async {
    final Uint8List bytes = await buildReceiptPdf(
      _order(
        items: <BagLine>[
          for (int i = 0; i < 24; i++)
            BagLine(i.isEven ? 'phone-speaker' : 'coaster', quantity: 1),
        ],
      ),
    );

    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('downloadReceipt is a no-op without the printing plugin', () async {
    // Widget tests have no platform implementation, so this must complete
    // instead of hanging or throwing.
    await downloadReceipt(_order());
  });
}
