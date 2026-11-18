// Textos de status do gateway: as mesmas regras das funções gs(), ms() e gps()
// da página web (webpage.html), portadas para Dart.
import 'dart:math' as math;

import '../core/format.dart';
import '../ui/widgets.dart';

/// Planos: [rádio 1, rádio 2 (Hz), faixa mínima, faixa máxima (MHz)].
const Map<String, List<int>> gwPlans = {
  'au915_sb0': [915600000, 916300000, 915, 928],
  'au915_sb1': [917200000, 917900000, 915, 928],
  'us915': [904300000, 905000000, 902, 928],
  'eu868': [867500000, 868500000, 863, 870],
  'cn470': [470600000, 471400000, 470, 510],
};

const Map<String, String> gwPlanNames = {
  'au915_sb0': 'AU915 SB0',
  'au915_sb1': 'AU915 SB1',
  'us915': 'US915',
  'eu868': 'EU868',
  'cn470': 'CN470',
};

/// Prefixo de região do tópico ChirpStack.
const Map<String, String> gwRegionTopic = {
  'au915_sb0': 'au915_0',
  'au915_sb1': 'au915_1',
  'us915': 'us915_0',
  'eu868': 'eu868',
  'cn470': 'cn470_10',
};

num _n(Map m, String k) => (m[k] as num?) ?? 0;
bool _b(Map m, String k) => m[k] == true;

typedef StatusLine = ({Level level, String text});

/// Faixa "Status" (gs).
StatusLine gatewayLine(Map gw) {
  if (!_b(gw, 'run')) {
    return (
      level: Level.warn,
      text: 'Encaminhador parado: o concentrador não iniciou ou o gateway está em modo Soft AP.'
    );
  }
  final udp = _b(gw, 'udp');
  final pullAge = _n(gw, 'pull_age');
  final stat = _n(gw, 'stat');
  if (udp && (pullAge < 0 || pullAge > math.max(30, stat))) {
    return (
      level: Level.warn,
      text: pullAge < 0
          ? 'O servidor LoRaWAN ainda não respondeu (nenhum PULL_ACK recebido).'
          : 'O servidor LoRaWAN não responde há ${dur(pullAge)}.'
    );
  }
  return (
    level: Level.ok,
    text: 'Gateway funcionando${udp ? ', servidor LoRaWAN respondendo.' : ', envio por MQTT.'}'
  );
}

/// Cartões do Status (sem o GPS).
List<KvItem> gatewayKv(Map gw) {
  final rssi = gw['rssi'] as num?;
  final temp = gw['temp'] as num?;
  final sensorMissing = gw['temp_sensor'] == false;
  final udp = _b(gw, 'udp');
  final pullAge = _n(gw, 'pull_age');
  return [
    KvItem('Ligado há', dur(_n(gw, 'up')), 'contadores zeram ao reiniciar'),
    KvItem('Memória livre', kb(_n(gw, 'heap')), 'mínima desde que ligou: ${kb(_n(gw, 'heap_min'))}'),
    KvItem(
      'Sinal Wi-Fi',
      rssi == null ? '-' : '$rssi dBm',
      rssi == null
          ? 'sem conexão Station'
          : rssi >= -60
              ? 'sinal bom'
              : rssi >= -75
                  ? 'sinal regular'
                  : 'sinal fraco',
    ),
    KvItem(
      'Temperatura',
      temp == null ? (sensorMissing ? 'não encontrado' : '-') : '${dec(temp, 1)} °C',
      temp == null
          ? (sensorMissing
              ? 'o STTS751 não respondeu no I2C (veja o log do boot) · RSSI compensado a 25 °C'
              : 'aguardando a primeira leitura')
          : 'concentrador, lida a cada ${_n(gw, 'stat')} s',
    ),
    KvItem('Pacotes recebidos', nf(gw['rx']),
        'CRC ok ${nf(gw['rx_ok'])} · erro ${nf(gw['rx_bad'])} · sem CRC ${nf(gw['rx_nocrc'])}'),
    KvItem('Encaminhados', nf(gw['fwd']), udp ? 'ao servidor por UDP' : 'ao broker por MQTT'),
    KvItem('Downlinks enviados', nf(gw['tx_ok']),
        'pedidos ${nf(gw['tx_req'])} · falhas ${nf(gw['tx_fail'])} · rejeitados ${nf(gw['tx_rej'])}'),
    udp
        ? KvItem('Último ACK do servidor', pullAge < 0 ? 'nenhum' : 'há ${dur(pullAge)}',
            'confirmados: PUSH ${pc(_n(gw, 'push_ack'), _n(gw, 'push'))} · PULL ${pc(_n(gw, 'pull_ack'), _n(gw, 'pull'))}')
        : const KvItem('Último ACK do servidor', 'UDP desligado', 'o envio é só por MQTT'),
  ];
}

