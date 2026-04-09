import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:speto/core/providers/providers.dart';
import 'package:speto/speto_app.dart';
import 'package:speto/src/core/bootstrap.dart';

void main() {
  testWidgets('renders onboarding entry screen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          bootstrapProvider.overrideWithValue(SpetoBootstrap.ephemeral()),
        ],
        child: SpetoApp(bootstrap: SpetoBootstrap.ephemeral()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('MARKET'), findsOneWidget);
  });
}
