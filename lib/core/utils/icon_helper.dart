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

  /// Exposes the map of all available icons for the IconPicker.
  static Map<String, IconData> get availableIcons => _iconMap;

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
    'local_drink': Icons.local_drink_rounded,
    'local_pizza': Icons.local_pizza_rounded,
    'local_cafe': Icons.local_cafe_rounded,
    'fastfood': Icons.fastfood_rounded,
    'cake': Icons.cake_rounded,
    'icecream': Icons.icecream_rounded,
    'liquor': Icons.liquor_rounded,
    'kebab_dining': Icons.kebab_dining_rounded,
    'ramen_dining': Icons.ramen_dining_rounded,
    'soup_kitchen': Icons.soup_kitchen_rounded,
    'tapas': Icons.tapas_rounded,
    'bento': Icons.bento_rounded,
    'rice_bowl': Icons.rice_bowl_rounded,

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

    // ─── Banking & Money ─────────────────────────────────────
    'currency_rupee': Icons.currency_rupee_rounded,
    'currency_exchange': Icons.currency_exchange_rounded,
    'price_check': Icons.price_check_rounded,
    'request_quote': Icons.request_quote_rounded,
    'paid': Icons.paid_rounded,
    'attach_money': Icons.attach_money_rounded,
    'money': Icons.money_rounded,
    'monetization_on': Icons.monetization_on_rounded,
    'money_off': Icons.money_off_rounded,
    'wallet': Icons.wallet_rounded,
    'sell': Icons.sell_rounded,
    'credit_score': Icons.credit_score_rounded,

    // ─── Bills & Subscriptions ───────────────────────────────
    'receipt': Icons.receipt_rounded,
    'fact_check': Icons.fact_check_rounded,
    'calendar_month': Icons.calendar_month_rounded,
    'event_repeat': Icons.event_repeat_rounded,
    'subscriptions': Icons.subscriptions_rounded,
    'confirmation_number': Icons.confirmation_number_rounded,

    // ─── Internet & Communication ────────────────────────────
    'wifi': Icons.wifi_rounded,
    'router': Icons.router_rounded,
    'network_wifi': Icons.network_wifi_rounded,
    'call': Icons.call_rounded,
    'mail': Icons.mail_rounded,
    'chat': Icons.chat_rounded,
    'notifications': Icons.notifications_rounded,

    // ─── Home Utilities ──────────────────────────────────────
    'water_drop': Icons.water_drop_rounded,
    'bathroom': Icons.bathroom_rounded,
    'power': Icons.power_rounded,
    'charging_station': Icons.charging_station_rounded,
    'cleaning_services': Icons.cleaning_services_rounded,
    'yard': Icons.yard_rounded,

    // ─── Work & Office ───────────────────────────────────────
    'work': Icons.work_rounded,
    'business': Icons.business_rounded,
    'badge': Icons.badge_rounded,
    'engineering': Icons.engineering_rounded,
    'groups': Icons.groups_rounded,
    'handyman': Icons.handyman_rounded,
    'plumbing': Icons.plumbing_rounded,
    'electrical_services': Icons.electrical_services_rounded,
    'pest_control': Icons.pest_control_rounded,
    'roofing': Icons.roofing_rounded,
    'hvac': Icons.hvac_rounded,

    // ─── Investments & Assets ────────────────────────────────
    'trending_up': Icons.trending_up_rounded,
    'trending_down': Icons.trending_down_rounded,
    'candlestick_chart': Icons.candlestick_chart_rounded,
    'query_stats': Icons.query_stats_rounded,
    'stacked_line_chart': Icons.stacked_line_chart_rounded,
    'analytics': Icons.analytics_rounded,

    // ─── Property & Assets ───────────────────────────────────
    'villa': Icons.villa_rounded,
    'apartment': Icons.apartment_rounded,
    'garage': Icons.garage_rounded,
    'foundation': Icons.foundation_rounded,
    'warehouse': Icons.warehouse_rounded,

    // ─── Travel & Outdoor ────────────────────────────────────
    'train': Icons.train_rounded,
    'subway': Icons.subway_rounded,
    'taxi_alert': Icons.taxi_alert_rounded,
    'luggage': Icons.luggage_rounded,
    'beach_access': Icons.beach_access_rounded,
    'terrain': Icons.terrain_rounded,

    // ─── Lifestyle ───────────────────────────────────────────
    'sports_soccer': Icons.sports_soccer_rounded,
    'sports_cricket': Icons.sports_cricket_rounded,
    'fitness_center': Icons.fitness_center_rounded,
    'spa': Icons.spa_rounded,
    'park': Icons.park_rounded,

    // ─── Alerts & Status ─────────────────────────────────────
    'warning': Icons.warning_rounded,
    'error': Icons.error_rounded,
    'check_circle': Icons.check_circle_rounded,
    'cancel': Icons.cancel_rounded,
    'info': Icons.info_rounded,

    // ─── Time & Tracking ─────────────────────────────────────
    'access_time': Icons.access_time_rounded,
    'timer': Icons.timer_rounded,
    'update': Icons.update_rounded,
    'history': Icons.history_rounded,

    // ─── Data & Files ────────────────────────────────────────
    'folder': Icons.folder_rounded,
    'insert_drive_file': Icons.insert_drive_file_rounded,
    'cloud': Icons.cloud_rounded,
    'backup': Icons.backup_rounded,
    'storage': Icons.storage_rounded,
  };

  /// Returns the [IconData] for the given icon name string.
  /// Falls back to [Icons.help_outline_rounded] if the name is not found.
  static IconData getIcon(String? name) {
    if (name == null || name.isEmpty) return Icons.help_outline_rounded;
    return _iconMap[name] ?? Icons.help_outline_rounded;
  }
}
