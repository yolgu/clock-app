import 'package:flutter/widgets.dart';

import 'app/public.dart' show AppComposition;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final AppComposition composition = AppComposition.forCurrentPlatform();
  await composition.initialize();
  runApp(composition.buildApp());
}
