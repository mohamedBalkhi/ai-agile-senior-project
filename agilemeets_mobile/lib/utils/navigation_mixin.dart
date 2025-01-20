import '../services/navigation_service.dart';

mixin NavigationMixin {
  void navigateTo(String route, {Object? arguments}) {
    NavigationService.navigateTo(route, arguments: arguments);
  }

  void replaceTo(String route, {Object? arguments}) {
    NavigationService.replaceTo(route, arguments: arguments);
  }

  void goBack() {
    NavigationService.goBack();
  }

  void navigateToAndClear(String route, {Object? arguments}) {
    NavigationService.navigateToAndRemoveUntil(route, arguments: arguments);
  }
} 