import 'package:flutter/material.dart';

import '../tokens/color_tokens.dart';
import '../tokens/spacing_tokens.dart';
import '../tokens/radius_tokens.dart';
import '../tokens/elevation_tokens.dart';
import '../tokens/typography_tokens.dart';

class DSBottomNavItem {
  final IconData icon;
  final String label;

  const DSBottomNavItem({
    required this.icon,
    required this.label,
  });
}

/// Enhanced Bottom Navigation Bar - Fixed overflow, proper spacing
class DSBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<DSBottomNavItem> items;

  const DSBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final itemCount = items.length;
    
    // Adjust sizing based on number of items to prevent overflow
    final navHeight = itemCount > 4 ? 72.0 : 70.0;
    final iconSize = itemCount > 4 ? 20.0 : 22.0;
    final fontSize = itemCount > 4 ? 8.5 : 10.0;
    final iconContainerSize = itemCount > 4 ? 32.0 : 36.0;
    final horizontalPadding = itemCount > 4 ? SpacingTokens.space2 : SpacingTokens.space4;

    return Container(
      decoration: BoxDecoration(
        color: colors.backgroundSurface,
        border: Border(
          top: BorderSide(
            color: colors.borderSubtle.withOpacity(0.5),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.borderSubtle.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, -4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: navHeight,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: SpacingTokens.space6,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(
              items.length,
              (index) => Expanded(
                child: _NavItem(
                  item: items[index],
                  isSelected: index == currentIndex,
                  onTap: () => onTap(index),
                  colors: colors,
                  iconSize: iconSize,
                  fontSize: fontSize,
                  iconContainerSize: iconContainerSize,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final DSBottomNavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final SemanticColors colors;
  final double iconSize;
  final double fontSize;
  final double iconContainerSize;

  const _NavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.colors,
    required this.iconSize,
    required this.fontSize,
    required this.iconContainerSize,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: RadiusTokens.button,
        splashColor: colors.accentPrimary.withOpacity(0.1),
        highlightColor: colors.accentPrimary.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.space2,
            vertical: SpacingTokens.space4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with animated background circle when selected
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                width: iconContainerSize,
                height: iconContainerSize,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.accentPrimary.withOpacity(0.15)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.icon,
                  size: iconSize,
                  color: isSelected
                      ? colors.accentPrimary
                      : colors.textSecondary,
                ),
              ),
              SizedBox(height: fontSize > 9 ? SpacingTokens.space2 : SpacingTokens.space4),
              // Label text with proper overflow handling - wrapped in Flexible
              Flexible(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected
                        ? colors.accentPrimary
                        : colors.textSecondary,
                    letterSpacing: 0.05,
                    height: 1.0,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
