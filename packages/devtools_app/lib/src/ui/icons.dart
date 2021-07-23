/*
 * Copyright 2017 The Chromium Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style license that can be
 * found in the LICENSE file.
 */

/// Platform independent definition of icons.
///
/// See [HtmlIconRenderer] for a browser specific implementation of icon
/// rendering. If you add an Icon class you also need to add a renderer class
/// to handle the actual platform specific icon rendering.
/// The benefit of this approach is that icons can be const objects and tests
/// of code that uses icons can run on the Dart VM.
library icons;

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import '../theme.dart';
import '../utils.dart';

class CustomIcon extends StatelessWidget {
  const CustomIcon({
    @required this.kind,
    @required this.text,
    this.isAbstract = false,
  });

  final IconKind kind;
  final String text;
  final bool isAbstract;

  AssetImageIcon get baseIcon => kind.icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: baseIcon.width,
      height: baseIcon.height,
      child: Stack(
        alignment: AlignmentDirectional.center,
        children: <Widget>[
          baseIcon,
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 9, color: Color(0xFF231F20)),
          ),
        ],
      ),
    );
  }
}

class CustomIconMaker {
  final Map<String, CustomIcon> iconCache = {};

  CustomIcon getCustomIcon(String fromText,
      {IconKind kind, bool isAbstract = false}) {
    kind ??= IconKind.classIcon;
    if (fromText?.isEmpty != false) {
      return null;
    }

    final String text = fromText[0].toUpperCase();
    final String mapKey = '${text}_${kind.name}_$isAbstract';

    return iconCache.putIfAbsent(mapKey, () {
      return CustomIcon(kind: kind, text: text, isAbstract: isAbstract);
    });
  }

  CustomIcon fromWidgetName(String name) {
    if (name == null) {
      return null;
    }

    while (name.isNotEmpty && !isAlphabetic(name.codeUnitAt(0))) {
      name = name.substring(1);
    }

    if (name.isEmpty) {
      return null;
    }

    return getCustomIcon(
      name,
      kind: isPrivate(name) ? IconKind.method : IconKind.classIcon,
    );
  }

  CustomIcon fromInfo(String name) {
    if (name == null) {
      return null;
    }

    if (name.isEmpty) {
      return null;
    }

    return getCustomIcon(name, kind: IconKind.info);
  }

  AssetImageIcon getWidgetIcon(String widgetType) {
    if (widgetType == null) {
      return null;
    }

    String widgetName;
    if (widgetType.contains('<')) {
      widgetName = widgetType.substring(0, widgetType.indexOf('<'));
    } else {
      widgetName = widgetType;
    }

    switch (widgetName) {
      case 'RenderObjectToWidgetAdapter':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/root.png',
        );
        break;
      case 'Text':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/text.png',
        );
        break;
      case 'Icon':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/icon.png',
        );
        break;
      case 'Image':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/image.png',
        );
        break;
      case 'FloatingActionButton':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/floatingab.png',
        );
        break;
      case 'Checkbox':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/checkbox.png',
        );
        break;
      case 'Radio':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/radio.png',
        );
        break;
      case 'Switch':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/toggle.png',
        );
        break;
      case 'AnimatedAlign':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/animated.png',
        );
        break;
      case 'AnimatedBuilder':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/animated.png',
        );
        break;
      case 'AnimatedContainer':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/animated.png',
        );
        break;
      case 'AnimatedCrossFade':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/animated.png',
        );
        break;
      case 'AnimatedDefaultTextStyle':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/animated.png',
        );
        break;
      case 'AnimatedListState':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/animated.png',
        );
        break;
      case 'AnimatedModalBarrier':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/animated.png',
        );
        break;
      case 'AnimatedOpacity':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/animated.png',
        );
        break;
      case 'AnimatedPhysicalModel':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/animated.png',
        );
        break;
      case 'AnimatedPositioned':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/animated.png',
        );
        break;
      case 'AnimatedSize':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/animated.png',
        );
        break;
      case 'AnimatedWidget':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/animated.png',
        );
        break;
      case 'AnimatedWidgetBaseState':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/animated.png',
        );
        break;
      case 'DecoratedBoxTransition':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/transition.png',
        );
        break;
      case 'FadeTransition':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/transition.png',
        );
        break;
      case 'PositionedTransition':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/transition.png',
        );
        break;
      case 'RotationTransition':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/transition.png',
        );
        break;
      case 'ScaleTransition':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/transition.png',
        );
        break;
      case 'SizeTransition':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/transition.png',
        );
        break;
      case 'SlideTransition':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/transition.png',
        );
        break;
      case 'Hero':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/hero.png',
        );
        break;
      case 'Container':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/container.png',
        );
        break;
      case 'Center':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/center.png',
        );
        break;
      case 'Row':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/row.png',
        );
        break;
      case 'Column':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/column.png',
        );
        break;
      case 'Padding':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/padding.png',
        );
        break;
      case 'Scaffold':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/scaffold.png',
        );
        break;
      case 'SizedBox':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/sizedbox.png',
        );
      case 'ConstrainedBox':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/sizedbox.png',
        );
        break;
      case 'Expanded':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/sizedbox.png',
        );
      case 'Flex':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/sizedbox.png',
        );
      case 'Align':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/align.png',
        );
      case 'Positioned':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/align.png',
        );
      case 'SingleChildScrollView':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/scroll.png',
        );
      case 'Scrollable':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/scroll.png',
        );
      case 'Stack':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/stack.png',
        );
      case 'InkWell':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/inkwell.png',
        );
      case 'GestureDetector':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/gesture.png',
        );
      case 'TextButton':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/textbutton.png',
        );
      case 'RaisedButton':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/textbutton.png',
        );
      case 'OutlinedButton':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/outlinedbutton.png',
        );
      case 'GridView':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/gridview.png',
        );
      case 'ListView':
        return const AssetImageIcon(
          asset: 'icons/inspector/widget_icons/listview.png',
        );
      default:
        return null;
    }
  }

  bool isAlphabetic(int char) {
    return (char < '0'.codeUnitAt(0) || char > '9'.codeUnitAt(0)) &&
        char != '_'.codeUnitAt(0) &&
        char != r'$'.codeUnitAt(0);
  }
}

