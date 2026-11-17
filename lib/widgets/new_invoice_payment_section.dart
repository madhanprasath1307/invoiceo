import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:invoiceo/common/constants.dart';
import 'package:invoiceo/l10n/app_localizations.dart';
import 'package:invoiceo/utils/formatters.dart';
import 'package:invoiceo/utils/new_invoice_payment.dart';

/// The name shown for a stored payment method ("Check" is shown as "Cheque").
String newInvoicePaymentMethodLabel(AppLocalizations l10n, String method) {
  switch (method) {
    case 'Cash':
      return l10n.paymentMethodCash;
    case 'Bank Transfer':
      return l10n.paymentMethodBankTransfer;
    case 'Check':
      return l10n.paymentMethodCheck;
    case 'Online':
      return l10n.paymentMethodOnline;
    default:
      return l10n.paymentMethodOther;
  }
}

/// The error text for a Partial payment that cannot be saved yet.
String newInvoicePaymentErrorText(AppLocalizations l10n, NewInvoicePaymentError e) => switch (e) {
      NewInvoicePaymentError.amountMissing => l10n.createInvoicePaymentAmountRequired,
      NewInvoicePaymentError.amountNotLessThanTotal => l10n.createInvoicePaymentAmountTooHigh,
    };

/// The Payment section of the New Invoice form: Unpaid (nothing recorded), Partial (asks for the amount received
/// now) or Paid (the whole total). Partial and Paid also ask for the payment method, as the Apply Payment dialog
/// does, with an optional reference. The invoice is saved first and the payment is recorded right after.
///
/// The parent owns the state and the two text controllers; [total] is the live invoice total.
class NewInvoicePaymentSection extends StatelessWidget {
  const NewInvoicePaymentSection({
    super.key,
    required this.status,
    required this.onStatusChanged,
    required this.method,
    required this.onMethodChanged,
    required this.amountController,
    required this.notesController,
    required this.onAmountChanged,
    required this.total,
    required this.currencySymbol,
    this.errorText,
  });

  final NewInvoicePaymentStatus status;
  final ValueChanged<NewInvoicePaymentStatus> onStatusChanged;
  final String method;
  final ValueChanged<String> onMethodChanged;
  final TextEditingController amountController;
  final TextEditingController notesController;
  final VoidCallback onAmountChanged;
  final double total;
  final String currencySymbol;

  /// Shown under the amount box (Partial) when the amount cannot be saved.
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final hintStyle = TextStyle(fontSize: AppFontSize.small, color: scheme.onSurfaceVariant);
    final typed = parseNewInvoicePaymentAmount(amountController.text) ?? 0;
    final balance = (total - typed).clamp(0, double.infinity).toDouble();

    InputDecoration deco(String label, {String? hint, String? error, String? prefix}) => InputDecoration(
          labelText: label,
          hintText: hint,
          errorText: error,
          prefixText: prefix,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
        );

    return Column(
      key: const ValueKey('newInvoicePaymentSection'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            l10n.createInvoicePaymentSectionTitle.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        SegmentedButton<NewInvoicePaymentStatus>(
          key: const ValueKey('newInvoicePaymentStatus'),
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
                value: NewInvoicePaymentStatus.unpaid,
                label: Text(l10n.paymentStatusUnpaid, key: const ValueKey('newInvoicePayUnpaid'))),
            ButtonSegment(
                value: NewInvoicePaymentStatus.partial,
                label: Text(l10n.paymentStatusPartial, key: const ValueKey('newInvoicePayPartial'))),
            ButtonSegment(
                value: NewInvoicePaymentStatus.paid,
                label: Text(l10n.paymentStatusPaid, key: const ValueKey('newInvoicePayPaid'))),
          ],
          selected: {status},
          onSelectionChanged: (s) => onStatusChanged(s.first),
        ),
        const SizedBox(height: 8),
        if (status == NewInvoicePaymentStatus.unpaid)
          Text(l10n.createInvoicePaymentUnpaidNote, key: const ValueKey('newInvoicePaymentUnpaidNote'), style: hintStyle),
        if (status == NewInvoicePaymentStatus.partial) ...[
          TextField(
            key: const ValueKey('newInvoicePaymentAmount'),
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            decoration: deco(l10n.createInvoicePaymentAmountLabel, error: errorText, prefix: '$currencySymbol '),
            onChanged: (_) => onAmountChanged(),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.createInvoicePaymentBalanceDue(AppFormatters.formatAmount(balance, currencySymbol)),
            key: const ValueKey('newInvoicePaymentBalance'),
            style: hintStyle,
          ),
        ],
        if (status == NewInvoicePaymentStatus.paid)
          Text(
            l10n.createInvoicePaymentPaidNote(AppFormatters.formatAmount(total, currencySymbol)),
            key: const ValueKey('newInvoicePaymentPaidNote'),
            style: hintStyle,
          ),
        if (status != NewInvoicePaymentStatus.unpaid) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: const ValueKey('newInvoicePaymentMethod'),
            isExpanded: true,
            value: method,
            decoration: deco(l10n.paymentDialogMethodFieldLabel),
            items: [
              for (final m in kNewInvoicePaymentMethods)
                DropdownMenuItem(value: m, child: Text(newInvoicePaymentMethodLabel(l10n, m))),
            ],
            onChanged: (m) {
              if (m != null) onMethodChanged(m);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('newInvoicePaymentNotes'),
            controller: notesController,
            maxLength: 200,
            decoration: deco(l10n.paymentDialogNotesFieldLabel, hint: l10n.paymentDialogNotesHint).copyWith(counterText: ''),
          ),
        ],
      ],
    );
  }
}
