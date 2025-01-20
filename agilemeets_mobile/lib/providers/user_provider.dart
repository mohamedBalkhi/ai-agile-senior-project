import 'package:flutter/material.dart';
import '../models/decoded_token.dart';

class UserProvider extends InheritedWidget {
  final DecodedToken? decodedToken;

  const UserProvider({
    super.key,
    required this.decodedToken,
    required super.child,
  });

  static UserProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<UserProvider>();
  }

  @override
  bool updateShouldNotify(UserProvider oldWidget) {
    return decodedToken != oldWidget.decodedToken;
  }
}
