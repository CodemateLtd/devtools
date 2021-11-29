import 'package:flutter/material.dart';

import '../../devtools_app.dart';
import 'inspector_text_styles.dart';

class InspectorBreadcrumbNavigator extends StatelessWidget {
  const InspectorBreadcrumbNavigator({
    Key key,
    @required List<InspectorTreeRow> rows,
    @required this.onTap,
  })  : assert(rows != null),
        _rows = rows,
        super(key: key);

  final List<InspectorTreeRow> _rows;
  final Function(InspectorTreeRow) onTap;

  @override
  Widget build(BuildContext context) {
    final items = _getRows();
    return SizedBox(
      height: 32, // TODO smaller when dense mode is on
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = index == items.length - 1;
          return _InspectorBreadcrumb(
            data: item,
            isSelected: isSelected,
            onTap: isSelected ? null : () => onTap(item.row),
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

  List<_InspectorBreadcrumbData> _getRows() {
    final List<_InspectorBreadcrumbData> rows =
        _rows.map((e) => _InspectorBreadcrumbData(e)).toList();
    if (rows.length > 5) {
      return []
        ..add(rows[0])
        ..add(_InspectorBreadcrumbData.more())
        ..addAll(rows.sublist(rows.length - 4, rows.length));
    } else {
      return rows;
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

  final _InspectorBreadcrumbData data;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textStyle = regular.copyWith(fontSize: 12);
    if (data.row == null) {
      return Text(
        '…',
        style: textStyle,
      );
    }

    final text = Text(
      data.text,
      style: textStyle,
    );
    final icon = Padding(
      padding: const EdgeInsets.only(right: iconPadding),
      child: data.icon,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: isSelected
              ? Theme.of(context).colorScheme.selectedRowBackgroundColor
              : Colors.transparent,
        ),
        child: Row(
          children: [icon, text],
        ),
      ),
    );
  }
}

class _InspectorBreadcrumbData {
  const _InspectorBreadcrumbData(this.row);

  /// Construct a special item that shows that there are more items between rows
  factory _InspectorBreadcrumbData.more() {
    return const _InspectorBreadcrumbData(null);
  }

  final InspectorTreeRow row;

  String get text => row.node.diagnostic.description;

  Widget get icon => row.node.diagnostic.icon;
}
