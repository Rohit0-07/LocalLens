import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ToastType { info, success, error }

class ToastMessage {
  const ToastMessage({
    required this.id,
    required this.message,
    required this.type,
  });

  final int id;
  final String message;
  final ToastType type;
}

final appMessengerProvider = NotifierProvider<AppMessenger, List<ToastMessage>>(
  AppMessenger.new,
);

class AppMessenger extends Notifier<List<ToastMessage>> {
  static const _maxQueue = 3;

  int _nextId = 0;
  final Map<int, Timer> _timers = {};

  @override
  List<ToastMessage> build() {
    ref.onDispose(() {
      for (final timer in _timers.values) {
        timer.cancel();
      }
      _timers.clear();
    });
    return const [];
  }

  void show(String message, {ToastType type = ToastType.info}) {
    if (state.any((toast) => toast.message == message && toast.type == type)) {
      return;
    }
    final id = _nextId++;
    final updated = [
      ...state,
      ToastMessage(id: id, message: message, type: type),
    ];
    state = updated.length > _maxQueue
        ? updated.sublist(updated.length - _maxQueue)
        : updated;
    _timers[id] = Timer(
      Duration(seconds: type == ToastType.error ? 6 : 4),
      () => dismiss(id),
    );
  }

  void dismiss(int id) {
    _timers.remove(id)?.cancel();
    state = state.where((toast) => toast.id != id).toList();
  }
}
