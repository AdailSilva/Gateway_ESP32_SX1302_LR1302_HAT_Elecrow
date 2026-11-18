# Placas suportadas pelo gateway

O mesmo código-fonte gera **um firmware para cada módulo ESP32**. A placa é escolhida no build pelo nome `BOARD`:

| `BOARD` | Módulo (DevKit) | `IDF_TARGET` | Flash | PSRAM | Antena Wi-Fi | Console | Guia de ligação |
|---|---|---|---|---|---|---|---|
| `esp32` | **ESP32-WROOM-32U** (DevKitC 38 pinos) | `esp32` | 4 MB quad, 3,3 V | — | externa (u.FL) | UART0 → `/dev/ttyUSB0` | [ESP32-WROOM-32U_DevKit.md](ESP32-WROOM-32U_DevKit.md) |
| `esp32s3_n16r8` | **ESP32-S3-WROOM-1U-N16R8** (DevKitC-1) | `esp32s3` | 16 MB **quad**, 3,3 V | 8 MB **octal** | externa (u.FL) | USB nativo → `/dev/ttyACM0` | [ESP32-S3-WROOM-1U_N16R8_DevKit.md](ESP32-S3-WROOM-1U_N16R8_DevKit.md) |
| `esp32s3_n32r16v` | **ESP32-S3-WROOM-2-N32R16V** (DevKitC-1) | `esp32s3` | 32 MB **octal**, **1,8 V** | 16 MB **octal** | de PCB | USB nativo → `/dev/ttyACM0` | [ESP32-S3-WROOM-2_N32R16V_DevKit.md](ESP32-S3-WROOM-2_N32R16V_DevKit.md) |

> **Os dois S3 não são intercambiáveis.** O N16R8 tem flash **quad** de 3,3 V, e o N32R16V tem flash **octal** de 1,8 V. O firmware de um não inicia no outro: o bootloader configura a flash do jeito errado, e a placa fica reiniciando ou parada em erro de flash/PSRAM. Confira o código impresso na blindagem do módulo (por exemplo `N16R8` ou `MCN32R16V`) antes de gravar.
>
> `esptool.py --chip esp32s3 -p /dev/ttyACM0 flash_id` também ajuda: o N16R8 responde com `Detected flash size: 16MB`, e o N32R16V com `32MB`.

---

## 1. Pinagem com o Elecrow LR1302 HAT (SPI)

Os dois S3 usam a **mesma pinagem**, porque o layout da DevKitC-1 é igual e nenhum pino usado depende da flash ou da PSRAM. O ESP32 clássico usa outra.

| Sinal | HAT (pino) | `esp32` | `esp32s3_n16r8` | `esp32s3_n32r16v` |
|---|:---:|:---:|:---:|:---:|
| SPI MOSI | 19 | GPIO23 | GPIO11 | GPIO11 |
| SPI MISO | 21 | GPIO19 | GPIO13 | GPIO13 |
| SPI SCLK | 23 | GPIO18 | GPIO12 | GPIO12 |
| CS do SX1302 | 24 | GPIO5 | GPIO10 | GPIO10 |
| RESET do SX1302 (ativo alto) | 11 | GPIO4 | GPIO6 | GPIO6 |
| CS do SX1261 (fica em nível alto) | 31 | GPIO25 | GPIO7 | GPIO7 |
| I2C SDA | 3 | GPIO21 | GPIO4 | GPIO4 |
| I2C SCL | 5 | GPIO22 | GPIO5 | GPIO5 |
| GPS RX do HAT *(opcional)* | 8 | GPIO17 | GPIO17 | GPIO17 |
| GPS TX do HAT *(opcional)* | 10 | GPIO16 | GPIO18 | GPIO18 |
| 5 V | 2 / 4 | 5V/VIN | 5V | 5V |
| GND | 6 | GND | GND | GND |
| Botão do Soft AP | — | GPIO0 (BOOT) | GPIO0 (BOOT) | GPIO0 (BOOT) |
| LED de status | — | GPIO2 | — (LED RGB) | — (LED RGB) |
| Controlador SPI | — | `SPI3_HOST` (VSPI) | `SPI2_HOST` (FSPI, IOMUX) | `SPI2_HOST` (FSPI, IOMUX) |

Onde fica no código: os blocos `if(IDF_TARGET STREQUAL ...)` de [`main/CMakeLists.txt`](../../main/CMakeLists.txt). Cada valor pode ser trocado com `-D`, por exemplo `idf.py ... -D PIN_NUM_CS=...`.

### GPIOs que não podem ser usados

