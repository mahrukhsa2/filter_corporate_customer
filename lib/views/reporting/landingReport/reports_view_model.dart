import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import '../../../services/excel_export_service.dart';

import '../../../data/network/api_response.dart';
import '../../../data/repositories/reports_repository.dart';
import '../../../models/reports_model.dart';
import '../../../widgets/app_alert.dart';

enum ReportsLoadStatus { idle, loading, loaded, error }
enum ExportStatus      { idle, exporting, done, error }

class ReportsViewModel extends ChangeNotifier {

  ReportsLoadStatus _loadStatus   = ReportsLoadStatus.idle;
  ExportStatus      _exportStatus = ExportStatus.idle;

  ReportsSummary? _summary;

  DateTime?      _customFromDate;
  DateTime?      _customToDate;
  ReportCategory _customCategory     = ReportCategory.monthlyBilling;
  bool           _isGeneratingCustom = false;
  String?        _customError;

  final List<ReportCategory> categories = ReportCategory.values;

  ReportsLoadStatus get loadStatus        => _loadStatus;
  ExportStatus      get exportStatus      => _exportStatus;
  ReportsSummary?   get summary           => _summary;
  bool get isLoading          => _loadStatus  == ReportsLoadStatus.loading;
  bool get isExporting        => _exportStatus == ExportStatus.exporting;
  bool get isGeneratingCustom => _isGeneratingCustom;
  String? get customError     => _customError;

  DateTime?      get customFromDate  => _customFromDate;
  DateTime?      get customToDate    => _customToDate;
  ReportCategory get customCategory  => _customCategory;

  bool get canGenerateCustom =>
      _customFromDate != null && _customToDate != null;

  ReportsViewModel() {
    debugPrint('[ReportsViewModel] created');
    _load();
  }

  Future<void> _load({BuildContext? context}) async {
    debugPrint('[ReportsViewModel] _load START');
    _loadStatus = ReportsLoadStatus.loading;
    notifyListeners();

    final result = await ReportsRepository.fetchSummary();

    if (result.success && result.data != null) {
      _summary    = result.data;
      _loadStatus = ReportsLoadStatus.loaded;
      debugPrint('[ReportsViewModel] _load SUCCESS: '
          'totalSpentThisYear=${_summary!.totalSpentThisYear}');
    } else {
      debugPrint('[ReportsViewModel] _load FAILED: '
          'errorType=${result.errorType} msg=${result.message}');

      _loadStatus = _summary != null
          ? ReportsLoadStatus.loaded
          : ReportsLoadStatus.error;

      if (context != null && context.mounted) {
        await AppAlert.apiError(
          context,
          errorType: result.errorType,
          message:   result.message,
          onRetry: result.errorType == ApiErrorType.noInternet ||
              result.errorType == ApiErrorType.timeout
              ? () => _load(context: context)
              : null,
        );
      }
    }

    notifyListeners();
    debugPrint('[ReportsViewModel] _load END status=$_loadStatus');
  }

  Future<void> refresh({BuildContext? context}) {
    debugPrint('[ReportsViewModel] refresh');
    return _load(context: context);
  }

  void setCustomFromDate(DateTime date) {
    _customFromDate = date;
    _customError    = null;
    notifyListeners();
  }

  void setCustomToDate(DateTime date) {
    _customToDate = date;
    _customError  = null;
    notifyListeners();
  }

  void setCustomCategory(ReportCategory cat) {
    _customCategory = cat;
    _customError    = null;
    notifyListeners();
  }

  Future<void> generateCustomReport({BuildContext? context}) async {
    if (!canGenerateCustom) return;

    _isGeneratingCustom = true;
    _customError        = null;
    notifyListeners();

    debugPrint('[ReportsViewModel] generateCustomReport '
        'from=$_customFromDate to=$_customToDate type=${_customCategory.apiType}');

    final res = await ReportsRepository.fetchCustomReport(
      fromDate: _customFromDate!,
      toDate:   _customToDate!,
      type:     _customCategory.apiType,
    );

    if (!res.success || res.data == null) {
      _isGeneratingCustom = false;
      _customError        = res.message ?? 'Failed to generate report.';
      notifyListeners();
      return;
    }

    final rawData  = res.data!;
    final dataList = rawData['data'];
    if (dataList is! List || (dataList as List).isEmpty) {
      _isGeneratingCustom = false;
      _customError        = 'No data found for the selected period.';
      notifyListeners();
      return;
    }

    String? filePath;
    try {
      filePath = await _buildAndSaveExcel(rawData);
      debugPrint('[ReportsViewModel] Excel saved → $filePath');
    } catch (e, stack) {
      debugPrint('[ReportsViewModel] Excel build error: $e\n$stack');
      _isGeneratingCustom = false;
      _customError        = 'Failed to build Excel file.';
      notifyListeners();
      return;
    }

    _isGeneratingCustom = false;
    notifyListeners();

    // Try to open — if the plugin isn't registered just log; the file is saved.
    try {
      await OpenFilex.open(filePath!);
    } catch (e) {
      debugPrint('[ReportsViewModel] OpenFilex unavailable (file still saved): $e');
    }
  }

  Future<String> _buildAndSaveExcel(Map<String, dynamic> raw) async {
    return ExcelExportService.exportFromApiResponse(
      raw:      raw,
      fromDate: _customFromDate!,
      toDate:   _customToDate!,
    );
  }

  Future<void> exportAll(String format) async {
    debugPrint('[ReportsViewModel] exportAll format=$format');
    _exportStatus = ExportStatus.exporting;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 1200));
    _exportStatus = ExportStatus.done;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 2));
    _exportStatus = ExportStatus.idle;
    notifyListeners();
  }
}