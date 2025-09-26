import 'package:flutter/material.dart';

class SegmentedControl extends StatefulWidget {
  final List<String> items;
  final int initialIndex;
  final ValueChanged<int> onSelected;

  const SegmentedControl({
    super.key,
    required this.items,
    this.initialIndex = 0,
    required this.onSelected,
  });

  @override
  State<SegmentedControl> createState() => _SegmentedControlState();
}

class _SegmentedControlState extends State<SegmentedControl>
    with SingleTickerProviderStateMixin {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _handleTap(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    widget.onSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(widget.items.length, (index) {
          final selected = index == _selectedIndex;
          return Expanded(
            child: AnimatedScale(
              scale: selected ? 1.05 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => _handleTap(index),
                    child: Center(
                      child: Text(
                        widget.items[index],
                        style: TextStyle(
                          color: selected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}