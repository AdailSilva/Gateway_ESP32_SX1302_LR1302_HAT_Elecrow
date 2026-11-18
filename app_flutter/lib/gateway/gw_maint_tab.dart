// Aba Manutenção: exportar/importar configuração, padrão de fábrica e reinício.
import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/device_api.dart';
import '../core/file_io.dart';
import '../core/format.dart';
import '../core/html_text.dart';
import '../core/session.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

class GwMaintTab extends StatelessWidget {
  const GwMaintTab({
    super.key,
    required this.session,
    required this.onImport,
    required this.onReboot,
    required this.onFactoryDone,
  });

  final DeviceSession session;

  /// Preenche a aba Configuração; devolve quantos campos foram usados.
  final int Function(Map<String, dynamic> json) onImport;
  final Future<void> Function({bool ask}) onReboot;
  final VoidCallback onFactoryDone;

  DeviceApi get api => session.api;

  Future<void> _export(BuildContext context) async {
    try {
      final j = await api.getJson('/config.json');
      final id = gatewayEui(j).replaceAll(RegExp(r'[^0-9A-Za-z]'), '');
      final name = 'gateway_${id.isEmpty ? 'esp32_sx1302' : id}_${dateStamp()}.json';
      final text = '${const JsonEncoder.withIndent('  ').convert(j)}\n';
      final path = await FileIO.saveText(name, text);
      if (context.mounted && path != null) snack(context, 'Salvo: $name');
    } on ApiException catch (e) {
      if (context.mounted && !e.unauthorized) messageDialog(context, 'Exportar', 'Não foi possível ler a configuração do gateway.\n${e.message}');
    } catch (e) {
      if (context.mounted) snack(context, 'Não foi possível salvar: $e');
    }
  }

  Future<void> _import(BuildContext context) async {
    String? text;
    try {
      text = await FileIO.pickText(extensions: const ['json']);
    } catch (e) {
      if (context.mounted) snack(context, 'Não foi possível abrir o arquivo: $e');
      return;
    }
    if (text == null || !context.mounted) return;
    Map<String, dynamic> j;
    try {
      final v = jsonDecode(text);
      if (v is! Map<String, dynamic>) throw const FormatException();
      j = v;
    } catch (_) {
      messageDialog(context, 'Importar', 'Arquivo JSON inválido.');
      return;
    }
    if (j['_mode'] != null) {
      messageDialog(context, 'Importar', 'Este arquivo é de um nó LoRaWAN, não do gateway.');
      return;
    }
    if (j['_type'] != 'esp32_sx1302') {
      final go = await confirmDialog(context, 'Importar',
          'Este arquivo não parece ser uma exportação deste gateway. Importar mesmo assim?',
          confirm: 'Importar');
      if (!go || !context.mounted) return;
    }
    final n = onImport(j);
    if (!context.mounted) return;
    if (n == 0) {
      messageDialog(context, 'Importar', 'Nenhum campo do gateway encontrado no arquivo.');
    } else {
      snack(context, 'Configuração carregada no formulário. Revise, informe as senhas se precisar e toque em Salvar.');
    }
  }

  Future<void> _factory(BuildContext context) async {
    final ok = await confirmDialog(
      context,
      'Restaurar padrão de fábrica',
      'Apagar toda a configuração salva (Wi-Fi, LoRaWAN, MQTT e certificados, GPS e login) e voltar aos '
          'valores de fábrica?\nO gateway reinicia em modo Soft AP (rede lorawan-gateway-sx1302, 192.168.101.101) e o login '
          'volta para admin / lorawan101.',
      confirm: 'Restaurar',
      danger: true,
    );
    if (!ok || !context.mounted) return;
    String? html;
    try {
      html = await api.postRestart('/factory');
    } on ApiException catch (e) {
      if (context.mounted && !e.unauthorized) messageDialog(context, 'Padrão de fábrica', e.message);
      return;
    }
    if (!context.mounted) return;
    final page = html == null ? null : parseSimplePage(html);
    if (page != null && page.isError) {
      messageDialog(context, page.title, page.body);
      return;
    }
    await messageDialog(
      context,
      page?.title.isNotEmpty == true ? page!.title : 'Padrão de fábrica restaurado',
      page?.body.isNotEmpty == true
          ? page!.body
          : 'O gateway está reiniciando sem nenhuma configuração salva e sobe em modo Soft AP. '
              'Conecte na rede lorawan-gateway-sx1302 (senha lorawan101) e abra 192.168.101.101. Login: admin / lorawan101.',
    );
    onFactoryDone();
  }

