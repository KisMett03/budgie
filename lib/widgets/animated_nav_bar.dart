import 'package:flutter/material.dart';

class AnimatedNavBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onTap;
  final Duration duration;
  final bool isVisible;

  const AnimatedNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onTap,
    required this.duration,
    required this.isVisible,
  }) : super(key: key);

  @override
  State<AnimatedNavBar> createState() => _AnimatedNavBarState();
}

class _AnimatedNavBarState extends State<AnimatedNavBar>
    with SingleTickerProviderStateMixin {
  int _previousIndex = 0;

  @override
  void didUpdateWidget(covariant AnimatedNavBar oldWidget) {
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _previousIndex = oldWidget.selectedIndex;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink(); // <--- ✨ this already works

    final double width = MediaQuery.of(context).size.width;
    final double itemWidth = width / 3;
    final int direction = widget.selectedIndex - _previousIndex;

    // REMOVE SafeArea here, move it to just below
    return AnimatedSlide(
      offset: widget.isVisible ? Offset.zero : const Offset(0, 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: AnimatedOpacity(
        opacity: widget.isVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Container(
          color: Colors.transparent,
          child: SafeArea(
            top: false,
            bottom: true, // only applies when visible
            child: Container(
              height: kBottomNavigationBarHeight,
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(3, (index) {
                  return _buildNavItem(index, itemWidth, direction);
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildNavItem(int index, double width, int direction) {
    final bool isSelected = index == widget.selectedIndex;

    return GestureDetector(
      onTap: () => widget.onTap(index),
      child: SizedBox(
        width: width,
        height: kBottomNavigationBarHeight,
        child: AnimatedContainer(
          duration: widget.duration,
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.2 : 1.0,
                duration: widget.duration,
                curve: Curves.easeInOut,
                child: Icon(
                  _getIconForIndex(index),
                  color: isSelected ? Colors.blue : Colors.grey,
                ),
              ),
              const SizedBox(width: 6),
              AnimatedDefaultTextStyle(
                duration: widget.duration,
                style: TextStyle(
                  color: isSelected ? Colors.blue : Colors.grey,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                child: Text(_getLabelForIndex(index)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForIndex(int index) {
    switch (index) {
      case 0:
        return Icons.dashboard;
      case 1:
        return Icons.add;
      case 2:
        return Icons.settings;
      default:
        return Icons.help;
    }
  }

  String _getLabelForIndex(int index) {
    switch (index) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Add Expenses';
      case 2:
        return 'Settings';
      default:
        return '';
    }
  }
}
