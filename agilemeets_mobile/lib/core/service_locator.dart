import 'package:get_it/get_it.dart';
import '../services/recording_manager.dart';
import '../services/recording_storage_service.dart';
import '../services/recording_background_service.dart';
import '../services/recording_notification_manager.dart';
import '../services/navigation_service.dart';
import '../services/upload_background_service.dart';
import '../services/upload_notification_manager.dart';
import '../services/upload_manager.dart';
import '../data/repositories/meeting_repository.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Initialize services
  final storageService = RecordingStorageService();
  await storageService.init();
  
  final backgroundService = RecordingBackgroundService();
  final notificationManager = RecordingNotificationManager();
  
  // Register recording services
  getIt.registerSingleton<RecordingStorageService>(storageService);
  getIt.registerSingleton<RecordingBackgroundService>(backgroundService);
  getIt.registerSingleton<RecordingNotificationManager>(notificationManager);
  
  // Register recording manager with its dependencies
  getIt.registerSingleton<RecordingManager>(RecordingManager(
      getIt<RecordingStorageService>(),
      getIt<RecordingBackgroundService>(),
      getIt<RecordingNotificationManager>(),
  ));
  
  // Register repositories
  getIt.registerSingleton<MeetingRepository>(MeetingRepository());
  
  // Register upload services
  final uploadBackgroundService = UploadBackgroundService();
  final uploadNotificationManager = UploadNotificationManager();
  
  getIt.registerSingleton<UploadBackgroundService>(uploadBackgroundService);
  getIt.registerSingleton<UploadNotificationManager>(uploadNotificationManager);
  
  // Register upload manager with its dependencies
  getIt.registerSingleton<UploadManager>(UploadManager(
      getIt<UploadBackgroundService>(),
      getIt<UploadNotificationManager>(),
      getIt<RecordingStorageService>(),
      getIt<MeetingRepository>(),
  ));
  
  // Register navigation service
  getIt.registerSingleton<NavigationService>(NavigationService());
} 