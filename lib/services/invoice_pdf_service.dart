import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/order_model.dart';
import 'invoice_file_saver.dart';

/// Creates and saves a customer invoice PDF to a location selected by the user.
Future<String?> downloadCustomerInvoice(OrderModel order) async {
  final invoiceNumber = order.invoiceNumber?.trim();
  if (invoiceNumber == null || invoiceNumber.isEmpty) {
    throw StateError(
      'Bill number is not available until delivery is completed',
    );
  }
  final document = pw.Document();
  final itemRows = <List<String>>[];

  for (var index = 0; index < order.products.length; index++) {
    final product = order.products[index];
    final quantity = index < order.quantities.length
        ? order.quantities[index]
        : 1;
    final amount = product.price * quantity;
    itemRows.add([
      '${index + 1}',
      product.name,
      '$quantity ${product.unit}'.trim(),
      _money(amount),
    ]);
  }

  if (itemRows.isEmpty) {
    itemRows.add(['1', 'No item details available', '', _money(0)]);
  }

  final subtotal = order.products.asMap().entries.fold<double>(
    0,
    (sum, entry) =>
        sum +
        entry.value.price *
            (entry.key < order.quantities.length
                ? order.quantities[entry.key]
                : 1),
  );

  document.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 14),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.green)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'DoorMart',
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Everything you need, delivered.',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'INVOICE',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.orange,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      invoiceNumber,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(_date(order.createdAt)),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Bill to',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            order.customerName.isEmpty ? 'Customer' : order.customerName,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          if (order.address.isNotEmpty) pw.Text(order.address),
          if (order.customerPhone.isNotEmpty) pw.Text(order.customerPhone),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: const ['S.No', 'Item description', 'Qty', 'Amount'],
            data: itemRows,
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green),
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellPadding: const pw.EdgeInsets.all(8),
            border: pw.TableBorder.all(color: PdfColors.green100),
          ),
          pw.SizedBox(height: 14),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              width: 240,
              padding: const pw.EdgeInsets.all(12),
              decoration: const pw.BoxDecoration(color: PdfColors.green50),
              child: pw.Column(
                children: [
                  _summaryRow('Items total', subtotal),
                  _summaryRow('Delivery fee', order.deliveryFee),
                  if (order.gstAmount > 0) _summaryRow('GST', order.gstAmount),
                  pw.Divider(color: PdfColors.green),
                  _summaryRow('Total', order.total, emphasis: true),
                ],
              ),
            ),
          ),
          pw.Spacer(),
          pw.Center(
            child: pw.Text(
              'Thank you for shopping with DoorMart.',
              style: const pw.TextStyle(color: PdfColors.grey700),
            ),
          ),
        ],
      ),
    ),
  );

  final bytes = await document.save();
  final filename = 'doormart-invoice-$invoiceNumber.pdf';
  return saveInvoiceBytes(Uint8List.fromList(bytes), filename);
}

pw.Widget _summaryRow(String label, double value, {bool emphasis = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 3),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontWeight: emphasis ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          _money(value),
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: emphasis ? PdfColors.green : PdfColors.black,
          ),
        ),
      ],
    ),
  );
}

String _money(double value) => '₹${value.toStringAsFixed(2)}';

String _date(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
