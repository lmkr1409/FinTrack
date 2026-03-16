import 'package:flutter/material.dart';

/// Utility to convert a Material Icon name stored in the database
/// into a Flutter [IconData] instance.
///
/// Usage:
/// ```dart
/// final icon = IconHelper.getIcon('home'); // returns Icons.home
/// ```
class IconHelper {
  IconHelper._();

  static const Map<String, IconData> _iconMap = {
    // ─── General ──────────────────────────────────────────
    'home': Icons.home_rounded,
    'more_horiz': Icons.more_horiz_rounded,
    'help_outline': Icons.help_outline_rounded,
    'swap_horiz': Icons.swap_horiz_rounded,
    'store': Icons.store_rounded,

    // ─── Finance ──────────────────────────────────────────
    'account_balance': Icons.account_balance_rounded,
    'credit_card': Icons.credit_card_rounded,
    'savings': Icons.savings_rounded,
    'payments': Icons.payments_rounded,
    'receipt_long': Icons.receipt_long_rounded,
    'show_chart': Icons.show_chart_rounded,
    'pie_chart': Icons.pie_chart_rounded,
    'lock': Icons.lock_rounded,
    'description': Icons.description_rounded,
    'account_balance_wallet': Icons.account_balance_wallet_rounded,

    // ─── Food & Groceries ─────────────────────────────────
    'shopping_basket': Icons.shopping_basket_rounded,
    'shopping_cart': Icons.shopping_cart_rounded,
    'shopping_bag': Icons.shopping_bag_rounded,
    'restaurant': Icons.restaurant_rounded,
    'lunch_dining': Icons.lunch_dining_rounded,
    'breakfast_dining': Icons.breakfast_dining_rounded,
    'bakery_dining': Icons.bakery_dining_rounded,
    'set_meal': Icons.set_meal_rounded,
    'coffee': Icons.coffee_rounded,
    'nutrition': Icons.egg_rounded,
    'eco': Icons.eco_rounded,

    // ─── Transport ────────────────────────────────────────
    'directions_bus': Icons.directions_bus_rounded,
    'directions_car': Icons.directions_car_rounded,
    'two_wheeler': Icons.two_wheeler_rounded,
    'local_gas_station': Icons.local_gas_station_rounded,
    'airport_shuttle': Icons.airport_shuttle_rounded,
    'flight': Icons.flight_rounded,

    // ─── Utilities ────────────────────────────────────────
    'lightbulb': Icons.lightbulb_rounded,
    'bolt': Icons.bolt_rounded,
    'local_fire_department': Icons.local_fire_department_rounded,
    'smartphone': Icons.smartphone_rounded,
    'language': Icons.language_rounded,

    // ─── Health & Insurance ───────────────────────────────
    'favorite': Icons.favorite_rounded,
    'medical_services': Icons.medical_services_rounded,
    'medication': Icons.medication_rounded,
    'local_hospital': Icons.local_hospital_rounded,
    'shield': Icons.shield_rounded,
    'car_crash': Icons.car_crash_rounded,
    'health_and_safety': Icons.health_and_safety_rounded,

    // ─── Education ────────────────────────────────────────
    'school': Icons.school_rounded,
    'menu_book': Icons.menu_book_rounded,
    'edit': Icons.edit_rounded,

    // ─── Entertainment & Travel ──────────────────────────
    'movie': Icons.movie_rounded,
    'music_note': Icons.music_note_rounded,
    'theater_comedy': Icons.theater_comedy_rounded,
    'hotel': Icons.hotel_rounded,
    'map': Icons.map_rounded,

    // ─── Shopping ─────────────────────────────────────────
    'checkroom': Icons.checkroom_rounded,
    'laptop': Icons.laptop_rounded,

    // ─── People & Purposes ────────────────────────────────
    'person': Icons.person_rounded,
    'woman': Icons.woman_rounded,
    'child_care': Icons.child_care_rounded,
    'schedule': Icons.schedule_rounded,
    'handshake': Icons.handshake_rounded,
    'volunteer_activism': Icons.volunteer_activism_rounded,
    'account_circle': Icons.account_circle_rounded,
    'card_giftcard': Icons.card_giftcard_rounded,

    // ─── Expense Sources ──────────────────────────────────
    'sms': Icons.sms_rounded,
    'keyboard': Icons.keyboard_rounded,

    // ─── Tools & Misc ─────────────────────────────────────
    'build': Icons.build_rounded,
    'grain': Icons.grain_rounded,
    'house': Icons.house_rounded,
  };

  /// Returns the [IconData] for the given icon name string.
  /// Falls back to [Icons.help_outline_rounded] if the name is not found.
  static IconData getIcon(String? name) {
    if (name == null || name.isEmpty) return Icons.help_outline_rounded;
    return _iconMap[name] ?? Icons.help_outline_rounded;
  }
}
