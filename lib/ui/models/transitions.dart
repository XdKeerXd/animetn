import 'package:flutter/material.dart';

/// Premium fade + scale page transition for navigating to info pages.
/// Replaces the default MaterialPageRoute slide transition.
class FadeScaleRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadeScaleRoute({required this.page})
      : super(
          transitionDuration: Duration(milliseconds: 350),
          reverseTransitionDuration: Duration(milliseconds: 250),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curvedAnimation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.94, end: 1.0).animate(curvedAnimation),
                child: child,
              ),
            );
          },
        );
}

/// Slide up transition for bottom sheets / modal-like pages.
class SlideUpRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SlideUpRoute({required this.page})
      : super(
          transitionDuration: Duration(milliseconds: 350),
          reverseTransitionDuration: Duration(milliseconds: 250),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return SlideTransition(
              position: Tween<Offset>(
                begin: Offset(0, 0.08),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: FadeTransition(
                opacity: curvedAnimation,
                child: child,
              ),
            );
          },
        );
}

/// Shared axis horizontal transition (good for tab-like navigation).
class SharedAxisRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final bool forward;

  SharedAxisRoute({required this.page, this.forward = true})
      : super(
          transitionDuration: Duration(milliseconds: 300),
          reverseTransitionDuration: Duration(milliseconds: 250),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return SlideTransition(
              position: Tween<Offset>(
                begin: Offset(forward ? 0.05 : -0.05, 0),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: FadeTransition(
                opacity: curvedAnimation,
                child: child,
              ),
            );
          },
        );
}
