import 'package:agilemeets/logic/cubits/auth/auth_cubit.dart';
import 'package:agilemeets/logic/cubits/auth/auth_state.dart';
import 'package:agilemeets/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../../logic/cubits/profile/profile_cubit.dart';
import '../../logic/cubits/profile/profile_state.dart';
import '../../data/models/profile/complete_profile_dto.dart';
import '../../data/models/country_dto.dart';
import '../../data/repositories/country_repository.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/auth_header.dart';

class CompleteProfileScreen extends StatefulWidget {
  final bool isNewUser;
  
  const CompleteProfileScreen({
    super.key,
    this.isNewUser = true,
  });

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  DateTime? _selectedDate;
  CountryDTO? _selectedCountry;
  List<CountryDTO> _countries = [];
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _loadCountries();
    if (!widget.isNewUser) {
      _loadExistingProfile();
    }
  }

  Future<void> _loadExistingProfile() async {
    final userId = context.read<AuthCubit>().state.userIdentifier;
    if (userId != null) {
      final profileCubit = context.read<ProfileCubit>();
      await profileCubit.loadProfile(userId);
      
      // Pre-fill form with existing data
      final profile = profileCubit.state.profile;
      if (profile != null) {
        setState(() {
          _nameController.text = profile.fullName ?? '';
          if (profile.birthDate != null) {
            _selectedDate = DateTime(
              profile.birthDate!.year,
              profile.birthDate!.month,
              profile.birthDate!.day,
            );
          }
          // Find and set the country
          if (_countries.isNotEmpty) {
            _selectedCountry = _countries.firstWhere(
              (country) => country.name == profile.countryName,
              orElse: () => _countries.first,
            );
          }
        });
      }
    }
  }

  Future<void> _loadCountries() async {
    final countryRepository = CountryRepository();
    final countries = await countryRepository.getAllCountries();
    setState(() {
      _countries = countries;
    });
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      final dto = CompleteProfileDTO(
        fullName: _nameController.text,
        birthDate: _selectedDate,
        countryId: _selectedCountry!.id,
        password: widget.isNewUser ? _passwordController.text : null,
      );

      if (widget.isNewUser) {
        context.read<ProfileCubit>().completeProfile(dto);
      } else {
        final userId = context.read<AuthCubit>().state.userIdentifier;
        context.read<ProfileCubit>().updateProfile(dto.toUpdateProfileDTO(), userId!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.isNewUser,
      ),
      body: PopScope(
        canPop: !widget.isNewUser,
        child: BlocConsumer<ProfileCubit, ProfileState>(
          listener: (context, state) {
            if (state.status == ProfileStatus.completed) {
              if (widget.isNewUser) {
                context.read<AuthCubit>().checkAuthStatus();
              } else {
                // Show success message before popping
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile updated successfully'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppTheme.successGreen,
                  ),
                );
                Navigator.pop(context); // Return to profile screen
              }
            } else if (state.status == ProfileStatus.error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error ?? 'An error occurred'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else if (state.status == ProfileStatus.validationError) {
              // Show validation errors
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please check the form for errors'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state.status == ProfileStatus.loading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.isNewUser) ...[
                      BlocBuilder<AuthCubit, AuthState>(
                        buildWhen: (previous, current) => !current.isInSignupFlow,
                        builder: (context, authState) {
                          if (!authState.isInSignupFlow) {
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
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                      SizedBox(width: 12.w),
                                      Expanded(
                                        child: Text(
                                          'Complete your profile to start using AgileMeets',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (email != null) ...[
                                  SizedBox(height: 24.h),
                                  Text(
                                    'Welcome, $email!',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                                // if (email != null) ...[
                                //   SizedBox(height: 8.h),
                                //   Text(
                                //     email,
                                //     style: theme.textTheme.bodyMedium?.copyWith(
                                //       color: theme.colorScheme.primary,
                                //       fontWeight: FontWeight.bold,
                                //     ),
                                //   ),
                                // ],
                                SizedBox(height: 24.h),
                              ],
                            );
                          }

                          return const SizedBox.shrink();
                        },
                      ),
                      const AuthHeader(
                        showLogo: false,
                        title: 'Complete Your Profile',
                        subtitle: 'Please provide your information',
                      ).animate().slideY(
                        begin: 0.3,
                        duration: 400.ms,
                        curve: Curves.easeOut,
                      ).fade(),
                      
                      SizedBox(height: 32.h),
                    ],
                    if(!widget.isNewUser) ...[
                    const AuthHeader(
                      showLogo: false,
                      title: 'Edit Your Profile',
                      subtitle: 'Edit your information',
                    ).animate().slideY(
                      begin: 0.3,
                      duration: 400.ms,
                      curve: Curves.easeOut,
                    ).fade(),
                      SizedBox(height: 32.h),
                    ],
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _nameController,
                            label: 'Full Name',
                            icon: Icons.person_outline_rounded,
                            index: 0,
                          ),
                          
                          SizedBox(height: 16.h),
                          
                          if (widget.isNewUser) ...[
                            _buildPasswordField(),
                            SizedBox(height: 16.h),
                          ],
                          
                          _buildDatePicker(),
                          
                          SizedBox(height: 16.h),
                          
                          _buildCountryDropdown(),
                          
                          SizedBox(height: 32.h),
                          
                          CustomButton(
                            onPressed: state.status == ProfileStatus.updating
                              ? null
                              : _handleSubmit,
                            text: widget.isNewUser ? 'Complete Profile' : 'Save Changes',
                            isLoading: state.status == ProfileStatus.updating,
                          ),
                        ].animate(
                          interval: 50.ms,
                        ).slideY(
                          begin: 0.3,
                          duration: 400.ms,
                          curve: Curves.easeOut,
                        ).fade(),
                      ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required int index,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20.w),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      style: TextStyle(fontSize: 16.sp),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'This field is required';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: Icon(Icons.lock_outline_rounded, size: 20.w),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
            size: 20.w,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      style: TextStyle(fontSize: 16.sp),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  Widget _buildDatePicker() {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate ?? DateTime(2000, 1, 1),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                dialogBackgroundColor: theme.scaffoldBackgroundColor,
              ),
              child: child!,
            );
          },
        );
        if (picked != null && picked != _selectedDate) {
          setState(() {
            _selectedDate = picked;
          });
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Birth Date',
          prefixIcon: Icon(Icons.calendar_today_outlined, size: 20.w),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: Text(
          _selectedDate == null
              ? 'Select Date'
              : DateFormat('MMM dd, yyyy').format(_selectedDate!),
          style: TextStyle(
            fontSize: 16.sp,
            color: _selectedDate == null
                ? theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)
                : theme.textTheme.bodyMedium?.color,
          ),
        ),
      ),
    );
  }

  Widget _buildCountryDropdown() {
    final theme = Theme.of(context);
    
    return DropdownButtonFormField<CountryDTO>(
      value: _selectedCountry,
      decoration: InputDecoration(
        labelText: 'Country',
        prefixIcon: Icon(Icons.public_outlined, size: 20.w),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      style: TextStyle(fontSize: 16.sp),
      items: _countries.map((CountryDTO country) {
        return DropdownMenuItem<CountryDTO>(
          value: country,
          child: Text(
            country.name ?? 'Unknown',
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
        );
      }).toList(),
      onChanged: (CountryDTO? newValue) {
        setState(() {
          _selectedCountry = newValue;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Please select a country';
        }
        return null;
      },
      icon: Icon(Icons.arrow_drop_down, size: 24.w),
      isExpanded: true,
      dropdownColor: theme.scaffoldBackgroundColor,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}