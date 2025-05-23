// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/charts/chart_controller.dart';
import '../../../../shared/common_widgets.dart';
import '../../../../shared/globals.dart';
import '../../../../shared/primitives/auto_dispose.dart';
import '../../../../shared/primitives/utils.dart';
import '../../../../shared/theme.dart';
import '../../../../shared/utils.dart';
import '../../memory_controller.dart';
import '../../shared/primitives/painting.dart';
import 'chart_control_pane.dart';
import 'chart_pane_controller.dart';
import 'legend.dart';
import 'memory_android_chart.dart';
import 'memory_charts.dart';
import 'memory_events_pane.dart';
import 'memory_vm_chart.dart';

class MemoryChartPane extends StatefulWidget {
  const MemoryChartPane({
    Key? key,
    required this.chartController,
    required this.keyFocusNode,
  }) : super(key: key);
  final MemoryChartPaneController chartController;

  /// Which widget's key press will be handled by chart.
  final FocusNode keyFocusNode;

  static final hoverKey = GlobalKey(debugLabel: 'Chart Hover');

  @override
  State<MemoryChartPane> createState() => _MemoryChartPaneState();
}

class _MemoryChartPaneState extends State<MemoryChartPane>
    with
        AutoDisposeMixin,
        SingleTickerProviderStateMixin,
        ProvidedControllerMixin<MemoryController, MemoryChartPane> {
  OverlayEntry? _hoverOverlayEntry;

  static const _hoverXOffset = 10;
  static const _hoverYOffset = 0.0;

  static double get _hoverWidth => scaleByFontFactor(225.0);
  static const _hover_card_border_width = 2.0;

  // TODO(terry): Compute below heights dynamically.
  static double get _hoverHeightMinimum => scaleByFontFactor(42.0);
  static double get hoverItemHeight => scaleByFontFactor(18.0);

  /// One extension event to display (4 lines).
  static double get _hoverOneEventsHeight => scaleByFontFactor(82.0);

  /// Many extension events to display.
  static double get _hoverEventsHeight => scaleByFontFactor(120.0);

  static double _computeHoverHeight(
    int eventsCount,
    int tracesCount,
    int extensionEventsCount,
  ) =>
      _hoverHeightMinimum +
      (eventsCount * hoverItemHeight) +
      _hover_card_border_width +
      (tracesCount * hoverItemHeight) +
      (extensionEventsCount > 0
          ? (extensionEventsCount == 1
              ? _hoverOneEventsHeight
              : _hoverEventsHeight)
          : 0);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!initController()) return;

    // TODO(polinach): generalize three addAutoDisposeListener below.
    addAutoDisposeListener(widget.chartController.event.tapLocation, () {
      if (widget.chartController.event.tapLocation.value != null) {
        if (_hoverOverlayEntry != null) {
          _hideHover();
        }
        final tapLocation = widget.chartController.event.tapLocation.value;
        if (tapLocation?.tapDownDetails != null) {
          final tapData = tapLocation!;
          final index = tapData.index;
          final timestamp = tapData.timestamp!;

          final copied = TapLocation.copy(tapLocation);
          widget.chartController.vm.tapLocation.value = copied;
          widget.chartController.android.tapLocation.value = copied;

          final allValues = ChartsValues(controller, index, timestamp);
          _showHover(
            context,
            allValues,
            tapData.tapDownDetails!.globalPosition,
          );
        }
      }
    });

    addAutoDisposeListener(widget.chartController.vm.tapLocation, () {
      if (widget.chartController.vm.tapLocation.value != null) {
        if (_hoverOverlayEntry != null) {
          _hideHover();
        }
        final tapLocation = widget.chartController.vm.tapLocation.value;
        if (tapLocation?.tapDownDetails != null) {
          final tapData = tapLocation!;
          final index = tapData.index;
          final timestamp = tapData.timestamp!;

          final copied = TapLocation.copy(tapLocation);
          widget.chartController.event.tapLocation.value = copied;
          widget.chartController.android.tapLocation.value = copied;

          final allValues = ChartsValues(controller, index, timestamp);

          _showHover(
            context,
            allValues,
            tapData.tapDownDetails!.globalPosition,
          );
        }
      }
    });

    addAutoDisposeListener(widget.chartController.android.tapLocation, () {
      if (widget.chartController.android.tapLocation.value != null) {
        if (_hoverOverlayEntry != null) {
          _hideHover();
        }
        final tapLocation = widget.chartController.android.tapLocation.value;
        if (tapLocation?.tapDownDetails != null) {
          final tapData = tapLocation!;
          final index = tapData.index;
          final timestamp = tapData.timestamp!;

          final copied = TapLocation.copy(tapLocation);
          widget.chartController.event.tapLocation.value = copied;
          widget.chartController.vm.tapLocation.value = copied;

          final allValues = ChartsValues(controller, index, timestamp);

          _showHover(
            context,
            allValues,
            tapData.tapDownDetails!.globalPosition,
          );
        }
      }
    });

    addAutoDisposeListener(controller.refreshCharts, () {
      setState(() {
        widget.chartController.recomputeChartData();
      });
    });

    // There is no listener passed, so SetState will be invoked.
    addAutoDisposeListener(controller.isAndroidChartVisibleNotifier);

    _updateListeningState();
  }

  void _updateListeningState() async {
    await serviceManager.onServiceAvailable;

    if (!controller.hasStarted) {
      controller.startTimeline();

      // TODO(terry): Need to set the initial state of buttons.
/*
      pauseButton.disabled = false;
      resumeButton.disabled = true;

      vmMemorySnapshotButton.disabled = false;
      resetAccumulatorsButton.disabled = false;
      gcNowButton.disabled = false;

      memoryChart.disabled = false;
*/
    }
  }

  @override
  Widget build(BuildContext context) {
    const memoryEventsPainHeight = 70.0;
    return ValueListenableBuilder<bool>(
      valueListenable: preferences.memory.showChart,
      builder: (_, showChart, __) {
        // TODO(https://github.com/flutter/devtools/issues/4576): animate
        // showing and hiding the chart.
        if (!showChart) return const SizedBox.shrink();

        return RawKeyboardListener(
          focusNode: widget.keyFocusNode,
          onKey: (RawKeyEvent event) {
            if (event.isKeyPressed(LogicalKeyboardKey.escape)) {
              _hideHover();
            }
          },
          autofocus: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The chart.
              Expanded(
                child: Column(
                  children: [
                    SizedBox(
                      height: memoryEventsPainHeight,
                      child: MemoryEventsPane(widget.chartController.event),
                    ),
                    MemoryVMChart(widget.chartController.vm),
                    if (controller.isAndroidChartVisibleNotifier.value)
                      SizedBox(
                        height: defaultChartHeight,
                        child: MemoryAndroidChart(
                          widget.chartController.android,
                        ),
                      ),
                  ],
                ),
              ),
              // The legend.
              DualValueListenableBuilder<bool, bool>(
                firstListenable: widget.chartController.legendVisibleNotifier,
                secondListenable: controller.isAndroidChartVisibleNotifier,
                builder: (_, isLegendVisible, isAndroidChartVisible, __) {
                  if (!isLegendVisible) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: denseSpacing),
                    child: MemoryChartLegend(
                      isAndroidVisible: isAndroidChartVisible,
                      chartController: widget.chartController,
                    ),
                  );
                },
              ),
              // Chart control pane.
              ChartControlPane(
                chartController: widget.chartController,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _hideHover(); // hover will leak if not hide
    controller.stopTimeLine();
    super.dispose();
  }

  List<Widget> _displayVmDataInHover(ChartsValues chartsValues) =>
      _dataToDisplay(
        chartsValues.displayVmDataToDisplay(widget.chartController.vm.traces),
      );

  List<Widget> _displayAndroidDataInHover(ChartsValues chartsValues) {
    const dividerLineVerticalSpace = 2.0;
    const dividerLineHorizontalSpace = 20.0;
    const totalDividerLineHorizontalSpace = dividerLineHorizontalSpace * 2;

    if (!controller.isAndroidChartVisibleNotifier.value) return [];

    final androidDataDisplayed = chartsValues
        .androidDataToDisplay(widget.chartController.android.traces);

    // Separator between Android data.
    // TODO(terry): Why Center widget doesn't work (parent width is bigger/centered too far right).
    //              Is it centering on a too wide Overlay?
    final width = _hoverWidth -
        totalDividerLineHorizontalSpace -
        DashedLine.defaultDashWidth;
    final dashedColor = Colors.grey.shade600;

    return _dataToDisplay(
      androidDataDisplayed,
      firstWidget: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: dividerLineVerticalSpace,
            horizontal: dividerLineHorizontalSpace,
          ),
          child: CustomPaint(painter: DashedLine(width, dashedColor)),
        ),
      ),
    );
  }

  void _showHover(
    BuildContext context,
    ChartsValues chartsValues,
    Offset position,
  ) {
    final theme = Theme.of(context);
    final focusColor = theme.focusColor;
    final colorScheme = theme.colorScheme;

    final box = MemoryChartPane.hoverKey.currentContext!.findRenderObject()
        as RenderBox;
    final renderBoxWidth = box.size.width;

    // Display hover to left of right side of position.
    double xPosition = position.dx + _hoverXOffset;
    if (xPosition + _hoverWidth > renderBoxWidth) {
      xPosition = position.dx - _hoverWidth - _hoverXOffset;
    }

    double totalHoverHeight;
    int totalTraces;
    totalTraces = controller.isAndroidChartVisibleNotifier.value
        ? chartsValues.vmData.entries.length -
            1 +
            chartsValues.androidData.entries.length
        : chartsValues.vmData.entries.length - 1;

    totalHoverHeight = _computeHoverHeight(
      chartsValues.eventCount,
      totalTraces,
      chartsValues.extensionEventsLength,
    );

    final displayTimestamp = prettyTimestamp(chartsValues.timestamp);

    final hoverHeading = theme.hoverTitleTextStyle;

    final OverlayState overlayState = Overlay.of(context);
    _hoverOverlayEntry ??= OverlayEntry(
      builder: (context) => Positioned(
        top: position.dy + _hoverYOffset,
        left: xPosition,
        height: totalHoverHeight,
        child: Container(
          padding: const EdgeInsets.only(top: 5, bottom: 8),
          decoration: BoxDecoration(
            color: colorScheme.defaultBackgroundColor,
            border: Border.all(
              color: focusColor,
              width: _hover_card_border_width,
            ),
            borderRadius: BorderRadius.circular(defaultBorderRadius),
          ),
          width: _hoverWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: _hoverWidth,
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Time $displayTimestamp',
                  style: hoverHeading,
                  textAlign: TextAlign.center,
                ),
              ),
            ]
              ..addAll(_displayEventsInHover(chartsValues))
              ..addAll(_displayVmDataInHover(chartsValues))
              ..addAll(_displayAndroidDataInHover(chartsValues))
              ..addAll(_displayExtensionEventsInHover(chartsValues)),
          ),
        ),
      ),
    );

    overlayState.insert(_hoverOverlayEntry!);
  }

  List<Widget> _dataToDisplay(
    Map<String, Map<String, Object?>> dataToDisplay, {
    Widget? firstWidget,
  }) {
    final results = <Widget>[];

    if (firstWidget != null) results.add(firstWidget);

    for (var entry in dataToDisplay.entries) {
      final keys = entry.value.keys;
      final image = keys.contains(renderImage)
          ? entry.value[renderImage] as String?
          : null;
      final color =
          keys.contains(renderLine) ? entry.value[renderLine] as Color? : null;
      final dashedLine =
          keys.contains(renderDashed) ? entry.value[renderDashed] : false;

      results.add(
        _hoverRow(
          name: entry.key,
          colorPatch: color,
          dashed: dashedLine == true,
          image: image,
          hasNumeric: true,
          scaleImage: true,
        ),
      );
    }

    return results;
  }

  Widget _hoverRow({
    required String name,
    String? image,
    Color? colorPatch,
    bool dashed = false,
    bool bold = true,
    bool hasNumeric = false,
    bool scaleImage = false,
  }) {
    final theme = Theme.of(context);
    final hoverTitleEntry = theme.hoverTextStyle;
    final hoverValueEntry = theme.hoverValueTextStyle;
    final hoverSmallEntry = theme.hoverSmallValueTextStyle;

    List<Widget> hoverPartImageLine(
      String name, {
      String? image,
      Color? colorPatch,
      bool dashed = false,
    }) {
      String displayName = name;
      // Empty string overflows, default value space.
      String displayValue = ' ';
      if (hasNumeric) {
        int startOfNumber = name.lastIndexOf(' ');

        final unitOrValue = name.substring(startOfNumber + 1);
        if (int.tryParse(unitOrValue) == null) {
          // Got a unit.
          startOfNumber = name.lastIndexOf(' ', startOfNumber - 1);
        }

        displayName = '${name.substring(0, startOfNumber)} ';
        displayValue = name.substring(startOfNumber + 1);
      }

      Widget traceColor;
      // Logic would be hard to read as a conditional expression.
      // ignore: prefer-conditional-expression
      if (colorPatch != null) {
        traceColor =
            dashed ? createDashWidget(colorPatch) : createSolidLine(colorPatch);
      } else {
        traceColor = image == null
            ? const SizedBox()
            : scaleImage
                ? Image(
                    image: AssetImage(image),
                    width: 20,
                    height: 10,
                  )
                : Image(
                    image: AssetImage(image),
                  );
      }

      return [
        traceColor,
        const PaddedDivider(
          padding: EdgeInsets.only(left: denseRowSpacing),
        ),
        Text(displayName, style: bold ? hoverTitleEntry : hoverSmallEntry),
        Text(displayValue, style: hoverValueEntry),
      ];
    }

    final rowChildren = <Widget>[];

    rowChildren.addAll(
      hoverPartImageLine(
        name,
        image: image,
        colorPatch: colorPatch,
        dashed: dashed,
      ),
    );
    return Container(
      margin: const EdgeInsets.only(left: 5, bottom: 2),
      child: Row(
        children: rowChildren,
      ),
    );
  }

  void _hideHover() {
    if (_hoverOverlayEntry != null) {
      widget.chartController.event.tapLocation.value = null;
      widget.chartController.vm.tapLocation.value = null;
      widget.chartController.android.tapLocation.value = null;

      _hoverOverlayEntry?.remove();
      _hoverOverlayEntry = null;
    }
  }

  List<Widget> _displayExtensionEventsInHover(ChartsValues chartsValues) {
    final widgets = <Widget>[];

    final eventsDisplayed = chartsValues.extensionEventsToDisplay;

    for (var entry in eventsDisplayed.entries) {
      if (entry.key.endsWith(eventsDisplayName)) {
        widgets.add(
          Container(
            height: _hoverEventsHeight,
            child: ListView(
              shrinkWrap: true,
              primary: false,
              children: [
                _listItem(
                  allEvents: chartsValues.extensionEvents,
                  title: entry.key,
                ),
              ],
            ),
          ),
        );
      } else {
        widgets.add(_hoverRow(name: entry.key, image: entry.value));

        /// Pull out the event name, and custom values.
        final output =
            _displayEvent(null, chartsValues.extensionEvents.first).trim();
        widgets.add(_hoverRow(name: output, bold: false));
      }
    }
    return widgets;
  }

  List<Widget> _displayEventsInHover(ChartsValues chartsValues) {
    final results = <Widget>[];

    final colorScheme = Theme.of(context).colorScheme;
    final eventsDisplayed = chartsValues.eventsToDisplay(colorScheme.isLight);

    for (var entry in eventsDisplayed.entries) {
      final widget = _hoverRow(name: ' ${entry.key}', image: entry.value);
      results.add(widget);
    }

    return results;
  }

  Widget _listItem({
    required List<Map<String, Object>> allEvents,
    required String title,
  }) {
    final widgets = <Widget>[];
    var index = 1;
    for (var event in allEvents) {
      final output = _displayEvent(index, event);
      widgets.add(_cardWidget(output));
      index++;
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hoverTextStyle = theme.hoverTextStyle;
    final contrastForeground = colorScheme.contrastForeground;
    final collapsedColor = colorScheme.defaultBackgroundColor;

    return Material(
      color: Colors.transparent,
      child: Theme(
        data: ThemeData(unselectedWidgetColor: contrastForeground),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.only(left: 5, top: 4),
            child: Image(
              image: allEvents.length > 1
                  ? const AssetImage(eventsLegend)
                  : const AssetImage(eventLegend),
            ),
          ),
          backgroundColor: collapsedColor,
          collapsedBackgroundColor: collapsedColor,
          title: Text(title, style: hoverTextStyle),
          children: widgets,
        ),
      ),
    );
  }

  Widget _cardWidget(String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hoverValueEntry = theme.hoverSmallValueTextStyle;
    final expandedGradient = colorScheme.verticalGradient;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      width: _hoverWidth,
      decoration: BoxDecoration(
        gradient: expandedGradient,
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: hoverValueEntry,
          ),
        ],
      ),
    );
  }

  String _displayEvent(int? index, Map<String, Object> event) {
    final output = StringBuffer();

    String? name;

    if (event[eventName] == devToolsEvent && event.containsKey(customEvent)) {
      final custom = event[customEvent] as Map<dynamic, dynamic>;
      name = custom[customEventName];
    } else {
      name = event[eventName] as String?;
    }

    output.writeln(index == null ? name : '$index. $name');
    output.write(_decodeEventValues(event));

    return output.toString();
  }

  String _decodeEventValues(Map<String, Object> event) {
    final output = StringBuffer();
    if (event[eventName] == imageSizesForFrameEvent) {
      // TODO(terry): Need a more generic event displayer.
      // Flutter event emit the event name and value.
      final data = (event[eventData] as Map).cast<String, Object>();
      final key = data.keys.first;
      output.writeln('${_longValueToShort(key)}');
      final values = data[key] as Map<dynamic, dynamic>;
      final displaySize = values[displaySizeInBytesData];
      final decodeSize = values[decodedSizeInBytesData];
      final outputSizes = '$displaySize/$decodeSize';
      if (outputSizes.length > 10) {
        output.writeln('Display/Decode Size=');
        output.write('    $outputSizes');
      } else {
        output.write('Display/Decode Size=$outputSizes');
      }
    } else if (event[eventName] == devToolsEvent &&
        event.containsKey(customEvent)) {
      final custom = event[customEvent] as Map<dynamic, dynamic>;
      final data = custom[customEventData];
      for (var key in data.keys) {
        output.write('$key=');
        output.writeln('${_longValueToShort(data[key])}');
      }
    } else {
      output.writeln('Unknown Event ${event[eventName]}');
    }

    return output.toString();
  }

  /// Long string need to show first part ... last part.
  static const _longStringLength = 34;
  static const _firstCharacters = 9;
  static const _lastCharacters = 20;

  // TODO(terry): Data could be long need better mechanism for long data e.g.,:
  //                const encoder = JsonEncoder.withIndent('  ');
  //                final displayData = encoder.convert(data);
  String _longValueToShort(String longValue) {
    var value = longValue;
    if (longValue.length > _longStringLength) {
      final firstPart = longValue.substring(0, _firstCharacters);
      final endPart = longValue.substring(longValue.length - _lastCharacters);
      value = '$firstPart...$endPart';
    }
    return value;
  }
}
