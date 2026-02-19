import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/pos_order.dart';
import '../models/pos_order_item.dart';
import '../services/app_settings_service.dart';

Future<Uint8List> buildTicketPdf(
  PosOrder order,
  List<PosOrderItem> items, {
  PdfPageFormat? format,
}) async {
  return buildCustomerBillPdf(order, items, format: format);
}

Future<Uint8List> buildKitchenTicketPdf(
  PosOrder order,
  List<PosOrderItem> items, {
  PdfPageFormat? format,
}) async {
  final doc = pw.Document();
  final pageFormat = format ?? PdfPageFormat.roll80;
  final logoImage = await _loadLogoImage();
  final orderTime = _formatOrderTime(order.createdAt);
  final payment = order.paymentMethod ?? '-';
  final statusText = '${order.status} / ${order.paymentStatus}';

  doc.addPage(
    pw.Page(
      pageFormat: pageFormat,
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logoImage != null)
              pw.Center(
                child: pw.SizedBox(
                  height: 56,
                  child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                ),
              ),
            if (logoImage != null) pw.SizedBox(height: 8),
            pw.Text(
              'BON CUISINE',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Commande #${order.id}'),
            pw.Text('Heure: $orderTime'),
            pw.Text('Type: ${_fulfillmentLabel(order.fulfillmentType)}'),
            pw.Text('Table: ${order.tableNumber ?? '-'}'),
            pw.Text('Client: ${order.customerName ?? '-'}'),
            pw.Text('Canal: ${order.channel}'),
            pw.Text('Statut: $statusText'),
            pw.Text('Paiement: $payment'),
            if (order.note != null && order.note!.trim().isNotEmpty)
              pw.Text('Note: ${order.note!.trim()}'),
            pw.Divider(),
            ...items.map(
              (it) => pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(
                    width: 32,
                    child: pw.Text(
                      '${it.quantity}x',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Expanded(child: pw.Text(it.productName)),
                ],
              ),
            ),
            pw.Divider(),
            pw.Text(
              'Articles: ${items.fold<int>(0, (sum, item) => sum + item.quantity)}',
            ),
          ],
        );
      },
    ),
  );

  return doc.save();
}

Future<Uint8List> buildCustomerBillPdf(
  PosOrder order,
  List<PosOrderItem> items, {
  PdfPageFormat? format,
}) async {
  final doc = pw.Document();
  final pageFormat = format ?? PdfPageFormat.roll80;
  final logoImage = await _loadLogoImage();
  final money = AppSettingsService.instance.formatAmount;
  final orderTime = _formatOrderTime(order.createdAt);

  final subtotal = order.originalTotal > 0
      ? order.originalTotal
      : order.totalPrice;
  final discount = order.discountAmount;
  final total = order.totalPrice;
  final payment = order.paymentMethod ?? '-';
  final statusText = '${order.status} / ${order.paymentStatus}';

  doc.addPage(
    pw.Page(
      pageFormat: pageFormat,
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logoImage != null)
              pw.Center(
                child: pw.SizedBox(
                  height: 56,
                  child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                ),
              ),
            if (logoImage != null) pw.SizedBox(height: 8),
            pw.Text(
              'ADDITION CLIENT',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Commande #${order.id}'),
            pw.Text('Heure: $orderTime'),
            pw.Text('Type: ${_fulfillmentLabel(order.fulfillmentType)}'),
            pw.Text('Table: ${order.tableNumber ?? '-'}'),
            pw.Text('Client: ${order.customerName ?? '-'}'),
            pw.Text('Tel: ${order.customerPhone ?? '-'}'),
            if (order.deliveryAddress != null)
              pw.Text('Adresse: ${order.deliveryAddress}'),
            pw.Text('Canal: ${order.channel}'),
            pw.Text('Statut: $statusText'),
            pw.Text('Paiement: $payment'),
            pw.Divider(),
            ...items.map(
              (it) => pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text('${it.quantity} x ${it.productName}'),
                  ),
                  pw.Text(money(it.unitPrice * it.quantity)),
                ],
              ),
            ),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [pw.Text('Sous-total'), pw.Text(money(subtotal))],
            ),
            if (discount > 0)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [pw.Text('Remise'), pw.Text('-${money(discount)}')],
              ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Total',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  money(total),
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );

  return doc.save();
}

