import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

class HeaderVisibilityController extends ValueNotifier<double> {
  HeaderVisibilityController() : super(0.0);
  double headerHeight = 56.0;

  Ticker? _ticker;
  double _settleFrom = 0;
  double _settleTo = 0;
  static const Duration _settleDuration = Duration(milliseconds: 180);

  void attachTicker(TickerProvider provider) {
    _ticker?.dispose();
    _ticker = provider.createTicker(_onTick);
  }

  void _onTick(Duration elapsed) {
    final t = elapsed.inMilliseconds / _settleDuration.inMilliseconds;
    if (t >= 1.0) {
      value = _settleTo;
      _ticker?.stop();
      return;
    }
    // easeOutCubic
    final eased = 1 - (1 - t) * (1 - t) * (1 - t);
    value = _settleFrom + (_settleTo - _settleFrom) * eased;
  }

  void _animateTo(double target) {
    _ticker?.stop();
    _settleFrom = value;
    _settleTo = target;
    _ticker?.start();
  }
  void updateByDelta(double pixelDelta) {
    _ticker?.stop();
    if (headerHeight <= 0) return;
    final next = (value + pixelDelta / headerHeight).clamp(0.0, 1.0);
    value = next;
  }

  void show() => _animateTo(0.0);

  void hide() => _animateTo(1.0);

  void settle() {
    _animateTo(value > 0.5 ? 1.0 : 0.0);
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }
}
class HeaderVisibilityScope extends InheritedWidget {
  final HeaderVisibilityController controller;

  const HeaderVisibilityScope({
    Key? key,
    required this.controller,
    required Widget child,
  }) : super(key: key, child: child);

  static HeaderVisibilityController? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<HeaderVisibilityScope>()
        ?.controller;
  }

  @override
  bool updateShouldNotify(HeaderVisibilityScope oldWidget) =>
      oldWidget.controller != controller;
}

class HeaderScrollListener extends StatefulWidget {
  final Widget child;

  const HeaderScrollListener({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<HeaderScrollListener> createState() => _HeaderScrollListenerState();
}

class _HeaderScrollListenerState extends State<HeaderScrollListener> {
  double _lastOffset = 0;
  bool _dragging = false;

  bool _onNotification(ScrollNotification notification, BuildContext context) {
    final controller = HeaderVisibilityScope.of(context);
    if (controller == null) return false;

    if (notification is ScrollStartNotification) {
      _lastOffset = notification.metrics.pixels;
      _dragging = true;
    } else if (notification is ScrollUpdateNotification) {
      final currentOffset = notification.metrics.pixels;
      if (currentOffset <= 0) {
        controller.show();
        _lastOffset = currentOffset;
        return false;
      }

      final delta = currentOffset - _lastOffset;
      controller.updateByDelta(delta);
      _lastOffset = currentOffset;
    } else if (notification is ScrollEndNotification) {
      _dragging = false;
      controller.settle();
    } else if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.idle && !_dragging) {
        controller.settle();
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (n) => _onNotification(n, context),
      child: widget.child,
    );
  }
}