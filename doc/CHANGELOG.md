# CHANGE LOG


## Unreleased
- docs: each repository is self-contained again; references to the other repositories were removed (workspace layout
  in README and user guide, CHANGELOG entries, DIAG_DEFAULT_HOST note)
- docs: new doc/CHIRPSTACK_DEVICE_PROFILES.md: gateway registration (ChirpStack v4 and v3 gateway-profiles) and the 32 example
  device profiles (au915_0/au915_1 x revision A/B x ABP/OTAA x classes A, A+B, A+B+C, A+C), field by field, with the v3
  equivalents; README section "Cadastro no ChirpStack", the same table in CLASSES_LORAWAN.md and in the user guide
- folder and repository renamed again, without the "LoRaWAN_" prefix: LoRaWAN_Gateway_ESP32_SX1302_LR1302_HAT_Elecrow ->
  Gateway_ESP32_SX1302_LR1302_HAT_Elecrow (folder in ~/Apps/lorawan_workspace, GitHub repository, CI package/release files
  Gateway_ESP32_SX1302_LR1302_HAT_Elecrow-<version>-<board>-{full,app}.bin / -parts.zip, README, doc/ and scripts/create_github_repo.sh, which now
  renames a repository still on GitHub with the old name). A build-<board>/ configured in the old folder is deleted and
  configured again by scripts/build.sh
- repository and folder renamed again, now naming the concentrator board: LoRaWAN_Gateway_ESP32_with_SX1302 ->
  LoRaWAN_Gateway_ESP32_SX1302_LR1302_HAT_Elecrow (folder in ~/Apps/lorawan_workspace, GitHub repository, CI
  package/release files LoRaWAN_Gateway_ESP32_SX1302_LR1302_HAT_Elecrow-<version>-<board>-{full,app}.bin / -parts.zip,
  README, doc/ and scripts/create_github_repo.sh). Unchanged: binary ESP32_SX1302-Pkt-Fwd.bin, console
  prompt, mDNS host and "_type" of the exported configuration
- fix: the gateway stopped receiving after hours of operation and only came back after a reboot: the SX1302 was reset or lost its 32 MHz clock (power dip on TX, glitch on RESET) while the ESP32 kept running, and lgw_receive() returned 0 packets forever. Field signature: "SX1302 counter (PPS)" frozen and the "Invalid time reference" age growing from the last received frame. SX1302 watchdog:
  - libloragw: new lgw_check_alive() (chip version over SPI, registers written once by lgw_start(), 1 MHz counter advancing like the ESP32 clock since the previous call; non-blocking, a few SPI accesses) and lgw_restart();
  - thread_up checks it once per second; after 2 failures in a row, on an lgw_receive() error (it used to exit and reboot) or after 30 min without any packet (doubling up to 6 h, never with a downlink queued) it calls the new lgw_restart() (abort TX, close the SPI only, POWER_EN/RESET pulse, lgw_start(); the I2C bus of the OLED and of the STTS751 stays open), in place (~2 s; Wi-Fi, MQTT, web, GPS and OLED untouched), and empties the JIT queues with the new jit_queue_reset() (jit_queue_init() created a new mutex on every call);
  - no limit to these restarts; more than 3 fault restarts in an hour log a hardware warning; the ESP32 reboots only when the SX1302 does not start again (3 attempts);
  - statistics: new "# SX1302 watchdog" line; README: feature, troubleshooting rows and power notes (bulk capacitor, short wires, antenna away from the RESET wire)
- security, web log (/logs, /logs_download): credentials no longer reach the RAM log shown on the web page.
  check_basic_auth() logged the whole Authorization header ("Basic base64(user:password)"; base64 is not
  encryption), so anyone reading /logs or a downloaded .log could recover the web login: the header is no longer
  logged, the comparison is constant-time, and the copies of the credential are wiped before free(). A refused
  login is logged once as "web login refused ... from <IP> <URI>" (not after "Sair"); "Authenticated!" moved to
  debug level
