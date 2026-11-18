# Gateway ESP32_SX1302 User Guide


## Basic Introduction

**Gateway ESP32_SX1302** project is based on the `SX1302_HAL` project and runs it natively on a single ESP32 microcontroller, which is the only host processor of the gateway. *ESP32_SX1302* = *ESP32* + *SX1302*.

This document is a very simple guide about how to configure and use ESP32_SX1302 gateway based on **version 0.0.1** of the repository `Gateway_ESP32_SX1302_LR1302_HAT_Elecrow`. The firmware is built only with **ESP-IDF**: see [Setting up ESP-IDF](#setting-up-esp-idf-windows-linux-and-macos).

First, please be noted that ESP32_SX1302 gateway has 2 types of Wi-Fi working modes, and 2 ways to configure it.

The 2 Wi-Fi modes are:
- **Soft AP** mode. The gateway works as an Wi-Fi Soft AP, so user can connect to it directly and configure it.
- **Station** mode. The gateway needs to connect to the same Wi-Fi router as the user and use that router for LoRaWAN uplink and downlink.

The 2 configuration ways are:
- **Web UI**. User can change gateway settings by browser after connect to the gateway.
- **Command line** (or Serial Port). There is a simple interactive command line interface available from the USB port, so user can configure the gateway that way without any network connection required.


## Configuration based on Wi-Fi mode

By default, the gateway boots to the Soft AP mode for the first time. It switches modes when necessary such as Wi-Fi disconnected or be controlled by user. But you can always specify which mode it boots into: just keep one of the Interface board buttons pressed during the poweron: Left button for Soft AP mode, while right button for Station mode.

In the Soft AP mode, user can connect the gateway by Wi-Fi. All the useful information can be seen from the screen, which is: `IP = "192.168.101.101"`; `Wi-Fi SSID = lorawan-gateway-sx1302`; `Wi-Fi password = lorawan101`.

Now user can access the web UI by browser with address: `http://192.168.101.101`. Please be noted that the protocol is **http**, not **https**. The default login information are: `username = admin`; `password = lorawan101`. It can be changed in the section "Acesso a esta página" of the web page or on the serial console with `web_auth --user <u> --pass <p>`; `web_auth --reset` restores the default. A gateway updated from an older firmware that still has the factory login of that version saved is moved to the current default `admin` / `lorawan101` at boot; a custom login is kept. The "Sair" link at the top of the configuration and log pages logs out: the browser asks for user and password again on the next access (the user name `_logout_` is reserved for this).

If the gateway boots to Station mode, then both the gateway and user needs to connect to the same wireless router. Then the only difference is user needs to get the right IP address showing on the screen or provided by the router, and access the web UI with that IP address. It **won't** be the "192.168.101.101" any more.

There are also some Wi-Fi mode automatic switch if some events happens:
- In Soft AP mode, if no changes to the web UI and no input to the command line, it reboots to Station mode in 10 minutes.
- If gateway boots to Station mode, but can't connect to wireless router (maybe wrong Wi-Fi settings or haven't set Wi-Fi yet), then it reboots to Soft AP mode in 5 minutes.
- If during the Station mode, `pkt_fwd` works all right for some time, then Wi-Fi disconnected, the gateway will try to re-connect to Wi-Fi for 5 minutes. If succeeds during that time, nothing happens; but if failed, then reboots to Soft AP mode.
- If after power on, the gateway reboots again by `brownout`, then it changes to the other mode. So user should check the screen or the command line output to be sure which mode the gateway is really in.


## Configuration by web UI

From web UI, user can configure below items:
- **next time boot into**. Generally after the configuration is done, the gateway should boot into station mode. But if the gateway will boot somewhere with some unknown Wi-Fi router and needs to provide the SSID informatioin again, then boots into Soft AP mode maybe make more sense. Consider you can always control which mode boots into by the hardware button, this option only becomes important when you can't access the gateway hardware easily.
- **Frequency Plan**. You need to choose this wisely based on your region and node settings. You can click each of them to know the details of the original JSON file used for that frequency plan.
- **AU915 (Brazil / Australia)**. Two plans are available, each one covering one AU915-928 sub-band (8 x 125 kHz + 1 x 500 kHz), since the SX1302 listens to 8+1 channels at once. **AU915 SB1** is the default when no plan has been saved yet. Set the end-devices / network server (e.g. ChirpStack) to the same sub-band.

  | Plan | 125 kHz uplink channels | 500 kHz channel | Radio 1 (radio_0) | Radio 2 (radio_1) |
  |------|-------------------------|-----------------|-------------------|-------------------|
  | AU915 SB0 | ch 0-7: 915.2 / 915.4 / 915.6 / 915.8 / 916.0 / 916.2 / 916.4 / 916.6 MHz | ch 64: 915.9 MHz (SF8BW500) | 915600000 | 916300000 |
  | AU915 SB1 | ch 8-15: 916.8 / 917.0 / 917.2 / 917.4 / 917.6 / 917.8 / 918.0 / 918.2 MHz | ch 65: 917.5 MHz (SF8BW500) | 917200000 | 917900000 |

  Radio 1 channels use IF offsets -400K/-200K/0K/+200K Hz (plus +300K Hz for the 500 kHz channel); Radio 2 channels use -300K/-100K/+100K/+300K Hz. Downlinks (RX1/RX2) are sent by radio_0 between 923.3 and 927.5 MHz (500 kHz BW), within the allowed 915-928 MHz TX range. With an AU915 plan selected, saved Radio center frequencies outside 915-928 MHz are ignored, so it's safe to leave the fields empty. **Hardware note**: the SX1302/SX1250 board and its RF matching/SAW filter must be the 915 MHz version (the Elecrow LR1302 HAT 915 MHz version; see `hardware_design/lr1302_hat/` and `hardware_design/sx1302/`).