/// Estado do MQTT (ms).
StatusLine mqttLine(Map m) {
  final en = _b(m, 'enabled'), con = _b(m, 'connected');
  final uri = '${m['uri'] ?? ''}';
  final err = '${m['error'] ?? ''}';
  if (!en) return (level: Level.none, text: 'MQTT desativado.');
  if (con) {
    final cs = m['format'] == 'chirpstack';
    return (
      level: Level.ok,
      text: 'Conectado a $uri'
          '${cs ? ', ChirpStack v4 ${m['encoding'] == 'protobuf' ? 'Protobuf' : 'JSON'}, ${m['down'] ?? 0} downlinks (${m['down_ok'] ?? 0} agendados)' : ''}'
          ', ${m['sent'] ?? 0} mensagens enviadas, tópico ${m['topic'] ?? ''}'
    );
  }
  return (
    level: Level.warn,
    text: 'Não conectado${uri.isNotEmpty ? ' a $uri' : ''}${err.isNotEmpty ? ': $err' : '. Tentando…'}'
  );
}

String mqttChip(Map? m) {
  if (m == null) return 'MQTT…';
  if (!_b(m, 'enabled')) return 'MQTT desativado';
  return _b(m, 'connected') ? 'MQTT conectado' : 'MQTT desconectado';
}

Level mqttChipLevel(Map? m) {
  if (m == null || !_b(m, 'enabled')) return Level.none;
  return _b(m, 'connected') ? Level.ok : Level.warn;
}

/// GPS: faixa da seção GPS, cartão "GPS" do Status e os 6 cartões da seção.
class GpsView {
  GpsView(this.line, this.card, this.items, this.pinsHint, this.lat, this.lon);

  final StatusLine line;
  final KvItem card;
  final List<KvItem> items;
  final String pinsHint;
  final double? lat;
  final double? lon;
}

GpsView gpsView(Map g) {
  final ag = _n(g, 'rx_age');
  final on = _b(g, 'on');
  final wait = _b(g, 'wait');
  final sat = _n(g, 'sat');
  final rxPin = g['rx_pin'];
  final txPin = g['tx_pin'];
  final pins = 'pino 10 do HAT → GPIO$rxPin (RX do ESP32), GND e 5 V';
  Level k = Level.none;
  String t;
  if (!_b(g, 'built')) {
    k = Level.warn;
    t = 'Este firmware foi compilado sem GPS (GPS_DISABLE).';
  } else if (!on && wait) {
    k = Level.warn;
    t = 'GPS ligado, aguardando a conexão MQTT para iniciar. A conexão segura (TLS) precisa da '
        'memória primeiro; o GPS também pausa enquanto o MQTT reconecta.';
  } else if (!on) {
    if (_b(g, 'cfg')) {
      k = Level.warn;
      t = 'GPS configurado como ligado, mas ainda não iniciou (encaminhador parado, modo Soft AP ou '
          'falha). Veja a página Logs.';
    } else {
      t = 'GPS desligado.';
    }
  } else if (!_b(g, 'run')) {
    k = Level.warn;
    t = 'GPS ligado, mas o encaminhador não está rodando (concentrador parado ou modo Soft AP).';
  } else if (ag < 0) {
    k = Level.warn;
    t = _n(g, 'on_for') < 5
        ? 'GPS ligado. Aguardando os primeiros dados…'
        : 'Nenhum dado chegou do GPS em ${dur(_n(g, 'on_for'))}. Confira: $pins.';
  } else if (ag > 5) {
    k = Level.warn;
    t = 'O GPS parou de enviar dados há ${dur(ag)}. Confira: $pins.';
  } else if (_n(g, 'nmea') == 0 && _n(g, 'bad') > 0) {
    k = Level.warn;
    t = 'Chegam bytes, mas as frases NMEA estão corrompidas: velocidade diferente de 9600 baud, '
        'fio solto ou ruído.';
  } else if (!_b(g, 'fix')) {
    k = Level.warn;
    t = 'Recebendo dados do GPS, ainda sem posição${sat > 0 ? ' ($sat satélites)' : ''}. '
        'O primeiro fix pode levar alguns minutos com a antena para o céu.';
  } else {
    k = Level.ok;
    t = 'Posição obtida com $sat satélites.${_b(g, 'tref') ? ' Referência de tempo válida.' : ''}';
  }
  final lat = (g['lat'] as num?)?.toDouble();
  final lon = (g['lon'] as num?)?.toDouble();
  final has = lat != null && lon != null;
  final fk = _b(g, 'fake') ? 'fixa no global_conf (fake)' : '';
  final card = KvItem(
    'GPS',
    !on
        ? (wait ? 'aguardando MQTT' : 'desligado')
        : _b(g, 'fix')
            ? '$sat satélites'
            : ag < 0
                ? 'sem dados'
                : 'sem posição',
    !on
        ? (wait ? 'inicia após a conexão MQTT' : 'liga na seção GPS')
        : has
            ? '${lat!.toStringAsFixed(5)}, ${lon!.toStringAsFixed(5)}'
            : ag < 0
                ? 'nada chega no GPIO$rxPin'
                : 'aguardando o fix${sat > 0 ? ' ($sat satélites)' : ''}',
  );
  final items = [
    KvItem('Latitude', has ? '${lat!.toStringAsFixed(6)}°' : '-',
        has ? (fk.isNotEmpty ? fk : (lat! < 0 ? 'Sul' : 'Norte')) : ''),
    KvItem('Longitude', has ? '${lon!.toStringAsFixed(6)}°' : '-',
        has ? (fk.isNotEmpty ? fk : (lon! < 0 ? 'Oeste' : 'Leste')) : ''),
    KvItem('Altitude', has ? '${g['alt'] ?? 0} m' : '-', has ? 'acima do nível do mar' : ''),
    KvItem('Satélites', on ? '$sat' : '-', on ? 'usados no fix' : ''),
    KvItem('Frases NMEA', on ? nf(g['nmea']) : '-',
        on ? 'com erro ${nf(g['bad'])} · ${nf(g['bytes'])} bytes' : ''),
    KvItem('Último dado', !on ? '-' : (ag < 0 ? 'nenhum' : 'há ${dur(ag)}'),
        on ? 'ligado há ${dur(_n(g, 'on_for'))}' : ''),
  ];
  final hint = 'Ligação: pino 10 do HAT (TX do GPS) → GPIO$rxPin (RX do ESP32) e pino 8 (RX do GPS) '
      '← GPIO$txPin. O primeiro fix pode levar alguns minutos; deixe a antena do GPS com vista para o céu.';
  return GpsView((level: k, text: t), card, items, hint, has ? lat : null, has ? lon : null);
}

