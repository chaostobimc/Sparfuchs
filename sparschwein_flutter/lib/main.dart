import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'app.dart';
import 'app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('de_DE');
  Intl.defaultLocale = 'de_DE';
  runApp(const SparschweinRoot());
}

class SparschweinRoot extends StatelessWidget {
  const SparschweinRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sparschwein',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: const Locale('de', 'DE'),
      supportedLocales: const [Locale('de', 'DE')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SparschweinApp(),
    );
  }
}