- **Radio 1 and Radio 2 center frequency**. These 2 values should be the reasonable values based on the Frequency plan. Each control the frequency bands. The frequency bands has offsets of -300K/-100K/100K/300K Hz with the center frequency for CN470, while it's -400K/-200K/0K/200K for EU868. So please check the Frequency plan link to be sure.
- **Wi-Fi SSID and password**. Please noted that both only support the ASCII characters. It doesn't work if your SSID or password contains other UTF-8 characters such as Chinese characters. This limitation is hard to remove so you may have to change your Wi-Fi router settings.
- **NS Host and Port**. Here user needs to provide the right NS IP address (or domain name) and port.
- **Gateway EUI** (Gateway ID). Automatic by default: with the field empty the gateway uses its ESP32 Wi-Fi station MAC
  expanded to EUI-64 with `FFFE` in the middle, the usual convention of LoRaWAN gateways
  (`24:0A:C4:00:8D:88` -> `240AC4FFFE008D88`). The page shows it as the field placeholder and in the header chip
  "Gateway". Type 16 hex characters to override it; the "Automático" button (or an empty field) goes back to the
  automatic one. Applied after a reboot. Register the same EUI in ChirpStack; it is also part of the default MQTT topic.

If you think the original value is correct for any of above fields, then you can just leave it empty. Any value you provided would be used to replace the original one from the JSON template file.

You can save your configurations whenever you like by clicking the **Apply** button. Such changes are saved in the gateway but won't apply to the current *packet-forward* process yet. It only happens after you click the **Reboot** button to reboot the gateway, or by user reboot the gateway by power off and on.

If you don't like the default dark theme, you can try the light theme by accessing `http://<gateway_ip>/w` instead.

**Backup (section "Manutenção").** "Exportar configuração" downloads `gateway_<GatewayID>_<YYYYMMDD>.json` with the
saved settings (read from `GET /config.json`). The Wi-Fi, MQTT and web passwords and the TLS certificates are never
exported. "Importar…" loads such a file into the form only: review it, type the passwords if needed and click
"Salvar". A file exported by a LoRaWAN node is refused. `gw_id` empty means the automatic EUI, so a file from a gateway
with the automatic EUI clones fine (each gateway keeps the EUI of its own MAC); with an overridden EUI, clear the field
or type another one. The file also has `_gw_eui` (EUI in use) and `_gw_eui_auto` (MAC + FFFE), informative only and
never imported.

**Factory defaults (section "Manutenção").** "Restaurar padrão de fábrica" (`POST /factory`) asks for confirmation,
erases the whole saved configuration, including the MQTT TLS certificates, and reboots. The gateway comes up as a new
one: Soft AP mode, Wi-Fi `lorawan-gateway-sx1302` / `lorawan101`, page at `http://192.168.101.101`, login `admin` / `lorawan101`. On the
serial console: `factory_reset --yes` (without `--yes` it only shows what will be erased).


## Configuration by command line

If you power on the gateway by connecting the micro USB cable to a PC, then you have access to its command line interface. Use any terminal tool such as `sscom` or `putty` to access it with configuration as: **115200-8-N-1**.

The command line is the same thing as the serial port, so it outputs gateway logs. When the *packet_forward* is running, the output would mix with any characters input by user. However, if the user ignores that and continues to input or delete characters, the command line will flush itself, so it is still usable. 

When the *packet_forward* doesn't run for reasons such as when Wi-Fi is not connected, then the command line looks like a regular Linux shell interactive window; it even supports basic readline shortcuts such as `Ctrl-A` and `Ctrl-W` etc.

