import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../company_settings/presentation/cubit/company_settings_cubit.dart';
import '../../data/repositories/credit_note_repository.dart';
import '../../domain/models/credit_note_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreditNoteDetailPage extends StatefulWidget {
  const CreditNoteDetailPage({
    required this.creditNoteId,
    required this.repository,
    required this.clientPhone,
    required this.orderNumber,
    super.key,
  });

  final String creditNoteId;
  final CreditNoteRepository repository;
  final String? clientPhone;
  final int orderNumber;

  @override
  State<CreditNoteDetailPage> createState() => _CreditNoteDetailPageState();
}

class _CreditNoteDetailPageState extends State<CreditNoteDetailPage> {
  late Future<CreditNoteModel> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.getById(widget.creditNoteId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle nota de crédito')),
      body: FutureBuilder<CreditNoteModel>(
        future: _future,
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No se pudo cargar la nota de crédito.'));
          }
          final note = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(14),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nota #${note.number}', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 6),
                      Text('Cliente: ${note.clientName}'),
                      Text('Pedido asociado: #${widget.orderNumber}'),
                      Text('Fecha: ${note.createdAt?.toLocal().toString().split('.').first ?? '-'}'),
                      Text('Motivo: ${note.reason}'),
                      Text('Total: ${note.totalAmount.toStringAsFixed(2)}'),
                      if ((note.notes ?? '').isNotEmpty) Text('Notas: ${note.notes}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => _showPdf(note),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Ver PDF'),
                  ),
                  FilledButton.icon(
                    onPressed: () => _sendPdfByWhatsApp(note),
                    icon: const Icon(Icons.send_to_mobile_outlined),
                    label: const Text('Enviar por WhatsApp'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      for (final item in note.items)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.productNameSnapshot),
                          subtitle: Text('Cant: ${item.quantity.toStringAsFixed(2)} · Unit: ${item.unitPrice.toStringAsFixed(2)}'),
                          trailing: Text(item.subtotal.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showPdf(CreditNoteModel note) async {
    final doc = await _buildPdf(note);
    await Printing.layoutPdf(onLayout: (_) => doc.save(), name: 'nota_credito_${note.number}.pdf');
  }

  Future<pw.Document> _buildPdf(CreditNoteModel note) async {
    final settings = context.read<CompanySettingsCubit>().state.settings;
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(margin: pw.EdgeInsets.all(24)),
        build: (_) => [
          pw.Text('Nota de Crédito #${note.number}', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Text('Empresa: ${settings.companyName}'),
          pw.Text('CUIT: ${settings.taxId ?? '-'}'),
          pw.Text('Dirección: ${settings.address ?? '-'} ${settings.city ?? ''} ${settings.province ?? ''}'.trim()),
          pw.Text('Tel: ${settings.phone ?? '-'} · Email: ${settings.email ?? '-'}'),
          pw.Divider(),
          pw.Text('Cliente: ${note.clientName}'),
          pw.Text('Pedido asociado: #${widget.orderNumber}'),
          pw.Text('Motivo: ${note.reason}'),
          pw.Text('Fecha: ${note.createdAt?.toLocal().toString().split('.').first ?? '-'}'),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headers: const ['Producto / Variante', 'Cant', 'Precio Unit.', 'Subtotal'],
            data: note.items
                .map((i) => [
                      i.productNameSnapshot,
                      i.quantity.toStringAsFixed(2),
                      i.unitPrice.toStringAsFixed(2),
                      i.subtotal.toStringAsFixed(2),
                    ])
                .toList(),
          ),
          pw.SizedBox(height: 12),
          pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('TOTAL NOTA DE CRÉDITO: ${note.totalAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
        ],
      ),
    );
    return doc;
  }

  Future<void> _sendPdfByWhatsApp(CreditNoteModel note) async {
    final cleaned = _cleanPhone(widget.clientPhone);
    if (cleaned == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El cliente no tiene teléfono/WhatsApp configurado.')));
      return;
    }

    final whatsappPhone = cleaned.startsWith('549') ? cleaned : '549$cleaned';
    final message = 'Hola, te enviamos la nota de crédito #${note.number} del pedido #${widget.orderNumber}';

    try {
      final doc = await _buildPdf(note);
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/nota_credito_${note.number}.pdf';
      final file = File(path);
      await file.writeAsBytes(await doc.save(), flush: true);

      final url = Uri.parse('https://wa.me/$whatsappPhone?text=${Uri.encodeComponent(message)}');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }

      await Share.shareXFiles([XFile(path)], text: message, subject: 'Nota de crédito #${note.number}');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo compartir la nota de crédito.')));
    }
  }

  String? _cleanPhone(String? raw) {
    final digits = (raw ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8) return null;
    return digits;
  }
}
