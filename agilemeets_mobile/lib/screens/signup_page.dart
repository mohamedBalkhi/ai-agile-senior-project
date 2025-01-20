// Sign up Page

import 'package:agilemeets/core/errors/app_exception.dart';
import 'package:agilemeets/core/errors/validation_error.dart';
import 'package:agilemeets/widgets/auth_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart' show DateFormat;
import '../logic/cubits/auth/auth_cubit.dart';
import '../logic/cubits/auth/auth_state.dart';
import '../data/models/sign_up_dto.dart';
import '../data/models/country_dto.dart';
import '../data/repositories/country_repository.dart';
import 'login_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:agilemeets/widgets/error_handlers/form_validation_errors.dart';
import 'package:agilemeets/extensions/context_extensions.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  DateTime? _selectedDate;
  CountryDTO? _selectedCountry;

  List<CountryDTO> _countries = [];

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    final countryRepository = CountryRepository();
    final countries = await countryRepository.getAllCountries();
    setState(() {
      _countries = countries;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _getFieldError(AuthState state, String fieldName) {
    if (state.validationErrors == null) return null;
    
    final errors = state.validationErrors!
        .where((e) => e.propertyName.toLowerCase().contains(fieldName.toLowerCase()))
        .map((e) => e.errorMessage)
        .toList();
        
    return errors.isEmpty ? null : errors.first;
  }

  bool _hasFieldErrors(AuthState state, String fieldName) {
    if (state.validationErrors == null) return false;
    
    return state.validationErrors!
        .any((e) => e.propertyName.toLowerCase().contains(fieldName.toLowerCase()));
  }

  void _handleSignUp() {
    if (!_formKey.currentState!.validate()) return;

    final signUpDTO = SignUpDTO(
      fullName: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      birthDate: _selectedDate!,
      countryIdCountry: _selectedCountry?.id,
    );

    context.read<AuthCubit>().signUp(signUpDTO);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.emailVerificationRequired) {
            Navigator.pushReplacementNamed(context, '/verify-email');
          } else if (state.status == AuthStatus.error) {
            context.showErrorSnackbar(
              const BusinessException(
                'An error occurred',
                code: 'SIGNUP_ERROR',
              ),
              onRetry: () => _handleSignUp(),
            );
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  children: [
                    // Welcome Section with Animation
                    Container(
                      padding: EdgeInsets.only(bottom: 16.h,top: 5.h),
                      child: const Column(
                        children: [
                         AuthHeader(
                          showLogo: true,
                          title: 'Create an Account',
                          subtitle: 'Join AgileMeets',
                          spacing: 8,
                        ),
                        // ... rest of welcome section
                      ],
                      ),
                    ),

                    // Form Section with Staggered Animation
                    Form(
                      key: _formKey,
                      child: Padding(
                        padding: EdgeInsets.all(12.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildAnimatedTextField(
                              controller: _nameController,
                              label: 'Full Name',
                              icon: Icons.person_outline_rounded,
                              errorText: _getFieldError(state, 'fullName'),
                              index: 0,
                            ),
                            
                            SizedBox(height: 12.h),
                            _buildTextField(
                              controller: _emailController,
                              label: 'Email',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              errorText: _getFieldError(state, 'email'),
                            ),
                           
                            SizedBox(height: 12.h),
                            _buildPasswordField(),
                       
                            SizedBox(height: 12.h),
                            _buildConfirmPasswordField(),
                            SizedBox(height: 12.h),
                            _buildDatePicker(),
                            SizedBox(height: 12.h),
                            _buildCountryDropdown(),
                          ].animate(
                            interval: 50.ms,
                          ).slideY(
                            begin: 0.3,
                            duration: 400.ms,
                            curve: Curves.easeOut,
                          ).fade(),
                        ),
                      )
                      .animate()
                      .scale(delay: 200.ms, duration: 400.ms)
                      .fade(),
                    ),

                    // Action Button with Animation
                    SizedBox(height: 12.h),
                    ElevatedButton(
                      onPressed: state.status == AuthStatus.loading
                          ? null
                          : _handleSignUp,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: state.status == AuthStatus.loading
                          ? SizedBox(
                              width: 24.w,
                              height: 24.w,
                              child: CircularProgressIndicator(strokeWidth: 2.w),
                            )
                          : Text('Join Now', style: TextStyle(fontSize: 16.sp)),
                    )
                    .animate()
                    .scale(delay: 400.ms)
                    .fade(),

                    // Sign In Link
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account?',
                            style: TextStyle(fontSize: 14.sp),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            ),
                            child: Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper methods for form fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? errorText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20.w),
        errorText: errorText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      style: TextStyle(fontSize: 16.sp),
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

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        labelText: 'Confirm Password',
        prefixIcon: Icon(Icons.lock_outline_rounded, size: 20.w),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      style: TextStyle(fontSize: 16.sp),
      validator: (value) {
        if (value != _passwordController.text) {
          return 'Passwords do not match';
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
                dialogBackgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                ? theme.textTheme.bodyMedium?.color?.withOpacity(0.5)
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

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required int index,
    TextInputType? keyboardType,
    String? errorText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20.w),
        errorText: errorText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      style: TextStyle(fontSize: 16.sp),
    ).animate(
      delay: (100 * index).ms,
    ).slideX(
      begin: 0.2,
      duration: 400.ms,
      curve: Curves.easeOut,
    ).fade();
  }
}
