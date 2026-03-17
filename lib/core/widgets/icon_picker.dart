import 'package:flutter/material.dart';
import '../utils/icon_helper.dart';

/// A bottom sheet widget that displays a searchable grid of all available icons.
class IconPicker extends StatefulWidget {
  final String? initialIcon;

  const IconPicker({super.key, this.initialIcon});

  /// Helper to show the picker as a bottom sheet.
  /// Returns the string name of the selected icon, or null if dismissed.
  static Future<String?> show(BuildContext context, {String? initialIcon}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => IconPicker(initialIcon: initialIcon),
    );
  }

  @override
  State<IconPicker> createState() => _IconPickerState();
}

class _IconPickerState extends State<IconPicker> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<MapEntry<String, IconData>> _filteredIcons = [];

  @override
  void initState() {
    super.initState();
    _filteredIcons = IconHelper.availableIcons.entries.toList();
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredIcons = IconHelper.availableIcons.entries.toList();
      } else {
        _filteredIcons = IconHelper.availableIcons.entries
            .where((entry) => entry.key.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.9, // Takes up 90% of screen height
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Expanded(child: Text('Pick an Icon', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search icons...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty 
                    ? IconButton(icon: const Icon(Icons.clear, size: 20), onPressed: () => _searchCtrl.clear())
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          // Icon Grid
          Expanded(
            child: _filteredIcons.isEmpty
                ? const Center(child: Text('No icons found.'))
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _filteredIcons.length,
                    itemBuilder: (context, index) {
                      final entry = _filteredIcons[index];
                      final isSelected = entry.key == widget.initialIcon;
                      return InkWell(
                        onTap: () => Navigator.pop(context, entry.key),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              entry.value,
                              color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).iconTheme.color,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
