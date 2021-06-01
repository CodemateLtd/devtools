import 'package:devtools_app/src/ui/label.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../auto_dispose_mixin.dart';
import '../globals.dart';
import '../service_extensions.dart';
import '../theme.dart';
import 'service_extension_widgets.dart';

class ToggleDropdownButton<T> extends StatefulWidget {
  const ToggleDropdownButton({
    Key key,
    this.hideIcon = false,
    this.minIncludeTextWidth,
    @required this.extensions,
    @required this.items,
  }) : super(key: key);

  final double minIncludeTextWidth;
  final List<DropdownItem<T>> items;
  final bool hideIcon;
  final List<ToggleableServiceExtensionDescription> extensions;

  @override
  _ToggleDropdownButtonState<T> createState() =>
      _ToggleDropdownButtonState<T>();
}

class _ToggleDropdownButtonState<T> extends State<ToggleDropdownButton<T>>
    with TickerProviderStateMixin, AutoDisposeMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry _overlayEntry;
  bool _isOpen = false;
  final int _currentIndex = -1;
  AnimationController _animationController;
  Animation<double> _expandAnimation;
  Animation<double> _rotateAnimation;
  bool toggleOn = false;

  List<ExtensionState> _extensionStates;

  @override
  void initState() {
    super.initState();
    // To use ToggleButtons we have to track states for all buttons in the
    // group here rather than tracking state with the individual button widgets
    // which would be more natural.
    _initExtensionState();
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

  void _initExtensionState() {
    _extensionStates = [for (var e in widget.extensions) ExtensionState(e)];

    for (var extension in _extensionStates) {
      // Listen for changes to the state of each service extension using the
      // VMServiceManager.
      final extensionName = extension.description.extension;
      // Update the button state to match the latest state on the VM.
      final state = serviceManager.serviceExtensionManager
          .getServiceExtensionState(extensionName);
      extension.isSelected = state.value.enabled;

      addAutoDisposeListener(state, () {
        setState(() {
          extension.isSelected = state.value.enabled;
        });
      });
      // Track whether the extension is actually exposed by the VM.
      final listenable = serviceManager.serviceExtensionManager
          .hasServiceExtension(extensionName);
      extension.isAvailable = listenable.value;
      addAutoDisposeListener(
        listenable,
        () {
          setState(() {
            extension.isAvailable = listenable.value;
          });
        },
      );
    }
  }

  @override
  void didUpdateWidget(ToggleDropdownButton oldWidget) {
    if (!listEquals(oldWidget.extensions, widget.extensions)) {
      cancel();
      _initExtensionState();
      setState(() {});
    }
    super.didUpdateWidget(oldWidget);
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
          _onPressed(_extensionStates[0]); //todo: fix index
        },
        child: Container(
          height: defaultButtonHeight,
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: defaultSpacing),
                  child: ImageIconLabel(
                    widget.extensions[0].icon,
                    'Show Guidelines',
                    minIncludeTextWidth: widget.minIncludeTextWidth,
                  ),
                ),
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
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      left:
                          BorderSide(color: Color.fromARGB(255, 128, 128, 128)),
                      right:
                          BorderSide(color: Color.fromARGB(255, 128, 128, 128)),
                      bottom:
                          BorderSide(color: Color.fromARGB(255, 128, 128, 128)),
                    ),
                  ),
                  child: Material(
                    borderRadius: BorderRadius.zero,
                    child: SizeTransition(
                      axisAlignment: 1,
                      sizeFactor: _expandAnimation,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height -
                              topOffset -
                              15,
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
                                            fillColor: MaterialStateProperty
                                                .resolveWith(getColor),
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
            ),
          ],
        ),
      ),
    );
  }

  void _toggleDropdown({bool close = false}) async {
    if (_isOpen || close) {
      await _animationController.reverse();
      if (_overlayEntry != null) {
        _overlayEntry.remove();
        _overlayEntry = null;
      }
      setState(() => _isOpen = false);
    } else {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry);
      setState(() => _isOpen = true);
      await _animationController.forward();
    }
  }

  void _onPressed(ExtensionState exState) {
    if (exState.isAvailable) {
      setState(() {
        final wasSelected = exState.isSelected;
        // TODO(jacobr): support analytics.
        // ga.select(extensionDescription.gaScreenName, extensionDescription.gaItem);

        serviceManager.serviceExtensionManager.setServiceExtensionState(
          exState.description.extension,
          !wasSelected,
          wasSelected
              ? exState.description.disabledValue
              : exState.description.enabledValue,
        );
      });
    } else {
      // TODO(jacobr): display a toast warning that the extension is
      // not available. That could happen as entire groups have to
      // be enabled or disabled at a time.
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
