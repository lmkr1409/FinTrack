import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/color_helper.dart';
import '../../../core/utils/icon_helper.dart';
import '../../../models/category.dart';
import '../../../models/sub_category.dart';
import '../../../services/providers.dart';
import '../../../core/widgets/icon_picker.dart';

/// Categories & SubCategories CRUD tab.
/// Displays a list of categories, each expandable to show its subcategories.
/// Tapping the FAB or a list item opens add/edit dialogs.
class CategoriesTab extends ConsumerStatefulWidget {
  const CategoriesTab({super.key});

  @override
  ConsumerState<CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends ConsumerState<CategoriesTab> {
  List<Category> _categories = [];
  Map<int, List<SubCategory>> _subCategoriesMap = {};
  final Set<int> _expandedIds = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final catRepo = ref.read(categoryRepositoryProvider);
    final subCatRepo = ref.read(subCategoryRepositoryProvider);

    final categories = await catRepo.getAllSorted();
    final subMap = <int, List<SubCategory>>{};
    for (final cat in categories) {
      subMap[cat.id!] = await subCatRepo.getByCategoryId(cat.id!);
    }

    setState(() {
      _categories = categories;
      _subCategoriesMap = subMap;
      _loading = false;
    });
  }

  // ─── Category CRUD dialogs ──────────────────────────────

