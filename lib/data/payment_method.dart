/// Payment options offered by the LUNTI prototype.
///
/// GCash and card are simulations: the app never collects wallet numbers or
/// card details, and no real money moves. Cash on Delivery is the only option
/// that represents a real payment, collected by the rider on delivery.
enum PaymentMethod { cashOnDelivery, gcash, card }

extension PaymentMethodX on PaymentMethod {
  /// Exact option label shown in Checkout, the payment picker and the order
  /// record saved to Firestore.
  String get label {
    switch (this) {
      case PaymentMethod.cashOnDelivery:
        return 'Cash on Delivery';
      case PaymentMethod.gcash:
        return 'GCash (Simulated)';
      case PaymentMethod.card:
        return 'Credit/Debit Card (Simulated)';
    }
  }

  /// Short label used in compact summaries such as "Payment · GCash".
  String get shortLabel {
    switch (this) {
      case PaymentMethod.cashOnDelivery:
        return 'Cash on Delivery';
      case PaymentMethod.gcash:
        return 'GCash';
      case PaymentMethod.card:
        return 'Credit/Debit Card';
    }
  }

  String get caption {
    switch (this) {
      case PaymentMethod.cashOnDelivery:
        return 'Pay the rider in cash when your order arrives';
      case PaymentMethod.gcash:
        return 'Demo wallet payment · no real money moves';
      case PaymentMethod.card:
        return 'Demo card payment · no card details are collected';
    }
  }

  /// Badge shown beside the option so the prototype behaviour is explicit.
  String get badgeLabel {
    switch (this) {
      case PaymentMethod.cashOnDelivery:
        return 'REAL PAYMENT / COD';
      case PaymentMethod.gcash:
      case PaymentMethod.card:
        return 'SIMULATION';
    }
  }

  /// Only Cash on Delivery represents a real payment in this prototype.
  bool get isSimulated => this != PaymentMethod.cashOnDelivery;

  /// Payment status stored with a successful order.
  String get paymentStatus {
    switch (this) {
      case PaymentMethod.cashOnDelivery:
        return 'Unpaid (COD)';
      case PaymentMethod.gcash:
        return 'Paid (GCash)';
      case PaymentMethod.card:
        return 'Paid (Card)';
    }
  }

  /// Paid variant for a stored payment method value.
  ///
  /// Cash on delivery settles on delivery, so a completed COD order becomes
  /// 'Paid (COD)'. Wallet and card orders settle up front and keep their own
  /// label; anything unrecognised falls back to a plain 'Paid'.
  static String paidStatusFor(Object? value) {
    final text = '${value ?? ''}'.trim().toLowerCase();
    if (text.contains('gcash')) return 'Paid (GCash)';
    if (text.contains('card') ||
        text.contains('credit') ||
        text.contains('debit')) {
      return 'Paid (Card)';
    }
    if (text.contains('cash') || text == 'cod' || text.contains('delivery')) {
      return 'Paid (COD)';
    }
    return 'Paid';
  }

  /// Message shown on Checkout under the selected method.
  String get checkoutNote {
    switch (this) {
      case PaymentMethod.cashOnDelivery:
        return 'Cash is collected when your order is delivered.';
      case PaymentMethod.gcash:
      case PaymentMethod.card:
        return 'This is a simulation. No real payment is processed.';
    }
  }

  /// Maps a stored value or legacy label onto a canonical method.
  static PaymentMethod parse(Object? value) {
    final text = '$value'.trim().toLowerCase();
    if (text.isEmpty) return PaymentMethod.gcash;
    // Check GCash before the generic "cash" match so "GCash (Simulated)" is
    // never mistaken for Cash on Delivery.
    if (text.contains('gcash')) return PaymentMethod.gcash;
    if (text.contains('card') ||
        text.contains('credit') ||
        text.contains('debit')) {
      return PaymentMethod.card;
    }
    if (text.contains('cash') ||
        text == 'cod' ||
        text == 'cash_on_delivery') {
      return PaymentMethod.cashOnDelivery;
    }
    return PaymentMethod.gcash;
  }
}
