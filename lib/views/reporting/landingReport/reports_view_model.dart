import 'package:flutter/material.dart';

import '../../../models/reports_model.dart';

enum ReportsLoadStatus { idle, loading, loaded, error }
enum ExportStatus { idle, exporting, done, error }

class ReportsViewModel extends ChangeNotifier {
  // ── State ─────────────────────────────────────────────────────────────────
  ReportsLoadStatus _loadStatus = ReportsLoadStatus.idle;
  ExportStatus _exportStatus    = ExportStatus.idle;

  ReportsSummary? _summary;

  // ── Custom report form state ───────────────────────────────────────────────
  DateTime? _customFromDate;
  DateTime? _customToDate;
  ReportCategory _customCategory = ReportCategory.monthlyBilling;
  bool _isGeneratingCustom = false;

  // ── All report categories (fixed list) ────────────────────────────────────
  final List<ReportCategory> categories = ReportCategory.values;

  // ── Getters ───────────────────────────────────────────────────────────────
  ReportsLoadStatus get loadStatus   => _loadStatus;
  ExportStatus      get exportStatus => _exportStatus;
  ReportsSummary?   get summary      => _summary;
  bool get isLoading          => _loadStatus == ReportsLoadStatus.loading;
  bool get isExporting        => _exportStatus == ExportStatus.exporting;
  bool get isGeneratingCustom => _isGeneratingCustom;

  DateTime? get customFromDate  => _customFromDate;
  DateTime? get customToDate    => _customToDate;
  ReportCategory get customCategory => _customCategory;

  bool get canGenerateCustom =>
      _customFromDate != null && _customToDate != null;

  ReportsViewModel() {
    _load();
  }

  // ── Load summary ──────────────────────────────────────────────────────────
  Future<void> _load() async {
    _loadStatus = ReportsLoadStatus.loading;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 700));

    // ── Dummy data – replace with real API call when ready ─────────────────
    _summary = const ReportsSummary(
      totalSpentThisYear:  128500,
      thisMonthAmount:     45200,
      thisMonthInvoices:   12,
      totalSavings:        18750,
      savingsPercent:      14.6,
      walletUsed:          32100,
      walletUsedPercent:   25,
    );

    _loadStatus = ReportsLoadStatus.loaded;
    notifyListeners();
  }

  Future<void> refresh() => _load();

  // ── Custom report form ────────────────────────────────────────────────────
  void setCustomFromDate(DateTime date) {
    _customFromDate = date;
    notifyListeners();
  }

  void setCustomToDate(DateTime date) {
    _customToDate = date;
    notifyListeners();
  }

  void setCustomCategory(ReportCategory cat) {
    _customCategory = cat;
    notifyListeners();
  }

  Future<void> generateCustomReport() async {
    if (!canGenerateCustom) return;
    _isGeneratingCustom = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1100));

    // TODO: call real report generation API
    // final request = CustomReportRequest(
    //   fromDate: _customFromDate!,
    //   toDate: _customToDate!,
    //   category: _customCategory,
    // );

    _isGeneratingCustom = false;
    notifyListeners();
  }

  // ── Export all ────────────────────────────────────────────────────────────
  Future<void> exportAll(String format) async {
    _exportStatus = ExportStatus.exporting;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1200));

    // TODO: call real export API (PDF / Excel)
    _exportStatus = ExportStatus.done;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));
    _exportStatus = ExportStatus.idle;
    notifyListeners();
  }
}
