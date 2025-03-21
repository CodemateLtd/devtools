import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../primitives/auto_dispose.dart';
import '../primitives/trees.dart';
import '../primitives/utils.dart';
import 'column_widths.dart';
import 'table_data.dart';

/// Represents the various pinning modes for [FlatTable]:
///
///   - [FlatTablePinBehavior.none] disables item pinning
///   - [FlatTablePinBehavior.pinOriginalToTop] moves the original item from
///     the list of unpinned items to the list of pinned items.
///   - [FlatTablePinBehavior.pinCopyToTop] creates a copy of the original item
///     and inserts it into the list of pinned items, leaving the original item
///     in the list of unpinned items.
enum FlatTablePinBehavior {
  none,
  pinOriginalToTop,
  pinCopyToTop,
}

class FlatTableController<T> extends TableControllerBase<T> {
  FlatTableController({
    required super.columns,
    required super.defaultSortColumn,
    required super.defaultSortDirection,
    super.secondarySortColumn,
    super.columnGroups,
    this.pinBehavior = FlatTablePinBehavior.none,
  });

  /// Determines how elements that request to be pinned are displayed.
  ///
  /// Defaults to [FlatTablePinBehavior.none], which disables pinnning.
  FlatTablePinBehavior pinBehavior;

  /// The unmodified, original data for the active data set [_tableData.value].
  ///
  /// This is reset each time [setData] is called.
  late UnmodifiableListView<T> _originalData;

  @override
  void setData(List<T> data, String key) {
    _originalData = UnmodifiableListView(
      List.of(data),
    );

    // Look up the UI state for [key], and sort accordingly.
    final uiState = _tableUiStateForKey(key);
    sortDataAndNotify(
      columns[uiState.sortColumnIndex],
      uiState.sortDirection,
      secondarySortColumn: secondarySortColumn,
      dataKey: key,
    );
  }

  @override
  void sortDataAndNotify(
    ColumnData<T> column,
    SortDirection direction, {
    ColumnData<T>? secondarySortColumn,
    String? dataKey,
  }) {
    var data = List<T>.of(_originalData);
    pinnedData = <T>[];
    data.sort(
      (T a, T b) => _compareData<T>(
        a,
        b,
        column,
        direction,
        secondarySortColumn: secondarySortColumn,
      ),
    );
    if (pinBehavior != FlatTablePinBehavior.none) {
      // Collect the list of pinned entries. We don't need to sort again since
      // we've already sorted the original data.
      final dataCopy = <T>[];
      for (final entry in data) {
        final pinnableEntry = entry as PinnableListEntry;
        if (pinnableEntry.pinToTop) {
          pinnedData.add(entry);
        }
        if (!pinnableEntry.pinToTop ||
            pinBehavior == FlatTablePinBehavior.pinCopyToTop) {
          dataCopy.add(entry);
        }
      }
      data = dataCopy;
    }
    _tableData.value = TableData<T>(
      data: data,
      key: dataKey ?? _tableData.value.key,
    );

    setTableUiState(sortColumn: column, sortDirection: direction);
  }
}

class TreeTableController<T extends TreeNode<T>>
    extends TableControllerBase<T> {
  TreeTableController({
    required super.columns,
    required super.defaultSortColumn,
    required super.defaultSortDirection,
    super.secondarySortColumn,
    super.columnGroups,
    required this.treeColumn,
    this.autoExpandRoots = false,
  })  : assert(columns.contains(treeColumn)),
        assert(columns.contains(defaultSortColumn));

  /// The column of the table to treat as expandable.
  final TreeColumnData<T> treeColumn;

  final bool autoExpandRoots;

  late List<double> columnWidths;

  late List<T> dataRoots;

  @override
  void setData(List<T> data, String key) {
    dataRoots = data;
    for (final root in dataRoots) {
      if (autoExpandRoots && !root.isExpanded) {
        root.expand();
      }
    }

    // Look up the UI state for [key], and sort accordingly.
    final uiState = _tableUiStateForKey(key);
    sortDataAndNotify(
      columns[uiState.sortColumnIndex],
      uiState.sortDirection,
      secondarySortColumn: secondarySortColumn,
      dataKey: key,
    );
  }

  @override
  void sortDataAndNotify(
    ColumnData<T> column,
    SortDirection direction, {
    ColumnData<T>? secondarySortColumn,
    String? dataKey,
  }) {
    pinnedData = <T>[];
    final sortFunction = (T a, T b) => _compareData<T>(
          a,
          b,
          column,
          direction,
          secondarySortColumn: secondarySortColumn,
        );
    void _sort(T dataObject) {
      dataObject.children
        ..sort(sortFunction)
        ..forEach(_sort);
    }

    dataRoots
      ..sort(sortFunction)
      ..forEach(_sort);

    _setDataAndNotify(dataKey: dataKey);

    setTableUiState(sortColumn: column, sortDirection: direction);
  }

  void _setDataAndNotify({
    bool rebuildFlatList = true,
    List<T> additionalChildrenForColumnWidthComputation = const [],
    String? dataKey,
  }) {
    var dataFlatList = _tableData.value.data;
    if (rebuildFlatList) {
      dataFlatList = buildFlatList(dataRoots);
    }
    columnWidths = computeColumnWidths(
      [
        ...dataFlatList,
        ...additionalChildrenForColumnWidthComputation,
      ],
    );

    _tableData.value = TableData<T>(
      data: dataFlatList,
      key: dataKey ?? _tableData.value.key,
    );
  }

  void updateDataForAnimatingChildren({
    required List<T> animatingChildren,
    bool rebuildFlatList = true,
  }) {
    _setDataAndNotify(
      rebuildFlatList: rebuildFlatList,
      additionalChildrenForColumnWidthComputation: animatingChildren,
    );
  }
}

