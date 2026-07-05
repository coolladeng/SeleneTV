import 'package:flutter/material.dart';
import 'dart:async';

/// TV 遥控器焦点包装器 - 为任意 Widget 添加焦点导航支持
class TvFocusWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color focusColor;
  final double scale;
  final FocusNode? focusNode;
  final bool autofocus;

  const TvFocusWrapper({
    super.key,
    required this.child,
    this.onTap,
    this.focusColor = const Color(0xFF3498db),
    this.scale = 1.03,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  State<TvFocusWrapper> createState() => _TvFocusWrapperState();
}

class _TvFocusWrapperState extends State<TvFocusWrapper> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.select) {
          widget.onTap?.call();
          return KeyEventResult.handled;
        }
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.enter) {
          widget.onTap?.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isFocused ? widget.scale : 1.0,
          duration: const Duration(milliseconds: 150),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: _isFocused
                  ? Border.all(color: widget.focusColor, width: 2)
                  : null,
              boxShadow: _isFocused
                  ? [BoxShadow(color: widget.focusColor.withOpacity(0.3), blurRadius: 8, spreadRadius: 1)]
                  : null,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
