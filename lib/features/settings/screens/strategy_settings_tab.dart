import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/color_helper.dart';
import '../../../core/utils/icon_helper.dart';
import '../../../models/category.dart';
import '../../../models/strategy_models.dart';
import '../../../services/providers.dart';
import '../../../widgets/glass_card.dart';

class StrategySettingsTab extends ConsumerStatefulWidget {
  const StrategySettingsTab({super.key});

  @override
  ConsumerState<StrategySettingsTab> createState() => _StrategySettingsTabState();
}

class _StrategySettingsTabState extends ConsumerState<StrategySettingsTab> {
  bool _loading = true;
  List<BudgetFramework> _frameworks = [];
  BudgetFramework? _activeFramework;
  List<BudgetBucket> _buckets = [];
  List<Category> _categories = [];
  Map<int, int> _mappings = {}; // CategoryID -> BucketID

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final repo = ref.read(strategyRepositoryProvider);
    final catRepo = ref.read(categoryRepositoryProvider);

    final frameworks = await repo.getAllFrameworks();
    final active = await repo.getActiveFramework();
    final categories = await catRepo.getAllSorted();
    
    if (active != null) {
      final buckets = await repo.getBucketsForFramework(active.id!);
      final mappings = await repo.getCategoryMappings(active.id!);
      
      // Auto-mapping for "Income" and "Mutual Funds" if not already mapped
      for (final cat in categories) {
        if (!mappings.containsKey(cat.id!)) {
          final bucket = _suggestBucket(cat, buckets);
          if (bucket != null) {
            await repo.updateCategoryMapping(cat.id!, active.id!, bucket.id!);
            mappings[cat.id!] = bucket.id!;
          }
        }
      }

      setState(() {
        _frameworks = frameworks;
        _activeFramework = active;
        _buckets = buckets;
        _categories = categories.where((c) => c.categoryName.toLowerCase() != 'income').toList();
        _mappings = mappings;
        _loading = false;
      });
    } else {
      setState(() {
        _frameworks = frameworks;
        _loading = false;
      });
    }
  }

  BudgetBucket? _suggestBucket(Category cat, List<BudgetBucket> buckets) {
    final name = cat.categoryName.toLowerCase();
    
    // Suggester logic based on standard frameworks
    if (name.contains('mutual') || name.contains('invest') || cat.categoryType == 'INVESTMENTS') {
      return buckets.where((b) => b.bucketType == 'SAVED').firstOrNull;
    }
    
    if (name.contains('rent') || name.contains('bill') || name.contains('grocer') || name.contains('utilit') || name.contains('health')) {
      return buckets.where((b) => b.name.toLowerCase().contains('essential') || b.name.toLowerCase().contains('need')).firstOrNull;
    }

    if (name.contains('food') || name.contains('shop') || name.contains('entertain') || name.contains('travel')) {
      return buckets.where((b) => b.name.toLowerCase().contains('want') || b.name.toLowerCase().contains('reward')).firstOrNull;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Text('Budgeting Framework', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                const Text('Choose the heuristic rule that governs your financial choices.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                const SizedBox(height: 16),
                _buildFrameworkSelector(),
                _buildFrameworkDescription(_activeFramework?.name),
                const SizedBox(height: 32),
                const Text('Category Mapping', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                const Text('Assign each category to a strategic bucket.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                const SizedBox(height: 16),
                _buildMappingDescription(),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final cat = _categories[index];
              return _buildCategoryMappingTile(cat);
            },
            childCount: _categories.length,
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
      ],
    );
  }

  Widget _buildFrameworkSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _activeFramework?.id,
          isExpanded: true,
          items: _frameworks.map((f) => DropdownMenuItem(
            value: f.id,
            child: Text(f.name),
          )).toList(),
          onChanged: (id) async {
            if (id != null) {
              await ref.read(strategyRepositoryProvider).setActiveFramework(id);
              _loadData();
            }
          },
        ),
      ),
    );
  }

  Widget _buildFrameworkDescription(String? name) {
    if (name == null) return const SizedBox.shrink();
    
    final description = _getFrameworkDescription(name);
    if (description == null) return const SizedBox.shrink();

    return GlassCard(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  String? _getFrameworkDescription(String name) {
    if (name.contains('50/30/20')) {
      return 'The most common heuristic: Essentials (50%), Wants (30%), and Savings (20%). It balances needs, luxury, and future growth.';
    }
    if (name.contains('70/20/10')) {
      return '70% Living Expenses: Combines needs and wants into one large bucket. 20% Savings & Investments: Building long-term wealth. 10% Debt Repayment or Giving: Dedicated to extra debt or charitable donations.';
    }
    if (name.contains('80/20')) {
      return 'The "pay yourself first" model. 20% for savings, and the remaining 80% for everything else without strict categorization.';
    }
    if (name.contains('50/25/15/10')) {
      return 'A advanced framework: 50% Essentials, 25% Growth (Long-term), 15% Stability (Safety net), and 10% Rewards (Guilt-free spending).';
    }
    return null;
  }

  Widget _buildCategoryMappingTile(Category cat) {
    final mappedBucketId = _mappings[cat.id];
    
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: ColorHelper.fromHex(cat.iconColor).withOpacity(0.15),
              child: Icon(IconHelper.getIcon(cat.icon), color: ColorHelper.fromHex(cat.iconColor), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(cat.categoryName, style: const TextStyle(fontWeight: FontWeight.w500)),
            ),
            const SizedBox(width: 8),
            DropdownButton<int?>(
              value: mappedBucketId,
              hint: const Text('Unmapped', style: TextStyle(fontSize: 12, color: Colors.white24)),
              style: const TextStyle(fontSize: 13, color: Colors.white),
              underline: const SizedBox.shrink(),
              items: _buckets.map((b) => DropdownMenuItem<int?>(
                value: b.id,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(
                      color: b.iconColor != null ? Color(int.parse(b.iconColor!.replaceFirst('#', '0xFF'))) : AppColors.primary,
                      shape: BoxShape.circle,
                    )),
                    const SizedBox(width: 8),
                    Text(b.name),
                  ],
                ),
              )).toList(),
              onChanged: (bucketId) async {
                if (bucketId != null && _activeFramework != null) {
                  await ref.read(strategyRepositoryProvider).updateCategoryMapping(cat.id!, _activeFramework!.id!, bucketId);
                  setState(() {
                    _mappings[cat.id!] = bucketId;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMappingDescription() {
    if (_buckets.isEmpty) return const SizedBox.shrink();

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _buckets.map((b) => Padding(
          padding: EdgeInsets.only(bottom: b == _buckets.last ? 0 : 12),
          child: _buildInfoRow(
            _getBucketIcon(b.icon),
            b.iconColor != null ? Color(int.parse(b.iconColor!.replaceFirst('#', '0xFF'))) : AppColors.primary,
            '${b.name} (${b.percentage.toStringAsFixed(0)}%)',
            _getBucketDescription(b.name),
          ),
        )).toList(),
      ),
    );
  }

  IconData _getBucketIcon(String? name) {
    switch (name) {
      case 'fact_check_rounded': return Icons.fact_check_rounded;
      case 'shopping_bag_rounded': return Icons.shopping_bag_rounded;
      case 'trending_up_rounded': return Icons.trending_up_rounded;
      case 'home_rounded': return Icons.home_rounded;
      case 'volunteer_activism_rounded': return Icons.volunteer_activism_rounded;
      case 'rocket_launch_rounded': return Icons.rocket_launch_rounded;
      case 'shield_rounded': return Icons.shield_rounded;
      case 'card_giftcard_rounded': return Icons.card_giftcard_rounded;
      case 'savings_rounded': return Icons.savings_rounded;
      default: return Icons.category_rounded;
    }
  }

  String _getBucketDescription(String name) {
    final n = name.toLowerCase();
    if (n.contains('essential') || n.contains('need')) {
      return 'Non-negotiable bills: Rent, Utilities, Insurance, Basic Groceries.';
    }
    if (n.contains('living')) {
      return 'Combined needs and wants: Housing, food, transport, and basic lifestyle.';
    }
    if (n.contains('want') || n.contains('reward') || n.contains('everyday')) {
      return 'Discretionary spending: Dining, Shopping, Hobbies, and Entertainment.';
    }
    if (n.contains('savings') || n.contains('invest') || n.contains('growth')) {
      return 'Wealth creation: SIPs, Mutual Funds, and Emergency Funds.';
    }
    if (n.contains('debt') || n.contains('giving')) {
      return 'Financial obligations & Charity: Extra loan payments or donations.';
    }
    if (n.contains('stability')) {
      return 'Safety net: Insurance premiums and liquid cash reserves.';
    }
    return 'Map your categories that fit this strategic target.';
  }

  Widget _buildInfoRow(IconData icon, Color color, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}
