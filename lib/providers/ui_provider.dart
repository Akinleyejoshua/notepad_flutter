import 'dart:async';
import 'package:flutter/material.dart';

// ─── Toast Types ─────────────────────────────────────────────────────────────

enum ToastType { success, error, info, warning }

class ToastData {
  final String message;
  final ToastType type;
  final DateTime createdAt;

  ToastData({required this.message, required this.type})
      : createdAt = DateTime.now();
}

// ─── Alert Types ─────────────────────────────────────────────────────────────

enum AlertType { info, warning, error, success }

class AlertData {
  final String title;
  final String message;
  final AlertType type;
  final VoidCallback? onDismiss;

  AlertData({
    required this.title,
    required this.message,
    this.type = AlertType.info,
    this.onDismiss,
  });
}

// ─── Confirm Types ───────────────────────────────────────────────────────────

class ConfirmData {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDangerous;
  final Completer<bool> completer;

  ConfirmData({
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.isDangerous = false,
    required this.completer,
  });
}

// ─── UI Provider ─────────────────────────────────────────────────────────────

class UiProvider extends ChangeNotifier {
  // Toast state
  ToastData? _activeToast;
  Timer? _toastTimer;
  ToastData? get activeToast => _activeToast;

  // Loading state
  bool _isLoading = false;
  String _loadingMessage = 'Loading...';
  bool get isLoading => _isLoading;
  String get loadingMessage => _loadingMessage;

  // Alert state
  AlertData? _alertData;
  AlertData? get alertData => _alertData;

  // Confirm state
  ConfirmData? _confirmData;
  ConfirmData? get confirmData => _confirmData;

  // ── Toast ──

  void showToast(String message, {ToastType type = ToastType.info}) {
    _toastTimer?.cancel();
    _activeToast = ToastData(message: message, type: type);
    notifyListeners();

    _toastTimer = Timer(const Duration(milliseconds: 2800), () {
      _activeToast = null;
      notifyListeners();
    });
  }

  void dismissToast() {
    _toastTimer?.cancel();
    _activeToast = null;
    notifyListeners();
  }

  // ── Loading ──

  void showLoading({String message = 'Loading...'}) {
    _isLoading = true;
    _loadingMessage = message;
    notifyListeners();
  }

  void hideLoading() {
    _isLoading = false;
    notifyListeners();
  }

  // ── Alert ──

  void showAlert({
    required String title,
    required String message,
    AlertType type = AlertType.info,
    VoidCallback? onDismiss,
  }) {
    _alertData = AlertData(
      title: title,
      message: message,
      type: type,
      onDismiss: onDismiss,
    );
    notifyListeners();
  }

  void dismissAlert() {
    final callback = _alertData?.onDismiss;
    _alertData = null;
    notifyListeners();
    callback?.call();
  }

  // ── Confirm ──

  Future<bool> showConfirm({
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDangerous = false,
  }) {
    final completer = Completer<bool>();
    _confirmData = ConfirmData(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      isDangerous: isDangerous,
      completer: completer,
    );
    notifyListeners();
    return completer.future;
  }

  void resolveConfirm(bool result) {
    _confirmData?.completer.complete(result);
    _confirmData = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }
}
