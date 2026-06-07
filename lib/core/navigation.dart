import 'package:flutter/material.dart';

class SmoothNavigator {
  SmoothNavigator._();

  static const _duration = Duration(milliseconds: 350);
  static const _curve = Cubic(0.05, 0.7, 0.1, 1.0);

  static Future<T?> push<T>(BuildContext context, Widget page) {
    return Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: _curve,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: _duration,
      ),
    );
  }

  static Future<T?> pushReplacement<T, R>(
      BuildContext context, Widget page) {
    return Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: _curve,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: _duration,
      ),
    );
  }

  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.pop(context, result);
  }
}
