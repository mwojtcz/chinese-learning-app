import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum NotebookFormat {
  bold,
  italic,
  underline,
  highlight,
  showPinyin,
  hidePinyin,
  showTranslation,
  hideTranslation,
  clear
}

/// Keeps the page toolbar connected to the last selected text, even when the
/// toolbar itself receives focus.
class NotebookEditingController extends ChangeNotifier {
  Object? _owner;
  TextSelection selection = const TextSelection.collapsed(offset: -1);
  Future<void> Function(NotebookFormat)? _apply;
  bool _disposed = false;
  bool _pending = false;

  bool get hasSelection => selection.isValid && !selection.isCollapsed;

  void attach(Object owner, TextSelection value,
      Future<void> Function(NotebookFormat) apply) {
    final changed = !identical(_owner, owner) || selection != value;
    _owner = owner;
    selection = value;
    _apply = apply;
    if (changed) _notify();
  }

  void detach(Object owner) {
    if (!identical(_owner, owner)) return;
    _owner = null;
    _apply = null;
    selection = const TextSelection.collapsed(offset: -1);
    _notify();
  }

  Future<void> apply(NotebookFormat format) async {
    if (hasSelection) await _apply?.call(format);
  }

  void _notify() {
    if (_pending || _disposed) return;
    _pending = true;
    scheduleMicrotask(() {
      _pending = false;
      if (!_disposed) notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _apply = null;
    super.dispose();
  }
}
