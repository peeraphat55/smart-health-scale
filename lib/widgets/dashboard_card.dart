import 'package:flutter/material.dart';
import 'package:project/core/app_theme.dart';

class DashboardCard extends StatelessWidget {
  final String label;
  final String value;
  final bool fullWidth;
  final bool isEditable;

  const DashboardCard({
    super.key,
    required this.label,
    required this.value,
    this.fullWidth = false,
    this.isEditable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w500)),
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primary)),
              ],
            ),
          ),
          if (isEditable)
            const Positioned(top: 8, right: 8, child: Icon(Icons.edit, size: 16, color: Colors.grey)),
        ],
      ),
    );
  }
}