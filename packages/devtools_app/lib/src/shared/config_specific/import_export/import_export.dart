// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../../devtools.dart';
import '../../connected_app.dart';
import '../../globals.dart';
import '../../primitives/simple_items.dart';
import '../../primitives/utils.dart';
import '_export_stub.dart'
    if (dart.library.html) '_export_web.dart'
    if (dart.library.io) '_export_desktop.dart';

const devToolsSnapshotKey = 'devToolsSnapshot';
const activeScreenIdKey = 'activeScreenId';
const devToolsVersionKey = 'devtoolsVersion';
const connectedAppKey = 'connectedApp';
const isFlutterAppKey = 'isFlutterApp';
const isProfileBuildKey = 'isProfileBuild';
const isDartWebAppKey = 'isDartWebApp';
const isRunningOnDartVMKey = 'isRunningOnDartVM';
const flutterVersionKey = 'flutterVersion';
const nonDevToolsFileMessage = 'The imported file is not a Dart DevTools file.'
    ' At this time, DevTools only supports importing files that were originally'
    ' exported from DevTools.';

String attemptingToImportMessage(String devToolsScreen) {
  return 'Attempting to import file for screen with id "$devToolsScreen".';
}

String successfulExportMessage(String exportedFile) {
  return 'Successfully exported $exportedFile to ~/Downloads directory';
}

// TODO(kenz): we should support a file picker import for desktop.
class ImportController {
  ImportController(
    this._pushSnapshotScreenForImport,
  );

  static const repeatImportTimeBufferMs = 500;

  final void Function(String screenId) _pushSnapshotScreenForImport;

  DateTime? previousImportTime;

  // TODO(kenz): improve error handling here or in snapshot_screen.dart.
  void importData(DevToolsJsonFile jsonFile) {
    final _json = jsonFile.data;

    // Do not allow two different imports within 500 ms of each other. This is a
    // workaround for the fact that we get two drop events for the same file.
    final now = DateTime.now();
    if (previousImportTime != null &&
        (now.millisecondsSinceEpoch -
                    previousImportTime!.millisecondsSinceEpoch)
                .abs() <
            repeatImportTimeBufferMs) {
      return;
    }
    previousImportTime = now;

    final isDevToolsSnapshot =
        _json is Map<String, dynamic> && _json[devToolsSnapshotKey] == true;
    if (!isDevToolsSnapshot) {
      notificationService.push(nonDevToolsFileMessage);
      return;
    }

    final devToolsSnapshot = _json;
    // TODO(kenz): support imports for more than one screen at a time.
    final activeScreenId = devToolsSnapshot[activeScreenIdKey];
    final connectedApp =
        (devToolsSnapshot[connectedAppKey] ?? <String, Object>{})
            .cast<String, Object>();
    offlineController
      ..enterOfflineMode()
      ..offlineDataJson = devToolsSnapshot;
    serviceManager.connectedApp = OfflineConnectedApp.parse(connectedApp);
    notificationService.push(attemptingToImportMessage(activeScreenId));
    _pushSnapshotScreenForImport(activeScreenId);
  }
}

enum ExportFileType {
  json,
  csv,
  yaml;

  @override
  String toString() {
    switch (this) {
      case json:
        return 'json';
      case csv:
        return 'csv';
      case yaml:
        return 'yaml';
      default:
        throw UnimplementedError('Unable to convert $this to a string');
    }
  }
}

abstract class ExportController {
  factory ExportController() {
    return createExportController();
  }

  const ExportController.impl();

  static String generateFileName({
    String prefix = 'dart_devtools',
    String postfix = '',
    required ExportFileType type,
    DateTime? time,
  }) {
    time ??= DateTime.now();
    final timestamp = DateFormat('yyyy-MM-dd_HH:mm:ss.SSS').format(time);
    return '${prefix}_$timestamp$postfix.$type';
  }

  /// Downloads a file with [contents]
  /// and pushes notification about success if [notify] is true.
  String downloadFile(
    String content, {
    String? fileName,
    ExportFileType type = ExportFileType.json,
    bool notify = true,
  }) {
    fileName ??= ExportController.generateFileName(type: type);
    saveFile(
      content: content,
      fileName: fileName,
    );
    notificationService.push(successfulExportMessage(fileName));
    return fileName;
  }

  /// Saves [content] to the [fileName].
  void saveFile({
    required String content,
    required String fileName,
  });

  String encode(String activeScreenId, Map<String, dynamic> contents) {
    final _contents = {
      devToolsSnapshotKey: true,
      activeScreenIdKey: activeScreenId,
      devToolsVersionKey: version,
      connectedAppKey: {
        isFlutterAppKey: serviceManager.connectedApp!.isFlutterAppNow,
        isProfileBuildKey: serviceManager.connectedApp!.isProfileBuildNow,
        isDartWebAppKey: serviceManager.connectedApp!.isDartWebAppNow,
        isRunningOnDartVMKey: serviceManager.connectedApp!.isRunningOnDartVM,
      },
      if (serviceManager.connectedApp!.flutterVersionNow != null)
        flutterVersionKey:
            serviceManager.connectedApp!.flutterVersionNow!.version,
    };
    // This is a workaround to guarantee that DevTools exports are compatible
    // with other trace viewers (catapult, perfetto, chrome://tracing), which
    // require a top level field named "traceEvents".
    if (activeScreenId == ScreenMetaData.performance.id) {
      final traceEvents = List<Map<String, dynamic>>.from(
        contents[traceEventsFieldName],
      );
      _contents[traceEventsFieldName] = traceEvents;
      contents.remove(traceEventsFieldName);
    }
    return jsonEncode(_contents..addAll({activeScreenId: contents}));
  }
}

class OfflineModeController {
  ValueListenable<bool> get offlineMode => _offlineMode;

  final _offlineMode = ValueNotifier(false);

  Map<String, dynamic> offlineDataJson = {};

  /// Stores the [ConnectedApp] instance temporarily while switching between
  /// offline and online modes.
  ConnectedApp? _previousConnectedApp;

  bool shouldLoadOfflineData(String screenId) {
    return _offlineMode.value &&
        offlineDataJson.isNotEmpty &&
        offlineDataJson[screenId] != null;
  }

  void enterOfflineMode() {
    _previousConnectedApp = serviceManager.connectedApp;
    _offlineMode.value = true;
  }

  void exitOfflineMode() {
    serviceManager.connectedApp = _previousConnectedApp;
    _offlineMode.value = false;
  }
}
