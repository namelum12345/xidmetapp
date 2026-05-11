import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../admin_stat_card.dart';
import '../super_stat_card.dart';

/// Real-time Firestore [Query] sayı + [AdminStatCard] (InkWell daxildə).
class StreamAdminQueryStatCard extends StatelessWidget {
  const StreamAdminQueryStatCard({
    super.key,
    required this.query,
    required this.icon,
    required this.label,
    required this.onTap,
    this.countFromDocs,
  });

  final Query<Map<String, dynamic>> query;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int Function(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs)?
      countFromDocs;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return AdminStatCard(
            icon: icon,
            label: label,
            value: '!',
            onTap: onTap,
          );
        }
        final waiting =
            snap.connectionState == ConnectionState.waiting && !snap.hasData;
        final docs = snap.data?.docs ?? const [];
        final n = countFromDocs != null ? countFromDocs!(docs) : docs.length;
        return AdminStatCard(
          icon: icon,
          label: label,
          value: waiting ? '…' : '$n',
          onTap: onTap,
        );
      },
    );
  }
}

/// Real-time Firestore + [SuperStatCard].
class StreamSuperQueryStatCard extends StatelessWidget {
  const StreamSuperQueryStatCard({
    super.key,
    required this.query,
    required this.icon,
    required this.label,
    required this.onTap,
    this.countFromDocs,
    this.accent,
  });

  final Query<Map<String, dynamic>> query;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int Function(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs)?
      countFromDocs;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return SuperStatCard(
            icon: icon,
            label: label,
            value: '!',
            accent: accent,
            onTap: onTap,
          );
        }
        final waiting =
            snap.connectionState == ConnectionState.waiting && !snap.hasData;
        final docs = snap.data?.docs ?? const [];
        final n = countFromDocs != null ? countFromDocs!(docs) : docs.length;
        return SuperStatCard(
          icon: icon,
          label: label,
          value: waiting ? '…' : '$n',
          accent: accent,
          onTap: onTap,
        );
      },
    );
  }
}
