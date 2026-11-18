<p align="center">
  <img src="doc/images/banner.svg" alt="ESP32_SX1302: gateway LoRaWAN de 8 canais com ESP32 e SX1302" width="100%"/>
</p>

<p align="center">
  <a href="https://github.com/AdailSilva/Gateway_ESP32_SX1302_LR1302_HAT_Elecrow/actions/workflows/build.yml"><img src="doc/images/badges.svg" alt="build · versão 0.0.1 · ESP-IDF v5.5 | v6.x · SX1302_HAL v2.1.0 · LoRaWAN AU915 · US915 · EU868 · CN470 · licença BSD-3-Clause" width="100%"/></a>
</p>

**ESP32_SX1302** é um gateway LoRaWAN de **8 canais** e baixo custo. O [SX1302_HAL v2.1.0](https://github.com/Lora-net/sx1302_hal) roda **nativamente em um único microcontrolador ESP32**, que controla sozinho o concentrador **Semtech SX1302**: não há outro processador no gateway. O firmware conversa com o **ChirpStack** (ou qualquer servidor compatível) por **UDP Semtech** ou por **MQTT/MQTTS** no protocolo de gateway do ChirpStack v4. A configuração é feita por uma página web em português ou pelo console serial.

O mesmo código-fonte gera firmware para **três placas** (módulos ESP32). A placa é escolhida no build com `scripts/build.sh <BOARD>`:

| `BOARD` | Placa | Papel |
|---|---|---|
| `esp32` | **ESP32-WROOM-32U DevKit** | Versão de **menor recurso**: tem todas as funções que existem hoje |
| `esp32s3_n16r8` | **ESP32-S3-WROOM-1U-N16R8 DevKit** | Versão de **maior recurso**: tudo o que já existe **e** as funções novas ([roadmap](#-roadmap-esp32-s3)) |
| `esp32s3_n32r16v` | **ESP32-S3-WROOM-2-N32R16V DevKit** | Versão de **maior recurso**, igual à de cima, para o módulo com flash/PSRAM octais de 1,8 V |

Detalhes de cada placa (pinagem, arquivos, flags e binários): [`doc/hardware/README.md`](doc/hardware/README.md).

---

## Sumário

- [Placas suportadas](#-placas-suportadas)
- [Funcionalidades](#-funcionalidades)
- [Classes LoRaWAN (A, B e C)](#-classes-lorawan-a-b-e-c)
- [Arquitetura do firmware](#-arquitetura-do-firmware)
- [Hardware e materiais](#-hardware-e-materiais)
- [Pinagem: ESP32-WROOM-32U DevKit](#-pinagem-esp32-wroom-32u-devkit)
- [Pinagem: ESP32-S3-WROOM-1U-N16R8 e ESP32-S3-WROOM-2-N32R16V DevKit](#-pinagem-esp32-s3-wroom-1u-n16r8-e-esp32-s3-wroom-2-n32r16v-devkit)
- [Header do LR1302 HAT](#-header-de-40-pinos-do-lr1302-hat)
- [Alimentação](#-alimentação)
- [Preparar o ambiente ESP-IDF](#-preparar-o-ambiente-esp-idf)
- [Compilar e gravar](#-compilar-e-gravar)
- [Primeiro uso](#-primeiro-uso)
- [Servidor web embutido](#-servidor-web-embutido)
- [App Android](#-app-android)
- [Configuração](#-configuração)
- [Roadmap (ESP32-S3)](#-roadmap-esp32-s3)
- [Cadastro no ChirpStack](#-cadastro-no-chirpstack)
- [Estrutura do repositório](#-estrutura-do-repositório)
- [Solução de problemas](#-solução-de-problemas)
- [Créditos e licença](#-créditos-e-licença)

---

## 🧩 Placas suportadas

<p align="center">
  <img src="doc/images/editions.svg" alt="Comparação entre as placas suportadas (ESP32 e os dois ESP32-S3)" width="100%"/>
</p>

| | ESP32-WROOM-32U DevKit | ESP32-S3-WROOM-1U-N16R8 DevKit | ESP32-S3-WROOM-2-N32R16V DevKit |
|---|---|---|---|
| `BOARD` (`scripts/build.sh`) | `esp32` | `esp32s3_n16r8` | `esp32s3_n32r16v` |
| `IDF_TARGET` | `esp32` | `esp32s3` | `esp32s3` |
| CPU | Xtensa LX6 dual-core, 240 MHz | Xtensa LX7 dual-core, 240 MHz | Xtensa LX7 dual-core, 240 MHz |
| RAM | 520 KB SRAM, sem PSRAM | 512 KB SRAM + **8 MB PSRAM octal** | 512 KB SRAM + **16 MB PSRAM octal** |
| Flash | 4 MB quad (DIO) | **16 MB quad (QIO), 3,3 V** | **32 MB octal (OPI), 1,8 V** |
| App (tabela de partições) | 1,5 MB | 4 MB | 4 MB |
| Antena Wi-Fi | externa (conector u.FL) | externa (conector u.FL) | de PCB |
| Console | UART0 (chip USB-UART), `/dev/ttyUSB0` | USB nativo (Serial/JTAG), `/dev/ttyACM0` | USB nativo (Serial/JTAG), `/dev/ttyACM0` |
| SPI do HAT | VSPI, `SPI3_HOST` (GPIO 18/19/23/5) | FSPI, `SPI2_HOST` em IOMUX (GPIO 10–13) | FSPI, `SPI2_HOST` em IOMUX (GPIO 10–13) |
| GPIO47/48 | — | 3,3 V (livres) | domínio de 1,8 V (não usar) |
| LED de status | GPIO2 (LED azul da DevKit) | — (o LED da DevKit é RGB WS2812) | — (o LED da DevKit é RGB WS2812) |
| Botão Soft AP | GPIO0 (BOOT) | GPIO0 (BOOT) | GPIO0 (BOOT) |
| mDNS (`http://<host>.local/`) | — (poupa RAM: heap livre chega a ~10 KB com MQTT TLS) | **sim** (`GW_MDNS`), achado pelo app Android | **sim** (`GW_MDNS`), achado pelo app Android |
| Arquivo da placa | [`boards/esp32.defaults`](boards/esp32.defaults) | [`boards/esp32s3_n16r8.defaults`](boards/esp32s3_n16r8.defaults) | [`boards/esp32s3_n32r16v.defaults`](boards/esp32s3_n32r16v.defaults) |
| Guia de ligação | [ESP32-WROOM-32U](doc/hardware/ESP32-WROOM-32U_DevKit.md) | [ESP32-S3-WROOM-1U-N16R8](doc/hardware/ESP32-S3-WROOM-1U_N16R8_DevKit.md) | [ESP32-S3-WROOM-2-N32R16V](doc/hardware/ESP32-S3-WROOM-2_N32R16V_DevKit.md) |

Como o build monta a configuração de cada placa:

- O [`CMakeLists.txt`](CMakeLists.txt) da raiz traduz `BOARD` em `IDF_TARGET` e carrega, nesta ordem: [`sdkconfig.defaults`](sdkconfig.defaults) (comum), `sdkconfig.defaults.<alvo>` ([`esp32`](sdkconfig.defaults.esp32): menos buffers do Wi-Fi; [`esp32s3`](sdkconfig.defaults.esp32s3): console USB e partições com app de 4 MB) e `boards/<BOARD>.defaults` (flash, PSRAM e a escolha `CONFIG_GW_BOARD_*`).
- A pinagem fica nos blocos `if(IDF_TARGET ...)` de [`main/CMakeLists.txt`](main/CMakeLists.txt). Os dois S3 usam a mesma.
- O boot, o `GET /info`, o `/config.json`, o mDNS e o app mostram a placa: `*** Board: ESP32-S3-WROOM-1U-N16R8 (esp32s3_n16r8, esp32s3) ***`.

> ⚠️ **Os dois S3 não são intercambiáveis.** O firmware do N16R8 (flash quad 3,3 V) não inicia no N32R16V (flash octal 1,8 V), e vice-versa. Confira a marcação na blindagem do módulo antes de gravar.

---

## ✨ Funcionalidades

Legenda: ✅ disponível · 🧪 disponível, falta validar em campo · 🗓️ planejado · ➖ não se aplica

### Rádio e LoRaWAN

| Função | ESP32 | ESP32-S3 |
|---|:---:|:---:|
| Concentrador SX1302 + SX1250, **8 canais** multi-SF + canal LoRa de serviço + FSK | ✅ | ✅ |
| Planos de frequência **AU915 SB0** (canais 0–7 + 64), **AU915 SB1** (8–15 + 65, padrão), **US915**, **EU868**, **CN470** | ✅ | ✅ |
| Frequência central dos rádios editável, com volta ao padrão do plano | ✅ | ✅ |
| Downlink com **JIT queue** (agendamento de TX) | ✅ | ✅ |
| Downlinks **Classe A** (`tmst`, RX1/RX2) e **Classe C** (`imme`, imediato); o gateway atende nós A, B e C ao mesmo tempo ([Classes LoRaWAN](#-classes-lorawan-a-b-e-c)) | ✅ | ✅ |
| Class B: beacon AU915 (923,3 MHz + n × 600 kHz, SF12BW500) | 🧪 | 🧪 |
| Compensação de RSSI pela temperatura (STTS751 no I2C; sem sensor, usa 25 °C) | ✅ | ✅ |
| SX1261 mantido fora do barramento SPI (CS em nível alto) | ✅ | ✅ |
| LBT / spectral scan com o SX1261 | ➖ | 🗓️ |
| GPS do HAT (NMEA): liga/desliga pela página web, sem reiniciar; posição enviada ao ChirpStack | ✅ | ✅ |
| Sincronismo por PPS do GPS | ➖ | 🗓️ |

### Rede e integração

| Função | ESP32 | ESP32-S3 |
|---|:---:|:---:|
| Wi-Fi **Station** com DHCP ou **IP fixo** (IP, máscara, gateway, DNS 1 e 2) | ✅ | ✅ |
| Wi-Fi **Soft AP** de configuração (`192.168.101.101`), por botão ou falha de conexão | ✅ | ✅ |
| NTP configurável (padrão `br.pool.ntp.org`) | ✅ | ✅ |
| **Gateway EUI automático** (MAC do Wi-Fi + `FFFE`), com sobrescrita manual | ✅ | ✅ |
| Packet forwarder **UDP Semtech** (ChirpStack Gateway Bridge, porta 1700) | ✅ | ✅ |
| **MQTT / MQTTS**: TLS com CA própria ou bundle público, **mTLS** (certificado + chave do cliente), usuário/senha | ✅ | ✅ |
| Formato **ChirpStack v4** em **JSON** ou **Protobuf** (uplink, stats, ack, conn state e downlink em `command/down`) | ✅ | ✅ |
| Formato Semtech JSON por MQTT (somente uplink) | ✅ | ✅ |
| UDP e MQTT exclusivos: MQTT ligado desliga o UDP | ✅ | ✅ |
| Buffers TLS dinâmicos (economia de RAM sem PSRAM) | ✅ | ✅ |
| TLS e filas grandes na PSRAM | ➖ | 🗓️ |
| Buffer offline em flash (guarda uplinks quando o broker cai) | ➖ | 🗓️ |
| Atualização OTA | ➖ | 🗓️ |

### Gestão e observabilidade

| Função | ESP32 | ESP32-S3 |
|---|:---:|:---:|
| **Página web em pt-BR**: tema claro/escuro, adaptada ao celular, validação nos campos | ✅ | ✅ |
| Painel de **status** (`GET /status`): uptime, heap, RSSI do Wi-Fi, temperatura, pacotes RX/TX, ACKs e GPS | ✅ | ✅ |
| Seção **GPS** na página: liga/desliga sem reiniciar, posição, satélites e frases NMEA ao vivo | ✅ | ✅ |
| **Log ao vivo** no navegador (`/logs`), com filtro, pausa e download (buffer circular de 16 KB) | ✅ | ✅ |
| **Diagnóstico de rede** (`/diag`): ping, traceroute e nslookup | ✅ | ✅ |
| Envio de certificados MQTT pela página | ✅ | ✅ |
| **Exportar / importar** a configuração em JSON (seção *Manutenção*), sem senhas nem certificados | ✅ | ✅ |
| **Restaurar padrão de fábrica** pela página (seção *Manutenção*) ou pelo console (`factory_reset --yes`) | ✅ | ✅ |
| Login da página (padrão `admin` / `lorawan101`), troca de senha e logout | ✅ | ✅ |
| **Console serial** `ESP32_SX1302>` (`config`, `mqtt`, `mqtt_cert`, `web_auth`, `gps`, `pkt_fwd`, `reboot`) | ✅ | ✅ |
| Web e console gravam as mesmas configurações na NVS | ✅ | ✅ |
| Diagnóstico de fiação do SX1302 quando o concentrador não inicia | ✅ | ✅ |
| **Watchdog do SX1302**: confere o concentrador a cada segundo (SPI, registradores, contador de 1 MHz) e, se ele foi resetado, perdeu o clock, falhou na leitura ou ficou mudo por muito tempo, reinicia só o SX1302 em ~2 s (Wi-Fi, MQTT, página, GPS e OLED seguem no ar) | ✅ | ✅ |
| Display OLED SSD1306 opcional no I2C | 🧪 | 🧪 |
| LED de status | ✅ (GPIO2) | 🗓️ (LED RGB WS2812) |
| Painel web completo (gráficos, histórico) | ➖ | 🗓️ |

---

## 📶 Classes LoRaWAN (A, B e C)

A **classe** define quando o **nó** escuta downlinks (servidor → nó). O uplink é igual nas três; todo nó suporta a **Classe A**, e B e C são modos adicionais. O **gateway não tem classe**: ele atende nós A, B e C ao mesmo tempo e transmite cada downlink no horário que o ChirpStack pedir.

| Classe | Quando o nó escuta | Atraso do downlink | Consumo | Uso típico |
|:---:|---|---|---|---|
| **A** | Só em 2 janelas curtas (RX1/RX2) depois de cada uplink | Até o **próximo uplink** | 🔋 Mínimo | Sensores a bateria: medidores, temperatura, nível, rastreadores |
| **B** | Janelas A + **ping slots** sincronizados por *beacon* (GPS) | Até o próximo ping slot (**1–128 s**) | 🔋🔋 Baixo/médio | Atuadores a bateria com atraso previsível: fechaduras, válvulas |
| **C** | **O tempo todo**, exceto enquanto transmite | **Quase imediato** | 🔌 Alto | Equipamentos na rede elétrica: relés, iluminação pública, alarmes |

**Neste gateway:**

| Classe | Como o downlink sai | Estado |
|:---:|---|:---:|
| **A** | `tmst` (RX1/RX2 depois do uplink), JIT queue | ✅ |
| **B** | Beacon gerado pelo gateway + `tmms` (hora GPS) nos ping slots | 🗓️ |
| **C** | `"imme": true` (imediato), JIT queue | ✅ |

A Classe B depende da **hora GPS pelo PPS**, que ainda não existe neste firmware (➖ no ESP32, 🗓️ no ESP32-S3). Sem ela o gateway não envia beacons nem agenda ping slots, e o `beacon_period` vem `0`. Classe A e C funcionam sem GPS.

Explicação completa (diagramas de tempo, quando usar cada classe, ChirpStack e suporte nas pilhas): **[`doc/CLASSES_LORAWAN.md`](doc/CLASSES_LORAWAN.md)**. O mesmo resumo está na página WEB **Classes** (`/classes`) e no app Android (ícone 🎓 **Classes LoRaWAN**).

---

## 🏗️ Arquitetura do firmware

<p align="center">
  <img src="doc/images/firmware_architecture.svg" alt="Arquitetura do firmware" width="100%"/>
</p>

- **`main/libloragw/`** é o porte do Semtech SX1302_HAL v2.1.0 para o ESP-IDF (SPI, I2C e UART pelo driver do ESP-IDF).
- **`main/packet_forwarder/`** contém o forwarder (`lora_pkt_fwd.c`), o cliente MQTT (`mqtt_gw.c`, `cs_codec.c`), o servidor web (`http_server.c`, `web_config.c`), o log (`weblog.c`), o diagnóstico (`diag.c`) e os LEDs/botões (`led_indication.c`, `ioe.c`).
- **`main/libloragw-test/`** guarda as ferramentas de teste (`test_hal_tx`, `test_hal_rx`, `test_toa`). Elas entram no lugar do forwarder quando `CONFIG_LIBLORAGW_TEST=1`.

---

## 🔧 Hardware e materiais

| Item | Observação |
|---|---|
| **ESP32-WROOM-32U DevKit** (38 pinos), **ESP32-S3-WROOM-1U-N16R8 DevKitC-1** **ou** **ESP32-S3-WROOM-2-N32R16V DevKitC-1** | O WROOM-32U e o WROOM-1U precisam de antena Wi-Fi no conector u.FL |
| **Elecrow LR1302 LoRaWAN HAT** (versão **SPI**) | SX1302 + SX1250 + SX1261, header de 40 pinos no padrão Raspberry Pi |
| Antena LoRa 915 MHz | **Nunca** ligue o gateway sem antena |
| Fonte **5 V / 2 A** | O USB do PC não aguenta os picos de TX em uso contínuo |
| 12 jumpers fêmea-fêmea **curtos** (< 15 cm) | 10 se não usar o GPS |
| *(opcional)* Display OLED SSD1306 I2C | Divide o barramento I2C com o sensor de temperatura |

> Para uma instalação fixa, sem jumpers soltos, a pasta [`hardware_design/`](hardware_design/) tem uma **placa adaptadora em placa perfurada** (o HAT encaixa num conector 2×20 e a DevKit em barras fêmeas, com os pull-ups do I2C e um jack DC de 5 V) e uma **caixa paramétrica** (STEP, STL e DXF). Ela serve para as três placas deste README: os fios até o HAT são os mesmos, e só muda o pino da DevKit em que cada um é soldado.

---

## 📌 Pinagem: ESP32-WROOM-32U DevKit

<p align="center">
  <img src="doc/images/pinout_esp32_wroom32u_devkit.svg" alt="Pinagem da ESP32-WROOM-32U DevKit" width="100%"/>
</p>

<p align="center">
  <a href="doc/images/wiring_esp32_wroom32u.png"><img src="doc/images/wiring_esp32_wroom32u.png" alt="Ligação ESP32-WROOM-32U DevKit com o LR1302 HAT" width="100%"/></a>
</p>
<p align="center"><sub>🔍 Alta resolução (PNG, 3720 px de largura): clique na imagem para ampliar · versão vetorial: <a href="doc/images/wiring_esp32_wroom32u.svg"><code>wiring_esp32_wroom32u.svg</code></a></sub></p>

| Sinal | ESP32 | → | HAT (pino) | Nome RPi |
|---|---|:---:|---|---|
| 🔵 SPI MOSI | **GPIO23** | → | **19** | GPIO10 / MOSI |
| 🔵 SPI MISO | **GPIO19** | ← | **21** | GPIO9 / MISO |
| 🔵 SPI SCLK | **GPIO18** | → | **23** | GPIO11 / SCLK |
| 🔵 CS do SX1302 | **GPIO5** | → | **24** | GPIO8 / CE0 |
| 🟠 RESET do SX1302 (ativo alto) | **GPIO4** | → | **11** | GPIO17 |
| 🟠 CS do SX1261 (fica em nível alto) | **GPIO25** | → | **31** | GPIO6 |
| 🟢 I2C SDA | **GPIO21** | ↔ | **3** | GPIO2 / SDA |
| 🟢 I2C SCL | **GPIO22** | → | **5** | GPIO3 / SCL |
| 🟣 GPS RXD *(opcional)* | **GPIO17** | → | **8** | GPIO14 / TXD |
| 🟣 GPS TXD *(opcional)* | **GPIO16** | ← | **10** | GPIO15 / RXD |
| 🔴 5 V | **5V / VIN** | → | **2** ou **4** | 5V |
| ⚫ GND | **GND** | — | **6** | GND |

> **I2C (pinos 3 e 5):** o módulo LR1302 tem um sensor de temperatura **STTS751**, que o HAT liga a esses pinos. No Raspberry Pi, o barramento tem pull-ups de 1,8 kΩ na própria placa do Pi, e por isso o HAT não traz os seus. No ESP32, os pull-ups internos (~45 kΩ) podem não bastar. Se o boot disser que o STTS751 não respondeu, ligue **um resistor de 4,7 kΩ do SDA ao 3,3 V e outro do SCL ao 3,3 V**. Veja [Solução de problemas](#-solução-de-problemas).

Guia completo, com o diagrama em texto e a conferência pós-ligação: [`doc/hardware/ESP32-WROOM-32U_DevKit.md`](doc/hardware/ESP32-WROOM-32U_DevKit.md).

---

## 📌 Pinagem: ESP32-S3-WROOM-1U-N16R8 e ESP32-S3-WROOM-2-N32R16V DevKit

Os dois módulos S3 usam a **mesma DevKitC-1 e os mesmos fios**. Só o firmware muda (`esp32s3_n16r8` ou `esp32s3_n32r16v`).

<p align="center">
  <img src="doc/images/pinout_esp32s3_wroom1u_n16r8_devkit.svg" alt="Pinagem da ESP32-S3-WROOM-1U N16R8 DevKit" width="100%"/>
</p>
<p align="center"><sub>1º · ESP32-S3-WROOM-1U-N16R8 (16 MB): GPIO47/48 de 3,3 V e antena u.FL</sub></p>

<p align="center">
  <img src="doc/images/pinout_esp32s3_wroom2_n32r16v_devkit.svg" alt="Pinagem da ESP32-S3-WROOM-2 N32R16V DevKit" width="100%"/>
</p>
<p align="center"><sub>2º · ESP32-S3-WROOM-2-N32R16V (32 MB): GPIO47/48 de 1,8 V e antena de PCB</sub></p>

<p align="center">
  <a href="doc/images/wiring_esp32s3_wroom1u_n16r8.png"><img src="doc/images/wiring_esp32s3_wroom1u_n16r8.png" alt="Ligação ESP32-S3-WROOM-1U N16R8 DevKit com o LR1302 HAT" width="100%"/></a>
</p>
<p align="center"><sub>🔍 Alta resolução (PNG, 3720 px de largura): clique na imagem para ampliar · versão vetorial: <a href="doc/images/wiring_esp32s3_wroom1u_n16r8.svg"><code>wiring_esp32s3_wroom1u_n16r8.svg</code></a></sub></p>

<p align="center">
  <a href="doc/images/wiring_esp32s3_wroom2.png"><img src="doc/images/wiring_esp32s3_wroom2.png" alt="Ligação ESP32-S3-WROOM-2 N32R16V DevKit com o LR1302 HAT" width="100%"/></a>
</p>
<p align="center"><sub>🔍 Alta resolução (PNG, 3720 px de largura): clique na imagem para ampliar · versão vetorial: <a href="doc/images/wiring_esp32s3_wroom2.svg"><code>wiring_esp32s3_wroom2.svg</code></a></sub></p>

| Sinal | ESP32-S3 | → | HAT (pino) | Nome RPi |
|---|---|:---:|---|---|
| 🔵 SPI MOSI | **GPIO11** | → | **19** | GPIO10 / MOSI |
| 🔵 SPI MISO | **GPIO13** | ← | **21** | GPIO9 / MISO |
| 🔵 SPI SCLK | **GPIO12** | → | **23** | GPIO11 / SCLK |
| 🔵 CS do SX1302 | **GPIO10** | → | **24** | GPIO8 / CE0 |
| 🟠 RESET do SX1302 (ativo alto) | **GPIO6** | → | **11** | GPIO17 |
| 🟠 CS do SX1261 (fica em nível alto) | **GPIO7** | → | **31** | GPIO6 |
| 🟢 I2C SDA | **GPIO4** | ↔ | **3** | GPIO2 / SDA |
| 🟢 I2C SCL | **GPIO5** | → | **5** | GPIO3 / SCL |
| 🟣 GPS RXD *(opcional)* | **GPIO17** | → | **8** | GPIO14 / TXD |
| 🟣 GPS TXD *(opcional)* | **GPIO18** | ← | **10** | GPIO15 / RXD |
| 🔴 5 V | **5V** | → | **2** ou **4** | 5V |
| ⚫ GND | **GND** | — | **6** | GND |

> ⚠️ **Não use** nos dois S3: GPIO26–32 (flash), GPIO33–37 (PSRAM octal), GPIO19/20 (USB do console), GPIO43/44 (UART0) e GPIO0/3/45/46 (strapping). No **N16R8**, GPIO47/48 são de 3,3 V; no **N32R16V** eles ficam no domínio de 1,8 V. Ficam livres para as funções novas: GPIO1, 2, 8, 9, 14, 15, 16, 21 e 38–42 (e 47/48 só no N16R8).

> **I2C (pinos 3 e 5):** o mesmo vale para o S3. Se o STTS751 do LR1302 não responder, ligue **4,7 kΩ do SDA (GPIO4) e do SCL (GPIO5) ao 3,3 V**.

Guias completos: [`ESP32-S3-WROOM-1U_N16R8_DevKit.md`](doc/hardware/ESP32-S3-WROOM-1U_N16R8_DevKit.md) e [`ESP32-S3-WROOM-2_N32R16V_DevKit.md`](doc/hardware/ESP32-S3-WROOM-2_N32R16V_DevKit.md).

---

## 🟩 Header de 40 pinos do LR1302 HAT

O HAT é o mesmo nas três placas. Muda só o GPIO do ESP32 em cada pino (os dois S3 usam os mesmos):

<p align="center">
  <a href="doc/images/lr1302_hat_header.png"><img src="doc/images/lr1302_hat_header.png" alt="Header de 40 pinos do LR1302 HAT com os GPIOs de cada placa" width="100%"/></a>
</p>
<p align="center"><sub>🔍 Alta resolução (PNG, 3720 px de largura): clique na imagem para ampliar · versão vetorial: <a href="doc/images/lr1302_hat_header.svg"><code>lr1302_hat_header.svg</code></a></sub></p>

- **Não ligue os 3V3 do header (pinos 1 e 17).** O HAT gera os próprios 3,3 V a partir dos 5 V.
- O LR1302 HAT **não tem POWER_EN** (`SX1302_POWER_EN_PIN=GPIO_NUM_NC`).
- A lógica do HAT é de 3,3 V, igual à do ESP32. Não precisa de conversor de nível.

---

## ⚡ Alimentação

<p align="center">
  <img src="doc/images/power.svg" alt="Alimentação recomendada" width="100%"/>
</p>

Durante o desenvolvimento, dá para alimentar tudo pelo USB da DevKit (o 5V/VIN segue para o HAT). Se aparecer *brownout* ou reset na hora de transmitir, a causa é a alimentação: use a fonte de 5 V / 2 A com GND comum.

Para o gateway ficar dias ligado sem travar, além da fonte: um **capacitor eletrolítico de 470–1000 µF / 10 V** entre 5 V e GND junto ao conector do HAT (segura os picos de corrente do TX), fios de 5 V e GND **curtos e grossos** e a antena **longe dos jumpers** (principalmente do RESET, pino 11 do HAT). Uma queda de tensão ou um pico no RESET reseta o SX1302 sem derrubar o ESP32: o watchdog do firmware percebe em ~2 s e reinicia só o concentrador, mas o ideal é que não aconteça.

---

## 🧰 Preparar o ambiente ESP-IDF

Este projeto usa **somente o ESP-IDF**. A versão de referência é a **v5.5.1**, a mesma da pipeline do GitHub Actions; o firmware também compila na 6.x. Os comandos deste README supõem esta organização de pastas:

```
~/Apps/esp-idf/                ← ESP-IDF (git clone)
~/Apps/lorawan_workspace/      ← pasta de trabalho; este projeto é clonado dentro dela
```

> ⚠️ O ESP-IDF não aceita **espaços** no caminho dele nem no do projeto. No Windows, prefira caminhos curtos (por exemplo `C:\Apps\...`).

| Sistema | Caminho recomendado | `scripts/build.sh` e comandos com log |
|---|---|---|
| 🐧 Linux | `git clone` do ESP-IDF | funcionam como estão |
| 🍎 macOS | `git clone` do ESP-IDF | funcionam com o `sed` do GNU e um ajuste no `script` |
| 🪟 Windows | **WSL2 + Ubuntu** (recomendado) | funcionam como no Linux |
| 🪟 Windows | nativo, com o instalador da Espressif (EIM) | use o `idf.py` direto no PowerShell |

### 🐧 Linux (Ubuntu / Debian)

**1. Dependências do sistema**

```bash
sudo apt-get update
sudo apt-get install -y git wget flex bison gperf python3 python3-pip python3-venv \
  cmake ninja-build ccache libffi-dev libssl-dev dfu-util libusb-1.0-0
```

Fedora: `sudo dnf install git wget flex bison gperf python3 python3-pip cmake ninja-build ccache dfu-util libusbx`. Arch: `sudo pacman -S --needed gcc git make flex bison gperf python cmake ninja ccache dfu-util libusb python-pip`.

**2. Baixar e instalar o ESP-IDF v5.5.1** (as ferramentas vão para `~/.espressif`)

```bash
mkdir -p ~/Apps/lorawan_workspace && cd ~/Apps
git clone -b v5.5.1 --recursive https://github.com/espressif/esp-idf.git
cd esp-idf && ./install.sh esp32,esp32s3
```

`esp32,esp32s3` instala as ferramentas das três placas do gateway (ESP32-WROOM-32U, ESP32-S3-WROOM-1U-N16R8 e ESP32-S3-WROOM-2-N32R16V); a mesma instalação serve para os nós LoRaWAN.

**3. Ativar o ambiente** em cada terminal novo, antes de compilar

```bash
. ~/Apps/esp-idf/export.sh
idf.py --version          # deve mostrar ESP-IDF v5.5.1
```

Atalho opcional: `echo "alias get_idf='. \$HOME/Apps/esp-idf/export.sh'" >> ~/.bashrc`; depois basta digitar `get_idf`.

**4. Permissão na porta serial** (uma vez só; depois saia e entre de novo na sessão)

```bash
sudo usermod -aG dialout $USER      # no Arch: uucp
ls /dev/ttyUSB* /dev/ttyACM*        # com a placa ligada no USB
```

**5. Clonar este projeto e compilar**

```bash
cd ~/Apps/lorawan_workspace
git clone https://github.com/AdailSilva/Gateway_ESP32_SX1302_LR1302_HAT_Elecrow.git
cd Gateway_ESP32_SX1302_LR1302_HAT_Elecrow
sh scripts/build.sh esp32             # ESP32-WROOM-32U DevKit
sh scripts/build.sh esp32s3_n16r8     # ESP32-S3-WROOM-1U-N16R8 DevKit
sh scripts/build.sh esp32s3_n32r16v   # ESP32-S3-WROOM-2-N32R16V DevKit
```

### 🍎 macOS (Intel ou Apple Silicon)

**1. Ferramentas da Apple e pacotes do [Homebrew](https://brew.sh)**

```bash
xcode-select --install
brew install cmake ninja dfu-util ccache python3 gnu-sed
```

**2. ESP-IDF:** o mesmo `git clone` e o mesmo `./install.sh esp32,esp32s3` do passo 2 do Linux. Ative com `. ~/Apps/esp-idf/export.sh` (funciona no zsh, o shell padrão do macOS) e confira com `idf.py --version`.

**3. `sed` do GNU.** O `scripts/gen_headers.sh` usa `sed -i` e o comando que limpa os logs usa `\x1B`; o `sed` do macOS não aceita nenhum dos dois. Coloque o `sed` do GNU na frente no `PATH`:

```bash
echo 'export PATH="$(brew --prefix)/opt/gnu-sed/libexec/gnubin:$PATH"' >> ~/.zshrc && source ~/.zshrc
```

**4. Porta serial.** A ESP32-WROOM-32U DevKit aparece como `/dev/cu.usbserial-*` (CP210x) ou `/dev/cu.wchusbserial*` (CH340); a porta USB nativa da ESP32-S3 aparece como `/dev/cu.usbmodem*`. Liste com `ls /dev/cu.*` e use sempre o `/dev/cu.*`, não o `/dev/tty.*`. Se a placa não aparecer, instale o driver do chip USB-serial (links no passo 1 do Windows nativo).

**5. Gravar com log.** O `script` do macOS tem outra sintaxe (`script -q <arquivo> <comando>`, sem `-c` e `-f`). O comando *compilar do zero, gravar e abrir o monitor* fica assim (troque a porta):

```bash
. ~/Apps/esp-idf/export.sh && \
cd ~/Apps/lorawan_workspace/Gateway_ESP32_SX1302_LR1302_HAT_Elecrow && \
mkdir -p logs && \
LOG=logs/esp32_$(date +%Y%m%d_%H%M%S).log && \
script -q "$LOG" sh -c "rm -rf build-esp32 sdkconfig.esp32 managed_components dependencies.lock && sh scripts/build.sh esp32 flash /dev/cu.usbserial-0001" ; \
sed -r 's/\x1B\[[0-9;]*[mK]//g; s/\r//g' "$LOG" > "${LOG%.log}_limpo.log" && \
echo "Logs salvos em: $LOG e ${LOG%.log}_limpo.log"
```

Para o S3, troque `esp32` por `esp32s3_n16r8` ou `esp32s3_n32r16v` (conforme o módulo) e a porta por `/dev/cu.usbmodem*`. Sem log, os atalhos funcionam iguais: `sh scripts/build.sh esp32s3_n32r16v flash /dev/cu.usbmodem1101`.

### 🪟 Windows

**Opção A: WSL2 + Ubuntu (recomendada).** Tudo neste README funciona igual ao Linux, inclusive o `scripts/build.sh` e os comandos com log.

1. No PowerShell **como administrador**:

   ```powershell
   wsl --install -d Ubuntu-24.04
   winget install --exact dorssel.usbipd-win
   ```

2. Reinicie o Windows, abra o **Ubuntu** e siga os passos do **Linux** acima. Deixe o ESP-IDF e os projetos dentro do Ubuntu (`~/Apps`), não em `/mnt/c`: a compilação fica muito mais rápida.

3. Passe a placa USB para o WSL (PowerShell como administrador; o `bind` é só na primeira vez):

   ```powershell
   usbipd list                                     # anote o BUSID da placa, por exemplo 2-3
   usbipd bind --busid 2-3
   usbipd attach --wsl --busid 2-3 --auto-attach
   ```

   Deixe essa janela aberta: o `--auto-attach` reconecta a placa sozinho quando ela reinicia ou é desconectada. No Ubuntu, a ESP32-WROOM-32U aparece como `/dev/ttyUSB0` e a porta USB nativa da ESP32-S3 como `/dev/ttyACM0`. No S3 o `--auto-attach` é indispensável: a porta USB nativa some e volta a cada reset durante a gravação.

**Opção B: Windows nativo.**

1. **Driver da porta serial**, se o Windows não reconhecer a placa: [CP210x (Silicon Labs)](https://www.silabs.com/developers/usb-to-uart-bridge-vcp-drivers) ou [CH340 (WCH)](https://www.wch-ic.com/downloads/CH341SER_EXE.html). A placa aparece como `COMx` no Gerenciador de Dispositivos.

2. **ESP-IDF Installation Manager (EIM)**, o instalador oficial da Espressif:

   ```powershell
   winget install Espressif.EIM
   ```

   Abra o EIM e instale o **ESP-IDF v5.5.1** num caminho curto e sem espaços. Pela linha de comando: `winget install Espressif.EIM-CLI` e depois `eim install -i v5.5.1`.

3. Abra o atalho **IDF_PowerShell** que o EIM cria na área de trabalho (ele já ativa o ambiente) e confira com `idf.py --version`.

4. O `scripts/build.sh`, o `scripts/gen_headers.sh`, o `script` e o `sed` são de Linux. No PowerShell, gere os dois headers embutidos (página web e planos de frequência) uma vez depois de clonar, e de novo sempre que editar `webpage.html` ou os JSON de `global_conf.json/`:

   ```powershell
   cd C:\Apps\lorawan_workspace
   git clone https://github.com/AdailSilva/Gateway_ESP32_SX1302_LR1302_HAT_Elecrow.git
   cd Gateway_ESP32_SX1302_LR1302_HAT_Elecrow

   # main\packet_forwarder\webpage.h
   python scripts\dump_html.py main\packet_forwarder\webpage.html webpage_str |
     Out-File -Encoding ascii main\packet_forwarder\webpage.h

   # main\packet_forwarder\global_json.h
   $dir = "main\packet_forwarder\global_conf.json"
   $plans = [ordered]@{ "cn490"="global_cn_conf"; "eu868"="global_eu_conf"; "us915"="global_us_conf";
                        "au915_sb0"="global_au0_conf"; "au915_sb1"="global_au1_conf" }
   $(foreach ($p in $plans.Keys) {
       "// dump from global_conf.$p.json as string array"
       "const static uint8_t $($plans[$p])[] = {"
       python scripts\json_to_hex_array.py "$dir\global_conf.$p.json"
       "};"
       ""
   }) | Out-File -Encoding ascii main\packet_forwarder\global_json.h
   ```

   Depois compile e grave com o `idf.py` direto, com os mesmos parâmetros que o `build.sh` usa (troque `COM5` pela porta da placa):

   ```powershell
   # ESP32-WROOM-32U DevKit
   idf.py -B build-esp32 -D SDKCONFIG=sdkconfig.esp32 -D IDF_TARGET=esp32 -D BOARD=esp32 build
   idf.py -B build-esp32 -D SDKCONFIG=sdkconfig.esp32 -D IDF_TARGET=esp32 -D BOARD=esp32 -p COM5 flash monitor

   # ESP32-S3-WROOM-1U-N16R8 DevKit: use a porta COM da USB nativa
   idf.py -B build-esp32s3_n16r8 -D SDKCONFIG=sdkconfig.esp32s3_n16r8 -D IDF_TARGET=esp32s3 -D BOARD=esp32s3_n16r8 build
   idf.py -B build-esp32s3_n16r8 -D SDKCONFIG=sdkconfig.esp32s3_n16r8 -D IDF_TARGET=esp32s3 -D BOARD=esp32s3_n16r8 -p COM6 flash monitor

   # ESP32-S3-WROOM-2-N32R16V DevKit: use a porta COM da USB nativa
   idf.py -B build-esp32s3_n32r16v -D SDKCONFIG=sdkconfig.esp32s3_n32r16v -D IDF_TARGET=esp32s3 -D BOARD=esp32s3_n32r16v build
   idf.py -B build-esp32s3_n32r16v -D SDKCONFIG=sdkconfig.esp32s3_n32r16v -D IDF_TARGET=esp32s3 -D BOARD=esp32s3_n32r16v -p COM6 flash monitor
   ```

   Nos comandos da tabela abaixo, troque `esp32` pelo `BOARD` do S3 (`esp32s3_n16r8` ou `esp32s3_n32r16v`), inclusive em `-D IDF_TARGET=esp32s3`.

   | Para | No PowerShell |
   |---|---|
   | Compilar do zero | `Remove-Item -Recurse -Force build-esp32, sdkconfig.esp32, managed_components, dependencies.lock -ErrorAction SilentlyContinue` e depois o `build` |
   | Apagar a flash (inclusive a NVS) | `idf.py -B build-esp32 -D SDKCONFIG=sdkconfig.esp32 -D IDF_TARGET=esp32 -D BOARD=esp32 -p COM5 erase-flash` |
   | Só monitorar | `idf.py -B build-esp32 -D SDKCONFIG=sdkconfig.esp32 -D IDF_TARGET=esp32 -D BOARD=esp32 -p COM5 monitor` |
      | Salvar o log do monitor | dentro do monitor, **Ctrl+T** e depois **Ctrl+L** (liga e desliga a gravação em arquivo na pasta do projeto) |

### ✅ Conferir a instalação

Com o ambiente ativado, `idf.py --version` mostra a versão do ESP-IDF, e `sh scripts/build.sh esp32` / `esp32s3_n16r8` / `esp32s3_n32r16v` (ou `sh scripts/build.sh all`, ou o `idf.py ... build` no Windows nativo) termina com `Project build complete`. O primeiro build baixa pelo Component Manager o `espressif/mdns` (só nos dois S3) e, no ESP-IDF 6.x, o `espressif/mqtt`; por isso precisa de internet.

---

## 🛠️ Compilar e gravar

### Requisitos

- [ESP-IDF](https://docs.espressif.com/projects/esp-idf/) **v5.5.1** (também compila no 6.x), com as ferramentas de `esp32` e `esp32s3`.
- Python 3 (vem com o ESP-IDF).

O passo a passo de instalação no Linux, no macOS e no Windows está em [Preparar o ambiente ESP-IDF](#-preparar-o-ambiente-esp-idf).

### Com o script do projeto (recomendado)

[`scripts/build.sh`](scripts/build.sh) gera os headers embutidos (página web e planos de frequência) e compila cada placa (`BOARD`) em uma pasta própria, com o próprio `sdkconfig`. Assim uma placa não sobrescreve a outra.

| `BOARD` | Placa | Pasta de build + sdkconfig | Porta |
|---|---|---|---|
| `esp32` | ESP32-WROOM-32U DevKit | `build-esp32/` + `sdkconfig.esp32` | `/dev/ttyUSB0` |
| `esp32s3_n16r8` | ESP32-S3-WROOM-1U-N16R8 DevKit | `build-esp32s3_n16r8/` + `sdkconfig.esp32s3_n16r8` | `/dev/ttyACM0` (USB nativa) |
| `esp32s3_n32r16v` | ESP32-S3-WROOM-2-N32R16V DevKit | `build-esp32s3_n32r16v/` + `sdkconfig.esp32s3_n32r16v` | `/dev/ttyACM0` (USB nativa) |

Comandos do script: `<BOARD>` (só compila), `<BOARD> flash <porta>` (compila, grava e abre o monitor), `<BOARD> monitor <porta>`, `<BOARD> erase <porta>` (apaga a flash inteira) e `all` (compila as três). O nome antigo `esp32s3` ainda funciona e vira `esp32s3_n32r16v`; as pastas `build-esp32s3/` e `sdkconfig.esp32s3` da v0.0.1 podem ser apagadas.

```bash
mkdir -p ~/Apps/lorawan_workspace && cd ~/Apps/lorawan_workspace
git clone https://github.com/AdailSilva/Gateway_ESP32_SX1302_LR1302_HAT_Elecrow.git
cd Gateway_ESP32_SX1302_LR1302_HAT_Elecrow

# ESP32-WROOM-32U DevKit  -> build-esp32/   + sdkconfig.esp32
./scripts/build.sh esp32
./scripts/build.sh esp32 flash /dev/ttyUSB0        # grava e abre o monitor

# ESP32-S3-WROOM-1U-N16R8  -> build-esp32s3_n16r8/ + sdkconfig.esp32s3_n16r8
./scripts/build.sh esp32s3_n16r8
./scripts/build.sh esp32s3_n16r8 flash /dev/ttyACM0     # porta USB nativa, não a "UART"

# ESP32-S3-WROOM-2-N32R16V -> build-esp32s3_n32r16v/ + sdkconfig.esp32s3_n32r16v
./scripts/build.sh esp32s3_n32r16v
./scripts/build.sh esp32s3_n32r16v flash /dev/ttyACM0   # porta USB nativa, não a "UART"

# as três placas de uma vez (só compila)
./scripts/build.sh all

# só o monitor (sem compilar nem gravar)
./scripts/build.sh esp32 monitor /dev/ttyUSB0
```

### Gravar e acompanhar o log

Pasta do projeto: `~/Apps/lorawan_workspace/Gateway_ESP32_SX1302_LR1302_HAT_Elecrow` (ESP-IDF em `~/Apps/esp-idf`). Os comandos abaixo valem para Linux e WSL2; no macOS e no Windows nativo, veja as variações em [Preparar o ambiente ESP-IDF](#-preparar-o-ambiente-esp-idf). A saída da compilação, da gravação e do monitor vai para `logs/<alvo>_<data>.log`. Uma cópia sem códigos de cor vai para `logs/<alvo>_<data>_limpo.log`. A pasta `logs/` fica fora do git.

Cada placa tem três comandos, prontos para copiar e colar:

| Comando | O que faz | Configuração na NVS |
|---|---|---|
| **Do zero** | libera a porta, apaga `build-<BOARD>/`, `sdkconfig.<BOARD>`, `managed_components/` e `dependencies.lock`, apaga a flash inteira (`erase`), compila, grava e abre o monitor | **apagada**: volta ao padrão de fábrica |
| **Atualizar** | libera a porta, apaga as mesmas pastas e arquivos de build, compila do zero, grava e abre o monitor | mantida |
| **Só monitorar** | libera a porta e abre o monitor, sem compilar nem gravar | mantida |

`sudo fuser -k <porta> 2>/dev/null ;` fecha o programa que estiver usando a porta serial (um monitor esquecido em outro terminal, por exemplo), que senão faria a gravação falhar com *port is busy*. A linha termina com `;` e não com `&&` de propósito: quando a porta já está livre, o `fuser` retorna erro e a sequência continua mesmo assim. O `sudo` pede a senha na primeira vez.

**O que o Do zero apaga.** O `erase-flash` apaga a flash inteira antes de gravar, inclusive a NVS. Use quando quiser o gateway "de fábrica" ou ao trocar de firmware na mesma placa (gateway ↔ nó). O gateway perde toda a configuração (Wi-Fi, servidor LoRaWAN, MQTT e certificados, rádio, GPS, login) e sobe em **Soft AP**, na rede **`lorawan-gateway-sx1302`** (senha `lorawan101`), com a página em `http://192.168.101.101` e login `admin` / `lorawan101`. Exporte a configuração antes (seção **Manutenção**) se for reaproveitar. Para regravar mantendo a configuração, use o **Atualizar**.

> Nos dois ESP32-S3 a gravação e o console usam a porta **USB nativa** (`/dev/ttyACM0`), não o conector "UART".

#### ESP32-WROOM-32U DevKit (`esp32`, `/dev/ttyUSB0`)

**Do zero:** apaga a flash, compila do zero, grava e abre o monitor

```bash
sudo fuser -k /dev/ttyUSB0 2>/dev/null ; \
cd ~/Apps/esp-idf/ && \
. ./export.sh && \
cd ~/Apps/lorawan_workspace/Gateway_ESP32_SX1302_LR1302_HAT_Elecrow && \
mkdir -p logs && \
LOG=logs/esp32_$(date +%Y%m%d_%H%M%S).log && \
script -f -q -c "rm -rf build-esp32 sdkconfig.esp32 managed_components dependencies.lock && sh scripts/build.sh esp32 erase /dev/ttyUSB0 && sh scripts/build.sh esp32 flash /dev/ttyUSB0" "$LOG" ; \
sed -r 's/\x1B\[[0-9;]*[mK]//g; s/\r//g' "$LOG" > "${LOG%.log}_limpo.log" && \
echo "Logs salvos em: $LOG e ${LOG%.log}_limpo.log"
```

**Atualizar:** compila do zero, grava e abre o monitor (mantém a configuração)

```bash
sudo fuser -k /dev/ttyUSB0 2>/dev/null ; \
cd ~/Apps/esp-idf/ && \
. ./export.sh && \
cd ~/Apps/lorawan_workspace/Gateway_ESP32_SX1302_LR1302_HAT_Elecrow && \
mkdir -p logs && \
LOG=logs/esp32_update_$(date +%Y%m%d_%H%M%S).log && \
script -f -q -c "rm -rf build-esp32 sdkconfig.esp32 managed_components dependencies.lock && sh scripts/build.sh esp32 flash /dev/ttyUSB0" "$LOG" ; \
sed -r 's/\x1B\[[0-9;]*[mK]//g; s/\r//g' "$LOG" > "${LOG%.log}_limpo.log" && \
echo "Logs salvos em: $LOG e ${LOG%.log}_limpo.log"
```

**Só monitorar:** sem compilar nem gravar

```bash
sudo fuser -k /dev/ttyUSB0 2>/dev/null ; \
cd ~/Apps/esp-idf/ && \
. ./export.sh && \
cd ~/Apps/lorawan_workspace/Gateway_ESP32_SX1302_LR1302_HAT_Elecrow && \
mkdir -p logs && \
LOG=logs/esp32_monitor_$(date +%Y%m%d_%H%M%S).log && \
script -f -q -c "sh scripts/build.sh esp32 monitor /dev/ttyUSB0" "$LOG" ; \
sed -r 's/\x1B\[[0-9;]*[mK]//g; s/\r//g' "$LOG" > "${LOG%.log}_limpo.log" && \
echo "Logs salvos em: $LOG e ${LOG%.log}_limpo.log"
```

#### ESP32-S3-WROOM-1U-N16R8 DevKit (`esp32s3_n16r8`, `/dev/ttyACM0`, porta USB nativa)

**Do zero:** apaga a flash, compila do zero, grava e abre o monitor

```bash
sudo fuser -k /dev/ttyACM0 2>/dev/null ; \
cd ~/Apps/esp-idf/ && \
. ./export.sh && \
cd ~/Apps/lorawan_workspace/Gateway_ESP32_SX1302_LR1302_HAT_Elecrow && \
mkdir -p logs && \
LOG=logs/esp32s3_n16r8_$(date +%Y%m%d_%H%M%S).log && \
script -f -q -c "rm -rf build-esp32s3_n16r8 sdkconfig.esp32s3_n16r8 managed_components dependencies.lock && sh scripts/build.sh esp32s3_n16r8 erase /dev/ttyACM0 && sh scripts/build.sh esp32s3_n16r8 flash /dev/ttyACM0" "$LOG" ; \
sed -r 's/\x1B\[[0-9;]*[mK]//g; s/\r//g' "$LOG" > "${LOG%.log}_limpo.log" && \
echo "Logs salvos em: $LOG e ${LOG%.log}_limpo.log"
```

**Atualizar:** compila do zero, grava e abre o monitor (mantém a configuração)

```bash
sudo fuser -k /dev/ttyACM0 2>/dev/null ; \
cd ~/Apps/esp-idf/ && \
. ./export.sh && \
cd ~/Apps/lorawan_workspace/Gateway_ESP32_SX1302_LR1302_HAT_Elecrow && \
mkdir -p logs && \
LOG=logs/esp32s3_n16r8_update_$(date +%Y%m%d_%H%M%S).log && \
script -f -q -c "rm -rf build-esp32s3_n16r8 sdkconfig.esp32s3_n16r8 managed_components dependencies.lock && sh scripts/build.sh esp32s3_n16r8 flash /dev/ttyACM0" "$LOG" ; \
sed -r 's/\x1B\[[0-9;]*[mK]//g; s/\r//g' "$LOG" > "${LOG%.log}_limpo.log" && \
echo "Logs salvos em: $LOG e ${LOG%.log}_limpo.log"
```

**Só monitorar:** sem compilar nem gravar

```bash
sudo fuser -k /dev/ttyACM0 2>/dev/null ; \
cd ~/Apps/esp-idf/ && \
. ./export.sh && \
cd ~/Apps/lorawan_workspace/Gateway_ESP32_SX1302_LR1302_HAT_Elecrow && \
mkdir -p logs && \
LOG=logs/esp32s3_n16r8_monitor_$(date +%Y%m%d_%H%M%S).log && \
script -f -q -c "sh scripts/build.sh esp32s3_n16r8 monitor /dev/ttyACM0" "$LOG" ; \
sed -r 's/\x1B\[[0-9;]*[mK]//g; s/\r//g' "$LOG" > "${LOG%.log}_limpo.log" && \
echo "Logs salvos em: $LOG e ${LOG%.log}_limpo.log"
```

#### ESP32-S3-WROOM-2-N32R16V DevKit (`esp32s3_n32r16v`, `/dev/ttyACM0`, porta USB nativa)

**Do zero:** apaga a flash, compila do zero, grava e abre o monitor

```bash
sudo fuser -k /dev/ttyACM0 2>/dev/null ; \
cd ~/Apps/esp-idf/ && \
. ./export.sh && \
cd ~/Apps/lorawan_workspace/Gateway_ESP32_SX1302_LR1302_HAT_Elecrow && \
mkdir -p logs && \
LOG=logs/esp32s3_n32r16v_$(date +%Y%m%d_%H%M%S).log && \
script -f -q -c "rm -rf build-esp32s3_n32r16v sdkconfig.esp32s3_n32r16v managed_components dependencies.lock && sh scripts/build.sh esp32s3_n32r16v erase /dev/ttyACM0 && sh scripts/build.sh esp32s3_n32r16v flash /dev/ttyACM0" "$LOG" ; \
sed -r 's/\x1B\[[0-9;]*[mK]//g; s/\r//g' "$LOG" > "${LOG%.log}_limpo.log" && \
echo "Logs salvos em: $LOG e ${LOG%.log}_limpo.log"
```

**Atualizar:** compila do zero, grava e abre o monitor (mantém a configuração)

```bash
sudo fuser -k /dev/ttyACM0 2>/dev/null ; \
cd ~/Apps/esp-idf/ && \
. ./export.sh && \
cd ~/Apps/lorawan_workspace/Gateway_ESP32_SX1302_LR1302_HAT_Elecrow && \
mkdir -p logs && \
LOG=logs/esp32s3_n32r16v_update_$(date +%Y%m%d_%H%M%S).log && \
script -f -q -c "rm -rf build-esp32s3_n32r16v sdkconfig.esp32s3_n32r16v managed_components dependencies.lock && sh scripts/build.sh esp32s3_n32r16v flash /dev/ttyACM0" "$LOG" ; \
sed -r 's/\x1B\[[0-9;]*[mK]//g; s/\r//g' "$LOG" > "${LOG%.log}_limpo.log" && \
echo "Logs salvos em: $LOG e ${LOG%.log}_limpo.log"
```

**Só monitorar:** sem compilar nem gravar

```bash
sudo fuser -k /dev/ttyACM0 2>/dev/null ; \
cd ~/Apps/esp-idf/ && \
. ./export.sh && \
cd ~/Apps/lorawan_workspace/Gateway_ESP32_SX1302_LR1302_HAT_Elecrow && \
mkdir -p logs && \
LOG=logs/esp32s3_n32r16v_monitor_$(date +%Y%m%d_%H%M%S).log && \
script -f -q -c "sh scripts/build.sh esp32s3_n32r16v monitor /dev/ttyACM0" "$LOG" ; \
sed -r 's/\x1B\[[0-9;]*[mK]//g; s/\r//g' "$LOG" > "${LOG%.log}_limpo.log" && \
echo "Logs salvos em: $LOG e ${LOG%.log}_limpo.log"
```

#### Compilar as três placas (sem gravar)

Útil para conferir, antes de um commit, que o firmware não quebrou em nenhuma placa. O `build.sh all` compila `esp32`, `esp32s3_n16r8` e `esp32s3_n32r16v` em sequência, cada um na sua pasta `build-<BOARD>/`.

```bash
cd ~/Apps/esp-idf/ && . ./export.sh && \
cd ~/Apps/lorawan_workspace/Gateway_ESP32_SX1302_LR1302_HAT_Elecrow && sh scripts/build.sh all
```

> **Lembretes**
> - Com duas placas no USB ao mesmo tempo, a segunda aparece como `/dev/ttyUSB1` ou `/dev/ttyACM1`. Confira com `ls /dev/ttyUSB* /dev/ttyACM*` e troque a porta nos comandos.
> - Para sair do monitor, use **Ctrl+]**.

Atalhos sem log, com o ambiente já ativado e dentro da pasta do projeto, estão em [Com o script do projeto](#com-o-script-do-projeto-recomendado).

### Com `idf.py` direto

```bash
./scripts/gen_headers.sh                            # gera webpage.h e global_json.h
idf.py -B build-esp32s3_n16r8 -D SDKCONFIG=sdkconfig.esp32s3_n16r8 -D IDF_TARGET=esp32s3 -D BOARD=esp32s3_n16r8 build
idf.py -B build-esp32s3_n16r8 -D SDKCONFIG=sdkconfig.esp32s3_n16r8 -D IDF_TARGET=esp32s3 -D BOARD=esp32s3_n16r8 -p /dev/ttyACM0 flash monitor
```

> `-D BOARD=` escolhe a placa (`esp32`, `esp32s3_n16r8`, `esp32s3_n32r16v`) e precisa combinar com `-D IDF_TARGET=`. Sem `BOARD`, o `CMakeLists.txt` usa `esp32` para o alvo `esp32` e `esp32s3_n32r16v` para o `esp32s3`.

> `webpage.h` e `global_json.h` são gerados e ficam fora do git. Depois de editar `main/packet_forwarder/webpage.html` ou os JSON de `global_conf.json/`, rode `scripts/gen_headers.sh` de novo (o `build.sh` já faz isso).

### Binários prontos (GitHub Actions)

O workflow [`.github/workflows/build.yml`](.github/workflows/build.yml) compila as **três placas** a cada push e pull request e publica os `.bin` como *artifacts*. Ao criar uma tag `v*` (por exemplo `v0.0.2`), ele também cria uma **Release** com estes arquivos:

| Arquivo | Uso |
|---|---|
| `Gateway_ESP32_SX1302_LR1302_HAT_Elecrow-<versão>-esp32-full.bin` | ESP32-WROOM-32U: imagem única, gravar em `0x0` |
| `Gateway_ESP32_SX1302_LR1302_HAT_Elecrow-<versão>-esp32-app.bin` | ESP32-WROOM-32U: só a aplicação, gravar em `0x10000` |
| `Gateway_ESP32_SX1302_LR1302_HAT_Elecrow-<versão>-esp32-parts.zip` | ESP32-WROOM-32U: bootloader, tabela de partições e aplicação com o `flash_args` |
| `Gateway_ESP32_SX1302_LR1302_HAT_Elecrow-<versão>-esp32s3_n16r8-full.bin` | ESP32-S3-WROOM-1U-N16R8: imagem única, gravar em `0x0` |
| `Gateway_ESP32_SX1302_LR1302_HAT_Elecrow-<versão>-esp32s3_n16r8-app.bin` | ESP32-S3-WROOM-1U-N16R8: só a aplicação, gravar em `0x10000` |
| `Gateway_ESP32_SX1302_LR1302_HAT_Elecrow-<versão>-esp32s3_n16r8-parts.zip` | ESP32-S3-WROOM-1U-N16R8: partes separadas com o `flash_args` |
| `Gateway_ESP32_SX1302_LR1302_HAT_Elecrow-<versão>-esp32s3_n32r16v-full.bin` | ESP32-S3-WROOM-2-N32R16V: imagem única, gravar em `0x0` |
| `Gateway_ESP32_SX1302_LR1302_HAT_Elecrow-<versão>-esp32s3_n32r16v-app.bin` | ESP32-S3-WROOM-2-N32R16V: só a aplicação, gravar em `0x10000` |
| `Gateway_ESP32_SX1302_LR1302_HAT_Elecrow-<versão>-esp32s3_n32r16v-parts.zip` | ESP32-S3-WROOM-2-N32R16V: partes separadas com o `flash_args` |
| `SHA256SUMS.txt` | somas de verificação |

A versão do firmware vem da **tag**: o workflow passa `FW_VERSION` para o [`CMakeLists.txt`](CMakeLists.txt), que preenche `ESP32_SX1302_VERSION` (boot, página web, metadados MQTT). Não há número de versão para editar à mão. As notas da Release vêm da seção `## vX.Y.Z` do [CHANGELOG](doc/CHANGELOG.md), quando existe. Tags com sufixo (`v0.1.0-rc1`) viram *pre-release*.

Para lançar uma versão nova: atualize o CHANGELOG, faça o commit e depois rode:

```bash
git tag -a v0.0.2 -m "v0.0.2" && git push origin v0.0.2
```

> A imagem única (`-full.bin`) preenche a área da NVS com `0xFF`: o gateway volta aos valores de fábrica, inclusive os certificados MQTT. Para atualizar mantendo a configuração, grave só a aplicação: `esptool.py --chip esp32 -p /dev/ttyUSB0 write_flash 0x10000 Gateway_ESP32_SX1302_LR1302_HAT_Elecrow-<versão>-esp32-app.bin`.

### Criar o repositório no GitHub

O [`scripts/create_github_repo.sh`](scripts/create_github_repo.sh) cria o repositório **`Gateway_ESP32_SX1302_LR1302_HAT_Elecrow`** com o GitHub CLI (`gh auth login` antes), envia o código e cria a tag `v0.0.1`, que dispara a primeira Release. Se a pasta já tem histórico git, ele é mantido e só o `origin` passa a apontar para o repositório novo. A pasta `configurations_backup/` nunca vai para o GitHub. Se o seu GitHub ainda tiver o repositório com o nome antigo (**`LoRaWAN_Gateway_ESP32_SX1302_LR1302_HAT_Elecrow`**, de antes de o projeto perder o prefixo `LoRaWAN_`), o script o **renomeia** (`gh repo rename`: histórico, Releases e estrelas continuam, e o GitHub redireciona o endereço antigo), aponta o `origin` para o novo nome e segue como no `--sync`.

```bash
cd ~/Apps/lorawan_workspace/Gateway_ESP32_SX1302_LR1302_HAT_Elecrow
sh scripts/create_github_repo.sh             # público
sh scripts/create_github_repo.sh --private   # privado
sh scripts/create_github_repo.sh --sync      # repositório já existe: só descrição, tópicos e tags
```

Descrição aplicada ao repositório:

> Low-cost 8-channel LoRaWAN gateway running the Semtech SX1302_HAL (v2.1.0) natively on a single ESP32 microcontroller.

O script aplica a descrição e os **tópicos** do repositório e cria a tag **`v0.0.1`**. Se o GitHub ainda não responder logo após a criação, ele tenta de novo e, no final, mostra os tópicos e as tags que ficaram no GitHub. Se faltar algo, rode com `--sync`.

Se o repositório foi apagado no GitHub, basta rodar de novo: as tags que já existem no histórico local também sobem, e o GitHub Actions refaz as Releases.

> **`GraphQL: You have created too many repositories, too quickly`**: é um limite temporário do GitHub para criar muitos repositórios em pouco tempo (aparece principalmente depois de apagar e recriar repositórios várias vezes). O script espera e tenta de novo sozinho (padrão: 6 tentativas, a cada 5 min; mude com `TRIES=8 WAIT=600 sh scripts/create_github_repo.sh`). Se o limite continuar, ele para com o código 75 sem perder nada: o commit local fica guardado, e basta rodar o mesmo comando mais tarde.

---

## 🚀 Primeiro uso

1. Ligue o gateway **com a antena LoRa conectada**.
2. Na primeira vez (ou segurando o botão **BOOT** logo depois do reset), ele sobe em **Soft AP**:
   - Rede Wi-Fi: **`lorawan-gateway-sx1302`**, senha **`lorawan101`**.
   - Abra **http://192.168.101.101** (é *http*, não *https*).
   - Login da página: **`admin` / `lorawan101`**. Troque a senha na seção *Acesso a esta página*.
3. Configure o **Wi-Fi Station**, o **plano de frequência** (AU915 SB1 é o padrão) e o modo de envio (**UDP** ou **MQTT**). O **Gateway EUI** já vem preenchido automaticamente a partir do MAC; só digite outro se quiser sobrescrevê-lo. Salve e reinicie.
4. No ChirpStack, cadastre o gateway com o **Gateway EUI** mostrado na página (cabeçalho *Gateway*).
5. *(Opcional)* Com os pinos 8/10 do HAT ligados, abra a seção **GPS**, escolha **Ligado** e salve: a posição aparece na página e no mapa do ChirpStack. Veja [1.6 GPS](#16-gps).
6. No monitor serial, o boot deve mostrar:

```
INFO: [main] concentrator started, packet can now be received
I (...) gw_mqtt: connected to the broker          ← quando o MQTT está ligado
INFO: [gps] GPS switched on: UART1 9600 baud, ...  ← quando o GPS está ligado
```

Com MQTT ligado, o GPS só inicia **depois** da linha `connected to the broker` (veja [1.6 GPS](#16-gps)); antes dela aparece `GPS start deferred until the MQTT connection`.

---

## 🖥️ Servidor web embutido

O gateway traz um servidor HTTP próprio (`esp_http_server`, porta **80**) com cinco telas: **Configuração** (com o painel de status), **Logs**, **Diagnósticos**, **Classes LoRaWAN** e o **JSON dos planos de frequência**, além das páginas curtas de confirmação. Tudo fica gravado na flash do firmware, não depende de internet nem de CDN e funciona igual no ESP32 e no ESP32-S3.

- **Endereço:** `http://192.168.101.101` em Soft AP, ou o IP que o roteador entregou (ou o IP fixo configurado) em Station. É *http*, não *https*.
- **Tema:** claro ou escuro, conforme o tema do sistema operacional/navegador (`prefers-color-scheme`). `/w` é um apelido de `/` mantido por compatibilidade.
- **Celular:** todas as telas se adaptam a telas estreitas (menu vira uma lista de botões, cartões em 2 colunas, campos em 1 coluna).
- **Código:** `main/packet_forwarder/webpage.html` (configuração), `logs_page.h`, `diag_page.h` e as páginas curtas em `http_server.c`. Depois de editar o `webpage.html`, rode `scripts/gen_headers.sh` (o `build.sh` já faz isso).

> As capturas abaixo foram geradas a partir do HTML/JS real do firmware, servido com **dados de exemplo** (Gateway ID `E45F01FFFE10E12E`, broker `mqtt.exemplo.com.br`, servidor `chirpstack.exemplo.com.br`). Os números não são de um gateway em campo.

### 🔐 Login e sessão

Todas as páginas e chamadas usam **HTTP Basic Auth**. O navegador abre a janela de usuário e senha dele mesmo na primeira visita.

| Item | Detalhe |
|---|---|
| Login padrão | `admin` / `lorawan101` |
| Trocar | Seção **Acesso** da página ou `web_auth --user <u> --pass <p>` no console. Vale **na hora**, sem reiniciar |
| Esqueceu a senha | `web_auth --reset` no console serial (volta para `admin` / `lorawan101`) |
| Gateway atualizado de firmware antigo | O login fica gravado na NVS e tem prioridade sobre o padrão. Se a NVS ainda tiver o login de fábrica de uma versão anterior, o firmware passa sozinho para o padrão atual `admin` / `lorawan101` no boot (o log mostra *“old default password found in NVS”*). Um login personalizado é mantido |
| Regras | Usuário de 1 a 31 caracteres; senha de 6 a 31; nenhum dos dois pode ter `:`; o usuário `_logout_` é reservado |
| Sair | Link **Sair** no topo de qualquer tela. Pede confirmação, troca o login guardado pelo navegador por um login falso (`_logout_`) e abre a tela **Você saiu**. O próximo acesso pede usuário e senha de novo |
| Sem login | Só `/favicon.svg`, `/favicon.ico` e `/saiu` |

As senhas (Wi-Fi, MQTT e da página) **nunca** voltam para o navegador: os campos aparecem vazios com a dica *“Salva (vazio mantém)”*, e no log o formulário enviado aparece com `wifi_pswd=***`, `mqtt_pswd=***` e `web_pswd=***`.

### 1. Configuração (`/`)

É a tela principal. Tem a **barra superior**, o **menu lateral**, o **painel de status** e as sete seções de configuração, com uma **barra de ações** fixa no rodapé.

<p align="center">
  <img src="doc/images/web/web_01_status.png" alt="Tela de configuração: barra superior, menu lateral e painel de status" width="100%"/>
</p>

**Barra superior** (fica fixa no topo ao rolar):

| Elemento | O que mostra |
|---|---|
| Ponto + texto MQTT | 🟢 *MQTT conectado* · 🟠 *MQTT desconectado* · ⚪ *MQTT desativado* (vem do `/status`) |
| IP | Endereço usado para abrir a página |
| Gateway | Gateway EUI: o digitado ou, com o campo vazio, o automático (MAC + `FFFE`). Muda enquanto você digita |
| Plano | Plano de frequência marcado (AU915 SB0/SB1, US915, EU868, CN470). Muda ao clicar em outro |
| Logs · Diagnósticos · Sair | Atalhos para as outras telas e para encerrar a sessão |

**Menu lateral:** Status, Rede Wi-Fi, Servidor LoRaWAN, MQTT, Rádio LoRa, GPS, Inicialização, Acesso e Manutenção. Clicar rola até a seção; ao rolar a página, o item da seção visível fica marcado.

#### 1.1 Painel de status

Lê `GET /status` a cada **5 s**, só enquanto a aba está visível. Um pedido novo só sai depois da resposta do anterior, para não sobrecarregar o ESP32.

A faixa no topo resume a situação:

| Faixa | Quando aparece |
|---|---|
| 🟢 *Gateway funcionando, servidor LoRaWAN respondendo.* | Forwarder rodando por UDP e o último `PULL_ACK` é recente |
| 🟢 *Gateway funcionando, envio por MQTT.* | Forwarder rodando com MQTT ativado |
| 🟠 *Encaminhador parado…* | O concentrador não iniciou (veja a fiação) ou o gateway está em Soft AP |
| 🟠 *O servidor LoRaWAN ainda não respondeu…* / *não responde há …* | Nenhum `PULL_ACK` recebido, ou o último é mais velho que o intervalo de estatística (mín. 30 s) |
| 🟠 *Sem resposta do gateway. Tentando de novo…* | O navegador perdeu contato com o gateway |

Os nove cartões:

| Cartão | Valor | Linha de baixo |
|---|---|---|
| Ligado há | Uptime (`2 d 5 h`, `14 min 3 s`…) | Lembra que os contadores zeram ao reiniciar |
| Memória livre | Heap interno livre | Mínimo já atingido desde que ligou |
| Sinal Wi-Fi | RSSI do AP em dBm | *sinal bom* (≥ −60), *regular* (≥ −75), *fraco*; ou *sem conexão Station* |
| Temperatura | Leitura do sensor STTS751 do módulo LR1302 (I2C, pinos 3 e 5 do HAT) | Intervalo de leitura. Se o sensor não respondeu no boot: *não encontrado · RSSI compensado a 25 °C* |
| Pacotes recebidos | Total de pacotes de RF | CRC ok · erro · sem CRC |
| Encaminhados | Pacotes enviados ao servidor | *ao servidor por UDP* ou *ao broker por MQTT* |
| Downlinks enviados | TX feitos pelo concentrador | Pedidos · falhas · rejeitados (colisão, cedo/tarde demais) |
| Último ACK do servidor | Idade do último `PULL_ACK` (UDP) | % de `PUSH_DATA` e `PULL_DATA` confirmados. Com MQTT: *UDP desligado* |
| GPS | *desligado*, *aguardando MQTT*, *sem dados*, *sem posição* ou *N satélites* | Latitude e longitude quando há posição; com o GPS ligado e nada chegando, o GPIO de RX a conferir. Detalhes na seção [GPS](#16-gps) |

O mesmo painel no tema escuro e logo depois do primeiro boot, em Soft AP (concentrador ainda parado):

<p align="center">
  <img src="doc/images/web/web_01_status_dark.png" alt="Tela de configuração no tema escuro" width="100%"/>
</p>

<p align="center">
  <img src="doc/images/web/web_09_softap.png" alt="Primeiro acesso em Soft AP, com o encaminhador parado" width="100%"/>
</p>

#### 1.2 Rede Wi-Fi

<p align="center">
  <img src="doc/images/web/web_02_wifi.png" alt="Seção Rede Wi-Fi com IP fixo" width="100%"/>
</p>

| Campo | Para que serve |
|---|---|
| Nome da rede (SSID) | Rede em que o gateway entra no modo Station. Só caracteres ASCII |
| Senha | Mínimo de 8 caracteres. **Mostrar/Ocultar** exibe o que foi digitado. Vazio mantém a senha salva |
| Endereço IP | **Automático (DHCP)** ou **IP fixo** |
| Endereço IP, Máscara, Gateway (roteador) | Obrigatórios com IP fixo. A máscara vazia vira `255.255.255.0`. A página sugere o IP atual e o roteador `x.x.x.1` |
| DNS primário / secundário | Primário vazio usa o roteador; secundário é opcional (sugestão `8.8.8.8`) |

Com IP fixo, a página confere se o roteador está na mesma rede do IP (pela máscara) e se não é o próprio IP. Depois de reiniciar, abra a página no IP novo.

#### 1.3 Servidor LoRaWAN (UDP)

<p align="center">
  <img src="doc/images/web/web_03_lorawan_udp.png" alt="Seção Servidor LoRaWAN" width="100%"/>
</p>

| Campo | Para que serve |
|---|---|
| Host do Gateway Bridge | IP ou domínio do ChirpStack Gateway Bridge (sem `http://`) |
| Porta UDP | Normalmente `1700` |
| Gateway EUI | Vazio = **automático** (MAC do Wi-Fi + `FFFE`, mostrado esmaecido no campo). Digite 16 hexadecimais para sobrescrever; o botão **Automático** volta ao padrão. Convertido para maiúsculas ao salvar. Cadastre o mesmo EUI no ChirpStack |
| Servidor NTP | Padrão `br.pool.ntp.org` |

Com o MQTT ativado aparece o aviso *“UDP desligado”*: host e porta continuam guardados para quando o MQTT for desligado. O Gateway EUI e o NTP valem nos dois modos.

##### Gateway EUI

O Gateway EUI (o *Gateway ID* do ChirpStack) tem 64 bits, escritos em 16 hexadecimais. O firmware segue a convenção usada pelos gateways LoRaWAN: pega o MAC de 48 bits do Wi-Fi (Station) do ESP32 e insere `FFFE` no meio.

```
MAC do Wi-Fi:  24:0A:C4:00:8D:88
Gateway EUI:   240AC4 FFFE 008D88  ->  240AC4FFFE008D88
```

- **Automático (padrão):** com o campo vazio, vale o EUI do MAC. Ele é único por placa, aparece como placeholder no campo e não muda ao regravar o firmware nem com *Restaurar padrão de fábrica*.
- **Sobrescrita:** digite outro EUI de 16 hexadecimais e salve. O valor fica gravado na NVS e substitui o automático. Para voltar, clique em **Automático** (ou apague o campo) e salve.
- **Vale após reiniciar.** Até lá a dica do campo mostra *Em uso até reiniciar: …*. Trocar o EUI muda também o tópico MQTT padrão (`au915_1/gateway/<eui>`) e exige recadastrar o gateway no ChirpStack.
- **Console:** `config` mostra o EUI e a origem (automatic / saved override); `config --gwid <16 hex>` sobrescreve, `config --gwid auto` volta ao automático.
- No boot o log mostra `Gateway EUI 240AC4FFFE008D88 (automatic: Wi-Fi MAC + FFFE)` ou `(saved override; ...)`.

No firmware original (antes da v0.0.1), com o campo vazio o forwarder usava o `AA555A0000000000` do `global_conf.json` embutido (e o MQTT, `unknown`). Gateways que já têm um ID salvo continuam com ele.


#### 1.4 MQTT

<p align="center">
  <img src="doc/images/web/web_04_mqtt.png" alt="Seção MQTT com os certificados TLS abertos" width="100%"/>
</p>

A faixa do topo mostra o estado ao vivo: broker, formato, codificação, downlinks recebidos/agendados, mensagens enviadas e tópico. Em caso de falha, mostra o último erro (*“Não conectado a … : <erro>”*).

| Campo | Opções |
|---|---|
| Envio por MQTT | **Desativado** (só UDP) · **Ativado** (só MQTT; o UDP desliga) |
| Formato | **Espelho Semtech** (JSON do UDP em `/up`, `/stats`, `/state`, sem downlinks) · **ChirpStack v4** (`event/up`, `event/stats`, `event/ack`, `state/conn`, `command/down`, com downlinks) |
| Codificação | **JSON** ou **Protobuf**. Só aparece no formato ChirpStack v4 |
| Protocolo | Lista: `mqtts://` (TLS, porta padrão 8883), `mqtt://` (sem criptografia, 1883), `wss://` (WebSocket com TLS, 443) ou `ws://` (WebSocket, 80) |
| Host do broker | IP ou domínio, sem o protocolo e sem a porta. Obrigatório com o MQTT ativado. Colar uma URI inteira (`mqtts://host:8883`) preenche os três campos |
| Porta | Porta do broker; vazio usa a padrão do protocolo. Trocar o protocolo troca a porta se ela era a padrão do anterior |
| Usuário / Senha | Credenciais do broker. Senha vazia mantém a salva |
| Tópico base | Vazio usa o padrão mostrado em cinza, calculado na hora: `au915_1/gateway/<id em minúsculas>` (ChirpStack, prefixo da região escolhida) ou `gateway/<ID>` (Semtech) |

**Certificados TLS** (clique para abrir): três caixas, **CA do broker**, **Certificado do cliente** e **Chave privada do cliente**, cada uma com o selo *instalado / não instalado*. Cole o PEM ou escolha um arquivo (`.pem`, `.crt`, `.cer`, `.key`, `.txt`) e clique em **Enviar**; **Remover** apaga (pede confirmação). Cada envio vai por `POST /mqtt_cert?type=ca|crt|key`, fica na NVS (até 8 KB cada) e reconecta o MQTT **na hora**, sem precisar de *Salvar*.

- Sem CA enviada, o broker é validado pelo bundle público do ESP-IDF (Let's Encrypt e outros).
- Certificado e chave do cliente só são usados juntos (TLS mútuo).

As configurações de MQTT valem assim que você clica em **Salvar**; não precisa reiniciar.

#### 1.5 Rádio LoRa

<p align="center">
  <img src="doc/images/web/web_05_radio.png" alt="Seção Rádio LoRa com o gráfico da sub-banda" width="100%"/>
</p>

- **Plano de frequência:** AU915 sub-banda 0 e sub-banda 1 (padrão no Brasil) ficam à vista; CN470, EU868 e US915 ficam em **Outros planos** (abre sozinho se um deles estiver salvo). Cada opção tem o link **JSON**, que abre o arquivo do plano em uma aba nova.
- **Gráfico da faixa AU915:** mostra os 64 canais de 125 kHz e os 8 de 500 kHz entre 915 e 928 MHz, com os 8 + 1 canais escutados em destaque. Só aparece nos planos AU915.
- **Rádio 1 / Rádio 2, frequência central (Hz):** ajuste avançado. Vazio usa o padrão do plano, que aparece em cinza. Precisa ter 9 dígitos e ficar dentro da faixa do plano (ex.: 915–928 MHz no AU915).

#### 1.6 GPS

O LR1302 HAT tem um receptor GNSS **Quectel L76K** (GPS, BeiDou e GLONASS) ligado aos pinos 8 e 10 do header. Com ele ligado, o gateway descobre a própria posição e a envia ao servidor LoRaWAN nas estatísticas. O ChirpStack então mostra o gateway no mapa, sem cadastro manual de coordenadas. Liga e desliga **ao clicar em Salvar, sem reiniciar**.

<p align="center">
  <img src="doc/images/chirpstack_gateway_mapa_gps.png" alt="ChirpStack v4: gateway no mapa com a posição enviada pelo GPS do ESP32 SX1302" width="100%"/>
  <br/><sub>ChirpStack v4: o marcador do gateway é posicionado pelas coordenadas que o GPS do HAT envia em <code>event/stats</code>.</sub>
</p>

##### Passo a passo

1. **Fiação:** pino 10 do HAT (TX do GPS) → **GPIO16** no ESP32 ou **GPIO18** no S3 (RX); pino 8 do HAT (RX do GPS) ← **GPIO17** (TX). GND comum e 5 V no HAT. UART1, 9600 baud, 8N1.
2. **Antena:** a antena GNSS do HAT precisa ver o céu (janela, varanda ou área externa). Dentro de casa, longe de janelas, ela pode até ver satélites, mas demora muito para fixar.
3. **Ligar:** na seção **GPS**, escolha **Ligado** e clique em **Salvar**. Também dá para usar o console: `gps on` ou `config --gps on`. A opção fica gravada na NVS (`gps_en`) e vale nos próximos boots.
4. **Esperar o fix:** a seção GPS mostra os satélites subindo. Com o céu aberto, o primeiro fix sai em menos de 1 minuto. A frio (primeira vez no local ou depois de dias desligado), pode levar alguns minutos.
5. **Conferir no ChirpStack:** **Tenant → Gateways → seu gateway → Dashboard**. O mapa se centraliza na posição recebida na próxima estatística (a cada 30 s).

##### A seção GPS da página

<p align="center">
  <img src="doc/images/web/web_20_gps.png" alt="Seção GPS com posição obtida" width="100%"/>
</p>

| Item | O que mostra |
|---|---|
| Receptor GPS | **Desligado** (padrão): a UART do GPS não é lida e nenhuma coordenada é enviada · **Ligado**: lê as frases NMEA a 9600 baud |
| Faixa de status | Diz o que está acontecendo e, quando nada chega, qual fio conferir (tabela abaixo) |
| Latitude / Longitude / Altitude | Posição do último `GGA` com fix, em graus decimais e metros acima do nível do mar |
| Satélites | Satélites usados no fix (campo *numSV* do `GGA`) |
| Frases NMEA | Frases com checksum válido · com erro · bytes recebidos desde que ligou |
| Último dado | Há quanto tempo chegou o último byte do GPS · há quanto tempo está ligado |
| Abrir no mapa | Link para o OpenStreetMap, quando há posição |

O painel **Status** também tem um card **GPS** (*desligado*, *aguardando MQTT*, *sem dados*, *sem posição* ou *N satélites*, com latitude e longitude quando há fix).

A faixa de status muda conforme o caso:

| Faixa | Significado | O que fazer |
|---|---|---|
| ⚪ *GPS desligado.* | Opção **Desligado** salva | — |
| 🟠 *GPS ligado, aguardando a conexão MQTT para iniciar…* | Com MQTT ligado, o GPS espera a conexão segura (TLS) com o broker. Também aparece enquanto o MQTT reconecta (veja [Ciclo de vida com o MQTT](#ciclo-de-vida-com-o-mqtt)) | Nada, se durar poucos segundos. Se não sair disso, o problema é o MQTT: veja a seção MQTT e a página Logs |
| 🟠 *Nenhum dado chegou do GPS em N s. Confira: pino 10 do HAT → GPIO16 (RX do ESP32), GND e 5 V.* | Nenhum byte na UART | Confira o fio do pino 10 (solto ou trocado com o 8), o GND comum e a alimentação do HAT. No S3, o RX é o **GPIO18** |
| 🟠 *Chegam bytes, mas as frases NMEA estão corrompidas…* | Bytes chegam, mas o checksum falha | Velocidade diferente de 9600 baud, fio longo ou ruído. Use fios curtos |
| 🟠 *Recebendo dados do GPS, ainda sem posição (N satélites).* | Fiação certa; falta o fix | Leve a antena para perto do céu e espere. Com 8 ou mais satélites por vários minutos e ainda sem posição, veja [Solução de problemas](#-solução-de-problemas) |
| 🟢 *Posição obtida com N satélites.* | Coordenadas válidas | Vão nas próximas estatísticas (a cada 30 s) |
| 🟠 *GPS ligado, mas o encaminhador não está rodando…* | O concentrador não iniciou ou o gateway está em Soft AP | O GPS começa quando o encaminhador subir |
| 🟠 *Este firmware foi compilado sem GPS (GPS_DISABLE).* | Build com `GPS_DISABLE` em `main/CMakeLists.txt` | Tire a definição e recompile |

<p align="center">
  <img src="doc/images/web/web_21_gps_sem_dados.png" alt="Seção GPS ligada sem receber dados" width="100%"/>
</p>

<p align="center">
  <img src="doc/images/web/web_22_gps_sem_fix.png" alt="Seção GPS recebendo dados, ainda sem posição" width="100%"/>
</p>

<p align="center">
  <img src="doc/images/web/web_23_gps_aguardando_mqtt.png" alt="Seção GPS ligada, aguardando a conexão MQTT para iniciar" width="100%"/>
</p>

##### Do GPS ao mapa do ChirpStack

```mermaid
flowchart LR
    A["Quectel L76K<br/>(LR1302 HAT)"] -- "NMEA 9600 baud<br/>pino 10 → GPIO16/18" --> B["UART1<br/>buffer 512 B"]
    B --> C["thread_gps<br/>lê e valida checksum"]
    C -- "$GNGGA" --> D["posição<br/>lat · lon · alt · satélites"]
    C -- "$GNRMC" --> E["hora UTC · status A/V"]
    D --> F["estatísticas<br/>a cada 30 s"]
    F -- "MQTT (ChirpStack v4)" --> G["event/stats<br/>location · source GPS"]
    F -- "UDP (Semtech)" --> H["stat<br/>lati · long · alti"]
    G --> I["ChirpStack<br/>atualiza a posição do gateway"]
    H --> I
```

- **Posição:** vem da frase `GGA` (`$GNGGA` no L76K, `$GPGGA` em módulos só GPS). Só vale com a qualidade do fix maior que 0 e latitude, longitude e altitude preenchidas.
- **Publicação:** a posição é atualizada a cada `GGA` e a cada `RMC` (1 por segundo) e enviada na próxima estatística. O intervalo vem de `stat_interval` no `global_conf.json` (padrão 30 s).
- **MQTT, formato ChirpStack v4:** vai em `<região>/gateway/<id>/event/stats`, no campo `location` (`source: GPS`), em Protobuf ou JSON, conforme a configuração. Em JSON:

  ```json
  {"gatewayId":"e45f01fffe10e12e","time":"2026-11-03T20:40:24Z",
   "location":{"latitude":-3.731862,"longitude":-40.991452,"altitude":803,"source":"GPS"},
   "rxPacketsReceived":42,"rxPacketsReceivedOk":40,"txPacketsReceived":3,"txPacketsEmitted":3,
   "metadata":{"gateway":"Gateway ESP32 with SX1302","version":"0.0.1"}}
  ```

- **UDP (Semtech):** vai no objeto `stat` do `PUSH_DATA`: `"lati":-3.73186,"long":-40.99145,"alti":803`. O ChirpStack Gateway Bridge converte para o mesmo `location`.
- **Sem posição:** a estatística sai sem `location`, e o ChirpStack mantém a última posição conhecida (ou a cadastrada à mão).

Para ver as estatísticas chegando ao broker (formato JSON):

```bash
mosquitto_sub -h mqtt.exemplo.com.br -p 8883 --cafile ca.crt -u <usuário> -P <senha> \
  -t 'au915_1/gateway/e45f01fffe10e12e/event/stats' -v
```

##### Ciclo de vida com o MQTT

No ESP32 sem PSRAM, o handshake TLS do MQTTS precisa de ~25–40 KB de RAM contígua e não cabe junto com o GPS. Antes desta solução, o log mostrava `Dynamic Impl: alloc(...) failed` e `mbedtls_ssl_handshake returned -0x2700` com *cert 0x8*. Isso parece erro de certificado, mas é falta de memória. Por isso o GPS só existe enquanto o MQTT está conectado:

| Situação | O que o GPS faz | Log |
|---|---|---|
| Boot, ou **Ligado** salvo, com MQTT ainda conectando | Espera; nada do GPS ocupa RAM | `GPS start deferred until the MQTT connection` |
| MQTT conectou | Inicia até 5 s depois: UART + `thread_gps` | `connected to the broker` → `GPS switched on: UART1 9600 baud…` |
| MQTT caiu, ou vai tentar conectar de novo | Para antes do handshake e devolve a RAM | `GPS stopped (MQTT connecting, …), RAM released` ou `thread_gps ended (MQTT disconnected…)` |
| MQTT reconectou | Volta sozinho e recomeça a busca de posição (*hot start*, segundos) | `GPS switched on…` |
| MQTT desligado (só UDP) | Inicia logo depois das tarefas do encaminhador | `GPS switched on…` |
| **Desligado** salvo | Para e libera tudo | `GPS switched off` → `GPS stopped (switched off), RAM released` |

O gancho é `mqtt_gw_set_before_connect_cb()`, chamado antes de criar o cliente MQTT e em cada `MQTT_EVENT_BEFORE_CONNECT`. Enquanto o MQTT reconecta, a posição não é enviada, mas também não haveria para onde enviar.

##### Memória

Medido em um ESP32-WROOM-32U com MQTTS (ChirpStack v4, Protobuf), página web e concentrador rodando:

| | Heap livre | Maior bloco |
|---|---|---|
| Antes de ligar o GPS (MQTT já conectado) | ~33 KB | ~30 KB |
| Depois de ligar o GPS | ~27 KB | ~27 KB |

- O GPS custa ~5,5 KB: a pilha de 3,5 KB do `thread_gps`, o buffer de 512 B da UART e o driver.
- Um minuto depois de ligar, o log mostra `thread_gps: N of 3584 bytes of stack never used`. Nas medições, sobraram 2,2 KB.
- O `thread_valid` original (outros 4 KB de pilha) virou uma etapa do `thread_gps`, executada uma vez por segundo.
- O `sdkconfig.defaults.esp32` libera mais RAM: 6 buffers RX estáticos do Wi-Fi em vez de 10, sem A-MPDU no RX.

##### Frases suportadas

| Frase | Usada para | Observação |
|---|---|---|
| `GGA` (`$GNGGA`, `$GPGGA`…) | Latitude, longitude, altitude, satélites, qualidade do fix | Qualidade `0` = sem fix: as coordenadas são descartadas |
| `RMC` (`$GNRMC`, `$GPRMC`…) | Hora e data UTC, status `A` (válido) / `V` | Aceita 13 campos (NMEA 2.3/4.0) e 14 (NMEA 4.10, com *navStatus*, padrão do L76K) |
| `GSV`, `GSA`, `VTG`, `ZDA`, `TXT` | — | Contadas como frases válidas e ignoradas |
| UBX `NAV-TIMEGPS` | Hora GPS (u-blox) | Só com PPS |

Com módulos de outro fabricante, basta saírem `GGA` e `RMC` em NMEA a 9600 baud. Os rótulos `$G?GGA` e `$G?RMC` aceitam qualquer constelação (`GP`, `GN`, `GL`, `GA`, `GB`).

##### PPS e referência de tempo

- O pulso PPS do GPS ainda não está ligado ao firmware. Sem ele, o SX1302 não tem a marca de tempo exata do segundo GPS.
- Por isso, a sincronização de tempo (`gps_process_sync`) só é compilada com `GPS_PPS_GPIO` definido. Hoje a referência de tempo fica **inválida** (`"tref":false` no `/status`, *Invalid time reference* nas estatísticas do log), em vez de uma referência errada.
- Isso não afeta a posição nem os uplinks e downlinks Classe A/C. Afeta só o que precisa de tempo GPS: Classe B (beacons), downlinks agendados por hora GPS e o `tmms` nos uplinks.
- Para usar o PPS no futuro, ligue o pino PPS do HAT a um GPIO livre (sugestões em [doc/hardware](doc/hardware/)). O suporte no firmware está no [roadmap](#-roadmap-esp32-s3).

##### Mensagens de log

| Mensagem | Significado |
|---|---|
| `INFO: [main] GPS switched on: starts after the forwarder threads and the MQTT connection` | Boot com GPS ligado e MQTT ativo |
| `INFO: [gps] GPS start deferred until the MQTT connection (the TLS handshake needs the RAM)` | Esperando o MQTT conectar |
| `INFO: [heap] before GPS start: free …` / `after GPS start: …` | Heap antes e depois de ligar o GPS |
| `INFO: [gps] GPS switched on: UART1 9600 baud, ESP32 RX GPIO16 <- HAT pin 10, …` | UART instalada e `thread_gps` rodando |
| `INFO: [gps] thread_gps: N of 3584 bytes of stack never used` | Folga de pilha, um minuto depois de ligar |
| `INFO: [gps] GPS stopped (…), RAM released` | GPS parado (desligado ou antes de um handshake TLS) |
| `INFO: [gps] thread_gps ended (MQTT disconnected, …)` | O MQTT caiu; o GPS cedeu a RAM sozinho |
| `WARNING: [gps] no data from the GPS for N s (check HAT pin 10 -> ESP32 GPIO16, GND and 5 V)` | Nenhum byte na UART (repete a cada 10 s) |
| `ERROR: [gps] UART driver install failed` / `failed to spawn thread_gps (out of RAM)` | Sem RAM para ligar; nova tentativa em 60 s |
| `# GPS coordinates: latitude …, longitude …, altitude … m` | Bloco `[GPS]` das estatísticas, a cada 30 s, com posição |
| `# no valid GPS coordinates available yet` | Bloco `[GPS]` sem posição |

##### Console

```
gps                 # status em uma linha (o mesmo objeto "gps" do /status)
gps on              # liga agora e grava na NVS (com MQTT: inicia após a conexão)
gps off             # desliga agora, libera a RAM e grava na NVS
config --gps on|off # o mesmo, junto com as outras opções do config
```

Ao desligar, o gateway descarta a posição, a referência de tempo e a correção do cristal, e para de enviar coordenadas.

#### 1.7 Inicialização e 1.8 Acesso

<p align="center">
  <img src="doc/images/web/web_06_boot.png" alt="Seção Inicialização" width="100%"/>
</p>

- **Modo Station:** conecta na rede Wi-Fi configurada (uso normal).
- **Modo Soft AP:** na próxima vez sobe a rede `lorawan-gateway-sx1302` (senha `lorawan101`) para configurar em `192.168.101.101`. O botão **BOOT** logo após o reset faz o mesmo sem mexer nesta opção.

<p align="center">
  <img src="doc/images/web/web_07_access.png" alt="Seção Acesso" width="100%"/>
</p>

- **Usuário**, **Nova senha** e **Confirmar nova senha** da própria página. Senha vazia mantém a atual. Ao salvar uma troca, o navegador pede o novo login.

#### 1.9 Manutenção: exportar, importar e padrão de fábrica

<p align="center">
  <img src="doc/images/web/web_19_maintenance.png" alt="Seção Manutenção" width="100%"/>
</p>

- **Exportar configuração:** baixa `gateway_<GatewayID>_<AAAAMMDD>.json` com a configuração **salva** no gateway (lida de `GET /config.json`), não com o que estiver digitado e ainda não salvo. Ficam de fora as senhas (Wi-Fi, MQTT e página) e os certificados TLS: esses nunca saem do gateway.
- **Importar…:** escolha um JSON exportado. Os valores vão para o formulário, e nada é gravado ainda. Revise, informe as senhas se for um gateway novo e clique em **Salvar**. Campos vazios no arquivo mantêm o valor atual, como no formulário.
- O arquivo traz `_type: "esp32_sx1302"`, a versão do firmware e a placa (`_target`). Um JSON exportado por um **nó** LoRaWAN é recusado. Um arquivo de outra origem só é carregado depois de confirmar.
- Serve para cópia de segurança e para configurar vários gateways iguais: exporte de um e importe nos outros. Se o original usa o EUI automático (`gw_id` vazio), cada gateway fica com o seu; se ele tem um EUI sobrescrito, apague o campo **Gateway EUI** (botão **Automático**) ou digite outro, porque o EUI precisa ser único.
- **Restaurar padrão de fábrica** (`POST /factory`): pede confirmação, apaga **toda** a configuração gravada na NVS (Wi-Fi, IP, servidor LoRaWAN, plano e rádios, NTP, MQTT **e os certificados TLS**, GPS e login da página) e reinicia. O gateway sobe como novo: em **modo Soft AP**, rede `lorawan-gateway-sx1302` (senha `lorawan101`), página em `http://192.168.101.101/`, login `admin` / `lorawan101` e o **Gateway EUI** automático (MAC do Wi-Fi + `FFFE`). Exporte a configuração antes, se quiser restaurar depois. Pelo console: `factory_reset --yes`.

Formato do arquivo (os valores são os mesmos gravados na NVS; `""` = não definido):

```json
{
  "_type": "esp32_sx1302",
  "_version": "0.0.1",
  "_target": "esp32",
  "_gw_eui": "E45F01FFFE10E12E",
  "_gw_eui_auto": "240AC4FFFE008D88",
  "wifi_ssid": "MinhaRede-4G",
  "ns_host": "",
  "ns_port": "",
  "gw_id": "E45F01FFFE10E12E",
  "wifi_mode": "station",
  "freq_region": "au915_sb1",
  "mqtt_en": "on",
  "mqtt_uri": "mqtts://mqtt.exemplo.com.br:8883",
  "mqtt_fmt": "chirpstack",
  "mqtt_enc": "protobuf",
  "web_user": "admin",
  "ip_mode": "static",
  "ip_addr": "192.168.18.101",
  "ip_gw": "192.168.18.1",
  "gps_en": "on"
}
```

(trecho; o arquivo real traz todos os campos da página.) `_gw_eui` é o EUI em uso e `_gw_eui_auto` o automático (MAC + `FFFE`); são só informativos e não são importados. `gw_id` vazio significa EUI automático: importado em outro gateway, ele passa a usar o EUI do próprio MAC.

#### 1.10 Salvar, reiniciar e validação

A barra do rodapé mostra *“Nenhuma alteração”* ou, com um ponto laranja, *“Alterações não salvas”*. Se você tentar sair da página com alterações pendentes, o navegador avisa.

- **Salvar** (`POST /resp`): valida os campos, grava na NVS e aplica na hora o **MQTT**, o **GPS** e o **login**. O resto (Wi-Fi, IP, servidor UDP, plano, rádios, NTP, modo de boot) vale depois de reiniciar. **Campos vazios mantêm o valor atual.**
- **Reiniciar gateway** (`POST /reboot`): pede confirmação e reinicia.

Antes de enviar, a página confere os campos e lista todos os problemas de uma vez no topo do formulário:

<p align="center">
  <img src="doc/images/web/web_08_validation.png" alt="Erros de validação listados no topo do formulário" width="100%"/>
</p>

| Campo | Regra |
|---|---|
| Rádio 1 / 2 | 9 dígitos em Hz, dentro da faixa do plano |
| Senha do Wi-Fi | Mínimo de 8 caracteres |
| IP fixo | IP, máscara e gateway obrigatórios, no formato `192.168.18.101`; máscara válida; gateway na mesma rede e diferente do IP |
| Host | Só IP ou domínio, sem `http://` e sem espaços |
| Porta | 1 a 65535 |
| Gateway EUI | Vazio (automático) ou exatamente 16 caracteres de `0–9` e `A–F` |
| Broker MQTT | Host obrigatório com MQTT ativado (só IP ou domínio, sem a porta); porta de 1 a 65535 ou vazia (padrão do protocolo). O formulário junta Protocolo, Host e Porta em `mqtt_uri` |
| Usuário da página | 1 a 31 caracteres, sem `:` |
| Nova senha da página | Mínimo de 6 caracteres, sem `:`, igual à confirmação |

O firmware também confere o login: se um usuário ou senha inválido chegar a ser gravado (vazio, longo demais, com `:` ou o usuário `_logout_`), ele volta a usar o padrão `admin` / `lorawan101`.

#### 1.11 Telas de confirmação

<p align="center">
  <img src="doc/images/web/web_10_saved.png" alt="Configuração salva" width="70%"/>
</p>

<p align="center">
  <img src="doc/images/web/web_11_reboot.png" alt="Reiniciando" width="70%"/>
</p>

<p align="center">
  <img src="doc/images/web/web_12_logout.png" alt="Você saiu" width="70%"/>
</p>

| Tela | Quando aparece | Botões |
|---|---|---|
| **Configuração salva** | Depois de *Salvar*. Se o login mudou, avisa que o navegador vai pedir o novo. Se o GPS não conseguiu ligar (UART, memória, firmware sem GPS ou encaminhador parado) ou vai esperar a conexão MQTT, mostra uma linha **GPS:** com o motivo | **Reiniciar agora** · **Voltar** |
| **Reiniciando…** | Depois de reiniciar. Volta sozinha para `/` em 15 s. Se o modo mudou (Soft AP ↔ Station), abra pelo novo endereço | — |
| **Você saiu** | Depois de *Sair* | **Entrar novamente**. Se o navegador entrar sem pedir senha, feche todas as janelas dele |

### 2. Logs (`/logs`)

Mostra a mesma saída do console serial, ao vivo, sem precisar de cabo USB.

> 🔐 **Segredos ficam fora deste log** (ele pode ser baixado e compartilhado): o header `Authorization` do navegador nunca é registrado (um login recusado aparece só como `web login refused ... from <IP>`), a senha do Soft AP e a senha de uma URI `mqtts://usuário:senha@host` aparecem mascaradas, e a sessão do console serial (o que é digitado, como `web_auth --pass ...`, e as respostas dos comandos) fica só na serial. Os valores completos continuam visíveis no console serial.

<p align="center">
  <img src="doc/images/web/web_13_logs.png" alt="Tela de logs ao vivo" width="100%"/>
</p>

- **Atualização:** a cada 1,5 s (`GET /logs_data?from=<posição>`), só com a aba visível. Quando há muito texto acumulado, busca de novo logo em seguida.
- **Memória:** o gateway guarda os últimos **16 KB** em RAM (`WEBLOG_SIZE` em `weblog.h`); a página guarda até **3000 linhas**. Se algo foi descartado entre duas leituras, aparece *“[… N bytes antigos descartados …]”*.
- **Cores:** 🔴 erros (`ERROR`, `E (`, `failed`) · 🟡 avisos (`WARN`, `W (`) · 🟢 pacotes recebidos (`rxpk`, `JSON up`).
- **Pausar / Continuar** para de buscar texto novo. **Limpar tela** limpa só a tela (o gateway continua guardando).
- **Filtrar:** mostra só as linhas que contêm o texto (sem diferenciar maiúsculas), por exemplo `rxpk`, `ERROR`, `mqtt`.
- **Rolar automático:** mantém a última linha visível.
- **Baixar do gateway** (`/logs_download`): arquivo `esp32_sx1302_<GatewayID>_<AAAAMMDD-HHMMSS>.log` com tudo o que está na RAM do gateway, sem os códigos de cor ANSI. Sem hora do NTP, o nome usa o uptime.
- **Baixar sessão:** gera no navegador `esp32_sx1302_sessao_<data-hora>.log` com tudo o que a página recebeu desde que foi aberta.

<p align="center">
  <img src="doc/images/web/web_14_logs_filter.png" alt="Logs filtrados por JSON up" width="100%"/>
</p>

> Mensagens anteriores ao início do log web (bootloader, `cpu_start`) só aparecem na porta serial.

### 3. Diagnósticos (`/diag`)

Testes de rede feitos **a partir do gateway**, no estilo da tela *Network → Diagnostics* do OpenWrt. Ajudam a separar problema de Wi-Fi, de DNS e de servidor.

<p align="center">
  <img src="doc/images/web/web_15_diag_ping.png" alt="Diagnósticos: ping" width="100%"/>
</p>

- **Destino:** já vem com **`chirpstack-v4.adailsilva.com.br`**, o destino padrão dos três testes (constante `DIAG_DEFAULT_HOST` em [`diag.h`](main/packet_forwarder/diag.h)). A lista de sugestões traz esse domínio, o servidor LoRaWAN, o host do broker MQTT, o roteador Wi-Fi, `8.8.8.8` e `openwrt.org`. Aceita IP ou nome de até 63 caracteres.
- **Ping:** 5 pacotes ICMP, 1 por segundo, com resumo de perda e min/média/máx. **Enter** no campo também roda o ping.
- **Traceroute:** até 15 saltos, 1 tentativa de 1 s por salto (`*` = sem resposta).
- **Nslookup:** resolve o nome pelo DNS que o gateway usa e mostra o servidor DNS e os endereços.
- O resultado chega linha a linha (`GET /diag_run?t=ping|trace|dns&h=<destino>`). **Parar** interrompe; o rodapé mostra o tempo gasto.
- Enquanto um teste roda, as outras páginas do gateway esperam ele terminar (ping ~5 s, traceroute até ~15 s), porque o servidor HTTP atende um pedido por vez.

<p align="center">
  <img src="doc/images/web/web_15_diag_trace.png" alt="Diagnósticos: traceroute" width="100%"/>
</p>

<p align="center">
  <img src="doc/images/web/web_15_diag_dns.png" alt="Diagnósticos: nslookup" width="100%"/>
</p>

### 4. Classes LoRaWAN (`/classes`)

Página só de leitura com a explicação das **Classes A, B e C**: quando o nó escuta, atraso do downlink, consumo, exemplos de uso, um comparativo e **o que este gateway suporta hoje**. O link **Classes** fica no topo da página de configuração, de Logs e de Diagnósticos. Explicação completa em [`doc/CLASSES_LORAWAN.md`](doc/CLASSES_LORAWAN.md).

<p align="center">
  <img src="doc/images/web/web_24_classes.png" alt="Página Classes LoRaWAN" width="100%"/>
</p>

### 5. JSON do plano de frequência

Os links **JSON** da seção Rádio LoRa abrem o `global_conf.json` embutido de cada plano (`/au915_sb0`, `/au915_sb1`, `/us915`, `/eu868`, `/cn470`), com os comentários que explicam o mapeamento dos canais. É o modelo que o gateway usa no boot, antes de aplicar o que foi salvo na página (frequências dos rádios, servidor, Gateway EUI).

<p align="center">
  <img src="doc/images/web/web_16_plan_json.png" alt="JSON do plano AU915 sub-banda 1" width="100%"/>
</p>

### 6. No celular

<p align="center">
  <img src="doc/images/web/web_17_mobile.png" alt="No celular: configuração (tema claro) e logs (tema escuro)" width="100%"/>
</p>

### Endereços HTTP

| Método | Caminho | Login | Resposta |
|---|---|:---:|---|
| GET | `/` (e `/w`) | ✅ | Página de configuração com os valores salvos |
| POST | `/resp` | ✅ | Recebe o formulário, grava na NVS, aplica MQTT, GPS e login, devolve *Configuração salva* |
| POST | `/reboot` | ✅ | Página *Reiniciando…* e reinício do ESP32 |
| POST | `/factory` | ✅ | Apaga a configuração salva e os certificados TLS (NVS `nvs` e `mqtt_tls`) e reinicia em modo Soft AP |
| GET | `/status` | ✅ | `{"gw":{...},"mqtt":{...},"gps":{...}}`: uptime, heap, RSSI, temperatura, contadores de RX/TX/UDP, estado do MQTT e do GPS |
| GET | `/config.json` | ✅ | Configuração salva em JSON (usada por *Exportar configuração*), sem senhas e sem certificados |
| POST | `/mqtt_cert?type=ca\|crt\|key` | ✅ | Corpo = PEM (vazio remove). `{"ok":true}` ou `{"ok":false,"error":"..."}`; acima de 8 KB, `413` |
| GET | `/logs` | ✅ | Página de logs |
| GET | `/logs_data?from=<n>` | ✅ | Texto novo desde a posição `n`; cabeçalhos `X-Log-Start` e `X-Log-Next` |
| GET | `/logs_download` | ✅ | Arquivo `.log` com todo o buffer em RAM |
| GET | `/diag` | ✅ | Página de diagnósticos |
| GET | `/diag_run?t=ping\|trace\|dns&h=<host>` | ✅ | Resultado em texto, enviado linha a linha; `400` se o teste ou o destino for inválido |
| GET | `/classes` | ✅ | Página *Classes LoRaWAN* (explicação das Classes A, B e C e o suporte neste gateway) |
| GET | `/au915_sb0`, `/au915_sb1`, `/us915`, `/eu868`, `/cn470` | ✅ | JSON do plano dentro de `<pre>` |
| GET | `/logout` | — | Só aceita o login falso `_logout_`; usado pelo link *Sair* |
| GET | `/saiu` | — | Página *Você saiu* |
| GET | `/favicon.svg`, `/favicon.ico` | — | Ícone do gateway |
| GET | `/info` | — | Identificação para o app Android (busca na rede). `gw_id` é o EUI em uso e `gw_id_auto` diz se é o automático: `{"type":"gateway","fw":...,"version":...,"target":...,"gw_id":...,"wifi_mode":...,"mdns":...,"host":...,"api":1}`. Nada secreto |

Objeto `gps` do `/status`:

```json
{"built":true,"cfg":true,"on":true,"run":true,"wait":false,"fix":true,"sat":9,"tref":false,
 "bytes":482113,"nmea":8124,"bad":2,"rx_age":0,"on_for":191040,"rx_pin":16,"tx_pin":17,
 "lat":-3.731862,"lon":-40.991452,"alt":803}
```

| Campo | Significado |
|---|---|
| `built` | `false` se o firmware foi compilado com `GPS_DISABLE` |
| `cfg` / `on` | Opção salva (`gps_en`) / GPS realmente ligado agora |
| `run` | Tarefa do GPS rodando (o encaminhador já subiu) |
| `wait` | `true` quando o GPS está ligado mas espera a conexão MQTT (TLS) para iniciar |
| `fix`, `lat`, `lon`, `alt`, `sat` | Posição (só com `fix`) e satélites do último `GGA` |
| `tref` | Referência de tempo GPS válida (precisa do PPS; hoje fica `false`) |
| `bytes`, `nmea`, `bad` | Bytes, frases válidas e frases com checksum errado desde que ligou |
| `rx_age`, `on_for` | Segundos desde o último byte (`-1` = nenhum) e desde que ligou |
| `rx_pin`, `tx_pin` | GPIOs da UART do GPS nesta placa |

Exemplo com `curl` na rede local:

```bash
curl -s -u admin:lorawan101 http://192.168.18.101/status | jq .gw.rx
curl -s -u admin:lorawan101 http://192.168.18.101/status | jq .gps
curl -s -u admin:lorawan101 -o gateway.json http://192.168.18.101/config.json
curl -s -u admin:lorawan101 -o gw.log http://192.168.18.101/logs_download
curl -s -u admin:lorawan101 "http://192.168.18.101/diag_run?t=ping&h=8.8.8.8"
```

---

## 📱 App Android

A pasta [`app_flutter/`](app_flutter/) tem um app **Flutter** com as mesmas funções desta página: login, Status, Configuração (com certificados TLS), Logs, Diagnósticos e Manutenção. Ele usa os **mesmos endereços HTTP** e o mesmo login (HTTP Basic), sem nuvem nem servidor extra. Por isso **não aumenta o uso de RAM** do gateway.

| Como o app acha o gateway | ESP32-WROOM-32U | ESP32-S3-WROOM-1U-N16R8 | ESP32-S3-WROOM-2-N32R16V |
|---|---|---|---|
| mDNS (`_http._tcp`, TXT `type=gateway`, `board=<BOARD>`) | — | ✅ | ✅ |
| Varredura da sub-rede (`GET /info` em cada IP) | ✅ | ✅ | ✅ |
| IP digitado / Soft AP `lorawan-gateway-sx1302` em `192.168.101.101` | ✅ | ✅ | ✅ |

Compilar: veja [`app_flutter/README.md`](app_flutter/README.md) (`./setup.sh` e depois `flutter build apk`).

> 🎓 **Classes LoRaWAN:** o ícone 🎓 na barra superior (lista de gateways e tela do gateway) abre a explicação das Classes A, B e C e o que este gateway suporta, igual à página `/classes`.

### 📲 Telas e uso do app

> As telas abaixo foram reproduzidas a partir do código do app (`app_flutter/lib/`: mesmos textos, cores do tema, componentes e ordem das seções), com **dados de exemplo**, em um celular de 412 × 892 dp. Os números não são de um equipamento em campo.

**Passo a passo rápido**

1. Instale o APK no celular (como gerar o `app-release.apk`: [`app_flutter/README.md`](app_flutter/README.md)).
2. Ligue o celular na **mesma rede Wi-Fi** do gateway. Se o gateway estiver em **Soft AP**, use o botão **Soft AP** (passo 2 abaixo).
3. Toque em **Procurar**, escolha o gateway e entre com **`admin` / `lorawan101`** (ou o login que você definiu).
4. Acompanhe a aba **Status**, ajuste o que precisar em **Config.**, toque em **Salvar** e, se a seção pedir, em **Reiniciar**.

#### 1. Lista de gateways

<p align="center">
  <img src="doc/images/app/gw_01_lista.png" alt="Lista de gateways salvos" width="32%"/>
  <img src="doc/images/app/gw_02_procurar.png" alt="Procurando gateways na rede" width="32%"/>
  <img src="doc/images/app/gw_03_adicionar_ip.png" alt="Adicionar gateway por IP" width="32%"/>
</p>

- A tela inicial mostra os gateways salvos no celular, com **IP · versão do firmware · placa** (`esp32`, `esp32s3_n16r8` ou `esp32s3_n32r16v`; firmware antigo mostra `esp32s3`). Toque em um para entrar.
- **Procurar** abre a busca: os dois **ESP32-S3** aparecem pelo **mDNS** (`esp32-sx1302-xxxxxx.local`); o **ESP32-WROOM-32U**, que não tem mDNS, é achado pela **varredura da sub-rede** (`GET /info` em cada IP). A barra mostra o progresso; toque no gateway encontrado para adicioná-lo e entrar.
- **Adicionar por IP** aceita IP, `nome.local` ou `IP:porta`. O IP aparece no display OLED, no console serial e no roteador.
- O menu **⋮** de cada gateway tem **Renomear**, **Esquecer senha** e **Remover da lista** (nada muda no gateway).

#### 2. Soft AP e login

<p align="center">
  <img src="doc/images/app/gw_04_softap.png" alt="Conectar ao Soft AP do gateway" width="32%"/>
  <img src="doc/images/app/gw_05_login.png" alt="Tela de login" width="32%"/>
</p>

- **Soft AP:** para um gateway novo, sem Wi-Fi configurado ou com o BOOT segurado logo após ligar. O app conecta na rede **`lorawan-gateway-sx1302`** (senha **`lorawan101`**) e fala com **`192.168.101.101`**. Essa rede não tem internet: o app prende o tráfego dele ao Wi-Fi enquanto estiver conectado. Se o Android não conectar sozinho, conecte pelas configurações de Wi-Fi e toque em **Continuar**.
- **Login:** mesmo usuário e senha da página web (padrão **`admin` / `lorawan101`**). **Lembrar a senha** guarda a senha criptografada no Android Keystore. Esqueceu? No console serial, `web_auth --reset`.

#### 3. Status

<p align="center">
  <img src="doc/images/app/gw_06_status.png" alt="Aba Status" width="32%"/>
  <img src="doc/images/app/gw_06_status_escuro.png" alt="Aba Status no tema escuro" width="32%"/>
</p>

- A barra do topo mostra o estado do **MQTT**, o **IP**, o **Gateway EUI** e o **plano** de frequência. O ícone ↦ no canto sai do gateway.
- Os cartões atualizam **a cada 5 s** enquanto a aba está aberta: tempo ligado, memória livre, sinal Wi-Fi, temperatura do concentrador, pacotes recebidos e encaminhados, downlinks, último ACK do servidor (UDP) e GPS. Puxe a tela para baixo para atualizar na hora.
- O cartão **MQTT** mostra o broker, o formato, quantas mensagens e downlinks passaram e quais certificados TLS estão instalados.
- O app segue o tema claro/escuro do Android.

#### 4. Configuração

<p align="center">
  <img src="doc/images/app/gw_07_config_rede.png" alt="Configuração: Rede Wi-Fi e Servidor LoRaWAN" width="32%"/>
  <img src="doc/images/app/gw_08_config_mqtt.png" alt="Configuração: MQTT" width="32%"/>
  <img src="doc/images/app/gw_09_config_radio.png" alt="Configuração: Rádio LoRa" width="32%"/>
</p>

<p align="center">
  <img src="doc/images/app/gw_10_config_gps.png" alt="Configuração: GPS" width="32%"/>
</p>

- Os botões do topo (**Rede Wi-Fi**, **Servidor LoRaWAN**, **MQTT**, **Rádio LoRa**, **GPS**, **Inicialização**, **Acesso**) levam direto à seção.
- A etiqueta de cada seção diz quando ela vale: **aplica ao salvar** (MQTT, GPS, Acesso) ou **vale após reiniciar** (Wi-Fi, servidor LoRaWAN, rádio, inicialização).
- **Rede Wi-Fi:** SSID, senha (vazia mantém a salva) e IP por DHCP ou fixo.
- **Servidor LoRaWAN:** host e porta UDP do Gateway Bridge e o **Gateway EUI**. Vazio usa o EUI automático (MAC do Wi-Fi + `FFFE`); **Automático** limpa um EUI digitado. Com o MQTT ativado, o UDP fica desligado e a seção avisa.
- **MQTT:** liga o envio, escolhe **Espelho Semtech** ou **ChirpStack v4** (JSON ou Protobuf), broker (Protocolo na lista — `mqtts://` = TLS —, Host e Porta em campos separados), usuário, senha e tópico base. Em **Certificados TLS**, cole o PEM ou escolha o arquivo e toque em **Enviar** (CA do broker, certificado e chave do cliente).
- **Rádio LoRa:** plano de frequência (**AU915 sub-banda 1** é o padrão no Brasil; **JSON** mostra o arquivo do plano), o desenho dos canais em uso e, em ajuste avançado, as frequências centrais dos dois rádios.
- **GPS:** liga e desliga o GPS do HAT sem reiniciar e mostra latitude, longitude, altitude e satélites.
- A barra de baixo avisa **Alterações não salvas**. **Salvar** grava no gateway; **Reiniciar** aplica o que só vale após reiniciar. O app valida os campos antes de enviar, com as mesmas regras da página.

#### 5. Logs e Diagnósticos

<p align="center">
  <img src="doc/images/app/gw_11_logs.png" alt="Aba Logs" width="32%"/>
  <img src="doc/images/app/gw_12_diag.png" alt="Aba Diagnósticos com ping" width="32%"/>
</p>

- **Logs:** tudo o que o gateway imprime no console, ao vivo. **Pausar**, **Limpar tela**, **Rolar automático**, **filtro** (ex.: `rxpk`, `ERROR`, `mqtt`) e **Baixar**: do gateway (os últimos 16 KB em RAM) ou a sessão (o que o app recebeu). Erros em vermelho, avisos em amarelo, pacotes recebidos em verde.
- **Diagnósticos:** **Ping**, **Traceroute** e **Nslookup** feitos **pelo próprio gateway**, para testar a rede dele até o servidor LoRaWAN, o broker MQTT ou a internet. O campo já vem com **`chirpstack-v4.adailsilva.com.br`** (padrão, igual à página) e os atalhos abaixo dele trazem esse domínio, o servidor LoRaWAN, o broker MQTT, `8.8.8.8` e `openwrt.org`. O resultado chega linha a linha; **Parar** interrompe.

#### 6. Manutenção

<p align="center">
  <img src="doc/images/app/gw_13_manutencao.png" alt="Aba Manutenção" width="32%"/>
</p>

- **Exportar configuração** salva um JSON no celular (sem senhas nem certificados). **Importar…** preenche a aba Configuração com um arquivo desses; revise e toque em **Salvar**.
- **Restaurar padrão de fábrica** apaga toda a configuração (inclusive os certificados) e o gateway volta em Soft AP.
- **Reiniciar gateway** e o cartão **Firmware** (versão, placa, endereço e Gateway EUI em uso).

### mDNS (só ESP32-S3)

A opção `GW_MDNS` (`idf.py menuconfig` → *ESP32_SX1302 gateway features*) vem **ligada** nos dois S3 (`esp32s3_n16r8` e `esp32s3_n32r16v`) e não existe no `esp32`. O componente `espressif/mdns` só é baixado para o S3 (regra em [`main/idf_component.yml`](main/idf_component.yml)). O nome é `esp32-sx1302-` seguido dos 3 últimos bytes do MAC, ou o que estiver em `GW_MDNS_HOSTNAME`. O boot mostra:

```
I (…) gw_mdns: mDNS: http://esp32-sx1302-a1b2c3.local/ (service _http._tcp, port 80)
```

## ⚙️ Configuração

### Páginas web

As telas, os campos e todos os endereços HTTP estão em [Servidor web embutido](#-servidor-web-embutido).

### Console serial (`ESP32_SX1302>`)

| Comando | Para que serve |
|---|---|
| `config` | Mostra e altera tudo o que a página altera: `--region`, `--radio0/1`, `--ntp`, `--mode station\|soft_ap`, `--ssid`, `--wifi-pass`, `--host`, `--port`, `--gwid <16 hex>\|auto`, `--ip-mode dhcp\|static`, `--ip`, `--mask`, `--gw`, `--dns1/2`, `--gps on\|off`, `--reboot` |
| `gps` | Sem argumento, mostra o status do GPS (posição, satélites, frases NMEA). `gps on` / `gps off` liga e desliga na hora e grava na NVS |
| `mqtt` | `--on`/`--off`, `--uri mqtts://host:8883`, `--user`, `--pass`, `--topic`, `--format chirpstack\|semtech`, `--encoding json\|protobuf` |
| `mqtt_cert` | Grava a CA, o certificado ou a chave do cliente (cole o PEM no terminal) |
| `web_auth` | Troca o usuário/senha da página (`--reset` volta para `admin`/`lorawan101`) |
| `pkt_fwd` | Inicia o forwarder pela linha de comando |
| `factory_reset` | Sem argumento, mostra o que será apagado. `factory_reset --yes` apaga toda a configuração salva (inclusive os certificados TLS) e reinicia em modo Soft AP |
| `reboot` | Reinicia o gateway |

**Exemplo com `pkt_fwd`:** Wi-Fi, servidor LoRaWAN (UDP) e Gateway EUI em uma linha só. Cada opção válida é gravada na NVS e o gateway reinicia para aplicar. Troque `<SSID>` e `<senha>` pelos da sua rede (espaço na senha vai escapado com `\`, por exemplo `-p minha\ senha`):

```text
ESP32_SX1302> pkt_fwd -u <SSID> -p <senha> --host chirpstack-v3.exemplo.com.br --port 1700 --gwid E45F01FFFE10E12E
ESP32_SX1302> pkt_fwd -u <SSID> -p <senha> --host chirpstack-v4.exemplo.com.br --port 1710 --gwid E45F01FFFE10E12E
```

A primeira linha aponta para um ChirpStack v3 (Gateway Bridge na porta UDP `1700`); a segunda, para um ChirpStack v4 que recebe o Semtech UDP na porta `1710`. Use a porta que o seu servidor expõe. `--gwid auto` usa o MAC do Wi-Fi + `FFFE`. `pkt_fwd -h` lista as opções.

### Tópicos MQTT

| Formato | Tópico base padrão | Tópicos |
|---|---|---|
| ChirpStack v4 | `<região>/gateway/<gateway eui>` em minúsculas, ex.: `au915_1/gateway/240ac4fffe008d88` | `event/up`, `event/stats`, `event/ack`, `state/conn` (LWT), `command/down` |
| Semtech JSON | `gateway/<GATEWAY EUI>` | `up`, `stats`, `state` |

Prefixo de região: `au915_0` (SB0), `au915_1` (SB1), `us915_0`, `eu868` e `cn470_10`. Esse prefixo precisa bater com o `topic_prefix` da região no ChirpStack.

---

## 🗺️ Roadmap (ESP32-S3)

O ESP32-WROOM-32U fica com o conjunto atual e passa a receber só correções. As funções novas entram nos dois **ESP32-S3** (**WROOM-1U-N16R8** e **WROOM-2-N32R16V**), ligadas por opções de Kconfig com valor padrão por alvo. Assim o código não fica cheio de `#if CONFIG_IDF_TARGET_ESP32S3`.

- [x] Pinagem própria e console no USB nativo
- [x] Flash 16 MB quad e PSRAM 8 MB octal do N16R8 (`boards/esp32s3_n16r8.defaults`)
- [x] Flash 32 MB e PSRAM 16 MB octais do N32R16V (`boards/esp32s3_n32r16v.defaults`)
- [x] Build por placa (`scripts/build.sh <BOARD>`, `-D BOARD=`), placa no boot, no `/info`, no `/config.json`, no mDNS e no app
- [x] Tabela de partições com app de 4 MB nos S3 (`partitions_esp32s3.csv`)
- [x] `main/Kconfig.projbuild` com as flags de funcionalidade (`GW_*`); a primeira é `GW_MDNS`
- [ ] Filas de RX/TX, buffer MQTT e sessão TLS na **PSRAM**
- [ ] Tabela de partições com OTA A/B + partição de dados (16 MB no N16R8, 32 MB no N32R16V)
- [ ] **OTA** por HTTPS, com o alvo no nome do binário
- [ ] **Buffer offline** em flash para uplinks quando o broker cair
- [x] **GPS do HAT** (NMEA) ligado/desligado pela página, com posição enviada ao ChirpStack (as três placas)
- [x] **mDNS** (`GW_MDNS`, em `main/Kconfig.projbuild`): `http://esp32-sx1302-xxxxxx.local/` e serviço `_http._tcp` para o app Android
- [ ] **PPS do GPS** (GPIO16 sugerido no S3) e timestamp GPS nos uplinks
- [ ] **LBT / spectral scan** com o SX1261
- [ ] LED RGB WS2812 de status
- [ ] Painel web completo (gráficos de RSSI/SNR e histórico de pacotes)
- [ ] Placa (`BOARD`) na versão reportada por MQTT e na página

---

## 📝 Cadastro no ChirpStack

Cadastre o gateway com o **Gateway EUI** mostrado na página (cabeçalho *Gateway*). No ChirpStack v4: *Tenant → Gateways → Add gateway*, *Gateway ID* = Gateway EUI, *Stats interval* = `30` s. No ChirpStack v3, use um *Gateway-profile* com os canais da sub-banda (`0–7, 64` ou `8–15, 65`). Detalhes em [`doc/CHIRPSTACK_DEVICE_PROFILES.md`](doc/CHIRPSTACK_DEVICE_PROFILES.md#cadastro-do-gateway).

### Perfis de dispositivo de exemplo (32)

**32 perfis = 2 configurações de região** (`au915_0` / `au915_1`) **× 2 revisões** (A / B) **× 2 ativações** (ABP / OTAA) **× 4 combinações de classe** (A / A+B / A+B+C / A+C). Campos de cada aba, cadastro passo a passo e equivalência no ChirpStack v3: [`doc/CHIRPSTACK_DEVICE_PROFILES.md`](doc/CHIRPSTACK_DEVICE_PROFILES.md).

O gateway **não usa** perfil de dispositivo: o perfil é escolhido para cada **nó** que fala com ele. O que o gateway define é a coluna **Region configuration**:

| Plano do gateway | Perfis |
|---|---|
| AU915 sub-banda 1 (padrão, canais 8–15 + 65) | `AU915_1` (#17 a #32) |
| AU915 sub-banda 0 (canais 0–7 + 64) | `AU915_0` (#1 a #16) |

Os perfis com **Class-B** (A+B e A+B+C) precisam de *beacons*, que este firmware ainda não transmite (falta o PPS do GPS; veja [`CLASSES_LORAWAN.md`](doc/CLASSES_LORAWAN.md#neste-gateway)). Classes A e C funcionam sem GPS.

A coluna **Region configuration** precisa ser a mesma sub-banda do gateway e do nó: `au915_0` = sub-banda 0 (canais 0–7 + 64) e `au915_1` = sub-banda 1 (canais 8–15 + 65).

| # | Nome do perfil (*Name*) | Region configuration | Revisão | Supports OTAA | Class-B | Class-C |
|---:|---|:---:|:---:|:---:|:---:|:---:|
| 1 | `Device Profile - AU915_0 - 1.0.3 - A - ABP - Class A` | `au915_0` | A | — | — | — |
| 2 | `Device Profile - AU915_0 - 1.0.3 - A - ABP - Class A+B` | `au915_0` | A | — | ✅ | — |
| 3 | `Device Profile - AU915_0 - 1.0.3 - A - ABP - Class A+B+C` | `au915_0` | A | — | ✅ | ✅ |
| 4 | `Device Profile - AU915_0 - 1.0.3 - A - ABP - Class A+C` | `au915_0` | A | — | — | ✅ |
| 5 | `Device Profile - AU915_0 - 1.0.3 - A - OTAA - Class A` | `au915_0` | A | ✅ | — | — |
| 6 | `Device Profile - AU915_0 - 1.0.3 - A - OTAA - Class A+B` | `au915_0` | A | ✅ | ✅ | — |
| 7 | `Device Profile - AU915_0 - 1.0.3 - A - OTAA - Class A+B+C` | `au915_0` | A | ✅ | ✅ | ✅ |
| 8 | `Device Profile - AU915_0 - 1.0.3 - A - OTAA - Class A+C` | `au915_0` | A | ✅ | — | ✅ |
| 9 | `Device Profile - AU915_0 - 1.0.3 - B - ABP - Class A` | `au915_0` | B | — | — | — |
| 10 | `Device Profile - AU915_0 - 1.0.3 - B - ABP - Class A+B` | `au915_0` | B | — | ✅ | — |
| 11 | `Device Profile - AU915_0 - 1.0.3 - B - ABP - Class A+B+C` | `au915_0` | B | — | ✅ | ✅ |
| 12 | `Device Profile - AU915_0 - 1.0.3 - B - ABP - Class A+C` | `au915_0` | B | — | — | ✅ |
| 13 | `Device Profile - AU915_0 - 1.0.3 - B - OTAA - Class A` | `au915_0` | B | ✅ | — | — |
| 14 | `Device Profile - AU915_0 - 1.0.3 - B - OTAA - Class A+B` | `au915_0` | B | ✅ | ✅ | — |
| 15 | `Device Profile - AU915_0 - 1.0.3 - B - OTAA - Class A+B+C` | `au915_0` | B | ✅ | ✅ | ✅ |
| 16 | `Device Profile - AU915_0 - 1.0.3 - B - OTAA - Class A+C` | `au915_0` | B | ✅ | — | ✅ |
| 17 | `Device Profile - AU915_1 - 1.0.3 - A - ABP - Class A` | `au915_1` | A | — | — | — |
| 18 | `Device Profile - AU915_1 - 1.0.3 - A - ABP - Class A+B` | `au915_1` | A | — | ✅ | — |
| 19 | `Device Profile - AU915_1 - 1.0.3 - A - ABP - Class A+B+C` | `au915_1` | A | — | ✅ | ✅ |
| 20 | `Device Profile - AU915_1 - 1.0.3 - A - ABP - Class A+C` | `au915_1` | A | — | — | ✅ |
| 21 | `Device Profile - AU915_1 - 1.0.3 - A - OTAA - Class A` | `au915_1` | A | ✅ | — | — |
| 22 | `Device Profile - AU915_1 - 1.0.3 - A - OTAA - Class A+B` | `au915_1` | A | ✅ | ✅ | — |
| 23 | `Device Profile - AU915_1 - 1.0.3 - A - OTAA - Class A+B+C` | `au915_1` | A | ✅ | ✅ | ✅ |
| 24 | `Device Profile - AU915_1 - 1.0.3 - A - OTAA - Class A+C` | `au915_1` | A | ✅ | — | ✅ |
| 25 | `Device Profile - AU915_1 - 1.0.3 - B - ABP - Class A` | `au915_1` | B | — | — | — |
| 26 | `Device Profile - AU915_1 - 1.0.3 - B - ABP - Class A+B` | `au915_1` | B | — | ✅ | — |
| 27 | `Device Profile - AU915_1 - 1.0.3 - B - ABP - Class A+B+C` | `au915_1` | B | — | ✅ | ✅ |
| 28 | `Device Profile - AU915_1 - 1.0.3 - B - ABP - Class A+C` | `au915_1` | B | — | — | ✅ |
| 29 | `Device Profile - AU915_1 - 1.0.3 - B - OTAA - Class A` | `au915_1` | B | ✅ | — | — |
| 30 | `Device Profile - AU915_1 - 1.0.3 - B - OTAA - Class A+B` | `au915_1` | B | ✅ | ✅ | — |
| 31 | `Device Profile - AU915_1 - 1.0.3 - B - OTAA - Class A+B+C` | `au915_1` | B | ✅ | ✅ | ✅ |
| 32 | `Device Profile - AU915_1 - 1.0.3 - B - OTAA - Class A+C` | `au915_1` | B | ✅ | — | ✅ |

Legenda: ✅ marcado · — desmarcado. Todos os 32 usam **Region** `AU915` e **MAC version** `LoRaWAN 1.0.3`.

---

## 📁 Estrutura do repositório

```
Gateway_ESP32_SX1302_LR1302_HAT_Elecrow/
├── .github/workflows/build.yml   # CI: compila as 3 placas, publica Release nas tags v*
├── CMakeLists.txt                # projeto ESP-IDF + escolha da placa (BOARD -> IDF_TARGET e defaults)
├── sdkconfig.defaults            # opções comuns às três placas
├── sdkconfig.defaults.esp32      # ESP32: menos buffers RX do Wi-Fi (RAM para o TLS)
├── sdkconfig.defaults.esp32s3    # os dois S3: console USB, partições com app de 4 MB
├── partitions_esp32s3.csv        # tabela de partições dos S3 (nvs 0x9000, app 4 MB em 0x10000)
├── boards/                       # um arquivo por placa: flash, PSRAM e CONFIG_GW_BOARD_*
│   ├── esp32.defaults            # ESP32-WROOM-32U: 4 MB DIO
│   ├── esp32s3_n16r8.defaults    # ESP32-S3-WROOM-1U-N16R8: 16 MB QIO + PSRAM 8 MB octal
│   └── esp32s3_n32r16v.defaults  # ESP32-S3-WROOM-2-N32R16V: 32 MB octal + PSRAM 16 MB octal
├── scripts/
│   ├── build.sh                  # build/flash/monitor/erase por placa (build-<BOARD>/, sdkconfig.<BOARD>)
│   ├── create_github_repo.sh     # cria o repositório no GitHub e publica a v0.0.1
│   ├── gen_headers.sh            # gera webpage.h e global_json.h
│   └── dump_html.py, json_to_hex_array.py, upgrader.py, udp_*.py
├── main/
│   ├── CMakeLists.txt            # fontes + PINAGEM POR PLACA (if IDF_TARGET ...)
│   ├── Kconfig.projbuild         # placa (GW_BOARD_*) e funções por placa (GW_*): GW_MDNS só nos S3
│   ├── idf_component.yml         # esp-mqtt (IDF ≥ 6) e mdns (só nos S3) pelo Component Registry
│   ├── libloragw/                # porte do SX1302_HAL v2.1.0
│   ├── libloragw-test/           # ferramentas de teste (CONFIG_LIBLORAGW_TEST)
│   ├── libtools/                 # parson (JSON), base64, tinymt32
│   └── packet_forwarder/         # forwarder, MQTT, web, log, diagnóstico
│       └── global_conf.json/     # planos AU915 SB0/SB1, US915, EU868, CN470
├── doc/
│   ├── images/                   # diagramas SVG deste README (+ PNG 3720 px dos wiring)
│   │   ├── web/                  # capturas das telas do servidor web
│   │   └── app/                  # telas do app Android
│   ├── hardware/                 # README (comparação das 3 placas) + guia de ligação de cada placa
│   ├── CHIRPSTACK_DEVICE_PROFILES.md  # cadastro no ChirpStack: gateway e os 32 perfis de dispositivo
│   ├── CHANGELOG.md, user_guide.md, notes_tips.md, todo_issue_list.md
├── app_flutter/                  # app Android (Flutter) com as funções da página web
├── logs/                         # logs da gravação e do monitor (fora do git)
├── configurations_backup/        # exportações da página (fora do git)
└── hardware_design/              # placa adaptadora ESP32 ↔ LR1302 HAT (3 placas) e caixa paramétrica
```

---

## 🩺 Solução de problemas

| Sintoma | O que verificar |
|---|---|
| `failed to start the concentrator` | O firmware imprime um diagnóstico de fiação. Confira MOSI/MISO/SCLK/CS e RESET, os 5 V e o GND. Use fios SPI curtos. O CS do SX1261 (pino 31) **não** pode ficar solto. |
| Leitura do SX1302 retorna `0x00` ou `0xFF` | MISO desconectado ou CS errado. Confira os pinos 21 e 24 do HAT. |
| Reset ou *brownout* ao transmitir | Alimentação. Use a fonte de 5 V / 2 A. |
| Depois de horas funcionando, o gateway para de receber (`RF packets received by concentrator: 0`), mas Wi-Fi, MQTT, GPS e página seguem normais; reiniciando, volta | O SX1302 foi resetado ou perdeu o clock de 32 MHz e o `lgw_receive()` passou a devolver 0 pacotes. Assinatura no log: `# SX1302 counter (PPS)` parado no mesmo valor e `# Invalid time reference (age: N sec)` crescendo desde o último pacote. O **watchdog do SX1302** resolve sozinho: `WARNING: [watchdog] SX1302 check failed` → `INFO: [watchdog] SX1302 restarted` em ~2 s, e a linha `# SX1302 watchdog` das estatísticas conta os reinícios. Se houver mais de 3 por hora, o log avisa (`ERROR: [watchdog] ... hardware problem to correct`): o gateway continua funcionando, mas a causa é de hardware: fonte de 5 V / 2 A com GND comum, capacitor de 470–1000 µF nos 5 V junto ao HAT, fios curtos (principalmente o RESET, pino 11 do HAT) e antena longe dos fios. O ESP32 só reinicia se o SX1302 não voltar a iniciar (3 tentativas). |
| `INFO: [watchdog] no packet received for N s: preventive SX1302 restart` | Normal numa rede sem tráfego: depois de 30 min sem nenhum pacote (nem com CRC errado) o SX1302 é reiniciado por precaução; o prazo dobra a cada vez (até 6 h) e volta a 30 min no próximo pacote. Nunca acontece com downlink na fila. |
| `WARNING: no STTS751 temperature sensor answered (...)` | O módulo LR1302 **tem** um STTS751, ligado aos pinos 3 (SDA) e 5 (SCL) do HAT, mas ele não respondeu em nenhum dos 8 endereços possíveis (0x38–0x3B, 0x48–0x4B). Logo abaixo, o boot faz uma varredura do I2C:<br/>• `no device answers on the I2C bus` → confira os fios SDA (pino 3 → GPIO21; GPIO4 no S3) e SCL (pino 5 → GPIO22; GPIO5 no S3) e ligue **4,7 kΩ do SDA e do SCL ao 3,3 V**. O HAT não tem pull-ups (no Raspberry Pi eles ficam na placa do Pi), e os internos do ESP32 (~45 kΩ) podem não bastar.<br/>• `bus timeout … stuck low` → SDA ou SCL em curto ou presos em nível baixo.<br/>• `devices on the bus: 0x..` → o barramento funciona; mande a lista para identificar o chip.<br/>Enquanto isso, o gateway funciona e usa **25 °C** na compensação de RSSI (+1,0 dB), e as estatísticas saem sem `temp`. |
| ESP32-S3 não inicia depois da gravação (reinicia sem parar ou erro de flash/PSRAM) | Firmware da placa errada. O N16R8 precisa de `esp32s3_n16r8` (flash quad) e o N32R16V de `esp32s3_n32r16v` (flash octal). Confira a marcação do módulo, apague `sdkconfig.<BOARD>` e `build-<BOARD>/` e compile de novo. |
| `BOARD=... but sdkconfig has board ...` no build | O `sdkconfig.<BOARD>` é de outra placa. Apague esse arquivo e a pasta `build-<BOARD>/` e rode `scripts/build.sh <BOARD>` de novo. |
| `BOARD='...' needs IDF_TARGET=...` | `-D BOARD` e `-D IDF_TARGET` não combinam. Use `scripts/build.sh <BOARD>`, que passa os dois. |
| Nada aparece no monitor do S3 | Use a porta **USB nativa** (`/dev/ttyACM0`), não a UART. |
| Seção GPS: *Nenhum dado chegou do GPS* | Nada chega na UART. Confira o pino 10 do HAT → GPIO16 (ESP32) ou GPIO18 (S3), o GND comum e os 5 V. No log aparece `WARNING: [gps] no data from the GPS for N s`. |
| Seção GPS: recebe frases mas fica *sem posição* | Fiação certa. Leve a antena do GPS para perto de uma janela ou para fora; o primeiro fix pode levar alguns minutos. |
| MQTTS conecta mas nada é enviado (ESP32) | Pouca RAM. Confira as linhas `INFO: [heap]` do log. O `sdkconfig.defaults` já liga os buffers TLS dinâmicos. |
| A seção GPS mostra posição, mas o gateway não aparece no mapa do ChirpStack | A posição vai nas estatísticas, a cada 30 s: espere a próxima. Confira se o `event/stats` chega ao broker (`mosquitto_sub`, veja [1.6 GPS](#16-gps)) e se o **Gateway EUI** da página é o mesmo cadastrado no ChirpStack. Recarregue o Dashboard do gateway. |
| MQTTS não conecta com o GPS ligado (ESP32): `alloc(...) failed`, `-0x2700`, `cert 0x8` | Falta de RAM no handshake TLS, não certificado errado. O firmware já para o GPS antes de cada conexão; se ainda acontecer, confira se o `sdkconfig.defaults.esp32` foi aplicado (apague `sdkconfig.esp32` e `build-esp32/` e compile de novo) e as linhas `INFO: [heap]` antes do `connecting to`. |

---

## 📜 Créditos e licença

- Porte original do **ESP32_SX1302** (ex-ESXP1302) para ESP32: Dennis Deng (Semtech).
- [SX1302_HAL](https://github.com/Lora-net/sx1302_hal) © Semtech.
- Adaptações para AU915, MQTT/ChirpStack v4, página web pt-BR, ESP32-WROOM-32U, ESP32-S3-WROOM-1U-N16R8 e ESP32-S3-WROOM-2-N32R16V com o LR1302 HAT: **Adail dos Santos Silva** ([k8s.adailsilva.com.br](https://k8s.adailsilva.com.br/)).

Distribuído sob a licença **BSD de 3 cláusulas**. Veja [LICENSE.TXT](LICENSE.TXT).
