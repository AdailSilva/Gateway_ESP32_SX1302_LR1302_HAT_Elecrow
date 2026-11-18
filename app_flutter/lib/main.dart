// App Android do gateway ESP32_SX1302 (ESP32 + SX1302 / LR1302 HAT).
// Mesmas funções da página web do firmware: login, status, configuração,
// logs, diagnósticos e manutenção.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_host.dart';
import 'core/flavor.dart';
import 'gateway/gw_shell.dart';
import 'ui/devices_screen.dart';
import 'ui/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  appHost = AppHost(
    flavor: const AppFlavor(
      kind: DeviceKind.gateway,
      appTitle: 'Gateway ESP32 SX1302',
      deviceNoun: 'gateway',
      defaultApSsid: 'lorawan-gateway-sx1302',
      apHint: 'Gateway em modo Soft AP (escolhido em Inicialização, BOOT segurado logo após ligar, '
          'Wi-Fi sem conexão ou padrão de fábrica): rede "lorawan-gateway-sx1302", senha lorawan101.',
    ),
    shellBuilder: (s) => GatewayShell(session: s),
  );
  runApp(const GatewayApp());
}

class GatewayApp extends StatelessWidget {
  const GatewayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gateway ESP32 SX1302',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const DevicesScreen(),
    );
  }
}
