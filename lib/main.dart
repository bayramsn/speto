import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/firebase/firebase_email_link_service.dart';
import 'core/providers/providers.dart';
import 'features/events/event_data.dart';
import 'speto_app.dart';
import 'src/core/bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SpetoFirebaseEmailLinkService.instance.initialize();
  await initializeSpetoCatalog();

  final SpetoBootstrap bootstrap = await SpetoBootstrap.persistent();

  runApp(
    ProviderScope(
      overrides: [bootstrapProvider.overrideWithValue(bootstrap)],
      child: SpetoApp(bootstrap: bootstrap),
    ),
  );
}
