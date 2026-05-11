import 'package:flutter/material.dart';

/// Marketplace job categories (icons + labels for UI).
enum JobCategoryId {
  cleaning,
  repair,
  electric,
  plumbing,
  delivery,
  beauty,
  moving,
}

extension JobCategoryIdX on JobCategoryId {
  String get labelAz {
    return switch (this) {
      JobCategoryId.cleaning => 'Təmizlik',
      JobCategoryId.repair => 'Təmir',
      JobCategoryId.electric => 'Elektrik',
      JobCategoryId.plumbing => 'Santexnika',
      JobCategoryId.delivery => 'Çatdırılma',
      JobCategoryId.beauty => 'Gözəllik',
      JobCategoryId.moving => 'Daşıma',
    };
  }

  IconData get icon {
    return switch (this) {
      JobCategoryId.cleaning => Icons.cleaning_services_outlined,
      JobCategoryId.repair => Icons.handyman_outlined,
      JobCategoryId.electric => Icons.electrical_services_outlined,
      JobCategoryId.plumbing => Icons.plumbing_outlined,
      JobCategoryId.delivery => Icons.local_shipping_outlined,
      JobCategoryId.beauty => Icons.spa_outlined,
      JobCategoryId.moving => Icons.inventory_2_outlined,
    };
  }

  String get id => name;
}
