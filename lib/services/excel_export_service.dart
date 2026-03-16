import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';

// ─────────────────────────────────────────────────────────────────────────────
// lib/services/excel_export_service.dart
//
// Reusable Excel export service — used by any screen that needs to export
// data as an Excel file.
//
// Usage:
//
//   // From a custom report API response (has type/from/to/count/data/summary)
//   await ExcelExportService.exportFromApiResponse(
//     raw:       responseMap,
//     fromDate:  _customFromDate,
//     toDate:    _customToDate,
//   );
//
//   // From any list of maps (e.g. wallet history, billing invoices)
//   await ExcelExportService.exportFromList(
//     title:     'Wallet Transaction History',
//     rows:      transactionList.map((t) => t.toMap()).toList(),
//     fromDate:  _fromDate,
//     toDate:    _toDate,
//   );
//
// Both methods:
//   - Auto-generate column headers from row keys (camelCase → Title Case)
//   - Format values by key name (dates, amounts, timestamps, status, nulls)
//   - Write meta header + optional summary block
//   - Save to Downloads (Android) or app documents (iOS)
//   - Open the file with OpenFilex
//   - Return the saved file path
// ─────────────────────────────────────────────────────────────────────────────

class ExcelExportService {
  ExcelExportService._();

  // ── Export from a full API response map ──────────────────────────────────
  // Expects the standard custom report shape:
  // { type, from, to, count, data: [...], summary?: {...} }

