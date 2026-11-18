// Aba Configuração do gateway: o mesmo formulário da página (POST /resp).
// Campos vazios mantêm o valor atual; MQTT, GPS e login valem ao salvar,
// o resto depois de reiniciar.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/device_api.dart';
import '../core/file_io.dart';
import '../core/format.dart';
import '../core/html_text.dart';
import '../core/session.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'gw_logic.dart';

class GatewayConfigTab extends StatefulWidget {
  const GatewayConfigTab({super.key, required this.session, required this.onReboot});

  final DeviceSession session;
  final Future<void> Function({bool ask}) onReboot;

  @override
  State<GatewayConfigTab> createState() => GatewayConfigTabState();
}

class GatewayConfigTabState extends State<GatewayConfigTab> {
  static const _textNames = [
    'wifi_ssid', 'wifi_pswd', 'ip_addr', 'ip_mask', 'ip_gw', 'ip_dns1', 'ip_dns2',
    'ns_host', 'ns_port', 'gw_id', 'ntp_server',
    'mqtt_user', 'mqtt_pswd', 'mqtt_topic',
    'web_user', 'web_pswd', 'freq_radio0', 'freq_radio1',
  ];
  static const _radioValues = {
    'wifi_mode': ['station', 'soft_ap'],
    'freq_region': ['au915_sb0', 'au915_sb1', 'cn470', 'eu868', 'us915'],
    'gps_en': ['off', 'on'],
    'ip_mode': ['dhcp', 'static'],
    'mqtt_en': ['off', 'on'],
    'mqtt_fmt': ['semtech', 'chirpstack'],
    'mqtt_enc': ['json', 'protobuf'],
  };
  static const _secret = {'wifi_pswd', 'mqtt_pswd', 'web_pswd'};

  final Map<String, TextEditingController> _c = {};
  final TextEditingController _webPass2 = TextEditingController();

  // Broker MQTT: o firmware guarda uma URI só (mqtt_uri); o formulário mostra
  // Protocolo, Host e Porta separados e junta tudo ao salvar.
  final TextEditingController _mqHost = TextEditingController();
  final TextEditingController _mqPort = TextEditingController();
  String _mqProto = 'mqtts';
  final Map<String, String?> _r = {};
  final Map<String, TextEditingController> _cert = {
    'ca': TextEditingController(),
    'crt': TextEditingController(),
    'key': TextEditingController(),
  };
  final Map<String, GlobalKey> _sec = {
    for (final k in ['wifi', 'lns', 'mqtt', 'radio', 'gps', 'boot', 'acc']) k: GlobalKey(),
  };
  bool _dirty = false;
  bool _saving = false;
  bool _filling = false;
  bool _morePlans = false;
  List<String> _errors = [];
  final ScrollController _scroll = ScrollController();

  DeviceSession get s => widget.session;
  DeviceApi get api => s.api;

  bool get dirty => _dirty;

