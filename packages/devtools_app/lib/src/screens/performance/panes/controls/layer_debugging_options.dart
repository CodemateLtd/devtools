// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../../../service/service_extension_widgets.dart';
import '../../../../service/service_extensions.dart' as extensions;
import '../../../../shared/feature_flags.dart';
import '../../../../shared/globals.dart';
import '../../../../shared/theme.dart';
import '../../performance_screen.dart';

class MoreDebuggingOptionsButton extends StatelessWidget {
  const MoreDebuggingOptionsButton({Key? key}) : super(key: key);

  static const _width = 720.0;

  @override
  Widget build(BuildContext context) {
    return ServiceExtensionCheckboxGroupButton(
      title: 'More debugging options',
      icon: Icons.build,
      tooltip: 'Opens a list of options you can use to help debug performance',
      minScreenWidthForTextBeforeScaling:
          SecondaryPerformanceControls.minScreenWidthForTextBeforeScaling,
      extensions: [
        extensions.disableClipLayers,
        extensions.disableOpacityLayers,
        extensions.disablePhysicalShapeLayers,
        if (FeatureFlags.widgetRebuildstats) extensions.trackRebuildWidgets,
      ],
      overlayDescription: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'After toggling a rendering layer on/off, '
            'reproduce the activity in your app to see the effects. '
            'All layers are rendered by default - disabling a '
            'layer might help identify expensive operations in your app.',
            style: Theme.of(context).subtleTextStyle,
          ),
          if (serviceManager.connectedApp!.isProfileBuildNow!) ...[
            const SizedBox(height: denseSpacing),
            RichText(
              text: TextSpan(
                text:
                    "These debugging options aren't available in profile mode. "
                    'To use them, run your app in debug mode.',
                style: Theme.of(context).subtleErrorTextStyle,
              ),
            ),
          ],
        ],
      ),
      overlayWidthBeforeScaling: _width,
    );
  }
}
