import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onCreatePressed;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onCreatePressed,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SizedBox(
      height: 90 + bottomPadding,

      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Nav bar background
          Positioned(
            left: 0,
            right: 0,
            bottom: 10,
            child: Container(
              height: 74 + bottomPadding,
              decoration: const BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomPadding),
                child: Row(
                  children: [
                    // Home tab
                    Expanded(
                      child: _NavItem(
                        icon: Icons.home_max,
                        label: 'Home',
                        isActive: currentIndex == 0,
                        onTap: () => onTabSelected(0),
                      ),
                    ),

                    // Spacer for the center button
                    const SizedBox(width: 80),

                    // Search tab
                    Expanded(
                      child: _NavItem(
                        icon: Icons.search_rounded,
                        label: 'Search',
                        isActive: currentIndex == 1,
                        onTap: () => onTabSelected(1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Overlapping Create button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: onCreatePressed,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 50,
                  width: 50,
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 229, 229, 229),
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4169E1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Color.fromARGB(255, 255, 255, 255),
                      size: 30,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF111111) : const Color(0xFFB0B0B0);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF111111).withValues(alpha: 0.06)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),

          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
          if (isActive) ...[
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 18,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFF4169E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
