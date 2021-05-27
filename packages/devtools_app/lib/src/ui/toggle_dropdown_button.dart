import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../service_extensions.dart';
import '../theme.dart';

class ToggleDropdownButton<T> extends StatefulWidget {
  const ToggleDropdownButton({
    Key key,
    this.hideIcon = false,
    @required this.title,
    @required this.extensions,
    @required this.items,
  }) : super(key: key);

  final Widget title;
  final List<DropdownItem<T>> items;
  final bool hideIcon;
  final List<ToggleableServiceExtensionDescription> extensions;

  @override
  _ToggleDropdownButtonState<T> createState() =>
      _ToggleDropdownButtonState<T>();
}

class _ToggleDropdownButtonState<T> extends State<ToggleDropdownButton<T>>
    with TickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry _overlayEntry;
  bool _isOpen = false;
  final int _currentIndex = -1;
  AnimationController _animationController;
  Animation<double> _expandAnimation;
  Animation<double> _rotateAnimation;
  bool toggleOn = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _rotateAnimation = Tween(begin: 0.0, end: 0.5).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          setState(() {
            !toggleOn ? toggleOn = true : toggleOn = false;
          });
          print('Toggle pressed');
        },
        child: Container(
          height: defaultButtonHeight,
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: toggleOn
                ? theme.colorScheme.toggleButtonBackgroundColor
                : Colors.transparent,
            border: Border.all(
              color: const Color.fromARGB(255, 128, 128, 128),
            ),
            borderRadius: BorderRadius.circular(defaultBorderRadius),
          ),
          child: Row(
            children: [
              if (_currentIndex == -1) ...[
                widget.title,
              ] else ...[
                widget.items[_currentIndex],
              ],
              if (!widget.hideIcon)
                RotationTransition(
                  turns: _rotateAnimation,
                  child: GestureDetector(
                    onTap: _toggleDropdown,
                    child: const SizedBox(
                      height: 20,
                      width: 20,
                      child: Icon(
                        Icons.arrow_drop_down_outlined,
                        color: Color.fromARGB(255, 128, 128, 128),
                        size: defaultIconSize,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    final topOffset = offset.dy + size.height + 5;

    Color getColor(Set<MaterialState> states) {
      const Set<MaterialState> interactiveStates = <MaterialState>{
        MaterialState.pressed,
        MaterialState.hovered,
        MaterialState.focused,
      };
      if (states.any(interactiveStates.contains)) {
        return Colors.blue;
      }
      return Colors.blue;
    }

    return OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: () => _toggleDropdown(close: true),
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Positioned(
              left: offset.dx,
              top: topOffset,
              width: size.width,
              child: CompositedTransformFollower(
                offset: Offset(0, size.height),
                link: _layerLink,
                showWhenUnlinked: false,
                child: Material(
                  borderRadius: BorderRadius.zero,
                  child: SizeTransition(
                    axisAlignment: 1,
                    sizeFactor: _expandAnimation,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight:
                            MediaQuery.of(context).size.height - topOffset - 15,
                      ),
                      child: ListView(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        children: widget.items.asMap().entries.map((item) {
                          return InkWell(
                            onTap: () {
                              _toggleDropdown();
                            },
                            child: Row(
                              children: [
                                ValueListenableBuilder<bool>(
                                    valueListenable: item.value.isChecked,
                                    builder: (context, value, child) {
                                      return Checkbox(
                                          checkColor: Colors.white,
                                          fillColor:
                                              MaterialStateProperty.resolveWith(
                                                  getColor),
                                          value: item.value.isChecked.value,
                                          onChanged: (bool value) {
                                            setState(() {
                                              item.value.isChecked.value =
                                                  value;
                                            });
                                          });
                                    }),
                                item.value,
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleDropdown({bool close = false}) async {
    if (_isOpen || close) {
      await _animationController.reverse();
      _overlayEntry.remove();
      setState(() => _isOpen = false);
    } else {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry);
      setState(() => _isOpen = true);
      _animationController.forward();
    }
  }
}

// ignore: must_be_immutable
class DropdownItem<T> extends StatelessWidget {
  final T value;
  final Widget child;
  ValueNotifier<bool> isChecked = ValueNotifier<bool>(true);

  DropdownItem(
      {Key key,
      @required this.value,
      @required this.child,
      @required this.isChecked})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class ToggleDropdownTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  ToggleDropdownTitle({Key key, @required this.title, @required this.icon})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 8),
        Icon(
          icon,
          size: defaultIconSize,
          color: const Color.fromARGB(255, 128, 128, 128),
        ),
        const SizedBox(width: 8),
        Text(title),
      ],
    );
  }
}
