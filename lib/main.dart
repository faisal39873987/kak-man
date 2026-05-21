import 'package:flutter/widgets.dart';

import 'backend/supabase_backend.dart';
import 'core/app/nerve_runner_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseBackend.initialize();
  runApp(const NerveRunnerApp());
}
