import 'package:flutter/material.dart';

class PivotTabBar extends StatefulWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final Color indicatorColor;
  final double indicatorHeight;
  final double indicatorWidth;
  final double tabWidth;
  final EdgeInsetsGeometry tabPadding;
  final TextStyle selectedTextStyle;
  final TextStyle unselectedTextStyle;
  final double tabSpacing;

  const PivotTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.indicatorColor = Colors.blue,
    this.indicatorHeight = 3.0,
    this.indicatorWidth = 40.0,
    this.tabWidth = 72.0,
    this.tabPadding = const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
    this.selectedTextStyle = const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16.0,
    ),
    this.unselectedTextStyle = const TextStyle(
      fontWeight: FontWeight.normal,
      fontSize: 16.0,
      color: Colors.grey,
    ),
    this.tabSpacing = 8.0,
  });

  @override
  State<PivotTabBar> createState() => _PivotTabBarState();
}

class _PivotTabBarState extends State<PivotTabBar>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;
  late int _currentIndex;
  late double _indicatorPosition;
  late double _indicatorWidth;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.selectedIndex;
    _indicatorWidth = widget.indicatorWidth;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 180),
      vsync: this,
    );
    
    _scrollController = ScrollController();
    
    // 初始位置设为0，等待构建完成后再计算正确位置
    _indicatorPosition = 0;
    
    // 监听滚动，更新指示器位置
    _scrollController.addListener(_onScroll);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 构建完成后初始化指示器位置
      _updateIndicatorPosition();
      _scrollToSelectedTab();
    });
  }

  void _onScroll() {
    // 当滚动时，重新计算指示器位置
    if (!_animationController.isAnimating) {
      _updateIndicatorPosition();
    }
  }

  void _updateIndicatorPosition() {
    if (!mounted) return;
    
    final newPosition = _calculateIndicatorPosition(_currentIndex);
    if (_indicatorPosition != newPosition) {
      setState(() {
        _indicatorPosition = newPosition;
      });
    }
  }

  double _calculateIndicatorPosition(int index) {
    // 计算理论位置
    final theoreticalPosition = index * (widget.tabWidth + widget.tabSpacing) + 
           (widget.tabWidth - widget.indicatorWidth) / 2;
    
    // 减去当前滚动偏移量，确保指示器位置正确
    // 使用?操作符避免在dispose时访问
    final scrollOffset = _scrollController.hasClients ? _scrollController.offset : 0.0;
    return theoreticalPosition - scrollOffset;
  }

  @override
  void didUpdateWidget(PivotTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.selectedIndex != _currentIndex) {
      _animateToIndex(widget.selectedIndex);
    }
  }

  void _animateToIndex(int index) {
    if (index < 0 || index >= widget.tabs.length) return;
    
    final targetPosition = _calculateIndicatorPosition(index);
    
    final animation = Tween<double>(
      begin: _indicatorPosition,
      end: targetPosition,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    animation.addListener(() {
      if (mounted) {
        setState(() {
          _indicatorPosition = animation.value;
        });
      }
    });
    
    _animationController
      ..reset()
      ..forward().then((_) {
        if (mounted) {
          setState(() {
            _currentIndex = index;
            _indicatorPosition = targetPosition;
          });
          _scrollToSelectedTab();
        }
      });
  }

  void _scrollToSelectedTab() {
    if (!_scrollController.hasClients || !mounted) return;
    
    final tabWidth = widget.tabWidth;
    final viewportWidth = MediaQuery.of(context).size.width;
    final totalWidth = widget.tabs.length * (tabWidth + widget.tabSpacing);
    
    if (totalWidth <= viewportWidth) return;
    
    final targetPosition = _currentIndex * (tabWidth + widget.tabSpacing);
    final maxOffset = totalWidth - viewportWidth;
    
    // 计算滚动位置，使选中的标签居中
    final centerOffset = targetPosition - (viewportWidth / 2) + (tabWidth / 2);
    final clampedOffset = centerOffset.clamp(0.0, maxOffset);
    
    _scrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 标签区域
        SizedBox(
          height: 40.0,
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: widget.tabs.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(right: index < widget.tabs.length - 1 ? widget.tabSpacing : 0),
                child: GestureDetector(
                  onTap: () {
                    if (index != _currentIndex) {
                      widget.onTabSelected(index);
                      _animateToIndex(index);
                    }
                  },
                  child: Container(
                    width: widget.tabWidth,
                    padding: widget.tabPadding,
                    child: Center(
                      child: Text(
                        widget.tabs[index],
                        style: index == _currentIndex
                            ? widget.selectedTextStyle.copyWith(
                                color: widget.indicatorColor,
                              )
                            : widget.unselectedTextStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        // 指示器区域
        SizedBox(
          height: widget.indicatorHeight + 4.0,
          child: Stack(
            children: [
              // 指示器
              AnimatedPositioned(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                left: _indicatorPosition,
                child: Container(
                  width: widget.indicatorWidth,
                  height: widget.indicatorHeight,
                  decoration: BoxDecoration(
                    color: widget.indicatorColor,
                    borderRadius: BorderRadius.circular(widget.indicatorHeight / 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}