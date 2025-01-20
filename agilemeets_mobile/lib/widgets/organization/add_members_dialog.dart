import 'package:agilemeets/logic/cubits/organization/organization_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../logic/cubits/organization/organization_cubit.dart';
import '../../utils/app_theme.dart';
import '../custom_text_field.dart';

class AddMembersDialog extends StatefulWidget {
  const AddMembersDialog({super.key});

  @override
  State<AddMembersDialog> createState() => _AddMembersDialogState();
}

class _AddMembersDialogState extends State<AddMembersDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final List<String> _emails = [];
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Container(
        width: 0.9.sw,
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Members',
              style: AppTheme.headingMedium,
            ).animate().fadeIn().slideX(begin: -0.2, end: 0),
            SizedBox(height: 8.h),
            Text(
              'Invite people to join your organization',
              style: AppTheme.subtitle.copyWith(
                color: AppTheme.textGrey,
              ),
            ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2, end: 0),
            SizedBox(height: 24.h),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  CustomTextField(
                    controller: _emailController,
                    label: 'Email Address',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _addEmail,
                    ), prefixIcon: Icons.email,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            if (_emails.isNotEmpty) ...[
              Text(
                'Added Emails:',
                style: AppTheme.subtitle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                constraints: BoxConstraints(maxHeight: 120.h),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: _emails.map((email) {
                      return Chip(
                        label: Text(email),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () => _removeEmail(email),
                      ).animate().scale(delay: 100.ms);
                    }).toList(),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: FilledButton(
                    onPressed: _isSubmitting || _emails.isEmpty ? null : _inviteMembers,
                    child: Text(_isSubmitting ? 'Inviting...' : 'Invite'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addEmail() {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      if (!_emails.contains(email)) {
        setState(() {
          _emails.add(email);
          _emailController.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email already added'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _removeEmail(String email) {
    setState(() {
      _emails.remove(email);
    });
  }

  Future<void> _inviteMembers() async {
    setState(() => _isSubmitting = true);
    
    try {
      await context.read<OrganizationCubit>().addMembers(_emails);
      if (mounted) {
        Navigator.pop(context);
        _showResultDialog(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showResultDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: BlocBuilder<OrganizationCubit, OrganizationState>(
            builder: (context, state) {
              if (state.status == OrganizationStatus.error) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppTheme.errorRed,
                      size: 48.w,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Error',
                      style: AppTheme.headingMedium,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      state.error ?? 'An error occurred',
                      textAlign: TextAlign.center,
                      style: AppTheme.subtitle.copyWith(
                        color: AppTheme.textGrey,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                );
              }

              final result = state.lastAddMembersResult;
              if (result == null) return const SizedBox();

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invitation Results',
                    style: AppTheme.headingMedium,
                  ).animate().fadeIn().slideX(begin: -0.2, end: 0),
                  SizedBox(height: 16.h),
                  Text(
                    state.message ?? '',
                    style: AppTheme.subtitle.copyWith(
                      color: AppTheme.textGrey,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  if (result.results.isNotEmpty) ...[
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: 0.4.sh,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: result.results.length,
                        itemBuilder: (context, index) {
                          final emailResult = result.results[index];
                          return ListTile(
                            leading: Icon(
                              emailResult.success
                                  ? Icons.check_circle
                                  : Icons.error_outline,
                              color: emailResult.success
                                  ? AppTheme.successGreen
                                  : AppTheme.errorRed,
                            ),
                            title: Text(emailResult.email),
                            subtitle: emailResult.errorMessage != null
                                ? Text(
                                    emailResult.errorMessage!,
                                    style: const TextStyle(
                                      color: AppTheme.errorRed,
                                    ),
                                  )
                                : null,
                          ).animate().fadeIn(delay: 100.ms * index);
                        },
                      ),
                    ),
                    SizedBox(height: 24.h),
                  ],
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
} 