- security: handle_basic_auth() let the request through without a login when check_basic_auth() ran out of
  memory (ESP_ERR_NO_MEM was not treated as a failure); it now answers 503 and refuses the request
- weblog: the serial console session (REPL task "console_repl") is no longer copied to the RAM log. linenoise
  echoes every typed character to stdout, so "web_auth --pass", "mqtt --pass" and "config --wifi-pass" showed the
  password on /logs; the command replies stay on the serial port too (messages of the other tasks unchanged)
- weblog: new weblog_secret() (full text on the serial console, masked text on /logs) used for the Soft AP
  password at boot, and weblog_uri() hides the password of a "scheme://user:pass@host" broker URI in the "mqtt"
  console status and in dump_config()
- I2C: libloragw/loragw_i2c.c moved from the legacy driver/i2c.h (end-of-life in ESP-IDF v6.0, removed in v7.0,
  "CRITICAL WARNING" on every build) to the new driver/i2c_master.h: one bus handle and one device handle per
  address, created on first use after an i2c_master_probe (absent devices fail quietly, as before). Same
  i2c_esp32_* functions, so SSD1306, STTS751 and AD5338R code is unchanged
- scripts/build.sh: a build-<board>/ configured in another folder (the workspace moved from ~/Apps/esp-idf_workspace
  to ~/Apps/lorawan_workspace) is removed before the build instead of failing with "CMakeCache.txt directory ... is
  different"; "all" builds the three boards even if one fails and lists the failures at the end
- Classes LoRaWAN (A, B e C): new doc/CLASSES_LORAWAN.md (what each class is, timing diagrams, when to use
  each one, ChirpStack v4 device-profile settings, support in LMiC/LoRaMac-node/Basics Modem and the state of
  each class in this gateway); README section; new read-only web page /classes (classes_page.h, link
  "Classes" in the top bar of the main, Logs and Diagnostics pages; max_uri_handlers 24 -> 28) and Android
  app screen "Classes LoRaWAN" (school icon in the app bar of the device list and of the gateway screen)
- docs: the project is self-contained; references to other repositories of the workspace were removed (README,
  hardware_design, scripts); README "Compilar as três placas" builds only this project
- Diagnostics (web /diag and app tab): the three tests (ping, traceroute, nslookup) now start with
  chirpstack-v4.adailsilva.com.br (DIAG_DEFAULT_HOST in diag.h, same constant as the LoRaWAN nodes), also first
  in the suggestion list; screenshots web_15_diag_*.png and app gw_12_diag.png updated
- Soft AP network renamed lorawan-gateway -> lorawan-gateway-sx1302: GW_SOFTAP_SSID in http_server.h (Wi-Fi setup, OLED, factory-defaults page, console help),
  web page, Android app (default Soft AP SSID and texts), README, app README, user guide, upgrade notes and the
  screenshots web_06_boot.png and app gw_04_softap.png. Password (lorawan101) and address (192.168.101.101) unchanged.
  Takes effect after flashing the new firmware; the old name was never stored in the NVS
- docs: README "Gravar e acompanhar o log" and doc/hardware/<board>.md with the full per-board commands
  (Do zero / Atualizar / Só monitorar: fuser on the port, ESP-IDF export, log in logs/), the build of
  the three boards, and a pkt_fwd console example (README, user_guide)
- three supported boards, one source tree, selected with BOARD (scripts/build.sh <board>, -D BOARD=<board>):
  esp32 = ESP32-WROOM-32U DevKit, esp32s3_n16r8 = ESP32-S3-WROOM-1U-N16R8 DevKit (new: 16 MB quad flash 3.3 V +
  8 MB octal PSRAM, u.FL antenna), esp32s3_n32r16v = ESP32-S3-WROOM-2-N32R16V DevKit (was "esp32s3", still accepted)
- boards/<board>.defaults: flash/PSRAM and CONFIG_GW_BOARD_* of each module; sdkconfig.defaults.esp32s3 keeps only
  what both S3 share (USB console, partition table). Top-level CMakeLists.txt maps BOARD -> IDF_TARGET and
  SDKCONFIG_DEFAULTS; main/CMakeLists.txt stops the build when BOARD and the sdkconfig board differ
