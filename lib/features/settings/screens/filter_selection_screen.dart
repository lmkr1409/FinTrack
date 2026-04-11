import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/color_helper.dart';
import '../../../core/utils/icon_helper.dart';
import '../../../models/category.dart';
import '../../../models/sub_category.dart';
import '../../../models/widget_filter.dart';
import '../../../services/providers.dart';
import '../../../widgets/glass_card.dart';

class FilterSelectionScreen extends ConsumerStatefulWidget {
  final String widgetKey;
  final String widgetName;

  const FilterSelectionScreen({
    super.key,
    required this.widgetKey,
    required this.widgetName,
  });

  @override
  ConsumerState<FilterSelectionScreen> createState() => _FilterSelectionScreenState();
}

class _FilterSelectionScreenState extends ConsumerState<FilterSelectionScreen> {
  bool _loading = true;
  List<Category> _categories = [];
  Map<int, List<SubCategory>> _subCategories = {};
  Set<int> _excludedCategories = {};
  Set<int> _excludedSubcats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final catRepo = ref.read(categoryRepositoryProvider);
    final subRepo = ref.read(subCategoryRepositoryProvider);
    final filterRepo = ref.read(widgetFilterRepositoryProvider);

    final cats = await catRepo.getAllSorted();
    final filters = await filterRepo.getFiltersForWidget(widget.widgetKey);

    final subMap = <int, List<SubCategory>>{};
    for (final cat in cats) {
      subMap[cat.id!] = await subRepo.getByCategoryId(cat.id!);
    }

    final exclCats = filters
        .where((f) => f.filterType == 'EXCLUDE' && f.targetType == 'CATEGORY')
        .map((f) => f.targetId)
        .toSet();
    final exclSubs = filters
        .where((f) => f.filterType == 'EXCLUDE' && f.targetType == 'SUBCATEGORY')
        .map((f) => f.targetId)
        .toSet();

    if (mounted) {
      setState(() {
        _categories = cats;
        _subCategories = subMap;
        _excludedCategories = exclCats;
        _excludedSubcats = exclSubs;
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final filterRepo = ref.read(widgetFilterRepositoryProvider);
    final filters = <WidgetFilter>[];

    for (final id in _excludedCategories) {
      filters.add(WidgetFilter(
        widgetKey: widget.widgetKey,
        targetId: id,
        targetType: 'CATEGORY',
        filterType: 'EXCLUDE',
      ));
    }
    for (final id in _excludedSubcats) {
      filters.add(WidgetFilter(
        widgetKey: widget.widgetKey,
        targetId: id,
        targetType: 'SUBCATEGORY',
        filterType: 'EXCLUDE',
      ));
    }

    await filterRepo.setFilters(widget.widgetKey, filters);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.widgetName} Filters'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded),
            onPressed: _save,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSection(
                  'Transactions',
                  Icons.swap_horiz_rounded,
                  _categories.where((c) => c.categoryType.toUpperCase() == 'TRANSACTIONS').toList(),
                ),
                _buildSection(
                  'Transfers',
                  Icons.move_up_rounded,
                  _categories.where((c) => c.categoryType.toUpperCase() == 'TRANSFERS').toList(),
                ),
                _buildSection(
                  'Investments',
                  Icons.trending_up_rounded,
                  _categories.where((c) => c.categoryType.toUpperCase() == 'INVESTMENTS').toList(),
                ),
              ],
            ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Category> sectionCategories) {
    if (sectionCategories.isEmpty) return const SizedBox.shrink();

    final isAnySelected = sectionCategories.any((cat) => !_excludedCategories.contains(cat.id));

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => _toggleSection(sectionCategories, !isAnySelected),
              child: Icon(
                isAnySelected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                color: isAnySelected ? AppColors.income : Colors.white24,
                size: 22,
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, color: AppColors.primary, size: 20),
          ],
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        children: sectionCategories.map((cat) => _buildCategoryTile(cat)).toList(),
      ),
    );
  }

  void _toggleSection(List<Category> sectionCategories, bool select) {
    setState(() {
      for (final cat in sectionCategories) {
        if (select) {
          _excludedCategories.remove(cat.id);
          for (final sub in _subCategories[cat.id!] ?? []) {
            _excludedSubcats.remove(sub.id);
          }
        } else {
          _excludedCategories.add(cat.id!);
          for (final sub in _subCategories[cat.id!] ?? []) {
            _excludedSubcats.add(sub.id!);
          }
        }
      }
    });
  }

  Widget _buildCategoryTile(Category cat) {
    final subs = _subCategories[cat.id!] ?? [];
    final isIncluded = subs.isEmpty 
        ? !_excludedCategories.contains(cat.id) 
        : subs.any((s) => !_excludedSubcats.contains(s.id));

    return ExpansionTile(
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 16), // Indentation for sub-level
          InkWell(
            onTap: () => _toggleCategory(cat, !isIncluded),
            child: Icon(
              isIncluded ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
              color: isIncluded ? AppColors.income : Colors.white24,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            IconHelper.getIcon(cat.icon),
            color: ColorHelper.fromHex(cat.iconColor).withOpacity(0.8),
            size: 16,
          ),
        ],
      ),
      title: Text(cat.categoryName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(
        isIncluded ? 'Included' : 'Excluded',
        style: TextStyle(
          fontSize: 10,
          color: isIncluded ? AppColors.income : AppColors.expense,
        ),
      ),
      children: subs.map((sub) {
        final isSubIncluded = !_excludedSubcats.contains(sub.id);
        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.only(left: 64, right: 16),
          leading: InkWell(
            onTap: () => _toggleSubcategory(cat, sub, !isSubIncluded),
            child: Icon(
              isSubIncluded ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
              color: isSubIncluded ? AppColors.income : Colors.white24,
              size: 18,
            ),
          ),
          title: Text(sub.subcategoryName, style: const TextStyle(fontSize: 13)),
        );
      }).toList(),
    );
  }

  void _toggleCategory(Category cat, bool select) {
    setState(() {
      if (select) {
        _excludedCategories.remove(cat.id);
        // Include all subcategories
        for (final sub in _subCategories[cat.id!] ?? []) {
          _excludedSubcats.remove(sub.id);
        }
      } else {
        _excludedCategories.add(cat.id!);
        // Exclude all subcategories
        for (final sub in _subCategories[cat.id!] ?? []) {
          _excludedSubcats.add(sub.id!);
        }
      }
    });
  }

  void _toggleSubcategory(Category parentCat, SubCategory sub, bool select) {
    setState(() {
      if (select) {
        _excludedSubcats.remove(sub.id);
        // Ensure parent category is also "Included"
        _excludedCategories.remove(parentCat.id);
      } else {
        _excludedSubcats.add(sub.id!);
        
        // If ALL subcategories are now excluded, exclude the parent category too
        final allSubs = _subCategories[parentCat.id!] ?? [];
        final anySubRemaining = allSubs.any((s) => s.id != sub.id && !_excludedSubcats.contains(s.id));
        if (!anySubRemaining) {
          _excludedCategories.add(parentCat.id!);
        }
      }
    });
  }
}
