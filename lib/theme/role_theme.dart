import 'dart:ui';

import 'package:flutter/material.dart';

class RoleTheme {
  final Color primary;
  final Color background;
  final Color card;
  final Color accent;
  final IconData icon;

  const RoleTheme({
    required this.primary,
    required this.background,
    required this.card,
    required this.accent,
    required this.icon,
  });
}

class AppThemes {
  static const delivery = RoleTheme(
    primary: Colors.blueGrey,
    background: Color(0xFFF2F4F7),
    card: Colors.white,
    accent: Colors.blue,
    icon: Icons.local_shipping,
  );

  static const vendor = RoleTheme(
    primary: Color(0xFF1B5E20),
    background: Color(0xFFF1F8F4),
    card: Colors.white,
    accent: Colors.green,
    icon: Icons.store,
  );

  static const admin = RoleTheme(
    primary: Color(0xFF4A148C),
    background: Color(0xFFF5F0FA),
    card: Colors.white,
    accent: Colors.purple,
    icon: Icons.admin_panel_settings,
  );

  static const client = RoleTheme(
    primary: Color(0xFFE65100),
    background: Color(0xFFFFF3E0),
    card: Colors.white,
    accent: Colors.orange,
    icon: Icons.shopping_cart,
  );
}