import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ui_provider.dart';

class GlobalOverlay extends StatelessWidget {
  final Widget child;
  const GlobalOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,

        // Loading overlay
        Consumer<UiProvider>(
          builder: (context, ui, _) {
            if (!ui.isLoading) return const SizedBox.shrink();
            return const _LoadingOverlay();
          },
        ),

        // Alert modal
        Consumer<UiProvider>(
          builder: (context, ui, _) {
            if (ui.alertData == null) return const SizedBox.shrink();
            return _AlertModal(data: ui.alertData!);
          },
        ),

        // Confirm modal
        Consumer<UiProvider>(
          builder: (context, ui, _) {
            if (ui.confirmData == null) return const SizedBox.shrink();
            return _ConfirmModal(data: ui.confirmData!);
          },
        ),

        // Toast notification
        Consumer<UiProvider>(
          builder: (context, ui, _) {
            if (ui.activeToast == null) return const SizedBox.shrink();
            return _ToastWidget(data: ui.activeToast!);
          },
        ),
      ],
    );
  }
}

// ─── Toast Widget ────────────────────────────────────────────────────────────

class _ToastWidget extends StatefulWidget {
  final ToastData data;
  const _ToastWidget({required this.data});

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _bgColor {
    switch (widget.data.type) {
      case ToastType.success:
        return const Color(0xFF10B981);
      case ToastType.error:
        return const Color(0xFFEF4444);
      case ToastType.warning:
        return const Color(0xFFF59E0B);
      case ToastType.info:
        return const Color(0xFF111111);
    }
  }

  IconData get _icon {
    switch (widget.data.type) {
      case ToastType.success:
        return Icons.check_circle_rounded;
      case ToastType.error:
        return Icons.error_rounded;
      case ToastType.warning:
        return Icons.warning_rounded;
      case ToastType.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onTap: () => Provider.of<UiProvider>(context, listen: false).dismissToast(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: _bgColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _bgColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(_icon, color: Colors.white, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.data.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Bricolage',
                      ),
                    ),
                  ),
                  const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Loading Overlay ─────────────────────────────────────────────────────────

class _LoadingOverlay extends StatefulWidget {
  const _LoadingOverlay();

  @override
  State<_LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<_LoadingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = Provider.of<UiProvider>(context).loadingMessage;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        color: Colors.black.withValues(alpha: 0.3),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: const Color(0xFF111111),
                      backgroundColor: Colors.grey.shade200,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                      fontFamily: 'Bricolage',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Alert Modal ─────────────────────────────────────────────────────────────

class _AlertModal extends StatefulWidget {
  final AlertData data;
  const _AlertModal({required this.data});

  @override
  State<_AlertModal> createState() => _AlertModalState();
}

class _AlertModalState extends State<_AlertModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _accentColor {
    switch (widget.data.type) {
      case AlertType.success:
        return const Color(0xFF10B981);
      case AlertType.error:
        return const Color(0xFFEF4444);
      case AlertType.warning:
        return const Color(0xFFF59E0B);
      case AlertType.info:
        return const Color(0xFF3B82F6);
    }
  }

  IconData get _icon {
    switch (widget.data.type) {
      case AlertType.success:
        return Icons.check_circle_rounded;
      case AlertType.error:
        return Icons.error_rounded;
      case AlertType.warning:
        return Icons.warning_rounded;
      case AlertType.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: GestureDetector(
        onTap: () => Provider.of<UiProvider>(context, listen: false).dismissAlert(),
        child: Container(
          color: Colors.black.withValues(alpha: 0.35),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: GestureDetector(
                  onTap: () {}, // Absorb taps on the card
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.82,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 40,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: _accentColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_icon, color: _accentColor, size: 28),
                        ),
                        const SizedBox(height: 20),

                        // Title
                        Text(
                          widget.data.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111111),
                            fontFamily: 'Bricolage',
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Message
                        Text(
                          widget.data.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                            height: 1.5,
                            fontFamily: 'Bricolage',
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Dismiss button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () =>
                                Provider.of<UiProvider>(context, listen: false).dismissAlert(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF111111),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Got it',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Bricolage',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Confirm Modal ───────────────────────────────────────────────────────────

class _ConfirmModal extends StatefulWidget {
  final ConfirmData data;
  const _ConfirmModal({required this.data});

  @override
  State<_ConfirmModal> createState() => _ConfirmModalState();
}

class _ConfirmModalState extends State<_ConfirmModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ui = Provider.of<UiProvider>(context, listen: false);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: GestureDetector(
        onTap: () => ui.resolveConfirm(false),
        child: Container(
          color: Colors.black.withValues(alpha: 0.35),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.82,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 40,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Warning icon
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: widget.data.isDangerous
                                ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                                : const Color(0xFFF59E0B).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.data.isDangerous
                                ? Icons.warning_rounded
                                : Icons.help_outline_rounded,
                            color: widget.data.isDangerous
                                ? const Color(0xFFEF4444)
                                : const Color(0xFFF59E0B),
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Title
                        Text(
                          widget.data.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111111),
                            fontFamily: 'Bricolage',
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Message
                        Text(
                          widget.data.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                            height: 1.5,
                            fontFamily: 'Bricolage',
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Action buttons
                        Row(
                          children: [
                            // Cancel
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: OutlinedButton(
                                  onPressed: () => ui.resolveConfirm(false),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF6B7280),
                                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(
                                    widget.data.cancelLabel,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Bricolage',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Confirm
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: () => ui.resolveConfirm(true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: widget.data.isDangerous
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFF111111),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    widget.data.confirmLabel,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Bricolage',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