| | `esp32` (WROOM-32U) | `esp32s3_n16r8` (WROOM-1U) | `esp32s3_n32r16v` (WROOM-2) |
|---|---|---|---|
| Memória flash | 6–11 | 26–32 | 26–32 |
| PSRAM | — | 35–37 (octal; 33/34 não saem no módulo) | 33–37 (flash/PSRAM octal) |
| Domínio de 1,8 V | — | — (47/48 são de 3,3 V) | **47, 48** |
| Console | 1, 3 (UART0) | 19, 20 (USB) · 43, 44 (UART0) | 19, 20 (USB) · 43, 44 (UART0) |
| Strapping | 0, 2, 5, 12, 15 (12 é o crítico) | 0, 3, 45, 46 | 0, 3, 45, 46 |
| Só entrada | 34–39 | — | — |
| **Livres** para expansão | 13, 14, 26, 27, 32, 33 | 1, 2, 8, 9, 14, 15, 16, 21, 38–42, 47, 48 | 1, 2, 8, 9, 14, 15, 16, 21, 38–42 |

---

## 2. Arquivos de configuração por placa

O `CMakeLists.txt` da raiz traduz `BOARD` em `IDF_TARGET` e na lista de `SDKCONFIG_DEFAULTS`. Os arquivos são carregados nesta ordem (o último vence):

| Ordem | Arquivo | `esp32` | `esp32s3_n16r8` | `esp32s3_n32r16v` | Conteúdo |
|:---:|---|:---:|:---:|:---:|---|
| 1 | [`sdkconfig.defaults`](../../sdkconfig.defaults) | ✅ | ✅ | ✅ | Comum: HTTP, mbedTLS dinâmico, tabela de partições do ESP32 |
| 2 | [`sdkconfig.defaults.esp32`](../../sdkconfig.defaults.esp32) | ✅ | — | — | Menos buffers RX do Wi-Fi (RAM para o TLS) |
| 2 | [`sdkconfig.defaults.esp32s3`](../../sdkconfig.defaults.esp32s3) | — | ✅ | ✅ | Console no USB nativo, tabela de partições com app de 4 MB |
| 3 | [`boards/esp32.defaults`](../../boards/esp32.defaults) | ✅ | — | — | Flash 4 MB DIO 40 MHz, `CONFIG_GW_BOARD_ESP32_WROOM_32U` |
| 3 | [`boards/esp32s3_n16r8.defaults`](../../boards/esp32s3_n16r8.defaults) | — | ✅ | — | Flash 16 MB **QIO** 80 MHz, PSRAM **octal**, `CONFIG_GW_BOARD_ESP32S3_WROOM_1U_N16R8` |
| 3 | [`boards/esp32s3_n32r16v.defaults`](../../boards/esp32s3_n32r16v.defaults) | — | — | ✅ | Flash 32 MB **octal (OPI)** 80 MHz, PSRAM **octal**, `CONFIG_GW_BOARD_ESP32S3_WROOM_2_N32R16V` |
| — | [`partitions_esp32s3.csv`](../../partitions_esp32s3.csv) | — | ✅ | ✅ | `nvs` 0x9000, `phy_init` 0xF000, `factory` 0x10000 com **4 MB** |
| — | [`main/Kconfig.projbuild`](../../main/Kconfig.projbuild) | ✅ | ✅ | ✅ | Escolha `GW_BOARD`, `GW_BOARD_ID`, `GW_BOARD_NAME`, `GW_MDNS` |
| — | [`main/CMakeLists.txt`](../../main/CMakeLists.txt) | ✅ | ✅ | ✅ | Pinagem por alvo e conferência `BOARD` × sdkconfig |

### Opções que mudam entre as placas (resultado no `sdkconfig.<board>`)

| Opção | `esp32` | `esp32s3_n16r8` | `esp32s3_n32r16v` |
|---|---|---|---|
| `CONFIG_IDF_TARGET` | `esp32` | `esp32s3` | `esp32s3` |
| `CONFIG_GW_BOARD_*` | `ESP32_WROOM_32U` | `ESP32S3_WROOM_1U_N16R8` | `ESP32S3_WROOM_2_N32R16V` |
| `CONFIG_ESPTOOLPY_FLASHMODE_*` | `DIO` | `QIO` | — (`OCT_FLASH=y` → OPI) |
| `CONFIG_ESPTOOLPY_OCT_FLASH` | — | — | `y` |
| `CONFIG_ESPTOOLPY_FLASHFREQ_*` | `40M` | `80M` | `80M` |
| `CONFIG_ESPTOOLPY_FLASHSIZE_*` | `4MB` | `16MB` | `32MB` |
| `CONFIG_SPIRAM` | — | `y` | `y` |
| `CONFIG_SPIRAM_MODE_OCT` | — | `y` | `y` |
| `CONFIG_SPIRAM_SPEED_80M` / `USE_MALLOC` | — | `y` / `y` | `y` / `y` |
| `CONFIG_ESP_CONSOLE_*` | `UART_DEFAULT` | `USB_SERIAL_JTAG` | `USB_SERIAL_JTAG` |
| Tabela de partições | `partitions_singleapp_large.csv` (app 1,5 MB) | `partitions_esp32s3.csv` (app 4 MB) | `partitions_esp32s3.csv` (app 4 MB) |
| `CONFIG_ESP_WIFI_STATIC_RX_BUFFER_NUM` | `6` | padrão (10) | padrão (10) |
| `CONFIG_GW_MDNS` | não existe | `y` | `y` |
| Componente `espressif/mdns` | não baixado | baixado | baixado |

