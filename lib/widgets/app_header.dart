import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showBack;
  final List<Widget>? trailing;
  final VoidCallback? onBack;

  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = false,
    this.trailing,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 20,
        bottom: 18,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFFCFCFD)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 8,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          if (showBack)
            GestureDetector(
              onTap: onBack ?? () => Navigator.of(context).pop(),
              child: Container(
                width: 42,
                height: 42,
                margin: const EdgeInsets.only(right: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(13),
                  // border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 27,
                  color: Color(0xFF111111),
                ),
              ),
            ),

          // Title + Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111111),
                    letterSpacing: -0.5,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Trailing actions
          if (trailing != null) ...trailing!,
        ],
      ),
    );
  }
}
