import 'package:agilemeets/core/errors/app_exception.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../logic/cubits/auth/auth_cubit.dart';
import '../logic/cubits/auth/auth_state.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/auth_header.dart';
import '../utils/navigation_mixin.dart';
import 'package:agilemeets/widgets/error_handlers/form_validation_errors.dart';
import 'package:agilemeets/extensions/context_extensions.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with NavigationMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthCubit, AuthState>(
        listenWhen: (previous, current) => 
            previous.status != current.status && 
            current.status != AuthStatus.loading && 
            current.status != AuthStatus.validationError,
        listener: (context, state) {
          switch (state.status) {
            case AuthStatus.authenticated:
              Navigator.pushReplacementNamed(context, '/shell');
              break;
            case AuthStatus.emailVerificationRequired:
              Navigator.pushReplacementNamed(context, '/verify-email');
              break;
            case AuthStatus.organizationCreationRequired:
              Navigator.pushReplacementNamed(context, '/create-organization');
              break;
            case AuthStatus.profileCompletionRequired:
              Navigator.pushReplacementNamed(context, '/complete-profile');
              break;
            case AuthStatus.error:
              context.showErrorSnackbar(
                BusinessException(
                  state.error ?? 'An error occurred',
                  code: 'LOGIN_ERROR',
                ),
              );
              break;
            default:
              break;
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  children: [
                    SizedBox(height: 40.h),
                   const AuthHeader(
  showLogo: true,
  title: 'Welcome Back',
                      subtitle: 'Sign in to continue',
                    ),

                    SizedBox(height: 32.h),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          CustomTextField(
                            controller: _emailController,
                            label: 'Email',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            animationIndex: 0,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              return null;
                            },
                          ),
                          if (_hasFieldErrors(state, 'email'))
                            FormValidationErrors(
                              errors: state.validationErrors!,
                              fieldName: 'email',
                            ),
                          SizedBox(height: 16.h),
                          CustomTextField(
                            controller: _passwordController,
                            label: 'Password',
                            prefixIcon: Icons.lock_outline_rounded,
                            obscureText: _obscurePassword,
                            animationIndex: 1,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                size: 20.w,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                          if (_hasFieldErrors(state, 'password'))
                            FormValidationErrors(
                              errors: state.validationErrors!,
                              fieldName: 'password',
                            ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24.h),
                    CustomButton(
                      onPressed: state.status == AuthStatus.loading
                          ? null
                          : _handleLogin,
                      text: 'Sign In',
                      isLoading: state.status == AuthStatus.loading,
                      animationDelay: 400,
                    ),

                    SizedBox(height: 16.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Don\'t have an account?',
                          style: TextStyle(fontSize: 14.sp),
                        ),
                        TextButton(
                          onPressed: _handleSignUp,
                          child: Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    )
                    .animate()
                    .slideY(begin: 0.3, delay: 500.ms)
                    .fade(),

                    TextButton(
                      onPressed: _handleForgotPassword,
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(fontSize: 14.sp),
                      ),
                    )
                    .animate()
                    .slideY(begin: 0.3, delay: 600.ms)
                    .fade(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleForgotPassword() {
    navigateTo('/forgot-password');
  }

  void _handleSignUp() {
    navigateToAndReplace('/signup');
  }


  bool _hasFieldErrors(AuthState state, String fieldName) {
    if (state.validationErrors == null) return false;
    
    return state.validationErrors!
        .any((e) => e.propertyName.toLowerCase().contains(fieldName.toLowerCase()));
  }

  void _handleLogin() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthCubit>().login(
      _emailController.text,
      _passwordController.text,
    );
  }
}