class IconKind {
  const IconKind(this.name, this.icon, [AssetImageIcon abstractIcon])
      : abstractIcon = abstractIcon ?? icon;

  static IconKind classIcon = const IconKind(
    'class',
    AssetImageIcon(asset: 'icons/custom/class.png'),
    AssetImageIcon(asset: 'icons/custom/class_abstract.png'),
  );
  static IconKind field = const IconKind(
    'fields',
    AssetImageIcon(asset: 'icons/custom/fields.png'),
  );
  static IconKind interface = const IconKind(
    'interface',
    AssetImageIcon(asset: 'icons/custom/interface.png'),
  );
  static IconKind method = const IconKind(
    'method',
    AssetImageIcon(asset: 'icons/custom/method.png'),
    AssetImageIcon(asset: 'icons/custom/method_abstract.png'),
  );
  static IconKind property = const IconKind(
    'property',
    AssetImageIcon(asset: 'icons/custom/property.png'),
  );
  static IconKind info = const IconKind(
    'info',
    AssetImageIcon(asset: 'icons/custom/info.png'),
  );

  final String name;
  final AssetImageIcon icon;
  final AssetImageIcon abstractIcon;
}

class ColorIcon extends StatelessWidget {
  const ColorIcon(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _ColorIconPainter(color, colorScheme),
      size: const Size(defaultIconSize, defaultIconSize),
    );
  }
}

class ColorIconMaker {
  final Map<Color, ColorIcon> iconCache = {};

  ColorIcon getCustomIcon(Color color) {
    return iconCache.putIfAbsent(color, () => ColorIcon(color));
  }
}

class _ColorIconPainter extends CustomPainter {
  const _ColorIconPainter(this.color, this.colorScheme);

  final Color color;

  final ColorScheme colorScheme;
  static const double iconMargin = 1;

  @override
  void paint(Canvas canvas, Size size) {
    // draw a black and gray grid to use as the background to disambiguate
    // opaque colors from translucent colors.
    final greyPaint = Paint()..color = colorScheme.grey;
    final iconRect = Rect.fromLTRB(
      iconMargin,
      iconMargin,
      size.width - iconMargin,
      size.height - iconMargin,
    );
    canvas
      ..drawRect(
        Rect.fromLTRB(
          iconMargin,
          iconMargin,
          size.width - iconMargin,
          size.height - iconMargin,
        ),
        Paint()..color = colorScheme.defaultBackground,
      )
      ..drawRect(
        Rect.fromLTRB(
          iconMargin,
          iconMargin,
          size.width * 0.5,
          size.height * 0.5,
        ),
        greyPaint,
      )
      ..drawRect(
        Rect.fromLTRB(
          size.width * 0.5,
          size.height * 0.5,
          size.width - iconMargin,
          size.height - iconMargin,
        ),
        greyPaint,
      )
      ..drawRect(
        iconRect,
        Paint()..color = color,
      )
      ..drawRect(
        iconRect,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = colorScheme.defaultForeground,
      );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    if (oldDelegate is _ColorIconPainter) {
      return oldDelegate.colorScheme.isLight != colorScheme.isLight;
    }
    return true;
  }
}

class FlutterMaterialIcons {
  FlutterMaterialIcons._();

  static Icon getIconForCodePoint(int charCode, ColorScheme colorScheme) {
    return Icon(IconData(charCode), color: colorScheme.defaultForeground);
  }
}

class AssetImageIcon extends StatelessWidget {
  const AssetImageIcon({
    @required this.asset,
    this.height = defaultIconSize,
    this.width = defaultIconSize,
  });

  final String asset;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Image(
      image: AssetImage(asset),
      height: height,
      width: width,
    );
  }
}

class ThemedImageIcon extends StatelessWidget {
  const ThemedImageIcon({
    @required this.lightModeAsset,
    @required this.darkModeAsset,
  });

  final String lightModeAsset;
  final String darkModeAsset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Image(
      image: AssetImage(theme.isDarkTheme ? darkModeAsset : lightModeAsset),
      height: defaultIconSize,
      width: defaultIconSize,
    );
  }
}

class Octicons {
  static const IconData bug = IconData(61714, fontFamily: 'Octicons');
  static const IconData info = IconData(61778, fontFamily: 'Octicons');
  static const IconData deviceMobile = IconData(61739, fontFamily: 'Octicons');
  static const IconData fileZip = IconData(61757, fontFamily: 'Octicons');
  static const IconData clippy = IconData(61724, fontFamily: 'Octicons');
  static const IconData package = IconData(61812, fontFamily: 'Octicons');
  static const IconData dashboard = IconData(61733, fontFamily: 'Octicons');
  static const IconData pulse = IconData(61823, fontFamily: 'Octicons');
}
