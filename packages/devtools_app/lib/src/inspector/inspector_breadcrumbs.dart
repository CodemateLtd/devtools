import 'package:flutter/material.dart';

import '../../devtools_app.dart';
import 'inspector_text_styles.dart';

class InspectorBreadcrumbNavigator extends StatefulWidget {
  const InspectorBreadcrumbNavigator({
    Key key,
    @required this.rows,
    @required this.onTap,
  })  : assert(rows != null),
        super(key: key);

  final List<InspectorTreeRow> rows;
  final Function(InspectorTreeRow) onTap;

  @override
  State<InspectorBreadcrumbNavigator> createState() =>
      _InspectorBreadcrumbNavigatorState();
}

class _InspectorBreadcrumbNavigatorState
    extends State<InspectorBreadcrumbNavigator> {
  ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rows.isEmpty) {
      return const SizedBox();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Scroll to the end of the list so the last breadcrumb is always visible
      if (_scrollController.hasClients) {
        _scrollController.autoScrollToBottom();
      }
    });

    final items = _getBreadcrumbs(widget.rows);
    return SizedBox(
      height: isDense() ? 24 : 32,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = index == items.length - 1;
          return _InspectorBreadcrumb(
            data: item,
            isSelected: isSelected,
            onTap: isSelected ? null : () => widget.onTap(item.row),
          );
        },
        separatorBuilder: (context, index) {
          return Icon(
            Icons.chevron_right,
            size: defaultIconSize,
          );
        },
      ),
    );
  }

  List<_InspectorBreadcrumbData> _getBreadcrumbs(List<InspectorTreeRow> rows) {
    final List<_InspectorBreadcrumbData> items =
        rows.map((e) => _InspectorBreadcrumbData(e)).toList();
    if (items.length > 5) {
      return []
        ..add(items[0])
        ..add(_InspectorBreadcrumbData.more())
        ..addAll(items.sublist(items.length - 4, items.length));
    } else {
      return items;
    }
  }
}

class _InspectorBreadcrumb extends StatelessWidget {
  const _InspectorBreadcrumb({
    Key key,
    @required this.data,
    @required this.onTap,
    @required this.isSelected,
  })  : assert(data != null),
        assert(isSelected != null),
        super(key: key);

  static const BorderRadius _borderRadius =
      BorderRadius.all(Radius.circular(4));

  final _InspectorBreadcrumbData data;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      data.text,
      style: regular.copyWith(fontSize: scaleByFontFactor(12.0)),
    );

    final icon = data.icon != null
        ? Padding(
            padding: const EdgeInsets.only(right: iconPadding),
            child: data.icon,
          )
        : null;

    return InkWell(
      onTap: data.row == null ? null : onTap,
      borderRadius: _borderRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: _borderRadius,
          color: isSelected
              ? Theme.of(context).colorScheme.selectedRowBackgroundColor
              : Colors.transparent,
        ),
        child: Row(
          children: [
            if (icon != null) icon,
            text,
          ],
        ),
      ),
    );
  }
}

class _InspectorBreadcrumbData {
  const _InspectorBreadcrumbData(this.row);

  /// Construct a special item for showing '…' symbol between other items
  factory _InspectorBreadcrumbData.more() {
    return const _InspectorBreadcrumbData(null);
  }

  final InspectorTreeRow row;

  String get text => row == null ? '…' : row.node.diagnostic.description;

  Widget get icon => row == null ? null : row.node.diagnostic.icon;
}
