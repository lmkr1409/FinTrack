import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/export_import_service.dart';

// Provides the ExportImportService instance
final exportImportServiceProvider = Provider((ref) {
  return ExportImportService();
});

// Provides the state for the export/import process loading indicator
final exportImportLoadingProvider = StateProvider<bool>((ref) => false);

// Provides the state for the result message 
final exportImportMessageProvider = StateProvider<String?>((ref) => null);
