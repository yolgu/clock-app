import 'dart:async';

import 'package:flutter/widgets.dart';

typedef VisibleClockBuilder =
    Widget Function(BuildContext context, DateTime now);

final class VisibleClockTicker extends StatefulWidget {
  const VisibleClockTicker({
    required this.builder,
    this.now = DateTime.now,
    this.onBecameVisible,
    this.notifyOnInitialVisibility = true,
    this.interval = const Duration(seconds: 1),
    super.key,
  });

  final VisibleClockBuilder builder;
  final DateTime Function() now;
  final VoidCallback? onBecameVisible;
  final bool notifyOnInitialVisibility;
  final Duration interval;

  @override
  State<VisibleClockTicker> createState() => _VisibleClockTickerState();
}

final class _VisibleClockTickerState extends State<VisibleClockTicker>
    with WidgetsBindingObserver {
  late final ValueNotifier<DateTime> _current = ValueNotifier<DateTime>(
    widget.now(),
  );
  Timer? _timer;
  bool _active = false;
  bool _hasActivated = false;
  int _activationGeneration = 0;
  bool _routeVisible = true;
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lifecycle =
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeVisible = TickerMode.valuesOf(context).enabled;
    _updateActivity();
  }

  @override
  void didUpdateWidget(VisibleClockTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.interval != oldWidget.interval || widget.now != oldWidget.now) {
      _deactivate();
      _updateActivity();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
    _updateActivity();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DateTime>(
      valueListenable: _current,
      builder: (BuildContext context, DateTime now, Widget? child) {
        return widget.builder(context, now);
      },
    );
  }

  void _updateActivity() {
    final bool shouldBeActive =
        _routeVisible && _lifecycle == AppLifecycleState.resumed;
    if (shouldBeActive == _active) {
      return;
    }
    if (shouldBeActive) {
      _activate();
    } else {
      _deactivate();
    }
  }

  void _activate() {
    _active = true;
    _activationGeneration += 1;
    final int generation = _activationGeneration;
    _sample();
    if (_hasActivated || widget.notifyOnInitialVisibility) {
      WidgetsBinding.instance.addPostFrameCallback((Duration elapsed) {
        if (mounted && _active && generation == _activationGeneration) {
          widget.onBecameVisible?.call();
        }
      });
    }
    _hasActivated = true;
    _timer = Timer.periodic(widget.interval, (_) => _sample());
  }

  void _deactivate() {
    _active = false;
    _activationGeneration += 1;
    _timer?.cancel();
    _timer = null;
  }

  void _sample() {
    _current.value = widget.now();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _deactivate();
    _current.dispose();
    super.dispose();
  }
}
