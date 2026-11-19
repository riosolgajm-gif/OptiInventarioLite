
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pages/login_page.dart';
import 'pages/inicio_page.dart';

const String supabaseUrl =
    'https://sojzbcuklgbikmuivjdz.supabase.co';

const String supabasePublishableKey =
    'sb_publishable_Jgopx7ZMyQsXj2-6KHKjPA_YSy6Mb4v';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );

  runApp(const OptiInventarioLite());
}

class OptiInventarioLite extends StatelessWidget {
  const OptiInventarioLite({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OptiInventario Lite',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1765BD),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F8FD),
      ),
      home: const ControlAcceso(),
    );
  }
}

class ControlAcceso extends StatelessWidget {
  const ControlAcceso({super.key});

  @override
  Widget build(BuildContext context) {
    final sesion = Supabase.instance.client.auth.currentSession;

    if (sesion != null) {
      return const InicioPage();
    }

    return const LoginPage();
  }
}