  @override
  void initState() {
    super.initState();
    for (final n in _textNames) {
      _c[n] = TextEditingController()..addListener(_onText);
    }
    _webPass2.addListener(_onText);
    _mqPort.addListener(_onText);
    _mqHost.addListener(_onHost);
    _fillFromConfig(s.config);
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    for (final c in _cert.values) {
      c.dispose();
    }
    _webPass2.dispose();
    _mqHost.dispose();
    _mqPort.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onText() {
    if (_filling) return;
    if (!_dirty) {
      setState(() => _dirty = true);
    } else {
      setState(() {}); // placeholders dependem de outros campos
    }
  }

  /// Colar uma URI inteira no host (mqtts://host:8883) preenche os três campos.
  void _onHost() {
    if (!_filling && RegExp(r'^\s*(mqtts?|wss?)://', caseSensitive: false).hasMatch(_mqHost.text)) {
      _setBroker(_mqHost.text);
    }
    _onText();
  }

  /// URI salva -> Protocolo, Host e Porta.
  void _setBroker(String uri) {
    final was = _filling;
    _filling = true;
    final b = splitBrokerUri(uri);
    _mqProto = b?.proto ?? 'mqtts';
    final host = b?.host ?? uri.trim();
    _mqHost.value = TextEditingValue(text: host, selection: TextSelection.collapsed(offset: host.length));
    _mqPort.text = b?.port ?? '';
    _filling = was;
  }

  /// Trocar o protocolo troca a porta só se ela era a padrão do anterior.
  void _setProto(String v) {
    setState(() {
      final old = mqttProtocols[_mqProto]?.port;
      if (old != null && _mqPort.text.trim() == '$old') {
        _filling = true;
        _mqPort.text = '${mqttProtocols[v]!.port}';
        _filling = false;
      }
      _mqProto = v;
      _dirty = true;
    });
  }

  String get _brokerUri => joinBrokerUri(_mqProto, _mqHost.text, _mqPort.text);

  String t(String n) => _c[n]!.text;

  /// Valores salvos, com as mesmas regras da página montada pelo firmware.
  void _fillFromConfig(Map<String, dynamic> cfg) {
    _filling = true;
    for (final n in _textNames) {
      if (_secret.contains(n)) {
        _c[n]!.text = '';
      } else {
        _c[n]!.text = sv(cfg[n]);
      }
    }
    if (t('ntp_server').isEmpty) _c['ntp_server']!.text = 'br.pool.ntp.org';
    _setBroker(sv(cfg['mqtt_uri']));
    _webPass2.text = '';
    final wm = sv(cfg['wifi_mode']);
    _r['wifi_mode'] = (wm == 'soft_ap' || wm == 'station') ? wm : null;
    final fr = sv(cfg['freq_region']);
    _r['freq_region'] = _radioValues['freq_region']!.contains(fr) ? fr : null;
    _r['gps_en'] = sv(cfg['gps_en']) == 'on' ? 'on' : 'off';
    _r['ip_mode'] = sv(cfg['ip_mode']) == 'static' ? 'static' : 'dhcp';
    _r['mqtt_en'] = sv(cfg['mqtt_en']) == 'on' ? 'on' : 'off';
    _r['mqtt_fmt'] = sv(cfg['mqtt_fmt']) == 'chirpstack' ? 'chirpstack' : 'semtech';
    _r['mqtt_enc'] = sv(cfg['mqtt_enc']) == 'protobuf' ? 'protobuf' : 'json';
    _morePlans = ['cn470', 'eu868', 'us915'].contains(_r['freq_region']);
    _filling = false;
    _dirty = false;
    _errors = [];
  }

  /// "Importar…" da Manutenção: preenche o formulário (sem senhas). Devolve quantos campos.
  int importJson(Map<String, dynamic> j) {
    var n = 0;
    _filling = true;
    j.forEach((k, v) {
      if (k.startsWith('_') || _secret.contains(k) || v == null) return;
      final val = '$v';
      if (_radioValues.containsKey(k)) {
        if (_radioValues[k]!.contains(val)) {
          _r[k] = val;
          n++;
        }
      } else if (k == 'mqtt_uri') {
        _setBroker(val);
        n++;
      } else if (_c.containsKey(k)) {
        _c[k]!.text = val;
        n++;
      }
    });
    _filling = false;
    if (['cn470', 'eu868', 'us915'].contains(_r['freq_region'])) _morePlans = true;
    setState(() => _dirty = true);
    return n;
  }

  void _radio(String name, String v) {
    setState(() {
      _r[name] = v;
      _dirty = true;
    });
  }

  // ------------------------------ validação ------------------------------
  List<String> _check() {
    final e = <String>[];
    final plan = gwPlans[_r['freq_region']];
    for (var i = 0; i < 2; i++) {
      final v = t('freq_radio$i').trim();
      if (v.isEmpty) continue;
      final ok = RegExp(r'^\d{9}$').hasMatch(v) &&
          (plan == null || (int.parse(v) >= plan[2] * 1000000 && int.parse(v) <= plan[3] * 1000000));
      if (!ok) {
        e.add('Rádio ${i + 1}: use 9 dígitos em Hz${plan != null ? ', entre ${plan[2]} e ${plan[3]} MHz.' : '.'}');
      }
    }
    var v = t('wifi_pswd');
    if (v.isNotEmpty && v.length < 8) e.add('Senha do Wi-Fi: mínimo de 8 caracteres.');
    if (_r['ip_mode'] == 'static') {
      e.addAll(validateStaticIp(t, (n, val) => _c[n]!.text = val));
    }
    v = t('ns_host').trim();
    if (v.isNotEmpty && !RegExp(r'^[0-9A-Za-z.-]+$').hasMatch(v)) {
      e.add('Host: só IP ou domínio, sem http:// e sem espaços.');
    }
    v = t('ns_port').trim();
    if (v.isNotEmpty) {
      final p = int.tryParse(v);
      if (!RegExp(r'^\d+$').hasMatch(v) || p == null || p < 1 || p > 65535) {
        e.add('Porta: número entre 1 e 65535.');
      }
    }
    v = t('gw_id').trim();
    if (v.isNotEmpty && !RegExp(r'^[0-9A-Fa-f]{16}$').hasMatch(v)) {
      e.add('Gateway EUI: exatamente 16 caracteres de 0–9 e A–F (ou vazio para o automático).');
    } else {
      _c['gw_id']!.text = v.toUpperCase();
    }
    v = _mqHost.text.trim();
    var auth = v.split('/').first;
    auth = auth.substring(auth.lastIndexOf('@') + 1);
    if (v.isNotEmpty && (RegExp(r'\s').hasMatch(v) || !RegExp(r'^[0-9A-Za-z.-]+$').hasMatch(auth))) {
      e.add('Host do broker: só IP ou domínio, sem espaços e sem a porta (o protocolo vai na lista e a porta '
          'no campo ao lado).');
    }
    final mp = _mqPort.text.trim();
    if (mp.isNotEmpty) {
      final p = int.tryParse(mp);
      if (!RegExp(r'^\d+$').hasMatch(mp) || p == null || p < 1 || p > 65535) {
        e.add('Porta do broker: número entre 1 e 65535 (vazio usa a padrão do protocolo).');
      }
    }
    if (_r['mqtt_en'] == 'on' && v.isEmpty) e.add('MQTT ativado: informe o host do broker.');
    v = t('web_user').trim();
    if (v.isEmpty || v.length > 31 || v.contains(':') || v == '_logout_') {
      e.add('Usuário da página: 1 a 31 caracteres, sem dois-pontos.');
    }
    v = t('web_pswd');
    if (v.isNotEmpty && (v.length < 6 || v.contains(':'))) {
      e.add('Nova senha da página: mínimo de 6 caracteres, sem dois-pontos.');
    }
    if (v != _webPass2.text) e.add('Nova senha da página: a confirmação não confere.');
    // o firmware só decodifica ASCII no formulário: acentos cortariam o valor
    const ascii = {
      'wifi_ssid': 'Nome da rede (SSID)',
      'wifi_pswd': 'Senha do Wi-Fi',
      'mqtt_uri': 'Host do broker',
      'mqtt_user': 'Usuário do MQTT',
      'mqtt_pswd': 'Senha do MQTT',
      'mqtt_topic': 'Tópico base',
      'web_user': 'Usuário da página',
      'web_pswd': 'Nova senha da página',
      'ntp_server': 'Servidor NTP',
    };
    ascii.forEach((n, label) {
      final val = n == 'mqtt_uri' ? _mqHost.text : t(n);
      if (val.isNotEmpty && !isAscii(val)) {
        e.add('$label: use só caracteres sem acento (ASCII); o gateway corta o resto.');
      }
    });
    return e;
  }

  // -------------------------------- salvar -------------------------------
  Future<void> save() async {
    FocusScope.of(context).unfocus();
    final e = _check();
    setState(() => _errors = e);
    if (e.isNotEmpty) {
      _scroll.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      return;
    }
    final fields = <String, String>{};
    for (final n in _textNames) {
      fields[n] = (n == 'wifi_pswd' || n == 'mqtt_pswd' || n == 'web_pswd') ? t(n) : t(n).trim();
    }
    fields['mqtt_uri'] = _brokerUri;
    _r.forEach((k, v) {
      if (v != null) fields[k] = v;
    });
    final newUser = t('web_user').trim();
    final newPass = t('web_pswd').isNotEmpty ? t('web_pswd') : api.password;
    final loginChanged = newUser != api.user || newPass != api.password;

    setState(() => _saving = true);
    try {
      final r = await api.postForm('/resp', fields);
      final page = parseSimplePage(r.text);
      if (loginChanged) await s.updateCredentials(newUser, newPass);
      try {
        await s.reloadConfig();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _fillFromConfig(s.config);
        _saving = false;
      });
      s.refreshStatus();
      final body = [
        if (page.body.isNotEmpty) page.body else 'Configuração enviada.',
        if (loginChanged) 'O app já passou a usar o novo login.',
      ].join('\n\n');
      await messageDialog(
        context,
        page.title.isEmpty ? 'Configuração salva' : page.title,
        body,
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Voltar')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onReboot(ask: false);
            },
            child: const Text('Reiniciar agora'),
          ),
        ],
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      // login recusado: a tela principal já avisa e volta para a lista
      if (e.unauthorized) return;
      messageDialog(context, 'Não foi possível salvar', e.message);
    }
  }

  // ----------------------------- certificados -----------------------------
  Future<void> _certPick(String type) async {
    try {
      final text = await FileIO.pickText();
      if (text != null && mounted) setState(() => _cert[type]!.text = text);
    } catch (e) {
      if (mounted) snack(context, 'Não foi possível abrir o arquivo: $e');
    }
  }

  Future<void> _certSend(String type, {bool remove = false}) async {
    final body = remove ? '' : _cert[type]!.text.trim();
    if (!remove && !body.contains('-----BEGIN')) {
      snack(context, 'Cole ou escolha um arquivo PEM (-----BEGIN ...).');
      return;
    }
    if (remove && !await confirmDialog(context, 'Remover', 'Remover este certificado?', confirm: 'Remover', danger: true)) {
      return;
    }
    try {
      final r = await api.postText('/mqtt_cert', body, query: {'type': type});
      Map<String, dynamic>? j;
      try {
        j = r.json;
      } catch (_) {}
      if (!mounted) return;
      if (j != null && j['ok'] == true) {
        _cert[type]!.clear();
        snack(context, remove ? 'Certificado removido.' : 'Certificado enviado e aplicado.');
      } else {
        messageDialog(context, 'Falha', '${j?['error'] ?? 'O gateway recusou (HTTP ${r.status}).'}');
      }
    } on ApiException catch (e) {
      if (mounted && !e.unauthorized) messageDialog(context, 'Sem resposta do gateway', e.message);
    }
    s.refreshStatus();
  }

  Future<void> _showPlanJson(String plan) async {
    try {
      final r = await api.get('/$plan');
      final text = preContent(r.text);
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text('${gwPlanNames[plan]} · JSON'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: SelectableText(text, style: const TextStyle(fontFamily: monoFont, fontSize: 11.5)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: text));
                snack(c, 'Copiado.');
              },
              child: const Text('Copiar'),
            ),
            FilledButton(onPressed: () => Navigator.pop(c), child: const Text('Fechar')),
          ],
        ),
      );
    } on ApiException catch (e) {
      if (mounted && !e.unauthorized) snack(context, e.message);
    }
  }

  void _jump(String key) {
    final ctx = _sec[key]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), alignment: 0.02);
    }
  }

  // --------------------------------- telas ---------------------------------
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: s,
      builder: (context, _) => Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
              children: [
                _jumpBar(),
                const SizedBox(height: 8),
                Hint('Campos vazios mantêm o valor atual. Salve e reinicie para aplicar; o MQTT, o GPS e '
                    'o login são aplicados ao salvar.', top: 0),
                const SizedBox(height: 10),
                ErrorBox(_errors),
                _wifi(),
                _lns(),
                _mqtt(),
                _radioSec(),
                _gps(),
                _boot(),
                _access(),
                const DevFooter('Gateway ESP32 with SX1302'),
              ],
            ),
          ),
          SaveBar(
            dirty: _dirty,
            saving: _saving,
            onSave: save,
            onReboot: () => widget.onReboot(ask: true),
            rebootLabel: 'Reiniciar',
          ),
        ],
      ),
    );
  }

  Widget _jumpBar() {
    const items = [
      ['wifi', 'Rede Wi-Fi'],
      ['lns', 'Servidor LoRaWAN'],
      ['mqtt', 'MQTT'],
      ['radio', 'Rádio LoRa'],
      ['gps', 'GPS'],
      ['boot', 'Inicialização'],
      ['acc', 'Acesso'],
    ];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final i in items) ActionChip(label: Text(i[1]), onPressed: () => _jump(i[0])),
      ],
    );
  }

  Widget _wifi() {
    final isStatic = _r['ip_mode'] == 'static';
    final host = api.host;
    final hostIsIp = ip4(host) != null && host != '192.168.101.101';
    return SectionCard(
      key: _sec['wifi'],
      title: 'Rede Wi-Fi',
      subtitle: 'Rede em que o gateway se conecta e como ele recebe o endereço IP.',
      tag: 'vale após reiniciar',
      tagNow: false,
      children: [
        TextFieldX(controller: _c['wifi_ssid']!, label: 'Nome da rede (SSID)', maxLength: 32),
        TextFieldX(
          controller: _c['wifi_pswd']!,
          label: 'Senha',
          password: true,
          maxLength: 64,
          hint: 'vazio mantém a senha salva',
        ),
        SegChoice(
          label: 'Endereço IP',
          options: const [
            SegOption('dhcp', 'Automático (DHCP)', 'O roteador entrega IP, gateway e DNS.'),
            SegOption('static', 'IP fixo',
                'Endereço, gateway e DNS definidos abaixo. Use um IP fora da faixa do DHCP do roteador.'),
          ],
          value: _r['ip_mode'],
          onChanged: (v) => _radio('ip_mode', v),
        ),
        if (isStatic) ...[
          Pair(
            TextFieldX(
                controller: _c['ip_addr']!,
                label: 'Endereço IP',
                mono: true,
                keyboard: const TextInputType.numberWithOptions(decimal: true),
                hint: hostIsIp ? host : null),
            TextFieldX(
                controller: _c['ip_mask']!,
                label: 'Máscara de rede',
                mono: true,
                hint: '255.255.255.0',
                keyboard: const TextInputType.numberWithOptions(decimal: true)),
          ),
          TextFieldX(
              controller: _c['ip_gw']!,
              label: 'Gateway (roteador)',
              mono: true,
              hint: hostIsIp ? host.replaceFirst(RegExp(r'\.\d+$'), '.1') : null,
              keyboard: const TextInputType.numberWithOptions(decimal: true)),
          Pair(
            TextFieldX(
                controller: _c['ip_dns1']!,
                label: 'DNS primário',
                mono: true,
                hint: t('ip_gw').trim().isEmpty ? 'igual ao gateway' : t('ip_gw').trim(),
                keyboard: const TextInputType.numberWithOptions(decimal: true)),
            TextFieldX(
                controller: _c['ip_dns2']!,
                label: 'DNS secundário (opcional)',
                mono: true,
                hint: '8.8.8.8',
                keyboard: const TextInputType.numberWithOptions(decimal: true)),
          ),
          const Hint('DNS primário vazio usa o gateway. Depois de reiniciar, abra o app no novo IP.', top: 0),
        ],
      ],
    );
  }

  Widget _lns() {
    final mqttOn = _r['mqtt_en'] == 'on';
    return SectionCard(
      key: _sec['lns'],
      title: 'Servidor LoRaWAN',
      subtitle: 'Destino dos pacotes pelo protocolo UDP do Semtech Packet Forwarder.',
      tag: 'vale após reiniciar',
      tagNow: false,
      children: [
        if (mqttOn)
          const StatusBanner(
              'UDP desligado: com o MQTT ativado, o gateway envia somente pelo MQTT. Host e porta ficam '
              'guardados para quando o MQTT for desativado.',
              level: Level.warn),
        Pair(
          TextFieldX(controller: _c['ns_host']!, label: 'Host do Gateway Bridge (IP ou domínio)', mono: true),
          TextFieldX(controller: _c['ns_port']!, label: 'Porta UDP', mono: true, keyboard: TextInputType.number),
          flexA: 2,
        ),
        TextFieldX(
          controller: _c['gw_id']!,
          label: 'Gateway EUI (Gateway ID, 16 hexadecimais)',
          hint: _euiAuto.isEmpty ? null : _euiAuto,
          mono: true,
          maxLength: 16,
          upper: true,
          helper: _euiHelper(),
          trailing: [
            TextButton(
              onPressed: t('gw_id').isEmpty ? null : () => _c['gw_id']!.clear(),
              child: const Text('Automático'),
            ),
            // copia o EUI que vale ao salvar: o digitado ou, vazio, o automático
            CopyHexButton(value: () => _euiEffective, name: 'Gateway EUI'),
          ],
        ),
        TextFieldX(controller: _c['ntp_server']!, label: 'Servidor NTP', mono: true),
      ],
    );
  }

  /// EUI automático (MAC do Wi-Fi + FFFE), informado pelo firmware no config.json.
  String get _euiAuto => sv(s.config['_gw_eui_auto']);

  /// EUI que valerá depois de salvar: o digitado ou, vazio, o automático.
  String get _euiEffective {
    final v = t('gw_id').trim().toUpperCase();
    return v.isNotEmpty ? v : _euiAuto;
  }

  String _euiHelper() {
    final a = _euiAuto;
    final v = t('gw_id').trim();
    var h = v.isNotEmpty
        ? 'Manual: sobrescreve o automático${a.isEmpty ? '' : ' ($a)'}. Toque em Automático para voltar a ele.'
        : 'Automático${a.isEmpty ? '' : ': $a'} (MAC do Wi-Fi do ESP32 com FFFE no meio). '
            'Digite outro EUI só para sobrescrever.';
    final use = sv(s.config['_gw_eui']);
    if (use.isNotEmpty && use != _euiEffective) h += ' Em uso até reiniciar: $use.';
    return '$h Cadastre no ChirpStack exatamente o mesmo ID.';
  }

  Widget _mqtt() {
    final m = s.status?['mqtt'] as Map?;
    final cs = _r['mqtt_fmt'] == 'chirpstack';
    final g = _euiEffective.isEmpty ? '<Gateway ID>' : _euiEffective;
    final topicPh = cs
        ? '${gwRegionTopic[_r['freq_region'] ?? 'au915_sb1'] ?? 'au915_1'}/gateway/${g.toLowerCase()}'
        : 'gateway/${g.toUpperCase()}';
    final line = m == null ? (level: Level.none, text: 'Carregando status…') : mqttLine(m);
    return SectionCard(
      key: _sec['mqtt'],
      title: 'MQTT',
      subtitle: 'Conexão com o broker. Quando ativado, substitui o envio por UDP.',
      tag: 'aplica ao salvar',
      children: [
        StatusBanner(line.text, level: line.level),
        SegChoice(
          label: 'Envio por MQTT',
          options: const [
            SegOption('off', 'Desativado', 'Envia somente pelo UDP (Servidor LoRaWAN).'),
            SegOption('on', 'Ativado', 'Envia somente pelo MQTT. O UDP fica desligado.'),
          ],
          value: _r['mqtt_en'],
          onChanged: (v) => _radio('mqtt_en', v),
        ),
        const FieldLabel('Formato'),
        OptionCards(
          items: const [
            OptionItem('semtech', 'Espelho Semtech',
                'JSON do protocolo UDP em /up, /stats e /state. Só uplinks e estatísticas, sem downlinks.'),
            OptionItem('chirpstack', 'ChirpStack v4',
                'Protocolo do Gateway Bridge (event/up, event/stats, command/down), com downlinks.'),
          ],
          value: _r['mqtt_fmt'],
          onChanged: (v) => _radio('mqtt_fmt', v),
        ),
        const SizedBox(height: 12),
        if (cs)
          SegChoice(
            label: 'Codificação',
            options: const [
              SegOption('json', 'JSON', 'Legível no cliente MQTT, bom para depurar.'),
              SegOption('protobuf', 'Protobuf', 'Binário e menor, igual ao Gateway Bridge.'),
            ],
            value: _r['mqtt_enc'],
            onChanged: (v) => _radio('mqtt_enc', v),
          ),
        _broker(),
        Pair(
          TextFieldX(controller: _c['mqtt_user']!, label: 'Usuário'),
          TextFieldX(controller: _c['mqtt_pswd']!, label: 'Senha', password: true, hint: 'vazio mantém a salva'),
        ),
        TextFieldX(
          controller: _c['mqtt_topic']!,
          label: 'Tópico base',
          mono: true,
          hint: topicPh,
          helper: '${cs ? 'Publica em <tópico>/event/up, /event/stats, /event/ack e /state/conn, e recebe '
              'downlinks em /command/down. O prefixo (ex.: au915_1) precisa ser o da região no ChirpStack.' : 'Publica em <tópico>/up, /stats e /state.'} '
              'Vazio usa o padrão mostrado no campo.',
        ),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Certificados TLS', style: TextStyle(fontSize: 14)),
          childrenPadding: const EdgeInsets.only(bottom: 4),
          children: [
            const Hint(
                'Sem CA enviada, o gateway confia nas autoridades públicas (Let\'s Encrypt e outras). '
                'Envie a CA se o broker usa certificado próprio. Certificado e chave do cliente só são '
                'necessários para TLS mútuo. Cada envio é aplicado na hora.',
                top: 0),
            const SizedBox(height: 8),
            for (final c in const [
              ['ca', 'CA do broker'],
              ['crt', 'Certificado do cliente'],
              ['key', 'Chave privada do cliente'],
            ])
              _certCard(c[0], c[1], m?[c[0]] == true),
          ],
        ),
      ],
    );
  }

  /// Protocolo (lista), Host e Porta lado a lado, como Host/Porta UDP do Servidor LoRaWAN.
  /// Celular estreito: Protocolo e Porta na primeira linha, Host embaixo.
  Widget _broker() {
    final pr = mqttProtocols[_mqProto] ?? mqttProtocols['mqtts']!;
    final proto = DropField<String>(
      label: 'Protocolo',
      items: [for (final e in mqttProtocols.entries) MapEntry(e.key, e.value.label)],
      value: _mqProto,
      onChanged: _setProto,
    );
    final host = TextFieldX(
      controller: _mqHost,
      label: 'Host do broker (IP ou domínio)',
      mono: true,
      hint: 'broker.exemplo.com',
      keyboard: TextInputType.url,
    );
    final port = TextFieldX(
      controller: _mqPort,
      label: 'Porta',
      mono: true,
      hint: '${pr.port}',
      keyboard: TextInputType.number,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(builder: (context, c) {
          if (c.maxWidth < 520) {
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: proto),
                const SizedBox(width: 12),
                SizedBox(width: 110, child: port),
              ]),
              host,
            ]);
          }
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 150, child: proto),
            const SizedBox(width: 12),
            Expanded(child: host),
            const SizedBox(width: 12),
            SizedBox(width: 110, child: port),
          ]);
        }),
        Hint('${pr.hint} Porta vazia usa a padrão.', top: 0),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _certCard(String type, String title, bool installed) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(90),
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600))),
            Tag(installed ? 'instalado' : 'não instalado',
                color: installed ? AppColors.okOf(context) : cs.onSurfaceVariant),
          ]),
          const SizedBox(height: 8),
          TextField(
            controller: _cert[type],
            minLines: 3,
            maxLines: 6,
            style: const TextStyle(fontFamily: monoFont, fontSize: 11.5),
            decoration: fieldDecoration(context, hint: '-----BEGIN ...-----'),
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 6, children: [
            OutlinedButton.icon(
                onPressed: () => _certPick(type), icon: const Icon(Icons.file_open, size: 18), label: const Text('Arquivo…')),
            FilledButton.tonal(onPressed: () => _certSend(type), child: const Text('Enviar')),
            TextButton(onPressed: () => _certSend(type, remove: true), child: const Text('Remover')),
          ]),
        ],
      ),
    );
  }

  Widget _radioSec() {
    final region = _r['freq_region'];
    final plan = gwPlans[region];
    final sb = region == 'au915_sb0' ? 0 : region == 'au915_sb1' ? 1 : -1;
    Widget planOpt(String v, String title, String sub) => OptionCards(
          items: [
            OptionItem(v, title, sub,
                trailing: TextButton(onPressed: () => _showPlanJson(v), child: const Text('JSON'))),
          ],
          value: region,
          onChanged: (x) => _radio('freq_region', x),
        );
    return SectionCard(
      key: _sec['radio'],
      title: 'Rádio LoRa',
      subtitle: 'Canais que o gateway escuta. Use o mesmo plano da região cadastrada no ChirpStack.',
      tag: 'vale após reiniciar',
      tagNow: false,
      children: [
        const FieldLabel('Plano de frequência'),
        planOpt('au915_sb0', 'AU915 sub-banda 0', 'Canais 0–7 e 64, 915,2–916,6 MHz'),
        const SizedBox(height: 8),
        planOpt('au915_sb1', 'AU915 sub-banda 1', 'Canais 8–15 e 65, 916,8–918,2 MHz. Padrão no Brasil'),
        ExpansionTile(
          key: PageStorageKey('plans$_morePlans'),
          initiallyExpanded: _morePlans,
          tilePadding: EdgeInsets.zero,
          title: const Text('Outros planos', style: TextStyle(fontSize: 14)),
          children: [
            planOpt('cn470', 'CN470', '470–510 MHz'),
            const SizedBox(height: 8),
            planOpt('eu868', 'EU868', '863–870 MHz'),
            const SizedBox(height: 8),
            planOpt('us915', 'US915', '902–928 MHz'),
            const SizedBox(height: 8),
          ],
        ),
        if (sb >= 0)
          BandChart(
            on: {for (var i = sb * 8; i < sb * 8 + 8; i++) i, 64 + sb},
            caption: 'Escutando 8 canais de 125 kHz e 1 de 500 kHz (canal ${64 + sb}) na faixa AU915.',
          ),
        const Divider(height: 24),
        Pair(
          TextFieldX(
              controller: _c['freq_radio0']!,
              label: 'Rádio 1, frequência central (Hz)',
              mono: true,
              keyboard: TextInputType.number,
              hint: plan == null ? null : '${plan[0]}'),
          TextFieldX(
              controller: _c['freq_radio1']!,
              label: 'Rádio 2, frequência central (Hz)',
              mono: true,
              keyboard: TextInputType.number,
              hint: plan == null ? null : '${plan[1]}'),
        ),
        const Hint('Ajuste avançado. Vazio usa o padrão do plano, mostrado em cinza.', top: 0),
      ],
    );
  }

  Widget _gps() {
    final g = s.status?['gps'] as Map?;
    final view = g == null ? null : gpsView(g);
    return SectionCard(
      key: _sec['gps'],
      title: 'GPS',
      subtitle: 'Receptor GPS do HAT. Com posição, o gateway informa latitude, longitude e altitude ao '
          'ChirpStack. Liga e desliga ao salvar, sem reiniciar.',
      tag: 'aplica ao salvar',
      children: [
        StatusBanner(view?.line.text ?? 'Carregando status…', level: view?.line.level ?? Level.none),
        SegChoice(
          label: 'Receptor GPS',
          options: const [
            SegOption('off', 'Desligado', 'A UART do GPS não é lida e o gateway não envia coordenadas.'),
            SegOption('on', 'Ligado', 'Lê as frases NMEA do GPS (9600 baud) e envia a posição nas estatísticas.'),
          ],
          value: _r['gps_en'],
          onChanged: (v) => _radio('gps_en', v),
        ),
        if (view != null) ...[
          KvGrid(view.items),
          Hint(view.pinsHint, top: 10),
          if (view.lat != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  final la = view.lat!.toStringAsFixed(6), lo = view.lon!.toStringAsFixed(6);
                  launchUrl(Uri.parse('https://www.openstreetmap.org/?mlat=$la&mlon=$lo#map=17/$la/$lo'),
                      mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.map_outlined),
                label: const Text('Abrir no mapa'),
              ),
            ),
        ],
      ],
    );
  }

  Widget _boot() {
    return SectionCard(
      key: _sec['boot'],
      title: 'Inicialização',
      subtitle: 'Como o Wi-Fi sobe na próxima vez que o gateway ligar.',
      tag: 'vale após reiniciar',
      tagNow: false,
      children: [
        OptionCards(
          items: const [
            OptionItem('station', 'Modo Station', 'Conecta na rede Wi-Fi configurada (uso normal).'),
            OptionItem('soft_ap', 'Modo Soft AP',
                'Cria a rede “lorawan-gateway-sx1302” (senha lorawan101) para configurar em 192.168.101.101.'),
          ],
          value: _r['wifi_mode'],
          onChanged: (v) => _radio('wifi_mode', v),
        ),
      ],
    );
  }

  Widget _access() {
    return SectionCard(
      key: _sec['acc'],
      title: 'Acesso',
      subtitle: 'Usuário e senha pedidos ao abrir a página e o app.',
      tag: 'aplica ao salvar',
      children: [
        TextFieldX(controller: _c['web_user']!, label: 'Usuário', maxLength: 31),
        Pair(
          TextFieldX(
              controller: _c['web_pswd']!,
              label: 'Nova senha',
              password: true,
              maxLength: 31,
              hint: 'vazio mantém a atual'),
          TextFieldX(controller: _webPass2, label: 'Confirmar nova senha', password: true, maxLength: 31),
        ),
        const Hint(
            'Mínimo de 6 caracteres. Depois de salvar, o app passa a usar o novo login. Esqueceu? No console '
            'serial: web_auth --reset (volta para admin / lorawan101).',
            top: 0),
      ],
    );
  }
}
