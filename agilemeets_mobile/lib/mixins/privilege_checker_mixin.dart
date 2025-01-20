import 'package:agilemeets/utils/app_theme.dart';

import '../data/models/project/member_privileges_dto.dart';
import 'package:flutter/material.dart';

mixin PrivilegeCheckerMixin {
  bool checkPrivilege(
    BuildContext context,
    MemberPrivilegesDTO? privileges,
    bool Function(MemberPrivilegesDTO) checker,
    String action,
  ) {
    if (privileges == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to verify permissions'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return false;
    }

    if (!checker(privileges)) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
          content: Text('You don\'t have permission to $action'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return false;
    }

    return true;
  }
} 