Future<Uint8List> buildKitchenAndCustomerTicketsPdf(
  PosOrder order,
  List<PosOrderItem> items, {
  PdfPageFormat? format,
}) async {
  final pageFormat = format ?? PdfPageFormat.roll80;
  final doc = pw.Document();
  final logoImage = await _loadLogoImage();
  final money = AppSettingsService.instance.formatAmount;
  final orderTime = _formatOrderTime(order.createdAt);
  final subtotal = order.originalTotal > 0
      ? order.originalTotal
      : order.totalPrice;
  final discount = order.discountAmount;
  final total = order.totalPrice;
  final payment = order.paymentMethod ?? '-';
  final statusText = '${order.status} / ${order.paymentStatus}';

  // Page 1: kitchen
  doc.addPage(
    pw.Page(
      pageFormat: pageFormat,
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logoImage != null)
              pw.Center(
                child: pw.SizedBox(
                  height: 56,
                  child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                ),
              ),
            if (logoImage != null) pw.SizedBox(height: 8),
            pw.Text(
              'BON CUISINE',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Commande #${order.id}'),
            pw.Text('Heure: $orderTime'),
            pw.Text('Type: ${_fulfillmentLabel(order.fulfillmentType)}'),
            pw.Text('Table: ${order.tableNumber ?? '-'}'),
            pw.Text('Client: ${order.customerName ?? '-'}'),
            pw.Text('Canal: ${order.channel}'),
            pw.Text('Statut: $statusText'),
            pw.Text('Paiement: $payment'),
            if (order.note != null && order.note!.trim().isNotEmpty)
              pw.Text('Note: ${order.note!.trim()}'),
            pw.Divider(),
            ...items.map(
              (it) => pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(
                    width: 32,
                    child: pw.Text(
                      '${it.quantity}x',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Expanded(child: pw.Text(it.productName)),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );

  // Page 2: customer bill
  doc.addPage(
    pw.Page(
      pageFormat: pageFormat,
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logoImage != null)
              pw.Center(
                child: pw.SizedBox(
                  height: 56,
                  child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                ),
              ),
            if (logoImage != null) pw.SizedBox(height: 8),
            pw.Text(
              'ADDITION CLIENT',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Commande #${order.id}'),
            pw.Text('Heure: $orderTime'),
            pw.Text('Type: ${_fulfillmentLabel(order.fulfillmentType)}'),
            pw.Text('Table: ${order.tableNumber ?? '-'}'),
            pw.Text('Client: ${order.customerName ?? '-'}'),
            pw.Text('Canal: ${order.channel}'),
            pw.Text('Statut: $statusText'),
            pw.Text('Paiement: $payment'),
            pw.Divider(),
            ...items.map(
              (it) => pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text('${it.quantity} x ${it.productName}'),
                  ),
                  pw.Text(money(it.unitPrice * it.quantity)),
                ],
              ),
            ),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [pw.Text('Sous-total'), pw.Text(money(subtotal))],
            ),
            if (discount > 0)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [pw.Text('Remise'), pw.Text('-${money(discount)}')],
              ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Total',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  money(total),
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );

  return doc.save();
}

Future<pw.MemoryImage?> _loadLogoImage() async {
  await AppSettingsService.instance.init();
  final settings = AppSettingsService.instance.settings;
  final logoPath = settings.ticketLogoPath;
  if (logoPath == null || logoPath.trim().isEmpty) {
    return null;
  }
  try {
    if (logoPath.startsWith('http://') || logoPath.startsWith('https://')) {
      final response = await http.get(Uri.parse(logoPath));
      if (response.statusCode == 200) {
        return pw.MemoryImage(response.bodyBytes);
      }
      return null;
    }

    final file = File(logoPath);
    if (await file.exists()) {
      return pw.MemoryImage(await file.readAsBytes());
    }
  } catch (_) {}
  return null;
}

String _fulfillmentLabel(String value) {
  switch (value.trim().toLowerCase()) {
    case 'delivery':
      return 'Livraison';
    case 'pickup':
      return 'A emporter';
    case 'on_site':
    default:
      return 'Sur place';
  }
}

String _formatOrderTime(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute';
}
