import 'dart:async';

import 'package:flutter/material.dart';

class TetrisControls extends StatelessWidget {
  final VoidCallback onLeft;
  final VoidCallback onRight;
  final VoidCallback onRotate;
  final VoidCallback onSoftDrop;
  final VoidCallback onHardDrop;

  const TetrisControls({
    super.key,
    required this.onLeft,
    required this.onRight,
    required this.onRotate,
    required this.onSoftDrop,
    required this.onHardDrop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Left/Right controls
          Row(
            children: [
              _ControlButton(
                icon: Icons.arrow_left,
                onPressed: onLeft,
                onLongPress: onLeft,
              ),
              const SizedBox(width: 8),
              _ControlButton(
                icon: Icons.arrow_right,
                onPressed: onRight,
                onLongPress: onRight,
              ),
            ],
          ),

          // Rotate
          _ControlButton(
            icon: Icons.rotate_right,
            onPressed: onRotate,
            size: 64,
          ),

          // Drop controls
          Row(
            children: [
              _ControlButton(
                icon: Icons.arrow_downward,
                onPressed: onSoftDrop,
                onLongPress: onSoftDrop,
              ),
              const SizedBox(width: 8),
              _ControlButton(
                icon: Icons.vertical_align_bottom,
                onPressed: onHardDrop,
                color: Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;
  final double size;
  final Color? color;

  const _ControlButton({
    required this.icon,
    required this.onPressed,
    this.onLongPress,
    this.size = 56,
    this.color,
  });

  @override
  State<_ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<_ControlButton> {
  Timer? _repeatTimer;

  void _startRepeat() {
    if (widget.onLongPress == null) return;
    _repeatTimer = Timer.periodic(
      const Duration(milliseconds: 80),
      (_) => widget.onLongPress!(),
    );
  }

  void _stopRepeat() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => _startRepeat(),
      onLongPressEnd: (_) => _stopRepeat(),
      onLongPressCancel: _stopRepeat,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: ElevatedButton(
          onPressed: widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.color,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Icon(widget.icon, size: 28),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _stopRepeat();
    super.dispose();
  }
}
