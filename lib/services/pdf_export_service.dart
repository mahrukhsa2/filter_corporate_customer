import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_filex/open_filex.dart';

// ─────────────────────────────────────────────────────────────────────────────
// lib/services/pdf_export_service.dart
//
// Reusable PDF export service.
// Required packages (add to pubspec.yaml if not present):
//   pdf: ^3.11.0
//   printing: ^5.12.0   (optional — for print/share dialog)
//   open_filex: ^4.3.4
//   path_provider: ^2.1.2
//
// Usage:
//
//   await PdfExportService.exportFromList(
//     title:    'Monthly Billing – March 2026',
//     subtitle: 'Due: 15 Apr 2026  |  Total: SAR 4,500',
//     rows:     invoices.map((i) => i.toExcelMap()).toList(),
//     fromDate: DateTime(2026, 3, 1),
//     toDate:   DateTime(2026, 3, 31),
//     summary:  {'Total Billed': 'SAR 4,500', 'Paid': 'SAR 2,000', ...},
//   );
// ─────────────────────────────────────────────────────────────────────────────

class PdfExportService {
  PdfExportService._();

  // Brand colours (mirror AppColors)
  static const _darkBg    = PdfColor.fromInt(0xFF23262D);
  static const _accent    = PdfColor.fromInt(0xFFFCC247);
  static const _rowAlt    = PdfColor.fromInt(0xFFF7F8FA);
  static const _textDark  = PdfColor.fromInt(0xFF23262D);
  static const _textGrey  = PdfColor.fromInt(0xFF888888);
  static const _white     = PdfColors.white;

  // ── Public API ────────────────────────────────────────────────────────────

