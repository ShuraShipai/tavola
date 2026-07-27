import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/tavola_app.dart';
import 'core/supabase/supabase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Date and currency presentation uses the restaurant's Indian locale across
  // operational screens. Initialise its symbols before any route can build a
  // DateFormat, otherwise a direct deep-link to Reservations crashes.
  await initializeDateFormatting('en_IN');
  await SupabaseBootstrap.initialize();

  runApp(const ProviderScope(child: TavolaApp()));
}