  Future<void> _showCategoryDialog({Category? category}) async {
    final nameCtrl = TextEditingController(text: category?.categoryName ?? '');
    final iconCtrl = TextEditingController(text: category?.icon ?? '');
    final colorCtrl = TextEditingController(
      text: category?.iconColor ?? '#607D8B',
    );
    final priorityCtrl = TextEditingController(
      text: category?.priority?.toString() ?? '99',
    );
    final isEdit = category != null;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Category' : 'Add Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: iconCtrl,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Icon',
                    border: const OutlineInputBorder(),
                    suffixIcon: Icon(IconHelper.getIcon(iconCtrl.text)),
                  ),
                  onTap: () async {
                    final selected = await IconPicker.show(
                      context,
                      initialIcon: iconCtrl.text,
                    );
                    if (selected != null) {
                      setDialogState(() => iconCtrl.text = selected);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: colorCtrl,
                  decoration: InputDecoration(
                    labelText: 'Icon Color (hex)',
                    border: const OutlineInputBorder(),
                    suffixIcon: CircleAvatar(
                      radius: 12,
                      backgroundColor: ColorHelper.fromHex(colorCtrl.text),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priorityCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Priority (Lower is higher)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(isEdit ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;

    final repo = ref.read(categoryRepositoryProvider);
    final priority = int.tryParse(priorityCtrl.text.trim()) ?? 99;

    if (isEdit) {
      await repo.updateCategory(
        category.copyWith(
          categoryName: name,
          icon: iconCtrl.text.trim(),
          iconColor: colorCtrl.text.trim(),
          priority: priority,
        ),
      );
    } else {
      await repo.insertCategory(
        Category(
          categoryName: name,
          icon: iconCtrl.text.trim(),
          iconColor: colorCtrl.text.trim(),
          priority: priority,
        ),
      );
    }
    await _loadData();
  }

  Future<void> _confirmDeleteCategory(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Delete "${category.categoryName}" and all its subcategories?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(categoryRepositoryProvider).deleteCategory(category.id!);
      await _loadData();
    }
  }

  // ─── SubCategory CRUD dialogs ───────────────────────────

  Future<void> _showSubCategoryDialog(
    int categoryId, {
    SubCategory? subCategory,
  }) async {
    final nameCtrl = TextEditingController(
      text: subCategory?.subcategoryName ?? '',
    );
    final iconCtrl = TextEditingController(text: subCategory?.icon ?? '');
    final colorCtrl = TextEditingController(
      text: subCategory?.iconColor ?? '#9E9E9E',
    );
    final priorityCtrl = TextEditingController(
      text: subCategory?.priority?.toString() ?? '99',
    );
    final isEdit = subCategory != null;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit SubCategory' : 'Add SubCategory'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'SubCategory Name',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: iconCtrl,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Icon',
                    border: const OutlineInputBorder(),
                    suffixIcon: Icon(IconHelper.getIcon(iconCtrl.text)),
                  ),
                  onTap: () async {
                    final selected = await IconPicker.show(
                      context,
                      initialIcon: iconCtrl.text,
                    );
                    if (selected != null) {
                      setDialogState(() => iconCtrl.text = selected);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: colorCtrl,
                  decoration: InputDecoration(
                    labelText: 'Icon Color (hex)',
                    border: const OutlineInputBorder(),
                    suffixIcon: CircleAvatar(
                      radius: 12,
                      backgroundColor: ColorHelper.fromHex(colorCtrl.text),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priorityCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Priority (Lower is higher)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(isEdit ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;

    final repo = ref.read(subCategoryRepositoryProvider);
    final priority = int.tryParse(priorityCtrl.text.trim()) ?? 99;

    if (isEdit) {
      await repo.updateSubCategory(
        subCategory.copyWith(
          subcategoryName: name,
          icon: iconCtrl.text.trim(),
          iconColor: colorCtrl.text.trim(),
          priority: priority,
        ),
      );
    } else {
      await repo.insertSubCategory(
        SubCategory(
          subcategoryName: name,
          categoryId: categoryId,
          icon: iconCtrl.text.trim(),
          iconColor: colorCtrl.text.trim(),
          priority: priority,
        ),
      );
    }
    await _loadData();
  }

  Future<void> _confirmDeleteSubCategory(SubCategory subCategory) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete SubCategory'),
        content: Text('Delete "${subCategory.subcategoryName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(subCategoryRepositoryProvider)
          .deleteSubCategory(subCategory.id!);
      await _loadData();
    }
  }

  // ─── Build ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: _categories.isEmpty
          ? Center(
              child: Text(
                'No categories yet.',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final subs = _subCategoriesMap[cat.id!] ?? [];
                final isExpanded = _expandedIds.contains(cat.id);

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: ColorHelper.fromHex(
                            cat.iconColor,
                          ).withValues(alpha: 0.15),
                          child: Icon(
                            IconHelper.getIcon(cat.icon),
                            color: ColorHelper.fromHex(cat.iconColor),
                          ),
                        ),
                        title: Text(
                          cat.categoryName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text('subcategories: ${subs.length}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              onPressed: () =>
                                  _showCategoryDialog(category: cat),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: colorScheme.error,
                              ),
                              onPressed: () => _confirmDeleteCategory(cat),
                            ),
                            IconButton(
                              icon: Icon(
                                isExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                              ),
                              onPressed: () {
                                setState(() {
                                  if (isExpanded) {
                                    _expandedIds.remove(cat.id);
                                  } else {
                                    _expandedIds.add(cat.id!);
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      if (isExpanded) ...[
                        const Divider(height: 1),
                        ...subs.map(
                          (sub) => ListTile(
                            contentPadding: const EdgeInsets.only(
                              left: 32,
                              right: 16,
                            ),
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: ColorHelper.fromHex(
                                sub.iconColor,
                              ).withValues(alpha: 0.15),
                              child: Icon(
                                IconHelper.getIcon(sub.icon),
                                size: 18,
                                color: ColorHelper.fromHex(sub.iconColor),
                              ),
                            ),
                            title: Text(sub.subcategoryName),
                            subtitle: Text(
                              'Priority: ${sub.priority ?? 99}',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                  ),
                                  onPressed: () => _showSubCategoryDialog(
                                    cat.id!,
                                    subCategory: sub,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: colorScheme.error,
                                  ),
                                  onPressed: () =>
                                      _confirmDeleteSubCategory(sub),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 32, bottom: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add SubCategory'),
                              onPressed: () => _showSubCategoryDialog(cat.id!),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
