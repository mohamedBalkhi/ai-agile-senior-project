import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as dev;

class NavigationService {
  static const platform = MethodChannel('com.agilemeets.mobile/navigation');
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  NavigationService() {
    _setupMethodChannel();
  }

  void _setupMethodChannel() {
    platform.setMethodCallHandler((call) async {
      if (call.method == 'openRecordingScreen') {
        final meetingId = call.arguments as String;
        openRecordingScreen(meetingId);
      }
    });
  }

  Future<void> openRecordingScreen(String meetingId) async {
    try {
      dev.log('Navigating to recording screen for meeting: $meetingId', 
        name: 'NavigationService');
      
      final navigator = navigatorKey.currentState;
      if (navigator != null) {
        // Replace this with your actual route name and arguments
        navigator.pushNamed(
          '/meeting/recording',
          arguments: meetingId,
        );
      }
    } catch (e) {
      dev.log('Error navigating to recording screen: $e',
        name: 'NavigationService',
        error: e
      );
    }
  }

  Future<void> openMeetingDetailsScreen(String meetingId) async {
    try {
      dev.log('Navigating to meeting details screen for meeting: $meetingId', 
        name: 'NavigationService');
      
      final navigator = navigatorKey.currentState;
      if (navigator != null) {
        navigator.pushNamed(
          '/meeting/details',
          arguments: meetingId,
        );
      }
    } catch (e) {
      dev.log('Error navigating to meeting details screen: $e',
        name: 'NavigationService',
        error: e
      );
    }
  }

  Future<dynamic> navigateTo(String routeName, {Object? arguments}) async {
    try {
      final navigator = navigatorKey.currentState;
      if (navigator != null) {
        return navigator.pushNamed(routeName, arguments: arguments);
      }
    } catch (e) {
      dev.log('Error navigating to $routeName: $e',
        name: 'NavigationService',
        error: e
      );
    }
    return null;
  }

  void goBack() {
    try {
      final navigator = navigatorKey.currentState;
      if (navigator != null && navigator.canPop()) {
        navigator.pop();
      }
    } catch (e) {
      dev.log('Error going back: $e',
        name: 'NavigationService',
        error: e
      );
    }
  }

  Future<dynamic> navigateToAndRemoveUntil(String routeName, {Object? arguments}) async {
    try {
      final navigator = navigatorKey.currentState;
      if (navigator != null) {
        return navigator.pushNamedAndRemoveUntil(
          routeName,
          (route) => false,
          arguments: arguments,
        );
      }
    } catch (e) {
      dev.log('Error navigating to $routeName and removing until: $e',
        name: 'NavigationService',
        error: e
      );
    }
    return null;
  }

  Future<dynamic> navigateToAndReplace(String routeName, {Object? arguments}) async {
    try {
      final navigator = navigatorKey.currentState;
      if (navigator != null) {
        return navigator.pushReplacementNamed(
          routeName,
          arguments: arguments,
        );
      }
    } catch (e) {
      dev.log('Error navigating to $routeName and replacing: $e',
        name: 'NavigationService',
        error: e
      );
    }
    return null;
  }
} 