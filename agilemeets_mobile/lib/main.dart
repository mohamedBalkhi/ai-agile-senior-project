import 'dart:io';

import 'package:agilemeets/data/api/api_client.dart';
import 'package:agilemeets/data/repositories/profile_repository.dart';
import 'package:agilemeets/data/repositories/project_repository.dart';
import 'package:agilemeets/logic/cubits/auth/auth_state.dart';
import 'package:agilemeets/logic/cubits/profile/profile_cubit.dart';
import 'package:agilemeets/logic/cubits/project/project_cubit.dart';
import 'package:agilemeets/screens/forgot_password_screen.dart';
import 'package:agilemeets/screens/meeting/project_meetings_screen.dart';
import 'package:agilemeets/screens/onboarding_screen.dart';
import 'package:agilemeets/screens/organization/member_management_screen.dart';
import 'package:agilemeets/screens/organization/organization_dashboard_screen.dart';
import 'package:agilemeets/screens/profile/complete_profile_screen.dart';
import 'package:agilemeets/screens/profile_screen.dart';
import 'package:agilemeets/screens/project/project_details_screen.dart';
import 'package:agilemeets/screens/reset_password_verification_screen.dart';
import 'package:agilemeets/screens/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/organization_repository.dart';
import 'logic/cubits/auth/auth_cubit.dart';
import 'logic/cubits/organization/organization_cubit.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_page.dart';
import 'screens/email_verification_screen.dart';
import 'screens/create_organization_screen.dart';
import 'utils/app_theme.dart';
import 'dart:developer' as developer;
import 'utils/route_guard.dart';
import 'widgets/shared/loading_overlay.dart';
import 'services/navigation_service.dart';
import 'data/repositories/requirements_repository.dart';
import 'logic/cubits/requirements/requirements_cubit.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'package:agilemeets/data/repositories/meeting_repository.dart';
import 'package:agilemeets/logic/cubits/meeting/meeting_cubit.dart';
import 'package:agilemeets/logic/cubits/timezone/timezone_cubit.dart';
import 'package:agilemeets/data/repositories/timezone_repository.dart';
import 'package:agilemeets/screens/meeting/meeting_details_screen.dart';
import 'package:agilemeets/screens/meeting/meeting_session_screen.dart';
import 'package:agilemeets/screens/meeting/create_meeting_screen.dart';
import 'utils/route_constants.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> _initializeAndroidAudioSettings() async {
  await webrtc.WebRTC.initialize(options: {
    'androidAudioConfiguration': webrtc.AndroidAudioConfiguration.media.toMap(),
  });
  webrtc.Helper.setAndroidAudioConfiguration(
    webrtc.AndroidAudioConfiguration.media,
  );
}
Future<void> _checkPermissions() async {
  var status = await Permission.bluetooth.request();
  if (status.isPermanentlyDenied) {
    print('Bluetooth Permission disabled');
  }
  status = await Permission.bluetoothConnect.request();
  if (status.isPermanentlyDenied) {
    print('Bluetooth Connect Permission disabled');
  }
}

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Set system UI mode to immersive sticky
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );
    
    await _initializeAndroidAudioSettings();
    await _checkPermissions();

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Initialize Notification Service
    await NotificationService().initialize();
    
    // Initialize ApiClient
    HttpOverrides.global = MyHttpOverrides();
    final apiClient = ApiClient();
    await apiClient.initialize();
    
    runApp(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) => AuthCubit(AuthRepository()),
              ),
              BlocProvider(create: (context) => ProfileCubit(ProfileRepository())),
              BlocProvider(create: (context) => OrganizationCubit(OrganizationRepository())),
              BlocProvider(create: (context) => ProjectCubit(ProjectRepository())),
              BlocProvider(create: (context) => RequirementsCubit(RequirementsRepository())),
              BlocProvider<MeetingCubit>(
                create: (context) => MeetingCubit(
                  MeetingRepository(),
                ),
              ),
              BlocProvider(
                create: (context) => TimeZoneCubit(TimeZoneRepository()),
              ),
            ],
            child: BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                return MaterialApp(
                  title: 'AgileMeets',
                  theme: AppTheme.lightTheme,
                  themeMode: ThemeMode.system,
                  navigatorKey: NavigationService.navigatorKey,
                  builder: (context, child) {
                    return child ?? const SizedBox();
                  },
                  initialRoute: '/',
                  onGenerateRoute: (settings) {
                    return MaterialPageRoute(
                      builder: (context) => _buildRoute(settings, state.status),
                      settings: settings,
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  } catch (e, stackTrace) {
    developer.log(
      'Fatal error during app initialization',
      name: 'Main',
      error: e,
      stackTrace: stackTrace,
    );
  }
}

Widget _buildRoute(RouteSettings settings, AuthStatus currentStatus) {
  switch (settings.name) {
    // Initial Route - No Guard needed
    case '/':
      return const SplashScreen();

    case '/onboarding':
      return const OnboardingScreen();

    // Auth Routes - Only accessible when unauthenticated
    case '/login':
      return const RouteGuard(
        primaryStates: [AuthStatus.unauthenticated],
        redirectRoute: '/',
        child: LoginScreen(),
      );

    case '/signup':
      return const RouteGuard(
        primaryStates: [AuthStatus.unauthenticated],
        redirectRoute: '/',
        child: SignUpPage(),
      );

    case '/forgot-password':
      return const RouteGuard(
        primaryStates: [AuthStatus.unauthenticated],
        redirectRoute: '/',
        child: ForgotPasswordScreen(),
      );

    case '/reset-password':
      if (settings.arguments is! String) return const SplashScreen();
      return RouteGuard(
        primaryStates: const [AuthStatus.unauthenticated, AuthStatus.resetCodeSent],
        redirectRoute: '/',
        child: ResetPasswordVerificationScreen(
          email: settings.arguments as String,
        ),
      );

    // Verification Route - Only when email verification is required
    case '/email-verification':
      return const RouteGuard(
        primaryStates: [AuthStatus.emailVerificationRequired],
        redirectRoute: '/',
        child: EmailVerificationScreen(),
      );

    // Organization Creation - Only for admins who need to create org
    case '/create-organization':
      return const RouteGuard(
        primaryStates: [AuthStatus.organizationCreationRequired],
        redirectRoute: '/',
        child: CreateOrganizationScreen(),
      );

    // Profile Completion - Only for non-admin users who need to complete profile
    case '/complete-profile':
      return const RouteGuard(
        primaryStates: [AuthStatus.profileCompletionRequired],
        redirectRoute: '/',
        child: CompleteProfileScreen(),
      );

    // Main App Shell - Only for fully authenticated users
    case '/shell':
      return const RouteGuard(
        primaryStates: [AuthStatus.authenticated],
        secondaryStates: [],
        redirectRoute: '/',
        child: ShellScreen(),
      );

    // Profile Routes - Only for authenticated users
    case '/profile':
      return const RouteGuard(
        primaryStates: [AuthStatus.authenticated],
        redirectRoute: '/',
        child: ProfileScreen(),
      );

    case '/profile/edit':
      return const RouteGuard(
        primaryStates: [AuthStatus.authenticated],
        redirectRoute: '/',
        child: CompleteProfileScreen(isNewUser: false),
      );
    case '/organization/dashboard':
      return const RouteGuard(
        primaryStates: [AuthStatus.authenticated],
        redirectRoute: '/',
        child: OrganizationDashboardScreen(),
      );
    case '/organization/members':
      return const RouteGuard(
        primaryStates: [AuthStatus.authenticated],
        redirectRoute: '/',
        child: MemberManagementScreen(),
      );
    case '/organization/roles':
      return const RouteGuard(
        primaryStates: [AuthStatus.authenticated],
        redirectRoute: '/',
        child: MemberManagementScreen(),
      );
    // Project Routes - Only for authenticated users
    case '/project-details':
      if (settings.arguments is! String) return const SplashScreen();
      return RouteGuard(
        primaryStates: const [AuthStatus.authenticated],
        redirectRoute: '/',
        child: ProjectDetailsScreen(
          projectId: settings.arguments as String,
        ),
      );
    // Meeting Routes - Only for authenticated users
    case '/meetings':
      return RouteGuard(
        primaryStates: const [AuthStatus.authenticated],
        redirectRoute: '/login',
        child: ProjectMeetingsScreen(
          projectId: settings.arguments as String,
        ),
      );

    case '/meetings/create':
      return RouteGuard(
        primaryStates: const [AuthStatus.authenticated],
        redirectRoute: '/login',
        child: CreateMeetingScreen(
          projectId: settings.arguments as String,
        ),
      );

    case '/meetings/details/':
      
      return RouteGuard(
        primaryStates: const [AuthStatus.authenticated],
        redirectRoute: '/login',
        child: MeetingDetailsScreen(meetingId: settings.arguments as String),
      );

    case '/meetings/session/':
      return RouteGuard(
        primaryStates: const [AuthStatus.authenticated],
        redirectRoute: '/login',
        child: MeetingSessionScreen(meetingId: settings.arguments as String),
      );
    // Default fallback
    default:
      return const SplashScreen();
  }
}