abstract class TableControllerBase<T> extends DisposableController {
  TableControllerBase({
    required this.columns,
    required this.columnGroups,
    required this.defaultSortColumn,
    required this.defaultSortDirection,
    this.secondarySortColumn,
  });

  final List<ColumnData<T>> columns;

  final List<ColumnGroup>? columnGroups;

  /// The default sort column for tables using this [TableController].
  ///
  /// The currently active sort column will be stored as part of the
  /// [_TableUiState] for the current data (stored in [_tableUiStateByData]).
  final ColumnData<T> defaultSortColumn;

  /// The default [SortDirection] for tables using this [TableController].
  ///
  /// The currently active [SortDirection] will be stored as part of the
  /// [_TableUiState] for the current data (stored in [_tableUiStateByData]).
  final SortDirection defaultSortDirection;

  /// The column to be used by the table sorting algorithm to break a tie for
  /// two data rows that are "the same" when sorted by the primary sort column.
  final ColumnData<T>? secondarySortColumn;

  ScrollController? verticalScrollController;

  void initScrollController([double initialScrollOffset = 0.0]) {
    verticalScrollController =
        ScrollController(initialScrollOffset: initialScrollOffset);
  }

  void storeScrollPosition() {
    final scrollController = verticalScrollController;
    if (scrollController != null && scrollController.hasClients) {
      setTableUiState(scrollOffset: scrollController.offset);
    }
  }

  /// The key for the current table data.
  ///
  /// The value assigned to [TableData.key] will only be used if
  /// [persistUiStates] has been set to true. Otherwise, all data sets will be
  /// assigned to and looked up from the key [TableData.defaultDataKey].
  String get _currentDataKey => _tableData.value.key;

  ValueListenable<TableData<T>> get tableData => _tableData;

  final _tableData = ValueNotifier<TableData<T>>(TableData<T>.empty());

  /// The pinned data for the active data set [_tableData.value].
  ///
  /// This value is reset each time [sortDataAndNotify] is called.
  late List<T> pinnedData;

  /// Returns the [_TableUiState] for the current data [_tableData.value].
  _TableUiState get tableUiState => _tableUiStateForKey(_currentDataKey);

  /// This method should be overridden by all subclasses.
  void setData(List<T> data, String key);

  void sortDataAndNotify(
    ColumnData<T> column,
    SortDirection direction, {
    ColumnData<T>? secondarySortColumn,
  });

  _TableUiState _tableUiStateForKey(String key) {
    var state = TableUiStateStore.lookup(key);
    if (state == null) {
      TableUiStateStore.add(
        key,
        _TableUiState(
          sortColumnIndex: columns.indexOf(defaultSortColumn),
          sortDirection: defaultSortDirection,
          // Ignore this lint to make it clear what the default values are.
          // ignore: avoid_redundant_argument_values
          scrollOffset: 0.0,
        ),
      );
      state = TableUiStateStore.lookup(key)!;
    }
    return state;
  }

  void setTableUiState({
    ColumnData<T>? sortColumn,
    SortDirection? sortDirection,
    double? scrollOffset,
  }) {
    final uiState = tableUiState;
    if (sortColumn != null) {
      uiState.sortColumnIndex = columns.indexOf(sortColumn);
    }
    if (sortDirection != null) {
      uiState.sortDirection = sortDirection;
    }
    if (scrollOffset != null) {
      uiState.scrollOffset = scrollOffset;
    }
  }

  @override
  void dispose() {
    verticalScrollController?.dispose();
    verticalScrollController = null;
    super.dispose();
  }
}

class TableData<T> {
  const TableData({
    required this.data,
    String? key,
  }) : key = key ?? defaultDataKey;

  factory TableData.empty() => TableData<T>(data: const []);

  static const defaultDataKey = 'defaultDataKey';

  final List<T> data;

  final String key;
}

class _TableUiState {
  _TableUiState({
    required this.sortColumnIndex,
    required this.sortDirection,
    this.scrollOffset = 0.0,
  });

  SortDirection sortDirection;
  int sortColumnIndex;
  double scrollOffset;

  @override
  String toString() {
    return '_TableUiState($sortColumnIndex - $sortDirection - $scrollOffset)';
  }
}

// Ignoring the 'avoid_classes_with_only_static_members' lint because the static
// members here allow us to add asserts that guarantee unique keys for tables
// across DevTools.
// ignore: avoid_classes_with_only_static_members
/// Stores the [_TableUiState] for each table, keyed on a unique [String].
///
/// This store will remain alive for the entire life of the DevTools instance.
/// This allows us to cache the [_TableUiState] for tables without having to
/// keep table [State] classes or table controller classes alive.
@visibleForTesting
abstract class TableUiStateStore<T> {
  static final _tableUiStateStore = <String, _TableUiState>{};

  static void add(String key, _TableUiState value) {
    assert(
      !_tableUiStateStore.containsKey(key),
      '_TableUiState already exists for key: $key',
    );
    _tableUiStateStore[key] = value;
  }

  static _TableUiState? lookup(String key) {
    return _tableUiStateStore[key];
  }

  @visibleForTesting
  static void clear() => _tableUiStateStore.clear();
}

int _compareFactor(SortDirection direction) =>
    direction == SortDirection.ascending ? 1 : -1;

int _compareData<T>(
  T a,
  T b,
  ColumnData<T> column,
  SortDirection direction, {
  ColumnData<T>? secondarySortColumn,
}) {
  final compare = column.compare(a, b) * _compareFactor(direction);
  if (compare != 0 || secondarySortColumn == null) return compare;

  return secondarySortColumn.compare(a, b) * _compareFactor(direction);
}

/// Callback for when a specific item in a table is selected.
typedef ItemSelectedCallback<T> = void Function(T item);
