import 'package:agilemeets/logic/cubits/auth/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../logic/cubits/organization/organization_cubit.dart';
import '../logic/cubits/organization/organization_state.dart';
import '../logic/cubits/auth/auth_cubit.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../utils/app_theme.dart';

class CreateOrganizationScreen extends StatefulWidget {
  const CreateOrganizationScreen({super.key});

  @override
  State<CreateOrganizationScreen> createState() => _CreateOrganizationScreenState();
}

class _CreateOrganizationScreenState extends State<CreateOrganizationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      context.read<OrganizationCubit>().createOrganization(
        _nameController.text,
        _descriptionController.text,
        context.read<AuthCubit>().state.userIdentifier!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          BlocBuilder<AuthCubit, AuthState>(
            buildWhen: (previous, current) => !current.isInSignupFlow,
            builder: (context, state) {
              if (!state.isInSignupFlow) {
                return TextButton.icon(
                  onPressed: () {
                    context.read<AuthCubit>().logout();
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Use Different Account'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: PopScope(
        canPop: false,
        child: BlocConsumer<OrganizationCubit, OrganizationState>(
          listener: (context, state) {
            if (state.status == OrganizationStatus.success) {
              context.read<AuthCubit>().checkAuthStatus();
            } else if (state.status == OrganizationStatus.error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error ?? 'An error occurred')),
              );
            }
          },
          builder: (context, state) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BlocBuilder<AuthCubit, AuthState>(
                      buildWhen: (previous, current) => !current.isInSignupFlow,
                      builder: (context, authState) {
                        if (!authState.isInSignupFlow) {
                          final name = authState.decodedToken?.fullName;
                          final email = authState.userEmail;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 16.h),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 12.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: Text(
                                        'Create an organization to start using AgileMeets',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (name != null) ...[
                                SizedBox(height: 24.h),
                                Text(
                                  'Welcome back, $name!',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                              if (email != null) ...[
                                SizedBox(height: 8.h),
                                Text(
                                  email,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                              SizedBox(height: 32.h),
                            ],
                          );
                        }
                        return SizedBox(height: 24.h);
                      },
                    ),
                    Text(
                      'Create Organization',
                      style: AppTheme.headingLarge,
                    ).animate()
                      .fadeIn()
                      .slideY(begin: 0.2, end: 0),
                    SizedBox(height: 8.h),
                    Text(
                      'Set up your team workspace',
                      style: AppTheme.subtitle,
                    ).animate()
                      .fadeIn(delay: 200.ms)
                      .slideY(begin: 0.2, end: 0),
                    SizedBox(height: 32.h),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          CustomTextField(
                            controller: _nameController,
                            label: 'Organization Name',
                            prefixIcon: Icons.domain,
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Please enter organization name';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16.h),
                          CustomTextField(
                            controller: _descriptionController,
                            label: 'Description',
                            prefixIcon: Icons.description_outlined,
                            maxLines: 3,
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Please enter organization description';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ).animate()
                      .fadeIn(delay: 400.ms)
                      .slideY(begin: 0.2, end: 0),
                    SizedBox(height: 24.h),
                    CustomButton(
                      onPressed: state.status == OrganizationStatus.loading
                          ? null
                          : _handleSubmit,
                      text: 'Create Organization',
                      isLoading: state.status == OrganizationStatus.loading,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
