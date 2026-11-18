// Aba Status: funcionamento do gateway desde que ligou (GET /status a cada 5 s).
import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/session.dart';
import '../ui/widgets.dart';
import 'gw_logic.dart';

class GwStatusTab extends StatelessWidget {
  const GwStatusTab({super.key, required this.session});

  final DeviceSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final st = session.status;
        final gw = st?['gw'] as Map?;
        final mqtt = st?['mqtt'] as Map?;
        final gps = st?['gps'] as Map?;
        final children = <Widget>[];
        if (session.statusError != null) {
          children.add(const StatusBanner('Sem resposta do gateway. Tentando de novo…', level: Level.warn));
          children.add(Hint(session.statusError!, top: 0));
          children.add(const SizedBox(height: 10));
        }
        if (gw == null) {
          if (session.statusError == null) children.add(const StatusBanner('Carregando status…'));
        } else {
          final line = gatewayLine(gw);
          final kv = gatewayKv(gw);
          if (gps != null) kv.add(gpsView(gps).card);
          children.addAll([
            SectionCard(
              title: 'Status',
              subtitle: 'Funcionamento do gateway desde que ligou. Atualiza a cada 5 s enquanto esta aba '
                  'estiver aberta${session.statusAt == null ? '' : ' · ${clock(session.statusAt)}'}.',
              children: [
                StatusBanner(line.text, level: line.level),
                KvGrid(kv),
              ],
            ),
          ]);
        }
        if (mqtt != null) {
          final m = mqttLine(mqtt);
          children.add(SectionCard(
            title: 'MQTT',
            subtitle: 'Conexão com o broker. Quando ativado, substitui o envio por UDP.',
            children: [
              StatusBanner(m.text, level: m.level),
              Wrap(spacing: 8, runSpacing: 6, children: [
                for (final c in const [['ca', 'CA'], ['crt', 'Certificado'], ['key', 'Chave']])
                  Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: Icon(mqtt[c[0]] == true ? Icons.verified : Icons.remove_circle_outline, size: 18),
                    label: Text('${c[1]}: ${mqtt[c[0]] == true ? 'instalado' : 'não instalado'}'),
                  ),
              ]),
            ],
          ));
        }
        children.add(const DevFooter('Gateway ESP32 with SX1302'));
        return RefreshIndicator(
          onRefresh: session.refreshStatus,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            physics: const AlwaysScrollableScrollPhysics(),
            children: children,
          ),
        );
      },
    );
  }
}