  static Future<String> exportFromApiResponse({
    required Map<String, dynamic> raw,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final reportType = raw['type']?.toString() ?? 'Report';
    final fromStr    = raw['from']?.toString() ?? '';
    final toStr      = raw['to']?.toString()   ?? '';
    final count      = (raw['count'] as num?)?.toInt() ?? 0;
    final rows       = (raw['data'] as List).cast<Map<String, dynamic>>();
    final summary    = raw['summary'] is Map
        ? raw['summary'] as Map<String, dynamic>
        : null;

    return _buildAndSave(
      reportType: reportType,
      fromStr:    fromStr,
      toStr:      toStr,
      count:      count,
      rows:       rows,
      summary:    summary,
      fromDate:   fromDate,
      toDate:     toDate,
    );
  }

  // ── Export from any list of maps ──────────────────────────────────────────
  // Use this when you already have parsed model objects —
  // just convert them to Map<String, dynamic> first.

  static Future<String> exportFromList({
    required String title,
    required List<Map<String, dynamic>> rows,
    required DateTime fromDate,
    required DateTime toDate,
    Map<String, dynamic>? summary,
  }) async {
    return _buildAndSave(
      reportType: title,
      fromStr:    fromDate.toIso8601String(),
      toStr:      toDate.toIso8601String(),
      count:      rows.length,
      rows:       rows,
      summary:    summary,
      fromDate:   fromDate,
      toDate:     toDate,
    );
  }

  // ── Core builder ──────────────────────────────────────────────────────────

  static Future<String> _buildAndSave({
    required String reportType,
    required String fromStr,
    required String toStr,
    required int    count,
    required List<Map<String, dynamic>> rows,
    required DateTime fromDate,
    required DateTime toDate,
    Map<String, dynamic>? summary,
  }) async {
    final excel = Excel.createExcel();
    excel.rename('Sheet1', 'Report');
    final sheet = excel['Report'];

    // ── Meta header (rows 0–3) ──────────────────────────────────────────────
    _writeCell(sheet, 0, 0, reportType,
        CellStyle(bold: true, fontSize: 14,
            fontColorHex: ExcelColor.fromHexString('#23262D')));

    _writeCell(sheet, 1, 0,
        'Period: ${_fmtDateStr(fromStr)}  →  ${_fmtDateStr(toStr)}',
        CellStyle(fontSize: 10, italic: true));

    _writeCell(sheet, 2, 0, 'Total records: $count',
        CellStyle(fontSize: 10));

    _writeCell(sheet, 3, 0, 'Generated: ${_fmtDate(DateTime.now())}',
        CellStyle(fontSize: 10, italic: true));

    // ── Summary row (row 4) ─────────────────────────────────────────────────
    if (summary != null && summary.isNotEmpty) {
      final parts = summary.entries
          .map((e) => '${humanKey(e.key)}: ${formatValue(e.key, e.value)}')
          .join('   |   ');
      _writeCell(sheet, 4, 0, parts,
          CellStyle(fontSize: 10, italic: true,
              fontColorHex: ExcelColor.fromHexString('#555555')));
    }

    // ── Empty data — throw so the caller can show a proper message ───────────
    if (rows.isEmpty) {
      throw ExcelExportException('No data available for the selected period.');
    }

    // ── Column headers from first row keys (row 5) ──────────────────────────
    final keys    = rows.first.keys.toList();
    final headers = keys.map(humanKey).toList();

    for (int c = 0; c < headers.length; c++) {
      _writeCell(sheet, 5, c, headers[c],
          CellStyle(
            bold:               true,
            fontSize:           11,
            fontColorHex:       ExcelColor.fromHexString('#FFFFFF'),
            backgroundColorHex: ExcelColor.fromHexString('#23262D'),
            horizontalAlign:    HorizontalAlign.Center,
          ));
    }

    // ── Data rows (starting row 6) ──────────────────────────────────────────
    for (int r = 0; r < rows.length; r++) {
      final row = rows[r];
      final bg  = r % 2 == 0
          ? ExcelColor.fromHexString('#FFFFFF')
          : ExcelColor.fromHexString('#F7F8FA');

      for (int c = 0; c < keys.length; c++) {
        _writeCell(sheet, 6 + r, c, formatValue(keys[c], row[keys[c]]),
            CellStyle(fontSize: 10, backgroundColorHex: bg));
      }
    }

    // ── Column widths ───────────────────────────────────────────────────────
    for (int c = 0; c < keys.length; c++) {
      sheet.setColumnWidth(c, _colWidth(keys[c]));
    }

    final path = await _save(excel, reportType, fromDate, toDate);
    await _open(path);
    return path;
  }

  // ── Save to disk ──────────────────────────────────────────────────────────

  static Future<String> _save(
      Excel excel, String reportType, DateTime from, DateTime to) async {
    final dir  = await _resolveDir();
    final slug = reportType
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+$'), '');
    final file = File(
        '${dir.path}/filter_${slug}_${_fmtDate(from)}_to_${_fmtDate(to)}.xlsx');
    await file.writeAsBytes(excel.encode()!, flush: true);
    debugPrint('[ExcelExportService] saved → ${file.path}');
    return file.path;
  }

  // ── Open with system viewer — non-fatal ───────────────────────────────────

  static Future<void> _open(String path) async {
    try {
      await OpenFilex.open(path);
    } catch (e) {
      debugPrint('[ExcelExportService] OpenFilex unavailable (file saved): $e');
    }
  }

  // ── Resolve save directory ────────────────────────────────────────────────

  static Future<Directory> _resolveDir() async {
    if (Platform.isAndroid) {
      final dl = Directory('/storage/emulated/0/Download');
      if (await dl.exists()) return dl;
    }
    return getApplicationDocumentsDirectory();
  }

  // ── Format a single cell value by key name ────────────────────────────────

  static String formatValue(String key, dynamic value) {
    if (value == null) return '—';

    final k = key.toLowerCase();

    // Epoch timestamp → readable date
    if (k == 'timestamp' && value is num) {
      try {
        return _fmtDate(DateTime.fromMillisecondsSinceEpoch(value.toInt()));
      } catch (_) {}
    }

    // Date strings
    if ((k.contains('date') || k == 'from' || k == 'to') && value is String) {
      return _fmtDateStr(value);
    }

    // Money fields → 2 decimal places
    if (k.contains('amount') || k.contains('spent') ||
        k.contains('total')  || k == 'price' || k.contains('balance') ||
        k.contains('saving')) {
      if (value is num) return value.toStringAsFixed(2);
      final parsed = double.tryParse(value.toString());
      if (parsed != null) return parsed.toStringAsFixed(2);
    }

    // Status / type → Title Case
    if (k == 'status' || k == 'type') {
      return _titleCase(value.toString());
    }

    // Nested map — flatten values
    if (value is Map) {
      return value.values
          .where((v) => v != null)
          .map((v) => v.toString())
          .join(' ');
    }

    // List — join with comma
    if (value is List) {
      return value.map((v) => v?.toString() ?? '').join(', ');
    }

    return value.toString();
  }

  // ── camelCase / snake_case → Title Case header ────────────────────────────

  static String humanKey(String key) {
    var s = key.replaceAll('_', ' ');
    s = s.replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}');
    return s
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  // ── Column width by key name ──────────────────────────────────────────────

  static double _colWidth(String key) {
    final k = key.toLowerCase();
    if (k.contains('description') || k.contains('name') ||
        k.contains('model'))        return 28;
    if (k.contains('date') || k == 'timestamp') return 16;
    if (k.contains('amount') || k.contains('spent') ||
        k.contains('total'))        return 16;
    if (k == 'status' || k == 'type') return 14;
    if (k == 'id')                  return 12;
    return 18;
  }

  // ── Write a single styled cell ────────────────────────────────────────────

  static void _writeCell(
      Sheet sheet, int row, int col, String value, CellStyle style) {
    final idx = CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row);
    sheet.cell(idx).value     = TextCellValue(value);
    sheet.cell(idx).cellStyle = style;
  }

  // ── Date helpers ──────────────────────────────────────────────────────────

  static String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _fmtDateStr(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try { return _fmtDate(DateTime.parse(raw)); } catch (_) { return raw; }
  }

  static String _titleCase(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ─────────────────────────────────────────────────────────────────────────────
// Typed exception — callers catch this to show user-facing messages
// ─────────────────────────────────────────────────────────────────────────────

class ExcelExportException implements Exception {
  final String message;
  const ExcelExportException(this.message);

  @override
  String toString() => 'ExcelExportException: $message';
}