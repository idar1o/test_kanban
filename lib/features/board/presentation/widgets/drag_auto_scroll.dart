import 'dart:async';

import 'package:flutter/material.dart';

class DragAutoScrollRegion extends StatefulWidget {
  const DragAutoScrollRegion({
    super.key,
    required this.controller,
    required this.axis,
    required this.child,
    this.edgeSize = 70,
    this.maxSpeed = 14,
  });

  final ScrollController controller;
  final Axis axis;
  final Widget child;
  final double edgeSize;
  final double maxSpeed;

  @override
  State<DragAutoScrollRegion> createState() => _DragAutoScrollRegionState();
}

class _DragAutoScrollRegionState extends State<DragAutoScrollRegion> {
  Timer? _timer;
  double _speed = 0;

  void _onPointerMove(PointerMoveEvent event) {
    _updateSpeed(event.position);
  }

  void _onPointerUp(PointerUpEvent _) => _stop();
  void _onPointerCancel(PointerCancelEvent _) => _stop();

  void _updateSpeed(Offset globalPointer) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final local = box.globalToLocal(globalPointer);
    final size = box.size;

    final isVertical = widget.axis == Axis.vertical;
    final before = isVertical ? local.dy : local.dx;
    final total = isVertical ? size.height : size.width;
    final after = total - before;

    final edge = widget.edgeSize;
    double speed = 0;
    if (before > 0 && before < edge) {
      speed = -((edge - before) / edge) * widget.maxSpeed;
    } else if (after > 0 && after < edge) {
      speed = ((edge - after) / edge) * widget.maxSpeed;
    }

    _speed = speed;
    if (speed.abs() > 0.1) {
      _startTimer();
    } else {
      _stopTimer();
    }
  }

  void _startTimer() {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!widget.controller.hasClients) return;
      final pos = widget.controller.position;
      final next =
          (pos.pixels + _speed).clamp(pos.minScrollExtent, pos.maxScrollExtent);
      if (next != pos.pixels) widget.controller.jumpTo(next);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _stop() {
    _stopTimer();
    _speed = 0;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: widget.child,
    );
  }
}