- main/Kconfig.projbuild: choice GW_BOARD + GW_BOARD_ID / GW_BOARD_NAME
- board reported on the boot banner ("*** Board: ... ***"), in GET /info ("board", "board_name"), in /config.json
  ("_board", "_board_name") and in the mDNS TXT record ("board"); the Android app shows it (Manutenção -> Placa)
- partitions_esp32s3.csv: 4 MB factory app on both S3 boards (the S3 binary filled 96 % of the 1.5 MB table);
  nvs/phy_init keep their offsets, so the configuration survives
- scripts/build.sh: build-<board>/ + sdkconfig.<board>, new "erase" and "all" commands, default port per board
- GitHub Actions: builds the three boards; release files are named ...-<board>-full.bin / -app.bin / -parts.zip
- doc/hardware/README.md (comparison of the three boards: pins, files, flags, binaries) and
  doc/hardware/ESP32-S3-WROOM-1U_N16R8_DevKit.md; images pinout_esp32s3_wroom1u_n16r8_devkit.svg and
  wiring_esp32s3_wroom1u_n16r8.svg


## v0.0.1 (first release of LoRaWAN_Gateway_ESP32_SX1302_LR1302_HAT_Elecrow):
- two supported boards, one source tree: ESP32-WROOM-32U DevKit (IDF_TARGET=esp32, current feature set)
  and ESP32-S3-WROOM-2 (N32R16V) DevKit (IDF_TARGET=esp32s3, current feature set + new features)
- sdkconfig.defaults.esp32s3: 32 MB octal flash + 16 MB octal PSRAM (the WROOM-2 N32R16V does not boot without them)
- scripts/gen_headers.sh (webpage.h / global_json.h) and scripts/build.sh <esp32|esp32s3> [flash <port>]:
  one build directory and one sdkconfig per target (build-<target>/, sdkconfig.<target>)