  static Future<String> exportFromList({
    required String  title,
    required List<Map<String, dynamic>> rows,
    required DateTime fromDate,
    required DateTime toDate,
    String?  subtitle,
    Map<String, dynamic>? summary,
  }) async {
    final doc = pw.Document();

    // Load font once
    pw.Font? font;
    try {
      final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      font = pw.Font.ttf(fontData);
    } catch (_) {
      // Fallback to built-in font if asset not found
    }

    final baseStyle = pw.TextStyle(
      font:     font,
      fontSize: 9,
      color:    _textDark,
    );

    final keys    = rows.isNotEmpty ? rows.first.keys.toList() : <String>[];
    final headers = keys.map(_humanKey).toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (ctx) => _buildHeader(title, subtitle, fromDate, toDate, font),
        footer: (ctx) => _buildFooter(ctx, font),
        build: (ctx) => [
          // ── Summary block ─────────────────────────────────────────────
          if (summary != null && summary.isNotEmpty) ...[
            _buildSummaryBlock(summary, baseStyle),
            pw.SizedBox(height: 14),
          ],

          // ── Table ─────────────────────────────────────────────────────
          if (rows.isEmpty)
            pw.Center(
              child: pw.Text('No data available for the selected period.',
                  style: baseStyle.copyWith(color: _textGrey, fontSize: 11)),
            )
          else
            _buildTable(headers, keys, rows, baseStyle),
        ],
      ),
    );

    return _save(doc, title, fromDate, toDate);
  }

  // ── Header ────────────────────────────────────────────────────────────────

  static pw.Widget _buildHeader(
      String title, String? subtitle, DateTime from, DateTime to, pw.Font? font) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
            bottom: pw.BorderSide(color: _accent, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(title,
                  style: pw.TextStyle(
                    font:      font,
                    fontSize:  14,
                    fontWeight: pw.FontWeight.bold,
                    color:     _textDark,
                  )),
              if (subtitle != null)
                pw.Text(subtitle,
                    style: pw.TextStyle(
                        font: font, fontSize: 9, color: _textGrey)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Period: ${_fmt(from)}  →  ${_fmt(to)}',
                style: pw.TextStyle(font: font, fontSize: 9, color: _textGrey),
              ),
              pw.Text(
                'Generated: ${_fmt(DateTime.now())}',
                style: pw.TextStyle(font: font, fontSize: 9, color: _textGrey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────

  static pw.Widget _buildFooter(pw.Context ctx, pw.Font? font) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
          border: pw.Border(
              top: pw.BorderSide(color: _rowAlt, width: 1))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Filter AutoServices — Confidential',
              style: pw.TextStyle(font: font, fontSize: 8, color: _textGrey)),
          pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style: pw.TextStyle(font: font, fontSize: 8, color: _textGrey)),
        ],
      ),
    );
  }

  // ── Summary block ─────────────────────────────────────────────────────────

  static pw.Widget _buildSummaryBlock(
      Map<String, dynamic> summary, pw.TextStyle base) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _rowAlt,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Wrap(
        spacing: 24,
        runSpacing: 6,
        children: summary.entries.map((e) {
          return pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text('${_humanKey(e.key)}: ',
                  style: base.copyWith(
                      fontWeight: pw.FontWeight.bold, fontSize: 9)),
              pw.Text(_formatValue(e.key, e.value),
                  style: base.copyWith(fontSize: 9)),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── Table ─────────────────────────────────────────────────────────────────

  static pw.Widget _buildTable(
      List<String> headers,
      List<String> keys,
      List<Map<String, dynamic>> rows,
      pw.TextStyle base) {
    final colWidths = {
      for (int i = 0; i < keys.length; i++)
        i: pw.FlexColumnWidth(_colFlex(keys[i]))
    };

    return pw.Table(
      columnWidths: colWidths,
      border: pw.TableBorder(
        horizontalInside: pw.BorderSide(color: _rowAlt, width: 0.5),
      ),
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _darkBg),
          children: headers.map((h) => pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
            child: pw.Text(h,
                style: base.copyWith(
                    color: _white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 8)),
          )).toList(),
        ),
        // Data rows
        ...rows.asMap().entries.map((entry) {
          final i   = entry.key;
          final row = entry.value;
          final bg  = i % 2 == 0 ? _white : _rowAlt;
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: bg),
            children: keys.map((k) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 6, vertical: 5),
              child: pw.Text(
                _formatValue(k, row[k]),
                style: base.copyWith(fontSize: 8),
              ),
            )).toList(),
          );
        }),
      ],
    );
  }

  // ── Save & open ───────────────────────────────────────────────────────────

  static Future<String> _save(
      pw.Document doc, String title, DateTime from, DateTime to) async {
    final dir  = await _resolveDir();
    final slug = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+$'), '');
    final file = File(
        '${dir.path}/filter_${slug}_${_fmt(from)}_to_${_fmt(to)}.pdf');
    await file.writeAsBytes(await doc.save());
    debugPrint('[PdfExportService] saved → ${file.path}');

    try {
      await OpenFilex.open(file.path);
    } catch (e) {
      debugPrint('[PdfExportService] OpenFilex unavailable: $e');
    }

    return file.path;
  }

  static Future<Directory> _resolveDir() async {
    if (Platform.isAndroid) {
      final dl = Directory('/storage/emulated/0/Download');
      if (await dl.exists()) return dl;
    }
    return getApplicationDocumentsDirectory();
  }

  // ── Shared formatting helpers (mirrors ExcelExportService) ────────────────

  static String _formatValue(String key, dynamic value) {
    if (value == null) return '—';
    final k = key.toLowerCase();

    if (k == 'timestamp' && value is num) {
      try {
        return _fmt(DateTime.fromMillisecondsSinceEpoch(value.toInt()));
      } catch (_) {}
    }
    if ((k.contains('date') || k == 'from' || k == 'to') && value is String) {
      return _fmtStr(value);
    }
    if (k.contains('amount') || k.contains('spent') || k.contains('total') ||
        k == 'price' || k.contains('balance') || k.contains('saving')) {
      if (value is num) return 'SAR ${value.toStringAsFixed(2)}';
      final p = double.tryParse(value.toString());
      if (p != null) return 'SAR ${p.toStringAsFixed(2)}';
    }
    if (k == 'status' || k == 'type') {
      return _titleCase(value.toString());
    }
    if (value is Map)  return value.values.where((v) => v != null).map((v) => v.toString()).join(' ');
    if (value is List) return value.map((v) => v?.toString() ?? '').join(', ');
    return value.toString();
  }

  static String _humanKey(String key) {
    var s = key.replaceAll('_', ' ');
    s = s.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}');
    return s.split(' ').where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
  }

  static double _colFlex(String key) {
    final k = key.toLowerCase();
    if (k.contains('description') || k.contains('name')) return 2.5;
    if (k.contains('amount') || k.contains('total'))     return 1.5;
    if (k.contains('date'))                              return 1.2;
    if (k == 'id' || k == 'status' || k == 'type')      return 1.0;
    return 1.4;
  }

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _fmtStr(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try { return _fmt(DateTime.parse(raw)); } catch (_) { return raw; }
  }

  static String _titleCase(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ─────────────────────────────────────────────────────────────────────────────
// Typed exception — mirrors ExcelExportException
// ─────────────────────────────────────────────────────────────────────────────

class PdfExportException implements Exception {
  final String message;
  const PdfExportException(this.message);

  @override
  String toString() => 'PdfExportException: $message';
}