/// Protocolos do broker MQTT: rótulo da lista, porta padrão e dica.
const mqttProtocols = <String, ({String label, int port, String hint})>{
  'mqtts': (label: 'mqtts://', port: 8883, hint: 'Criptografado com TLS. Porta padrão 8883.'),
  'mqtt': (label: 'mqtt://', port: 1883, hint: 'Sem criptografia. Porta padrão 1883.'),
  'wss': (
    label: 'wss://',
    port: 443,
    hint: 'MQTT sobre WebSocket com TLS. Porta padrão 443. Se o broker usar um caminho, '
        'coloque no host (ex.: broker.exemplo.com/mqtt).'
  ),
  'ws': (
    label: 'ws://',
    port: 80,
    hint: 'MQTT sobre WebSocket, sem criptografia. Porta padrão 80. Se o broker usar um caminho, '
        'coloque no host (ex.: broker.exemplo.com/mqtt).'
  ),
};

/// Broker MQTT separado em Protocolo, Host e Porta. O firmware guarda uma URI só
/// (mqtt_uri); o host pode levar "usuário:senha@" na frente e "/caminho" no fim.
typedef BrokerParts = ({String proto, String host, String port});

/// "mqtts://[user:pass@]host[:port][/path]" -> partes. Sem esquema conhecido,
/// o texto inteiro fica no host e o protocolo volta para mqtts.
BrokerParts? splitBrokerUri(String uri) {
  final m = RegExp(r'^\s*(mqtts?|wss?)://(.*)$', caseSensitive: false).firstMatch(uri);
  if (m == null) return null;
  final rest = m.group(2)!.trim();
  final slash = rest.indexOf('/');
  var auth = slash < 0 ? rest : rest.substring(0, slash);
  final path = slash < 0 ? '' : rest.substring(slash);
  final at = auth.lastIndexOf('@');
  final user = auth.substring(0, at + 1);
  auth = auth.substring(at + 1);
  var port = '';
  final q = RegExp(r'^(.*):(\d*)$').firstMatch(auth);
  if (q != null) {
    auth = q.group(1)!;
    port = q.group(2)!;
  }
  return (proto: m.group(1)!.toLowerCase(), host: '$user$auth$path', port: port);
}

/// Partes -> URI. Host vazio = sem broker (""); porta vazia = padrão do protocolo.
String joinBrokerUri(String proto, String host, String port) {
  final h = host.trim();
  if (h.isEmpty) return '';
  final p = port.trim();
  final slash = h.indexOf('/');
  final auth = slash < 0 ? h : h.substring(0, slash);
  final path = slash < 0 ? '' : h.substring(slash);
  return '$proto://$auth${p.isEmpty ? '' : ':$p'}$path';
}

/// Host do broker (para as sugestões dos diagnósticos): mqtt[s]://[user@]host[:port]/...
String mqttHost(String uri) {
  var p = uri;
  final i = p.indexOf('://');
  if (i >= 0) p = p.substring(i + 3);
  final slash = p.indexOf('/');
  final head = slash >= 0 ? p.substring(0, slash) : p;
  final at = head.indexOf('@');
  if (at >= 0) p = p.substring(at + 1);
  final m = RegExp(r'^[^:/?]+').firstMatch(p);
  return m?.group(0) ?? '';
}
