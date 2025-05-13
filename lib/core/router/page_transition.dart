import 'package:flutter/material.dart';

enum TransitionType {

  slideRight,

  slideLeft,

  slideUp,

  slideDown,

  fade,

  scale,

  rotate,

  fadeAndScale,

  fadeAndSlideUp,

  fadeAndSlideRight,

  fadeAndSlideLeft,

  none,
}

/// 自定义页面路由转换类
class PageTransition extends PageRouteBuilder {
  final Widget child;
  final TransitionType type;
  final Curve curve;
  final Alignment alignment;
  final Duration duration;

  PageTransition({
    required this.child,
    this.type = TransitionType.slideRight,
    this.curve = Curves.easeInOut,
    this.alignment = Alignment.center,
    this.duration = const Duration(milliseconds: 300),
    RouteSettings? settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: duration,
          settings: settings,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            switch (type) {
              case TransitionType.slideRight:
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: animation, curve: curve),
                  ),
                  child: child,
                );
              case TransitionType.slideLeft:
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(-1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: animation, curve: curve),
                  ),
                  child: child,
                );
              case TransitionType.slideUp:
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: animation, curve: curve),
                  ),
                  child: child,
                );
              case TransitionType.slideDown:
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -1),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: animation, curve: curve),
                  ),
                  child: child,
                );
              case TransitionType.fade:
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              case TransitionType.scale:
                return ScaleTransition(
                  scale: animation,
                  alignment: alignment,
                  child: child,
                );
              case TransitionType.rotate:
                return RotationTransition(
                  turns: animation,
                  alignment: alignment,
                  child: child,
                );
              case TransitionType.fadeAndScale:
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                      CurvedAnimation(parent: animation, curve: curve),
                    ),
                    child: child,
                  ),
                );
              case TransitionType.fadeAndSlideUp:
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(parent: animation, curve: curve),
                    ),
                    child: child,
                  ),
                );
              case TransitionType.fadeAndSlideRight:
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.3, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(parent: animation, curve: curve),
                    ),
                    child: child,
                  ),
                );
              case TransitionType.fadeAndSlideLeft:
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(-0.3, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(parent: animation, curve: curve),
                    ),
                    child: child,
                  ),
                );
              case TransitionType.none:
              default:
                return child;
            }
          },
        );
}

/// 屏幕切换方向
enum NavDirection { forward, backward }

/// 基于导航方向决定页面转场效果
Route createRoute(Widget page,
    {NavDirection direction = NavDirection.forward,
    RouteSettings? settings,
    TransitionType? forwardTransition,
    TransitionType? backwardTransition}) {
  // 设置默认的转场效果
  final defaultForwardTransition = TransitionType.fadeAndSlideRight;
  final defaultBackwardTransition = TransitionType.fadeAndSlideLeft;

  // 使用提供的转场效果或默认值
  TransitionType type = direction == NavDirection.forward
      ? (forwardTransition ?? defaultForwardTransition)
      : (backwardTransition ?? defaultBackwardTransition);

  return PageTransition(
    child: page,
    type: type,
    settings: settings,
  );
}
