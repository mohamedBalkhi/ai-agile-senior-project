import '../services/navigation_service.dart';
import '../core/service_locator.dart';

mixin NavigationMixin {
  NavigationService get _navigationService => getIt<NavigationService>();

  Future<void> navigateTo(String route, {Object? arguments}) async {
    await _navigationService.navigateTo(route, arguments: arguments);
  }

  Future<void> navigateToAndReplace(String route, {Object? arguments}) async {
    await _navigationService.navigateToAndReplace(route, arguments: arguments);
  }

  void goBack() {
    _navigationService.goBack();
  }

  Future<void> navigateToAndClear(String route, {Object? arguments}) async {
    await _navigationService.navigateToAndRemoveUntil(route, arguments: arguments);
  }
} 