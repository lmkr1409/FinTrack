import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/glass_card.dart';
import '../providers/export_import_providers.dart';

class ExportImportScreen extends ConsumerStatefulWidget {
  const ExportImportScreen({super.key});

  @override
  ConsumerState<ExportImportScreen> createState() => _ExportImportScreenState();
}

class _ExportImportScreenState extends ConsumerState<ExportImportScreen> {
  bool _exportConfig = true;
  bool _exportTransactions = true;
  
  bool _importConfig = true;
  bool _importTransactions = true;

  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _handleExport() async {
    if (!_exportConfig && !_exportTransactions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one option to export.')),
      );
      return;
    }

    ref.read(exportImportLoadingProvider.notifier).state = true;
    try {
      final service = ref.read(exportImportServiceProvider);
      final path = await service.exportData(
        exportConfig: _exportConfig,
        exportTransactions: _exportTransactions,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (mounted) {
        if (path != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Export successful! \nStored at: $path'), duration: const Duration(seconds: 5)),
          );
        } else {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Export Canceled.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export Failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      ref.read(exportImportLoadingProvider.notifier).state = false;
    }
  }

  Future<void> _handleDownloadDatabase() async {
    ref.read(exportImportLoadingProvider.notifier).state = true;
    try {
      final service = ref.read(exportImportServiceProvider);
      final path = await service.downloadDatabase();
      if (mounted && path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Database saved to $path')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download database: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      ref.read(exportImportLoadingProvider.notifier).state = false;
    }
  }

  Future<void> _handleImport() async {
    if (!_importConfig && !_importTransactions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one option to import.')),
      );
      return;
    }

    // Confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Import'),
        content: const Text(
            'Importing data will add new records to your database. Existing configuration items with the same name will be mapped. It is recommended to import into an empty or clean database to prevent unexpected behavior. \n\nContinue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Import')),
        ],
      ),
    );

    if (confirm != true) return;

    ref.read(exportImportLoadingProvider.notifier).state = true;
    try {
      final service = ref.read(exportImportServiceProvider);
      await service.importData(
        importConfig: _importConfig,
        importTransactions: _importTransactions,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Import Successful! Restart the app to see all changes.')),
        );
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import Failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
       ref.read(exportImportLoadingProvider.notifier).state = false;
    }
  }

  Future<void> _pickDateRange() async {
     final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    if(picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(exportImportLoadingProvider);

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Backup & Restore',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Export Section
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.upload_file, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text('Export Data', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('Save your data securely into a JSON backup file.', style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 16),
                        
                        // Filters
                        CheckboxListTile(
                          title: const Text('Include Configuration (Accounts, Cards, Categories, Budgets, Rules)'),
                          value: _exportConfig,
                          activeColor: AppColors.primary,
                          onChanged: (val) => setState(() => _exportConfig = val ?? false),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                        CheckboxListTile(
                          title: const Text('Include Transactions'),
                          value: _exportTransactions,
                           activeColor: AppColors.primary,
                          onChanged: (val) => setState(() => _exportTransactions = val ?? false),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                        
                        if (_exportTransactions) ...[
                          const SizedBox(height: 8),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Date Range'),
                            subtitle: Text(_startDate != null && _endDate != null 
                              ? '${DateFormat('MMM dd, yyyy').format(_startDate!)} - ${DateFormat('MMM dd, yyyy').format(_endDate!)}' 
                              : 'All Dates', style: const TextStyle(color: AppColors.primary)),
                            trailing: IconButton(
                              icon: const Icon(Icons.date_range, color: Colors.white70),
                              onPressed: _pickDateRange,
                            ),
                            onTap: _pickDateRange,
                          ),
                          if (_startDate != null)
                             TextButton(
                                onPressed: () => setState(() { _startDate = null; _endDate = null; }),
                                child: const Text('Clear Date Filter')
                             )
                        ],

                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: isLoading ? null : _handleExport,
                            icon: const Icon(Icons.save_alt),
                            label: const Text('Export JSON Backup'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        if (kDebugMode) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: isLoading ? null : _handleDownloadDatabase,
                              icon: const Icon(Icons.file_download, color: Colors.white),
                              label: const Text('Download Raw Database (.db)', style: TextStyle(color: Colors.white)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: const BorderSide(color: AppColors.primary, width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Import Section
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.download, color: AppColors.secondary),
                            SizedBox(width: 8),
                            Text('Import Data', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('Restore your data from a previously saved JSON backup file.', style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 16),
                        
                         CheckboxListTile(
                          title: const Text('Import Configuration'),
                          value: _importConfig,
                          activeColor: AppColors.secondary,
                          onChanged: (val) => setState(() => _importConfig = val ?? false),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                        CheckboxListTile(
                          title: const Text('Import Transactions'),
                          value: _importTransactions,
                           activeColor: AppColors.secondary,
                          onChanged: (val) => setState(() => _importTransactions = val ?? false),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),

                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: isLoading ? null : _handleImport,
                            icon: const Icon(Icons.file_open),
                            label: const Text('Select File & Import'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: AppColors.secondary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}
