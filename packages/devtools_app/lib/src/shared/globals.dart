// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../extension_points/extensions_base.dart';
import '../screens/debugger/breakpoint_manager.dart';
import '../service/service_manager.dart';
import '../shared/notifications.dart';
import 'config_specific/ide_theme/ide_theme.dart';
import 'config_specific/import_export/import_export.dart';
import 'framework_controller.dart';
import 'preferences.dart';
import 'primitives/message_bus.dart';
import 'primitives/storage.dart';
import 'scripts/script_manager.dart';
import 'survey.dart';

/// Whether this DevTools build is external.
bool get isExternalBuild => _isExternalBuild;
bool _isExternalBuild = true;
void setInternalBuild() => _isExternalBuild = false;

final Map<Type, Object> globals = <Type, Object>{};

ServiceConnectionManager get serviceManager =>
    globals[ServiceConnectionManager] as ServiceConnectionManager;

ScriptManager get scriptManager => globals[ScriptManager] as ScriptManager;

MessageBus get messageBus => globals[MessageBus] as MessageBus;

FrameworkController get frameworkController =>
    globals[FrameworkController] as FrameworkController;

Storage get storage => globals[Storage] as Storage;

SurveyService get surveyService => globals[SurveyService] as SurveyService;

PreferencesController get preferences =>
    globals[PreferencesController] as PreferencesController;

DevToolsExtensionPoints get devToolsExtensionPoints =>
    globals[DevToolsExtensionPoints] as DevToolsExtensionPoints;

OfflineModeController get offlineController =>
    globals[OfflineModeController] as OfflineModeController;

IdeTheme get ideTheme => globals[IdeTheme] as IdeTheme;

NotificationService get notificationService =>
    globals[NotificationService] as NotificationService;

BreakpointManager get breakpointManager =>
    globals[BreakpointManager] as BreakpointManager;

void setGlobal(Type clazz, Object instance) {
  globals[clazz] = instance;
}
