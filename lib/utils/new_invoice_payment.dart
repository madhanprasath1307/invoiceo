import 'package:invoiceo/domain/invoice_calculator.dart';
import 'package:invoiceo/models/invoice.dart';
import 'package:invoiceo/repositories/payment_repository.dart';

/// What the New Invoice form's Payment section says about the invoice being made:
/// Unpaid (nothing is recorded), Partial (an amount was received now) or Paid (the whole total was received).
enum NewInvoicePaymentStatus { unpaid, partial, paid }

/// Why a Partial payment cannot be saved yet.
enum NewInvoicePaymentError {
  /// No amount, zero, or not a number.
  amountMissing,

  /// The amount is the whole total or more: that is "Paid", not a part payment.
  amountNotLessThanTotal,
}

/// The payment methods, as the Apply Payment dialog lists them (the stored values).
const List<String> kNewInvoicePaymentMethods = ['Cash', 'Bank Transfer', 'Check', 'Online', 'Other'];

/// The method preselected in the section: the commonest one for a counter sale.
const String kNewInvoiceDefaultPaymentMethod = 'Cash';

double _round2(double v) => (v * 100).round() / 100;

/// The amount typed in the Partial box; null when it is empty or not a number.
double? parseNewInvoicePaymentAmount(String text) {
  final t = text.trim().replaceAll(',', '');
  if (t.isEmpty) return null;
  return double.tryParse(t);
}

/// Whether a Partial payment of [amountText] is acceptable for an invoice of [total]: more than nothing and less
/// than the total. Null when it is fine (and always for Unpaid and Paid).
NewInvoicePaymentError? validateNewInvoicePayment({
  required NewInvoicePaymentStatus status,
  required String amountText,
  required double total,
}) {
  if (status != NewInvoicePaymentStatus.partial) return null;
  final amount = parseNewInvoicePaymentAmount(amountText);
  if (amount == null || amount <= InvoiceCalculator.moneyEpsilon) {
    return NewInvoicePaymentError.amountMissing;
  }
  if (amount >= total - InvoiceCalculator.moneyEpsilon) {
    return NewInvoicePaymentError.amountNotLessThanTotal;
  }
  return null;
}

/// The amount to record when the invoice is created: nothing for Unpaid, the whole [total] for Paid, the typed
/// amount for Partial (rounded to 2 decimals, like every amount in the app).
double? newInvoicePaymentAmount({
  required NewInvoicePaymentStatus status,
  required String amountText,
  required double total,
}) {
  switch (status) {
    case NewInvoicePaymentStatus.unpaid:
      return null;
    case NewInvoicePaymentStatus.paid:
      return total > InvoiceCalculator.moneyEpsilon ? _round2(total) : null;
    case NewInvoicePaymentStatus.partial:
      final a = parseNewInvoicePaymentAmount(amountText);
      return a == null ? null : _round2(a);
  }
}

/// Records the payment chosen on the form for the invoice that was just saved, the same way the Apply Payment dialog
/// does (a receipt number, the method, the balance after it). Returns false when nothing needed recording.
Future<bool> recordNewInvoicePayment({
  required PaymentRepository payments,
  required Invoice invoice,
  required NewInvoicePaymentStatus status,
  required String amountText,
  required String method,
  required String notes,
}) async {
  final amount = newInvoicePaymentAmount(status: status, amountText: amountText, total: invoice.total);
  if (amount == null) return false;
  await payments.addPayment(
    invoice: invoice,
    amountPaid: amount,
    datePaid: invoice.date,
    paymentMethod: method,
    notes: notes.trim().isEmpty ? null : notes.trim(),
  );
  return true;
}