- GitHub Actions: builds both targets on every push/PR, publishes a Release with the binaries on v* tags
- .gitignore: sdkconfig.defaults* were ignored by "sdkconfig.*"; build-*/, managed_components/, logs/ ignored
- README in pt-BR with colored pinout / wiring / architecture diagrams (doc/images/*.svg) and
  per-board wiring guides (doc/hardware/)
- version numbering restarts at 0.0.1 for this repository
- firmware version = Git tag: ESP32_SX1302_VERSION and the app descriptor come from FW_VERSION (CI) or
  "git describe" (0.0.1, 0.0.1-3-gabc1234, 0.0.1-dirty); no version to edit by hand
- releases: tag vX.Y.Z builds both boards and publishes, per board, a single image to write at 0x0
  (-full.bin), the application only (-app.bin) and the separate parts (-parts.zip), plus SHA256SUMS.txt;
  release notes come from the CHANGELOG section of the version; vX.Y.Z-rc1 tags are pre-releases
- MQTT (ChirpStack format): no downlink ever reached the gateway when the topic was typed with the gateway EUI in
  upper case (au915_1/gateway/A842E3FFFE90A3D4). ChirpStack v4 publishes to <region>/gateway/<eui in lower
  case>/command/down and MQTT topics are case sensitive, so the uplinks arrived (ChirpStack reads the ID from the
  payload) but the gateway was subscribed to a command/down topic that never got anything: no JoinAccept (OTAA) and
  no downlink (ABP). The EUI level of the base topic is now put in lower case (warning in the log)
- web page and answers in Portuguese everywhere: the TLS certificate file picker no longer shows the browser's
  "Choose File / No file chosen" (hidden input + "Escolher arquivo…" button and the file name, or "Nenhum arquivo
  selecionado"); ping / traceroute / nslookup output of the Diagnostics page in Portuguese ("bytes de", "tempo=",
  "estatísticas do ping", "Servidor/Nome/Endereço"; the page and the Android app highlight both the old and the new
  format); MQTT error shown in the status ("o broker recusou a conexão...", "endereço do broker não configurado");
  404 and 408 answers in Portuguese instead of the ESP-IDF defaults. Fixed json_str() of the MQTT status, which turned
  every UTF-8 byte into a space (char is signed on Xtensa). Screenshots web_04_mqtt and web_15_diag_* updated
- repository description: "Low-cost 8-channel LoRaWAN gateway running the Semtech SX1302_HAL (v2.1.0) natively on a
  single ESP32 microcontroller."; README and user guide intro no longer compare it with a Raspberry Pi
- Gateway EUI automatic by default, with override: the ESP32 Wi-Fi station MAC expanded to EUI-64 with FFFE in the
  middle (AA:BB:CC:DD:EE:FF -> AABBCCFFFEDDEEFF, the convention of LoRaWAN gateways). A valid EUI saved in gw_id
  overrides it; an empty field (or "config --gwid auto") goes back to the automatic one. Before, with gw_id empty the
  forwarder used the AA555A0000000000 placeholder of the embedded global_conf.json and MQTT used "unknown", although
  "config" said "(from the MAC address)". New gw_eui() / gw_eui_auto() / gw_eui_saved() / gw_eui_is_auto() in
  web_config.c; the EUI in use is latched at boot (log "Gateway EUI ... (automatic: Wi-Fi MAC + FFFE)")
- web page: field "Gateway EUI" with the automatic EUI as placeholder, button "Automático" and a hint that says
  automatic / manual and "Em uso até reiniciar"; header chip and MQTT topic placeholder use the automatic EUI when
  the field is empty; an empty gw_id is now saved as "clear it" (was "keep the old value")
- GET /config.json: new "_gw_eui" (in use) and "_gw_eui_auto"; GET /info: gw_id is the EUI in use, new gw_id_auto;
  log download and export file names use the EUI in use
- console: "config" shows the EUI and its origin; "config --gwid auto" and "pkt_fwd --gwid auto"; pkt_fwd --gwid
  now validates the 16 hex characters
- Android app: same field (placeholder, "Automático" button, hint), header chip, device list name and export file
  name with the EUI in use; Manutenção > Firmware shows "Gateway EUI" (automatic / manual)
- docs: README 1.3 "Gateway EUI", screenshot web_03_lorawan_udp.png, config.json and /info examples, user guide
- Soft AP network renamed esp32 -> lorawan-gateway (password still lorawan101, page at 192.168.101.101). One macro, GW_SOFTAP_SSID in http_server.h, used by the Wi-Fi
  setup, the OLED, the factory-defaults page and the console help; web page, Android app, README, user guide and
  screenshot web_06_boot.png updated
- scripts/create_github_repo.sh: topics and tag no longer lost when "gh repo edit" fails right after the
  creation (retried, never stops the script), new --sync for a repository already on GitHub (description,
  topics and missing tags), lists the topics and tags GitHub has at the end; topic flutter added; pushes the tags
  already in the local history (a repository deleted and created
  again on GitHub gets its releases back), checks git user.name/email before committing, commit message from MSG=
- ESP-IDF only (scripts/build.sh + idf.py): the build files of the original project that no longer apply were
  removed (Makefile, dropped in ESP-IDF 5; run_me.sh, replaced by scripts/build.sh; the PlatformIO files).
  doc/user_guide.md uses scripts/build.sh
- configurations_backup/ (exports of the web page) out of git: .gitignore, and scripts/create_github_repo.sh stops
  tracking it
- repository and folder renamed esp32_sx1302 -> LoRaWAN_Gateway_ESP32_with_SX1302 (GitHub, README, release
  files LoRaWAN_Gateway_ESP32_with_SX1302-<version>-<target>-{full,app}.bin / -parts.zip). Unchanged on purpose:
  binary ESP32_SX1302-Pkt-Fwd.bin, ESP32_SX1302_VERSION, console prompt, mDNS host esp32-sx1302-<MAC>, log file
  names and "_type": "esp32_sx1302" of the exported configuration (old backups still import)
- scripts/build.sh: new "monitor <port>" mode (no build, no flash) and BAUD=<bps>; README with the flash/monitor
  commands that save the output in logs/<target>_<date>.log and logs/<target>_<date>_limpo.log
- CI: -parts.zip now keeps bootloader/ and partition_table/ so "esptool.py write_flash @flash_args" works from
  inside the extracted folder; release notes show how to flash only the app (keeps the NVS)
- scripts/create_github_repo.sh: keeps an existing git history (only "origin" changes), first tag v0.0.1
  (VER=<x.y.z> for another one); the same script in the two LoRaWAN node repositories
- Android app (Flutter) in app_flutter/: same functions as the web page (login, Status, Configuração with the
  MQTT TLS certificates, Logs, Diagnósticos, Manutenção), through the same HTTP endpoints and HTTP Basic login;
  no extra RAM on the gateway (JSON only, one keep-alive connection, status every 5 s only while visible)
- GET /info (no login): identification for the app's network scan and "add by IP" (type, firmware, version,
  target, gw_id, wifi_mode, mdns, host); 23 URI handlers (limit 24)
- mDNS, ESP32-S3-WROOM-2 (N32R16V) build only: new main/Kconfig.projbuild with the first feature flag GW_MDNS
  (depends on IDF_TARGET_ESP32S3, default y) and GW_MDNS_HOSTNAME; component espressif/mdns pulled by
  main/idf_component.yml only for target esp32s3; announces http://esp32-sx1302-<MAC>.local/ and _http._tcp
  (TXT type=gateway, fw, target, info=/info). Not offered on the ESP32-WROOM-32U (free heap down to ~10 KB
  with the MQTT TLS session). New gw_mdns.c/.h
- factory defaults, as in the LoRaWAN nodes: new button "Restaurar padrão de fábrica" in the "Manutenção" section
  (POST /factory, with confirmation) and console command "factory_reset --yes". Erases the NVS namespaces "nvs"
  (configuration) and "mqtt_tls" (certificates) and reboots in Soft AP mode with the default login; 22 URI handlers
- temperature sensor: after "no temperature sensor found" the HAL kept the last port tried (0x38) and read it on
  every received packet and every statistics report, flooding the log with "ERROR: failed to read I2C device 0x38
  (err=-1)" / "failed to get current temperature". Now the HAL forgets the port (ts_addr 0xFF), never touches the
  I2C bus again and says once at boot that the RSSI is compensated for 25 C (LGW_DEFAULT_TEMPERATURE); new
  lgw_temperature_sensor_found()
- temperature sensor: the LR1302 module has a STTS751 (HAT pins 3/5), but only 3 of its 8 possible addresses were
  probed (0x39 0x3B 0x38). All 8 are probed now (0x38-0x3B, 0x48-0x4B; ST datasheet table 1). When none answers,
  the boot scans the I2C bus (new i2c_esp32_scan()) and prints the devices found, or a hint about the SDA/SCL
  wiring and the pull-ups (the HAT has none: they are on the Raspberry Pi board, 1.8 k)
- RSSI: without a temperature reading lgw_receive() compensated the RSSI for 0 C (offset 0 dB instead of
  +1.0 dB at 25 C, +1.8 dB at 40 C with the AU915 coefficients); it now uses 25 C
- statistics: "temp" was sent with an uninitialized value when there is no sensor; it is now sent only with a
  real reading (UDP stat "temp", ChirpStack event/stats metadata "temperature", JSON and Protobuf)
- GET /status: new gw.temp_sensor; the Status card "Temperatura" says "não encontrado" when the STTS751 did not answer
- GPS fix never shown with the Quectel L76K of the HAT (status "sem posição (16 satélites)" for ever): its NMEA 4.10 RMC has a
  14th field (navStatus) and the parser accepted exactly 13, so every $GNRMC was ignored and the position, parsed
  from GGA, was never published. RMC with 13 or 14 fields accepted; the position is also published on each GGA;
  a GGA with fix quality 0 is no longer a position
- GPS time reference (gps_process_sync) only when GPS_PPS_GPIO is defined: without the PPS pulse the SX1302
  trigger counter is stale and the reference would be garbage (it stays invalid, as documented)
- GPS gives its RAM to the MQTTS (TLS) handshake (classic ESP32 without PSRAM: "Dynamic Impl: alloc failed",
  mbedtls -0x2700, cert 0x8 with the GPS on): with MQTT enabled the GPS starts only once the MQTT session is
  connected (boot and switch-on), and stops (UART driver deleted, task deleted) before every connection attempt
  (new mqtt_gw_set_before_connect_cb(), MQTT_EVENT_BEFORE_CONNECT) and when the session drops; it restarts after
  the reconnection. With MQTT disabled it starts right after the forwarder threads, as before
- GPS: thread_valid merged into thread_gps (one task, 3584 bytes of stack instead of 2 x 4096; stack high-water
  printed after one minute); GPS UART RX buffer 1024 -> 512 bytes; switched off, the GPS keeps no RAM at all;
  a failed UART driver install is now reported; a failed start is retried after 60 s
- web page / GET /status: GPS "wait" state ("GPS ligado, aguardando a conexão MQTT…", card "aguardando MQTT");
  "Configuração salva" says when the GPS waits for MQTT; console "gps on" too (GPS_APPLY_WAIT)
- docs: screenshot web_23_gps_aguardando_mqtt.png (GPS section waiting for the MQTT connection) in README 1.6
- docs: README 1.6 GPS rewritten in depth (step by step, path of the position to ChirpStack with a Mermaid diagram
  and event/stats / stat examples, life cycle with MQTT, measured RAM, supported NMEA sentences, PPS and time
  reference, log messages, console); user guide "GPS of the LR1302 HAT" extended the same way; new troubleshooting
  row "gateway not on the ChirpStack map"; new image doc/images/chirpstack_gateway_mapa_gps.png (ChirpStack v4
  gateway dashboard with the position sent by the GPS)
- sdkconfig.defaults.esp32 (new, classic ESP32 only): 6 Wi-Fi static RX buffers (was 10), no A-MPDU on RX;
  delete sdkconfig.esp32 once so it applies
- docs: Wi-Fi example network renamed MinhaRede-2G -> MinhaRede-4G (README, screenshots web_01, web_01_dark,
  web_02, web_08, web_17, web_18)
- GPS of the HAT switched on/off at run time, no reboot: new "GPS" section in the web page (Desligado / Ligado,
  applied when saved), console "gps [on|off]" and "config --gps on|off"; saved in NVS as gps_en (default off).
  GPS_DISABLE is no longer set in main/CMakeLists.txt (still honored to build a firmware without GPS)
- GPS threads (thread_gps + thread_valid, 8 KB of stack) are created only the first time the GPS is switched on;
  switched off they sleep, the UART is not read and the coordinates, time reference and XTAL correction are dropped
- GET /status: new "gps" object (on, fix, lat/lon/alt, satellites, NMEA sentences ok/bad, bytes, age of the last
  data); the page shows it live (5 s) with a hint about the wiring when nothing arrives, plus a "GPS" card in
  the Status panel (9th card)
- docs: README section "1.6 GPS" (screens, status messages, /status "gps" object, console), user guide
  "GPS of the LR1302 HAT"; screenshots web_20/21/22_gps*.png added, web_01/08/09/10/17 regenerated
- "WARNING: [gps] read() returned value 0" (once a second without data) replaced by one warning every 10 s
  that names the HAT pin and the ESP32 RX GPIO to check
- stats: the coordinates are no longer sent after the GPS is switched off (coord_ok kept its old value)
- web page: new "Manutenção" section with "Exportar configuração" (downloads gateway_<GatewayID>_<YYYYMMDD>.json)
  and "Importar…" (fills the form from such a file; nothing is saved until "Salvar"); a node's file is refused
- GET /config.json: saved configuration as JSON, without the Wi-Fi / MQTT / web passwords and without the
  TLS certificates; httpd max_uri_handlers 20 -> 24 (21 handlers registered now)
- Soft AP: fixed address 192.168.101.101/24 (gateway 192.168.101.1) instead of the ESP-IDF default 192.168.4.1;
  the OLED shows the address read from the interface
- default passwords unified: Soft AP lorawan101 and web login admin / lorawan101
- web login: a gateway updated from an older firmware kept the factory login of that version, because the login
  saved in NVS wins over the compiled default. At boot, that old factory login is now replaced by the current
  default admin / lorawan101 and saved (warning in the log); any other saved login is kept


---

# History of the original ESP32_SX1302 project (before this repository)

The versions below come from the original port and its AU915 adaptation. They are kept for reference only:
the tags of this repository start at v0.0.1, and this repository builds only with ESP-IDF (the PlatformIO
entries below refer to the original project).

## v0.9.1 (AU915):
- web status panel ("Status" section at the top of the configuration page): uptime, free / minimum free heap,
  Wi-Fi RSSI, concentrator temperature, packets received (CRC ok / error / no CRC), forwarded, downlinks
  (requested / sent / failed / rejected) and age of the last server ACK with PUSH/PULL ack ratio; counters are
  totals since boot (kept apart from the per-report counters, ~70 bytes of RAM)
- GET /status returns {"gw":{...},"mqtt":{...}} and replaces /mqtt_status: the page makes one request every 5 s
- web polling chained with setTimeout (no overlapping requests when the gateway is slow) and paused while the
  browser tab is hidden, on the configuration page and on /logs
- fix: side menu marked "Acesso" after clicking "Inicialização" (the last sections can not reach the top of
  the screen); the clicked item now stays marked until the page is scrolled by hand
- fix: with MQTTS enabled no message was sent (0 sent): the TLS session started in parallel with the
  concentrator init and took the RAM of the thread_up stack ("Failed to spawn thread_up", largest free
  block 13 KB). MQTT now starts after thread_up/down/jit, a failed thread spawn reboots instead of failing
  silently, the free heap is logged at each stats cycle, and mbedTLS uses dynamic buffers (sdkconfig.defaults)
- add AU915-928 frequency plans (Brazil / Australia): "AU915 SB0" (ch 0-7 + 64) and "AU915 SB1" (ch 8-15 + 65)
- AU915 SB1 becomes the default plan when none has been saved
- ignore saved radio center frequencies outside 915-928 MHz when an AU915 plan is selected
- Class B beacon parameters for AU915 (923.3 MHz + n*600 kHz, SF12BW500)
- web UI: AU915 options, fix Radio 2 frequency validation, increase max URI handlers, enlarge JSON view buffer
- regenerate main/global_json.h from the JSON files (the embedded copy was out of date)
- default NTP server set to br.pool.ntp.org
- build fixes for ESP-IDF 6.x / GCC 16: speed_t -> uint32_t in lgw_gps_enable(), FreeRTOS include in loragw_spi.c,
  4-byte buffers initialized with {0} instead of string literals, WIFI_IF_STA instead of ESP_IF_WIFI_STA,
  esp-mqtt fetched from the Component Registry (main/idf_component.yml) since it left the IDF core in v6.0
- ESP32-S3 support: pin map in main/CMakeLists.txt, console/REPL on the native USB Serial/JTAG port,
  GPIO_NUM_NC handled for reset/power, buttons and blink LED, platformio env "esp32s3"
- default options moved from "sdkconfig" to "sdkconfig.defaults" (+ "sdkconfig.defaults.esp32s3"),
  so "idf.py set-target" works
- ESP32-S3 pin map matches the Elecrow LR1302 HAT wiring (RESET=6, SDA=4, SCL=5, SX1261 CS=7 held high, no POWER_EN)
- optional SX1261_NSS_PIN, driven high before the SX1302 reset
- on concentrator start failure, print a wiring hint and wait 20 s before rebooting
- ESP32 (classic) + LR1302 HAT pin map: VSPI 18/19/23/5, RESET=4, SX1261 CS=25, I2C 21/22, GPS 17/16
- web login with a default user/password, changeable in the web page and with the console command "web_auth" (--reset restores the default)
- web pages: "Desenvolvido por AdailSilva" credit in the footer, linked to https://k8s.adailsilva.com.br/
- console "config" (all the settings of the web page) and "reboot"; web and console share the same NVS settings
- web: radio frequencies can be cleared (back to the plan default); passwords masked in the form log
- UDP and MQTT are exclusive: MQTT enabled = UDP forwarder off (any MQTT format)
- fix: web form field "mqtt_enc" was read as "mqtt_en" (prefix match), so MQTT could not be enabled from the page
- web page icon (favicon: antenna tower with radio waves), served at /favicon.svg and /favicon.ico
- MQTT format "ChirpStack v4" in JSON or Protobuf (hand written encoder/decoder, checked against the official .proto): UplinkFrame / GatewayStats / DownlinkTxAck / ConnState in JSON, downlinks from command/down (RX1/RX2 alternatives), UDP off in this mode (cs_codec.c); console "mqtt --format", web option
- web logout: "Sair" link on the configuration and log pages (/logout replaces the browser saved login, /saiu page)
- log download: "Baixar do gateway" (/logs_download, whole RAM buffer, colors removed) and "Baixar sessão" (what the page received)
- web log viewer: page /logs (live, filter, pause), stdout tee into a 16 KB RAM ring buffer (weblog.c), link in the header
- project renamed ESXP1302 -> ESP32_SX1302 (folder esp32_sx1302/, binary ESP32_SX1302-Pkt-Fwd.bin, ESP32_SX1302_VERSION)
- MQTT/MQTTS client (mqtt_gw.c): uplinks/stats/state topics, TLS with custom CA or public CA bundle,
  mutual TLS (client cert + key), user/password; managed from the web page (status, certificate upload)
  and console commands "mqtt" / "mqtt_cert"; replaces the old unused MQTT stub
- web page sent in chunks with HTML-escaped values (no 12 KB RAM buffer)
- gateway name "Gateway ESP32 with SX1302" (banner, OLED, console prompt, web pages), set in packet_forwarder/branding.h
- new web configuration page (pt-BR, light/dark, phone friendly, inline validation, hyphen allowed in host, password show/hide)
- form POST read completely (up to 1 KB, was 256 bytes); new "saved" and "rebooting" pages
- scripts/dump_html.py embeds the page as UTF-8 bytes
- GPS disabled by default on the LR1302 HAT pin maps (GPS_DISABLE; remove it after wiring the GPS)
- SX1302 wiring diagnostic on start failure (MISO level with CS high/low, both reset polarities, 2 MHz / 500 kHz)
- LEDs set to GPIO_NUM_NC are skipped at init; MISO weak pull-up + chip version diagnostics (0x00 / 0xFF)

## v0.9.0:
- upgrade to sx1302_hal v2.1.0
- support nodo board
- add option to set NTP server address
- extends us915 TX frequency to cover the range of AS923
- allow up to 1.5MB app size
- remove black web theme
- other fixes to make esp32_sx1302 be more flexible for different hardware designs.


## v0.8.0:
- add hardware reference design materials
- add support for esp32c3
- add support for compiling using PlatformIO
- add support for compiling under Windows (based on PlatformIO)
- optimize memory usage
- update scripts to Python3
- other fixes and document improvement


## v0.7.0:
- show version info in the screen
- change CN470 tx_freq_min from 500MHz to 470MHz for supporting RP2
- fix the bug that ns host can't be domain name
- change the default web username/password
- add upgrader.py to simplify upgrade the firmware
- add license info


## v0.6.2:
- disable gps output
- workaround to support sx1303


## v0.6.1:
- hide wifi password


## v0.6.0:
- the first public released version
- add version info in the serial port output
- documents
