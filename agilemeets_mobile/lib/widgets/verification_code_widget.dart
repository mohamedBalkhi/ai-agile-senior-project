import 'dart:async';
import 'package:agilemeets/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class VerificationCodeWidget extends StatefulWidget {
  final Function(String) onCompleted;
  final VoidCallback onResendPressed;
  final String? errorText;
  final bool isLoading;
  final String? email;

  const VerificationCodeWidget({
    super.key,
    required this.onCompleted,
    required this.onResendPressed,
    this.errorText,
    this.isLoading = false,
    this.email,
  });

  @override
  State<VerificationCodeWidget> createState() => _VerificationCodeWidgetState();
}

class _VerificationCodeWidgetState extends State<VerificationCodeWidget> {
  late final TextEditingController textEditingController;
  late final StreamController<ErrorAnimationType> errorController;
  int resendTimer = 30;
  Timer? _timer;
  bool canResend = true;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    textEditingController = TextEditingController();
    errorController = StreamController<ErrorAnimationType>.broadcast();
    startTimer();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    if (!_isDisposed) {
      textEditingController.dispose();
    }
    
    try {
      if (!errorController.isClosed) {
        errorController.close();
      }
    } catch (e) {
      debugPrint('Error during disposal: $e');
    }

    super.dispose();
  }

  void startTimer() {
    if (_isDisposed) return;
    
    setState(() {
      canResend = false;
      resendTimer = 30;
    });
    
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      
      if (resendTimer == 0) {
        setState(() => canResend = true);
        timer.cancel();
      } else {
        setState(() => resendTimer--);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisposed) return const SizedBox.shrink();
    
    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PinCodeTextField(
            appContext: context,
            length: 5,
            obscureText: false,
            animationType: AnimationType.fade,
            keyboardType: TextInputType.number,
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(12),
              fieldHeight: 56.h,
              fieldWidth: 52.w,
              activeFillColor: Colors.white,
              inactiveFillColor: Colors.white,
              selectedFillColor: Colors.white,
              activeColor: Theme.of(context).primaryColor,
              inactiveColor: AppTheme.cardBorderGrey,
              selectedColor: Theme.of(context).primaryColor,
              borderWidth: 1.5,
            ),
            backgroundColor: Colors.transparent,
            cursorColor: Theme.of(context).colorScheme.primary,
            animationDuration: const Duration(milliseconds: 200),
            textStyle: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
            ),
            enableActiveFill: true,
            errorAnimationController: errorController,
            controller: textEditingController,
            onCompleted: widget.onCompleted,
            beforeTextPaste: (text) => true,
            onChanged: (_) {},
          ),
          if (widget.errorText != null)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Text(
                widget.errorText!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12.sp,
                ),
              ),
            ),
          SizedBox(height: 24.h),
          if (widget.isLoading)
            CircularProgressIndicator(strokeWidth: 2.w)
          else
            Column(
              children: [
                TextButton.icon(
                  onPressed: canResend ? () {
                    widget.onResendPressed();
                    startTimer();
                  } : null,
                  icon: Icon(
                    Icons.refresh_rounded,
                    size: 18.sp,
                    color: canResend ? null : Theme.of(context).disabledColor,
                  ),
                  label: Text(
                    canResend ? 'Resend Code' : 'Resend in ${resendTimer}s',
                    style: TextStyle(fontSize: 14.sp),
                  ),
                ),
                if (widget.email != null)
                  Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: Text(
                      'Didn\'t receive the code?',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppTheme.textGrey,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}