  @override
  Widget build(BuildContext context) {
    final cfg = session.config;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        SectionCard(
          title: 'Manutenção',
          subtitle: 'Cópia de segurança da configuração e volta ao padrão de fábrica.',
          children: [
            Wrap(spacing: 10, runSpacing: 10, children: [
              FilledButton.tonalIcon(
                onPressed: () => _export(context),
                icon: const Icon(Icons.download),
                label: const Text('Exportar configuração'),
              ),
              OutlinedButton.icon(
                onPressed: () => _import(context),
                icon: const Icon(Icons.upload_file),
                label: const Text('Importar…'),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.errOf(context)),
                onPressed: () => _factory(context),
                icon: const Icon(Icons.restore),
                label: const Text('Restaurar padrão de fábrica'),
              ),
            ]),
            const Hint(
                'A exportação gera um JSON com a configuração salva, menos as senhas (Wi-Fi, MQTT e página) e os '
                'certificados TLS. Importar preenche o formulário da aba Configuração; revise, informe as senhas '
                'se precisar e toque em Salvar. O padrão de fábrica apaga toda a configuração salva, inclusive os '
                'certificados TLS, e o gateway reinicia em modo Soft AP.',
                top: 10),
          ],
        ),
        SectionCard(
          title: 'Reiniciar',
          subtitle: 'Reinicia o ESP32. Wi-Fi, servidor LoRaWAN, rádio e inicialização passam a valer.',
          children: [
            FilledButton.icon(
              onPressed: () => onReboot(ask: true),
              icon: const Icon(Icons.restart_alt),
              label: const Text('Reiniciar gateway'),
            ),
          ],
        ),
        SectionCard(
          title: 'Firmware',
          children: [
            KvGrid([
              KvItem('Versão', sv(cfg['_version']).isEmpty ? '-' : sv(cfg['_version'])),
              // _board_name / _board come from firmware with the three board builds;
              // older firmware only sends _target (esp32 = WROOM-32U, esp32s3 = WROOM-2 N32R16V).
              KvItem('Placa',
                  sv(cfg['_board_name']).isNotEmpty
                      ? sv(cfg['_board_name'])
                      : sv(cfg['_target']) == 'esp32s3' ? 'ESP32-S3-WROOM-2-N32R16V' : sv(cfg['_target']) == 'esp32' ? 'ESP32-WROOM-32U' : sv(cfg['_target']),
                  '${sv(cfg['_board']).isNotEmpty ? sv(cfg['_board']) : sv(cfg['_target'])} · ${sv(cfg['_target']) == 'esp32s3' ? 'com mDNS' : 'sem mDNS'}'),
              KvItem('Endereço', api.baseUrl.replaceAll('http://', '').replaceAll('/', '')),
              KvItem.copyable('Gateway EUI', gatewayEui(cfg).isEmpty ? '-' : gatewayEui(cfg),
                  !cfg.containsKey('_gw_eui')
                      ? ''
                      : sv(cfg['gw_id']).isEmpty
                          ? 'automático (MAC do Wi-Fi + FFFE)'
                          : 'manual (sobrescrito)'),
            ]),
          ],
        ),
        const DevFooter('Gateway ESP32 with SX1302'),
      ],
    );
  }
}
