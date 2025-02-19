import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OrganizationSettingsSheet extends StatelessWidget {
  const OrganizationSettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 8.h),
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha:0.4),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Organization Settings',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 16.h),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Organization'),
            onTap: () {
              // Navigate to edit organization screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.admin_panel_settings),
            title: const Text('Manage Roles'),
            onTap: () => Navigator.pushNamed(context, '/organization/roles'),
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Security Settings'),
            onTap: () {
              // Navigate to security settings
            },
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16.h),
        ],
      ),
    );
  }
} 