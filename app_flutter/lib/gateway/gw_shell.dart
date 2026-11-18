// Tela do gateway depois do login: Status, Configuração, Logs, Diagnósticos
// e Manutenção (os mesmos menus da página web).
import 'package:flutter/material.dart';

import '../core/flavor.dart';
import '../core/format.dart';
import '../core/session.dart';
import '../ui/logs_screen.dart';
import '../ui/lorawan_classes_screen.dart';
import '../ui/reboot_dialog.dart';
import '../ui/widgets.dart';
import 'gw_config_tab.dart';
import 'gw_diag_tab.dart';
import 'gw_logic.dart';
import 'gw_maint_tab.dart';
import 'gw_status_tab.dart';

final gatewayLogStyle = LogStyle(
  err: RegExp(r'ERROR|^E \(|failed|fail', caseSensitive: false),
  warn: RegExp(r'WARN|^W \('),
  ok: RegExp(r'rxpk|JSON up'),
  filterHint: 'Filtrar (ex.: rxpk, ERROR, mqtt)',
  deviceDownloadLabel: 'Baixar do gateway (até 16 KB em RAM)',
  sessionPrefix: 'esp32_sx1302_sessao',
  defaultDownloadName: 'esp32_sx1302.log',
);

class GatewayShell extends StatefulWidget {
  const GatewayShell({super.key, required this.session});

  final DeviceSession session;

  @override
  State<GatewayShell> createState() => _GatewayShellState();
}

class _GatewayShellState extends State<GatewayShell> with WidgetsBindingObserver {
  int _tab = 0;
  bool _fg = true;
  bool _authDialog = false;
  bool _rebooting = false;
  final GlobalKey<GatewayConfigTabState> _cfgKey = GlobalKey<GatewayConfigTabState>();

  DeviceSession get s => widget.session;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    s.addListener(_onSession);
    _applyPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    s.removeListener(_onSession);
    s.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _fg = state == AppLifecycleState.resumed;
    _applyPolling();
    setState(() {});
  }

  /// Status a cada 5 s só com Status ou Configuração na tela (como a aba visível da página).
  void _applyPolling() => s.setPolling(_fg && (_tab == 0 || _tab == 1));

  /// Login recusado em qualquer aba (Status, Configuração, Logs...): avisa e volta
  /// para a lista. Durante o reinício quem cuida é a janela "Reiniciando…".
  void _onSession() {
    if (s.authLost && !_authDialog && !_rebooting && mounted) {
      _authDialog = true;
      // fecha o que estiver aberto por cima (diálogo de erro, menu) antes de avisar
      Navigator.of(context).popUntil((r) => r is PageRoute);
      messageDialog(context, 'Login recusado',
              'O gateway não aceitou mais o usuário/senha (o login foi trocado?). Entre de novo.')
          .then((_) {
        if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
      });
    }
  }

  Future<void> _reboot({bool ask = true}) async {
    if (ask && !await confirmDialog(context, 'Reiniciar', 'Reiniciar o gateway agora?', confirm: 'Reiniciar')) {
      return;
    }
    s.setPolling(false);
    _rebooting = true;
    try {
      await s.api.postRestart('/reboot');
    } catch (e) {
      _rebooting = false;
      if (mounted) messageDialog(context, 'Reiniciar', '$e');
      _applyPolling();
      return;
    }
    if (!mounted) return;
    final back = await waitReboot(context, s, 'gateway');
    _rebooting = false;
    if (!mounted) return;
    if (!back || s.authLost) {
      Navigator.of(context).popUntil((r) => r.isFirst);
      return;
    }
    _applyPolling();
  }

  Future<void> _leave() async {
    final dirty = _cfgKey.currentState?.dirty ?? false;
    final ok = await confirmDialog(
      context,
      'Sair',
      dirty
          ? 'Há alterações não salvas na Configuração. Sair mesmo assim?'
          : 'Sair da configuração do gateway?',
      confirm: 'Sair',
    );
    if (ok && mounted) Navigator.of(context).pop();
  }

  void _setTab(int i) {
    setState(() => _tab = i);
    _applyPolling();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: AnimatedBuilder(
        animation: s,
        builder: (context, _) {
          final mqtt = s.status?['mqtt'] as Map?;
          final region = sv(s.config['freq_region']);
          final id = gatewayEui(s.config);
          return Scaffold(
            appBar: AppBar(
              title: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(s.device.name, maxLines: 1, softWrap: false)),
              actions: [
                const ClassesButton(),
                IconButton(onPressed: _leave, icon: const Icon(Icons.logout), tooltip: 'Sair'),
              ],
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // chips com quebra de linha (nunca cortados nem escondidos numa rolagem lateral)
                Container(
                  color: Theme.of(context).appBarTheme.backgroundColor,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  child: InfoChips([
                      ChipInfo(mqttChip(mqtt), '', level: mqttChipLevel(mqtt)),
                      ChipInfo('IP', s.api.host),
                      ChipInfo('Gateway', id.isEmpty ? '-' : id, copy: true),
                      ChipInfo('Plano', gwPlanNames[region] ?? '-'),
                    ]),
                ),
                Expanded(
                  child: IndexedStack(
              index: _tab,
              children: [
                GwStatusTab(session: s),
                GatewayConfigTab(key: _cfgKey, session: s, onReboot: _reboot),
                LogsView(api: s.api, active: _fg && _tab == 2, style: gatewayLogStyle),
                GwDiagTab(session: s),
                GwMaintTab(
                  session: s,
                  onReboot: _reboot,
                  onImport: (j) {
                    final n = _cfgKey.currentState?.importJson(j) ?? 0;
                    if (n > 0) _setTab(1);
                    return n;
                  },
                  onFactoryDone: () async {
                    await s.updateCredentials(AppFlavor.defaultUser, AppFlavor.defaultPassword);
                    if (mounted) Navigator.of(context).pop();
                  },
                ),
              ],
            ),
                ),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: _setTab,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: const [
                NavigationDestination(icon: Icon(Icons.monitor_heart_outlined), label: 'Status'),
                NavigationDestination(icon: Icon(Icons.tune), label: 'Config.'),
                NavigationDestination(icon: Icon(Icons.article_outlined), label: 'Logs'),
                NavigationDestination(icon: Icon(Icons.network_ping), label: 'Diagnóst.'),
                NavigationDestination(icon: Icon(Icons.build_outlined), label: 'Manutenção'),
              ],
            ),
          );
        },
      ),
    );
  }
}