> O `esptool` grava `--flash_mode dio` no cabeçalho do N16R8 mesmo com QIO: no S3 o bootloader liga o modo QIO sozinho. No N32R16V aparece `dout`, que é o esperado para flash octal.

---

## 3. Compilar, gravar e monitorar

Com o ESP-IDF ativado (`. $IDF_PATH/export.sh`):

```bash
./scripts/build.sh esp32                              # ESP32-WROOM-32U
./scripts/build.sh esp32s3_n16r8                      # ESP32-S3-WROOM-1U-N16R8
./scripts/build.sh esp32s3_n32r16v                    # ESP32-S3-WROOM-2-N32R16V
./scripts/build.sh all                                # as três, em sequência

./scripts/build.sh esp32           flash /dev/ttyUSB0 # grava e abre o monitor
./scripts/build.sh esp32s3_n16r8   flash /dev/ttyACM0 # S3: porta "USB" (nativa), não a "UART"
./scripts/build.sh esp32s3_n32r16v flash /dev/ttyACM0

./scripts/build.sh esp32s3_n16r8 monitor /dev/ttyACM0 # só o monitor
./scripts/build.sh esp32s3_n16r8 erase   /dev/ttyACM0 # apaga a flash inteira (volta ao padrão de fábrica)
```

Os comandos completos de cada placa (liberar a porta com `fuser`, ativar o ESP-IDF e salvar a saída em `logs/`), nas variantes **Do zero** (apaga a flash), **Atualizar** (mantém a configuração) e **Só monitorar**, estão em [Gravar e acompanhar o log](../../README.md#gravar-e-acompanhar-o-log) do README e no documento de cada placa: [ESP32-WROOM-32U](ESP32-WROOM-32U_DevKit.md), [ESP32-S3-WROOM-1U-N16R8](ESP32-S3-WROOM-1U_N16R8_DevKit.md), [ESP32-S3-WROOM-2-N32R16V](ESP32-S3-WROOM-2_N32R16V_DevKit.md).

Cada placa tem a própria pasta de build e o próprio `sdkconfig`. Uma placa nunca sobrescreve a outra:

| `BOARD` | Pasta de build | sdkconfig gerado |
|---|---|---|
| `esp32` | `build-esp32/` | `sdkconfig.esp32` |
| `esp32s3_n16r8` | `build-esp32s3_n16r8/` | `sdkconfig.esp32s3_n16r8` |
| `esp32s3_n32r16v` | `build-esp32s3_n32r16v/` | `sdkconfig.esp32s3_n32r16v` |

O `build.sh` mostra a linha do `idf.py` que ele usa. No Windows nativo (PowerShell), rode essa linha direto:

```powershell
idf.py -B build-esp32           -D SDKCONFIG=sdkconfig.esp32           -D IDF_TARGET=esp32   -D BOARD=esp32           build
idf.py -B build-esp32s3_n16r8   -D SDKCONFIG=sdkconfig.esp32s3_n16r8   -D IDF_TARGET=esp32s3 -D BOARD=esp32s3_n16r8   build
idf.py -B build-esp32s3_n32r16v -D SDKCONFIG=sdkconfig.esp32s3_n32r16v -D IDF_TARGET=esp32s3 -D BOARD=esp32s3_n32r16v build
# gravar: troque "build" por "-p COM6 flash monitor"
```

> **Quem já compilava o S3 com o nome antigo:** `./scripts/build.sh esp32s3` continua funcionando e vira `esp32s3_n32r16v` (o script avisa). As pastas antigas `build-esp32s3/` e `sdkconfig.esp32s3` não são mais usadas e podem ser apagadas.
>
> **Se aparecer** `BOARD=... but sdkconfig has board ...`, o `sdkconfig.<board>` é de outra placa (por exemplo, copiado à mão). Apague esse arquivo e a pasta `build-<board>/` e compile de novo.

---

## 4. Binários prontos (GitHub Actions / Releases)

O workflow [`build.yml`](../../.github/workflows/build.yml) compila as três placas a cada push e publica os binários nas tags `v*`:

| Arquivo | Uso |
|---|---|
| `Gateway_ESP32_SX1302_LR1302_HAT_Elecrow-<versão>-<BOARD>-full.bin` | imagem única, gravar em `0x0` (apaga a configuração) |
| `Gateway_ESP32_SX1302_LR1302_HAT_Elecrow-<versão>-<BOARD>-app.bin` | só a aplicação, gravar em `0x10000` (mantém a configuração) |
| `Gateway_ESP32_SX1302_LR1302_HAT_Elecrow-<versão>-<BOARD>-parts.zip` | bootloader, partições e app separados, com `flash_args` |

```bash
esptool.py --chip esp32   -p /dev/ttyUSB0 write_flash 0x0 Gateway_ESP32_SX1302_LR1302_HAT_Elecrow-<versão>-esp32-full.bin
esptool.py --chip esp32s3 -p /dev/ttyACM0 write_flash 0x0 Gateway_ESP32_SX1302_LR1302_HAT_Elecrow-<versão>-esp32s3_n16r8-full.bin
esptool.py --chip esp32s3 -p /dev/ttyACM0 write_flash 0x0 Gateway_ESP32_SX1302_LR1302_HAT_Elecrow-<versão>-esp32s3_n32r16v-full.bin
```

> **S3 que já rodava a v0.0.1** (tabela de 1,5 MB): grave a imagem `-full.bin`, ou o `-parts.zip`, uma vez, para trocar a tabela de partições pela de 4 MB. Como a `nvs` continua em `0x9000`, a gravação do `-parts.zip` (`write_flash @flash_args`) **mantém** a configuração; a `-full.bin` apaga. Depois disso, as atualizações podem ser só do `-app.bin`.

---

## 5. Como o firmware informa a placa

| Onde | Exemplo |
|---|---|
| Boot (monitor serial) | `*** Board: ESP32-S3-WROOM-1U-N16R8 (esp32s3_n16r8, esp32s3) ***` |
| `GET /info` (sem login) | `"target":"esp32s3","board":"esp32s3_n16r8","board_name":"ESP32-S3-WROOM-1U-N16R8"` |
| `GET /config.json` | `"_target"`, `"_board"`, `"_board_name"` |
| mDNS (TXT do `_http._tcp`) | `board=esp32s3_n16r8` |
| App Android | Manutenção → **Placa**: nome do módulo e `BOARD` |

## Placa adaptadora e caixa (instalação fixa)

Para não usar jumpers soltos, [`hardware_design/`](../../hardware_design/) tem uma placa adaptadora em placa perfurada 70 × 90 mm (o HAT encaixa num 2×20 e a DevKit em barras fêmeas, com os pull-ups do I2C e um jack DC de 5 V) e uma caixa paramétrica. Ela serve para as três placas desta página; a figura [`esp32_lr1302_adapter_devkit_pins.png`](../../hardware_design/motherboard/esp32_lr1302_adapter_devkit_pins.png) mostra em que pino de cada DevKit soldar cada fio.

## Diagramas de ligação em alta resolução

Clique na imagem para abrir o PNG de 3720 px. Cada um tem a versão vetorial (SVG) ao lado.

| ESP32-WROOM-32U (`esp32`) | ESP32-S3-WROOM-1U-N16R8 (`esp32s3_n16r8`) | ESP32-S3-WROOM-2-N32R16V (`esp32s3_n32r16v`) |
|:---:|:---:|:---:|
| [![ESP32 ↔ LR1302 HAT](../images/wiring_esp32_wroom32u.png)](../images/wiring_esp32_wroom32u.png) | [![ESP32-S3 N16R8 ↔ LR1302 HAT](../images/wiring_esp32s3_wroom1u_n16r8.png)](../images/wiring_esp32s3_wroom1u_n16r8.png) | [![ESP32-S3 N32R16V ↔ LR1302 HAT](../images/wiring_esp32s3_wroom2.png)](../images/wiring_esp32s3_wroom2.png) |
| [SVG](../images/wiring_esp32_wroom32u.svg) | [SVG](../images/wiring_esp32s3_wroom1u_n16r8.svg) | [SVG](../images/wiring_esp32s3_wroom2.svg) |

<p align="center">
  <a href="../images/lr1302_hat_header.png"><img src="../images/lr1302_hat_header.png" alt="Header de 40 pinos do LR1302 HAT com os GPIOs de cada placa" width="100%"/></a>
</p>
<p align="center"><sub>🔍 Alta resolução (PNG, 3720 px de largura): clique na imagem para ampliar · versão vetorial: <a href="../images/lr1302_hat_header.svg"><code>lr1302_hat_header.svg</code></a></sub></p>