So far, this interface only supports one command named `pkt_fwd`. You can input `pkt_fwd -h` to learn all the options it supports, which, let's be honest, not much. It supports only parts of all the configurations available from web UI. Here is the output of `pkt_fwd -h`:
```
 ---- pkt_fwd ----

Available options:
 -h                   print this help
 -u <wifi ssid>       Wifi SSID
 -p <wifi password>   Wifi Password
 --host <NS Host>     NS Host
 --port <NS Port>     NS Port
 --gwid <id>|auto     Gateway EUI (16 hex); auto = Wi-Fi MAC + FFFE
```

So, if you need to change other configuration items, please use the web UI way.

Example: Wi-Fi, LoRaWAN server (UDP) and Gateway EUI in a single line (replace `<SSID>` and `<password>` with your network's):

```
ESP32_SX1302> pkt_fwd -u <SSID> -p <password> --host chirpstack-v3.example.com --port 1700 --gwid E45F01FFFE10E12E
ESP32_SX1302> pkt_fwd -u <SSID> -p <password> --host chirpstack-v4.example.com --port 1710 --gwid E45F01FFFE10E12E
```

The first line targets a ChirpStack v3 Gateway Bridge on UDP port `1700`; the second, a ChirpStack v4 receiving Semtech UDP on port `1710`.

**Note:**
- Whenever you provide a valid option to `pkt_fwd`, it's saved and the gateway will reboot to apply the new changes.
- To input whitespace in command line (such as for Wi-Fi password, use `\` to escape. For example: `pkt_fwd -u mywifi -p my\ password`.

### install Windows Driver

To access the command line under Windows, users would need to install the right device driver first.

Below is the list of USB to serial converter chips installed on most of the ESP32 boards produced by Espressif together with links to the drivers:

- CP210x: [CP210x USB to UART Bridge VCP Drivers](https://www.silabs.com/developers/usb-to-uart-bridge-vcp-drivers)
- FTDI: [FTDI Virtual COM Port Drivers](https://ftdichip.com/drivers/vcp-drivers)

User can blindly install both drivers, or identifies the USB-to-UART bridge on the ESP32 board first and chooses the right one.

One way to identify the bridge under Linux is using the `lsusb` command. Run it would give output similar as **Bus 002 Device 027: ID 10c4:ea60 Silicon Labs `CP210x` UART Bridge** or **Bus 002 Device 025: ID 1a86:7523 QinHeng Electronics `CH340` serial converter**.


## Android app

The folder `app_flutter/` has an Android app (Flutter) with the same functions as the web page, through the same
HTTP addresses and the same login. How to build the APK: [`app_flutter/README.md`](../app_flutter/README.md). The
screens below were reproduced from the app source code with sample data; the README section "Telas e uso do app"
describes every screen in Portuguese.

<p align="center">
  <img src="images/app/gw_01_lista.png" alt="Saved gateways" width="32%"/>
  <img src="images/app/gw_05_login.png" alt="Login" width="32%"/>
  <img src="images/app/gw_06_status.png" alt="Status tab" width="32%"/>
</p>
<p align="center">
  <img src="images/app/gw_08_config_mqtt.png" alt="Configuration tab, MQTT" width="32%"/>
  <img src="images/app/gw_11_logs.png" alt="Logs tab" width="32%"/>
  <img src="images/app/gw_13_manutencao.png" alt="Maintenance tab" width="32%"/>
</p>

1. Connect the phone to the same Wi-Fi network as the gateway and tap **Procurar** (search). The ESP32-S3 gateway is
   found by mDNS; the ESP32-WROOM-32U, which has no mDNS, by scanning the subnet (`GET /info`). **Adicionar por IP**
   adds it by address.
2. Gateway in Soft AP mode: tap **Soft AP**. The app joins `lorawan-gateway-sx1302` (password `lorawan101`) and talks to
   `192.168.101.101`, keeping its traffic on that Wi-Fi network even without internet.
3. Log in with the web page user and password (default `admin` / `lorawan101`). The password can be remembered,
   encrypted in the Android Keystore.
4. Tabs: **Status** (refreshed every 5 s), **Config.** (same sections and validation as the web page, including the
   MQTT TLS certificates; **Salvar** saves, **Reiniciar** reboots), **Logs** (live, filter, download),
   **Diagnóst.** (ping, traceroute and nslookup run by the gateway; default target chirpstack-v4.adailsilva.com.br) and **Manutenção** (export / import the
   configuration, factory defaults, reboot, firmware version).

## LoRaWAN classes (A, B and C)

The class is a property of the **node**, not of the gateway: it says when the node listens for downlinks. The ESP32_SX1302 gateway serves Class A, B and C nodes at the same time and sends each downlink when ChirpStack asks:

| Class | Node listens | Downlink from the gateway | Status here |
|:---:|---|---|---|
| A | 2 short windows (RX1/RX2) after each uplink | `tmst` (1 s / 2 s after the uplink) | ✅ |
| B | A + ping slots synchronised by a GPS beacon every 128 s | beacon + `tmms` (GPS time) | 🗓️ |
| C | all the time, except while transmitting | `"imme": true` (immediately) | ✅ |

Class B needs the GPS time (PPS), not available in this firmware yet (planned for the ESP32-S3), so the gateway sends no beacons; `beacon_period` stays `0`. Classes A and C work without GPS. Full explanation (in Portuguese): [CLASSES_LORAWAN.md](CLASSES_LORAWAN.md), web page `/classes` and the 🎓 icon in the Android app.

## ChirpStack device profiles (32 examples)

The nodes that talk to this gateway need a **device profile** in ChirpStack. The project ships **32 example profiles** =
2 region configurations (`au915_0` / `au915_1`) × 2 revisions (A / B) × 2 activations (ABP / OTAA) × 4 class combinations
(A / A+B / A+B+C / A+C). Step-by-step registration (in Portuguese), field by field and for ChirpStack v3:
[CHIRPSTACK_DEVICE_PROFILES.md](CHIRPSTACK_DEVICE_PROFILES.md).

Fields that are the same in all 32 (ChirpStack v4, *Tenant → Device profiles → Add device profile*):

| Tab | Field | Value |
|---|---|---|
| General | Region / MAC version | `AU915` / `LoRaWAN 1.0.3` |
| General | ADR algorithm | `Default ADR algorithm (LoRa only)` |
| General | Flush queue on activate / Allow roaming | on / off |
| General | Expected uplink interval (secs) / Device-status request frequency (req/day) | `3600` / `1` |
| General | RX1 Delay (0 = use system default) | `0` |
| Join | RX1 delay / RX1 data-rate offset / RX2 data-rate / RX2 frequency (Hz) | `1` / `0` / `8` / `923300000` (ABP only) |
| Class-B | confirmed downlink timeout / ping-slot periodicity / data-rate / frequency | `5` / `every 128 seconds` / `8` / `0` |
| Class-C | confirmed downlink timeout | `0` |
| Codec | Payload codec | `JavaScript functions` |

The **Region configuration** must match the gateway plan: AU915 sub-band 1 (default, channels 8–15 + 65) → `AU915_1`
profiles (#17–#32); sub-band 0 (channels 0–7 + 64) → `AU915_0` profiles (#1–#16). Profiles with **Class-B** need
beacons, not sent by this firmware yet (no GPS PPS). For a Class C node prefer the **A+C** profiles.

| # | Profile name (*Name*) | Region configuration | Revision | Supports OTAA | Class-B | Class-C |
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

Legend: ✅ checked · — unchecked.

## Other Useful Documents

For other useful information, please refer to other documents included in the project, include the `README.md`, and a few others located in the folder `doc` including `esp32_sx1302_upgrade_notes.md`, `notes_tips.md` and `todo_issue_list.md`.


## Setting up ESP-IDF (Windows, Linux and macOS)

The firmware is an **ESP-IDF** project only. The reference version is **ESP-IDF v5.5.1**, the same one used by the
GitHub Actions pipeline (it also builds with 6.x). The commands of this guide and of the README assume this layout:

```
~/Apps/esp-idf/               <- ESP-IDF (git clone)
~/Apps/lorawan_workspace/     <- working folder; this project is cloned inside it
```

ESP-IDF does not accept **spaces** in its path or in the project path. On Windows, prefer short paths (`C:\Apps\...`).
The README section "Preparar o ambiente ESP-IDF" has the same steps in Portuguese, with every command.

### Linux (Ubuntu / Debian)

1. System packages (Fedora and Arch equivalents are in the README):
   ```bash
   sudo apt-get update
   sudo apt-get install -y git wget flex bison gperf python3 python3-pip python3-venv \
     cmake ninja-build ccache libffi-dev libssl-dev dfu-util libusb-1.0-0
   ```
2. ESP-IDF v5.5.1 with the tools of both boards:
   ```bash
   mkdir -p ~/Apps/lorawan_workspace && cd ~/Apps
   git clone -b v5.5.1 --recursive https://github.com/espressif/esp-idf.git
   cd esp-idf && ./install.sh esp32,esp32s3
   ```
3. In every new terminal: `. ~/Apps/esp-idf/export.sh`, then check with `idf.py --version`.
4. Serial port access (once, then log out and in): `sudo usermod -aG dialout $USER` (`uucp` on Arch).
   Ports: `/dev/ttyUSB0` (ESP32-WROOM-32U) and `/dev/ttyACM0` (ESP32-S3 native USB).
5. Clone and build:
   ```bash
   cd ~/Apps/lorawan_workspace
   git clone https://github.com/AdailSilva/Gateway_ESP32_SX1302_LR1302_HAT_Elecrow.git
   cd Gateway_ESP32_SX1302_LR1302_HAT_Elecrow
   sh scripts/build.sh esp32       # or: sh scripts/build.sh esp32s3
   ```

### macOS (Intel or Apple Silicon)

1. `xcode-select --install`, then with [Homebrew](https://brew.sh): `brew install cmake ninja dfu-util ccache python3 gnu-sed`.
2. Same `git clone` and `./install.sh esp32,esp32s3` as on Linux; activate with `. ~/Apps/esp-idf/export.sh`.
3. `scripts/gen_headers.sh` uses `sed -i` and the log commands use `\x1B`, which the macOS `sed` does not accept.
   Put GNU sed first in the `PATH`:
   `echo 'export PATH="$(brew --prefix)/opt/gnu-sed/libexec/gnubin:$PATH"' >> ~/.zshrc`.
4. Ports: `/dev/cu.usbserial-*` or `/dev/cu.wchusbserial*` (ESP32-WROOM-32U DevKit) and `/dev/cu.usbmodem*`
   (ESP32-S3 native USB); list them with `ls /dev/cu.*`.
5. The macOS `script` has another syntax (`script -q <file> <command>`, no `-c` / `-f`); the README shows the
   full command. Without a log: `sh scripts/build.sh esp32 flash /dev/cu.usbserial-0001`.

### Windows

**Option A, WSL2 + Ubuntu (recommended):** every command of the README works as on Linux.

1. In an **administrator** PowerShell: `wsl --install -d Ubuntu-24.04` and `winget install --exact dorssel.usbipd-win`.
2. Reboot, open **Ubuntu** and follow the Linux steps above (keep the files in `~/Apps`, not in `/mnt/c`).
3. Attach the board to WSL (administrator PowerShell; `bind` only the first time):
   ```powershell
   usbipd list                                     # BUSID of the board, e.g. 2-3
   usbipd bind --busid 2-3
   usbipd attach --wsl --busid 2-3 --auto-attach
   ```
   Keep that window open. `--auto-attach` is required for the ESP32-S3: its native USB port disappears and comes
   back on every reset while flashing.

**Option B, native Windows:**

1. USB-serial driver if the board is not recognized: CP210x or CH340 (links in "install Windows Driver" above).
2. Install the ESP-IDF Installation Manager: `winget install Espressif.EIM`, then install **ESP-IDF v5.5.1** in a
   short path without spaces (command line: `winget install Espressif.EIM-CLI` and `eim install -i v5.5.1`).
3. Open the **IDF_PowerShell** shortcut created by EIM and check with `idf.py --version`.
4. `scripts/*.sh` need a POSIX shell. Generate `webpage.h` and `global_json.h` with the PowerShell commands of the
   README ("Preparar o ambiente ESP-IDF" > Windows nativo), then build with `idf.py` directly:
   ```powershell
   idf.py -B build-esp32 -D SDKCONFIG=sdkconfig.esp32 -D IDF_TARGET=esp32 build
   idf.py -B build-esp32 -D SDKCONFIG=sdkconfig.esp32 -D IDF_TARGET=esp32 -p COM5 flash monitor
   ```
   For the ESP32-S3 use `build-esp32s3`, `sdkconfig.esp32s3`, `IDF_TARGET=esp32s3` and the COM port of the native USB.
   Inside the monitor, **Ctrl+T** then **Ctrl+L** saves the output to a file.


## ESP32-S3

The firmware also builds for the ESP32-S3 (the pin map lives in `main/CMakeLists.txt` and can be changed there):

```bash
# build-esp32s3/ + sdkconfig.esp32s3 (sdkconfig.defaults + sdkconfig.defaults.esp32s3);
# regenerates webpage.h / global_json.h, builds, flashes and opens the monitor
sh scripts/build.sh esp32s3 flash /dev/ttyACM0
```

Default wiring: ESP32-S3 + Elecrow LR1302 LoRaWAN HAT (SPI version), using the HAT's Raspberry Pi header.

| Function | ESP32-S3 GPIO | LR1302 HAT header pin | Notes |
|----------|---------------|-----------------------|-------|
| SX1302 MOSI | 11 | 19 | SPI2 (FSPI) |
| SX1302 MISO | 13 | 21 | |
| SX1302 SCK  | 12 | 23 | |
| SX1302 CS (CE0) | 10 | 24 | |
| SX1302 RESET | 6 | 11 | active high |
| SX1261/SX1262 CS | 7 | 31 | held HIGH so it never drives MISO |
| I2C SDA (STTS751 / OLED) | 4 | 3 | |
| I2C SCL (STTS751 / OLED) | 5 | 5 | |
| ESP TX -> GPS RX | 17 | 8 | optional, GPS switched on in the web page |
| GPS TX -> ESP RX | 18 | 10 | optional |
| 5V | 5V | 2 / 4 | the HAT does not use the header 3.3V |
| GND | GND | 6 | |
| Button 1 (Soft AP) | 0 | - | on-board BOOT button, hold right after reset |

The LR1302 HAT has no POWER_EN line (`SX1302_POWER_EN_PIN=GPIO_NUM_NC`). LEDs and button 2 are disabled by default.
GPIO 26-37 (flash/PSRAM), 19/20 (USB), 43/44 (UART0) and 3/45/46 (strapping) are intentionally not used.
On the S3 the console (logs and the `ESP32_SX1302>` command line) runs on the chip's native USB port (`/dev/ttyACM0`).


## ESP32 (classic) + LR1302 HAT

For an ESP32-WROOM-32/32U DevKit the pin map is in the `elseif(IDF_TARGET STREQUAL "esp32")` block of `main/CMakeLists.txt`
(remove that block to go back to the original ESP32_SX1302 motherboard pins).

```bash
# build-esp32/ + sdkconfig.esp32: lives side by side with the ESP32-S3 build
sh scripts/build.sh esp32 flash /dev/ttyUSB0
```

| Function | ESP32 GPIO | LR1302 HAT header pin | Notes |
|----------|------------|-----------------------|-------|
| SX1302 MOSI | 23 | 19 | VSPI (SPI3_HOST) |
| SX1302 MISO | 19 | 21 | |
| SX1302 SCK  | 18 | 23 | |
| SX1302 CS (CE0) | 5 | 24 | |
| SX1302 RESET | 4 | 11 | active high |
| SX1261/SX1262 CS | 25 | 31 | held HIGH |
| I2C SDA | 21 | 3 | |
| I2C SCL | 22 | 5 | |
| ESP TX -> GPS RX | 17 | 8 | optional, GPS switched on in the web page |
| GPS TX -> ESP RX | 16 | 10 | optional |
| 5V / GND | 5V / GND | 2 / 6 | |
| Button 1 (Soft AP) | 0 | - | on-board BOOT button |
| Status LED | 2 | - | on-board LED |

GPIO12 is not used: it is a strapping pin (flash voltage) and must stay low while the ESP32 boots.


## Settings: web page or console

The web page and the console write the same settings (NVS), so a setting made in either place is applied the same
way at boot. MQTT, the GPS, the TLS certificates and the web login are applied at once; the others after a reboot
("Reiniciar agora" on the page, or `reboot` / `config --reboot` on the console).

```
config                                          # show every saved setting
config --region au915_sb1                       # au915_sb0 | au915_sb1 | us915 | eu868 | cn470
config --radio0 917200000 --radio1 default      # radio center frequencies (default = plan default)
config --ntp br.pool.ntp.org --mode station
config --ssid MinhaRede-4G --wifi-pass secret123 --host ns.example.com --port 1700
config --gwid E45F01FFFE10E12E               # override the Gateway EUI (16 hex)
config --gwid auto                              # back to the automatic EUI (Wi-Fi MAC + FFFE)
config --reboot                                 # reboot to apply
reboot
```

## GPS of the LR1302 HAT

The GPS of the HAT (NMEA, UART1 at 9600 baud) is switched on and off at run time, **without a reboot**:

- web page, section **GPS**: choose **Ligado** / **Desligado** and click **Salvar**;
- console: `gps on`, `gps off` (or `config --gps on|off`); `gps` alone prints the status.

The setting is saved in NVS as `gps_en` (default `off`). `GPS_DISABLE` is no longer set in `main/CMakeLists.txt`;
add it there only to build a firmware without GPS.

Wiring: HAT pin 10 (GPS TX) -> ESP32 **GPIO16** / ESP32-S3 **GPIO18** (RX); HAT pin 8 (GPS RX) <- **GPIO17** (TX).

The section shows the live status (every 5 s, from `GET /status`, object `gps`): latitude, longitude, altitude,
satellites, NMEA sentences ok / with errors, bytes received and the age of the last data. When nothing arrives it
names the pin and GPIO to check; on the console the same case prints
`WARNING: [gps] no data from the GPS for N s (check HAT pin 10 -> ESP32 GPIO16, GND and 5 V)` every 10 s.

With a fix, the coordinates go in the statistics (`lati` / `long` / `alti` of the UDP `stat`, `location` of the
ChirpStack `event/stats`), so ChirpStack shows the gateway on its map. Switched off, the gateway drops the
position, the GPS time reference and the XTAL correction, and stops sending coordinates.

![ChirpStack v4 gateway dashboard: the map marker is placed by the GPS of the HAT](images/chirpstack_gateway_mapa_gps.png)

How the position reaches ChirpStack:

1. The Quectel L76K of the HAT (GPS, BeiDou, GLONASS) sends NMEA at 9600 baud to UART1 (512-byte RX buffer).
2. `thread_gps` reads it, checks the checksum and parses:
   - `GGA` (`$GNGGA`, `$GPGGA`, ...): latitude, longitude, altitude, satellites and fix quality. Quality `0` means
     no fix, and the coordinates are dropped.
   - `RMC` (`$GNRMC`, ...): UTC time/date and status A/V. Both the 13-field form (NMEA 2.3/4.0) and the
     14-field form (NMEA 4.10, with *navStatus*) are accepted. The L76K uses NMEA 4.10; before this was fixed,
     every RMC was ignored and the position was never published.
   - Other sentences (`GSV`, `GSA`, `VTG`, `ZDA`, `TXT`) are counted as valid and ignored.
3. The position is refreshed on every GGA/RMC (1 Hz) and sent with the next statistics (`stat_interval`,
   30 s by default):
   - MQTT, ChirpStack v4 format: `<region>/gateway/<id>/event/stats`, field `location` (`source: GPS`), as
     Protobuf or JSON;
   - UDP: `stat.lati/long/alti` in `PUSH_DATA`.
4. ChirpStack updates the gateway location from the stats. Without a fix, the stats carry no `location`, and
   ChirpStack keeps the last known position.

Time reference: the PPS pulse is not wired to the firmware yet, so `gps_process_sync()` is compiled only with
`GPS_PPS_GPIO` defined. Without the PPS, the SX1302 trigger counter is stale and the reference would be wrong. The
reference stays invalid (`"tref":false`). This only matters for Class B, GPS-timed downlinks and `tmms`; the
position and Class A/C are not affected.

Measured on an ESP32-WROOM-32U with MQTTS, the web page and the concentrator running: ~33 KB free heap before
the GPS starts and ~27 KB after (the GPS costs ~5.5 KB). One minute after starting, `thread_gps` reports
~2.2 KB of its 3584-byte stack never used.

The PPS is not used yet, so the GPS time reference stays invalid; the position does not depend on it.

**GPS and MQTT (RAM).** On the ESP32 without PSRAM the MQTTS (TLS) handshake needs ~25-40 KB of heap and does
not fit together with the GPS: it failed with `Dynamic Impl: alloc(...) failed` and
`mbedtls_ssl_handshake returned -0x2700` (*cert 0x8*, which looks like a certificate problem but is RAM). So the
GPS (UART driver + one task, `thread_gps`, ~5 KB; the old `thread_valid` now runs inside it) exists only while
it may use that RAM:

- with MQTT enabled it starts only once the MQTT session is connected (checked every 5 s), at boot and when
  switched on from the web page / console; the page shows *GPS ligado, aguardando a conexão MQTT…* meanwhile
  and `/status` reports `"wait":true`;
- before every MQTT connection attempt (`MQTT_EVENT_BEFORE_CONNECT`, hook `mqtt_gw_set_before_connect_cb()`)
  and as soon as the session drops, the task releases the UART, deletes itself and gives the RAM back; after
  the reconnection the GPS starts again and looks for the position from scratch;
- with MQTT disabled (UDP) it starts right after the forwarder threads;
- switched off, nothing of the GPS stays in RAM.

```
INFO: [gps] GPS start deferred until the MQTT connection (the TLS handshake needs the RAM)
I (...) gw_mqtt: connected to the broker
INFO: [heap] before GPS start: free ..., largest block ..., minimum ever ... bytes
INFO: [gps] GPS switched on: UART1 9600 baud, ESP32 RX GPIO16 <- HAT pin 10, TX GPIO17 -> HAT pin 8
INFO: [gps] thread_gps: N of 3584 bytes of stack never used          (one minute later)
INFO: [gps] thread_gps ended (MQTT disconnected, the TLS handshake needs the RAM); ...
```

`sdkconfig.defaults.esp32` (classic ESP32 only) also frees RAM: 6 Wi-Fi static RX buffers instead of 10
and no A-MPDU on RX. It applies to a new
`sdkconfig.esp32`: delete `sdkconfig.esp32` and `build-esp32/` once before building.

```
gps                 # status: GPS: {"built":true,"cfg":true,"on":true,"fix":true,"sat":9,"lat":-3.731862,...}
gps on              # switch on now and save
gps off             # switch off now and save
```

## MQTT over TLS

Besides the Semtech UDP forwarding, the gateway can publish to an MQTT broker, optionally over TLS
(`main/packet_forwarder/mqtt_gw.c`). Configure it in the web page (section "MQTT seguro (TLS)") or on the serial console.

**UDP and MQTT are exclusive**: with MQTT enabled the gateway sends only by MQTT and the UDP forwarder is off;
with MQTT disabled it sends only by UDP (the host / port of "Servidor LoRaWAN" are kept for that).

Two formats ("Formato" in the web page, `mqtt --format` on the console):

### ChirpStack v4 (`chirpstack`)

The gateway speaks the ChirpStack v4 gateway protocol directly (the messages the ChirpStack Gateway Bridge
publishes, in JSON). No Gateway Bridge and no UDP port are needed.
Base topic default: `<region>/gateway/<gateway EUI in lower case>`, e.g. `au915_1/gateway/e45f01fffe10e12e`
(the region prefix must be the one of the ChirpStack region: AU915 SB0 = `au915_0`, SB1 = `au915_1`).

| Topic | Message |
|-------|---------|
| `<base>/event/up` | UplinkFrame (one per received packet) |
| `<base>/event/stats` | GatewayStats (every stats interval, 30 s) - this is what makes the gateway "online" |
| `<base>/event/ack` | DownlinkTxAck |
| `<base>/state/conn` | ConnState ONLINE / OFFLINE (retained, last will) |
| `<base>/command/down` | DownlinkFrame (subscribed): the alternatives (RX1, RX2) are tried in order |

Encoding ("Codificação" in the web page, `mqtt --encoding json|protobuf` on the console): **JSON** (default,
readable in any MQTT client) or **Protobuf** (binary, smaller, the same as the Gateway Bridge). ChirpStack v4 accepts
both: it detects JSON when the payload contains `gatewayId`, and answers each gateway in the encoding of its last
event. The gateway reads the downlinks in either encoding. The MQTT user of the gateway needs publish rights on `<base>/event/#` and `<base>/state/#` and subscribe
rights on `<base>/command/#`. ChirpStack v3 is not supported by this mode (different JSON); use the UDP forwarder.

### Semtech mirror (`semtech`, default)

Semtech JSON of the UDP protocol, uplinks and statistics only (no downlinks). Topics (base topic default `gateway/<Gateway ID>`):

| Topic | Payload |
|-------|---------|
| `<base>/up` | `{"gw":"<id>","rxpk":[...]}` (Semtech JSON of the received packets), QoS 1 |
| `<base>/stats` | `{"gw":"<id>","stat":{...}}` every stats interval, QoS 1 |
| `<base>/state` | `online` / `offline` (retained, last will) |

TLS: with `mqtts://` and no CA installed, the broker certificate is checked against the ESP-IDF public CA bundle
(Let's Encrypt etc.). Install the broker CA for a private PKI; install client certificate + key for mutual TLS.
Certificates are stored in NVS (namespace `mqtt_tls`), max 8 KB each.

Console:

```
mqtt                                              # status
mqtt --on --uri mqtts://broker.example.com:8883 --user gw01 --pass secret
mqtt --topic lorawan/gw01      mqtt --clear-topic  mqtt --off
mqtt --format chirpstack --topic au915_1/gateway/e45f01fffe10e12e
mqtt --encoding protobuf        mqtt --encoding json
mqtt --format semtech
mqtt_cert ca                                      # then paste the PEM
mqtt_cert crt / mqtt_cert key                     # client certificate / key (mutual TLS)
mqtt_cert ca clear                                # remove
```

Changes made on the console, by "Salvar" on the web page or by uploading a certificate are applied immediately.


## Logs in the web page

Open `http://<gateway IP>/logs` (or the "Logs" link at the top of the configuration page). It shows the same output
as the serial console, updated every 1.5 s, with filter, pause and auto-scroll. The last 16 KB are kept in RAM
(`WEBLOG_SIZE` in `main/packet_forwarder/weblog.h`); older lines are discarded. Two download buttons: "Baixar do gateway" (`/logs_download`, everything still in the gateway RAM) and
"Baixar sessão" (everything the page received since it was opened, up to 3000 lines). Messages printed before the
first boot step (bootloader, `cpu_start`) only appear on the serial port.

Secrets never go to this log (it can be downloaded and shared): the `Authorization` header of the browser is not
logged, the Soft AP password and the password of a `mqtts://user:pass@host` broker URI appear masked, and the
serial console session (what is typed, e.g. `web_auth --pass ...`, and the command replies) stays on the serial
port only. To see the full values, use the serial console.

