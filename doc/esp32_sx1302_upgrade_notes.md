# Notes for Gateway ESP32_SX1302 Upgrade

These notes cover flashing the **ready-made binaries** of a GitHub Release (version 0.0.1 onwards). Flashing a
binary does not need ESP-IDF, only `esptool`. To build the firmware yourself, see the README section
"Preparar o ambiente ESP-IDF" or "Setting up ESP-IDF" in [user_guide.md](user_guide.md).


## firmware upgrade preparation

Make sure you have `Python 3` installed in your PC, then install `esptool`:
```shell
pip install esptool
```

If it fails, try `python -m pip install esptool` or `pip3 install esptool`. Check it with `esptool.py version`
(or `python -m esptool version`). Inside an activated ESP-IDF terminal, `esptool.py` is already available.


## release files

Each Release publishes, for each board (`esp32` = ESP32-WROOM-32U DevKit, `esp32s3` = ESP32-S3-WROOM-2 N32R16V DevKit):

| File | Use |
|---|---|
| `Gateway_ESP32_SX1302_LR1302_HAT_Elecrow-<version>-<board>-full.bin` | single image, write at `0x0` |
| `Gateway_ESP32_SX1302_LR1302_HAT_Elecrow-<version>-<board>-app.bin` | application only, write at `0x10000` |
| `Gateway_ESP32_SX1302_LR1302_HAT_Elecrow-<version>-<board>-parts.zip` | bootloader, partition table and application, with `flash_args` |
| `SHA256SUMS.txt` | checksums |


## upgrade firmware

Change the port to the right one: `/dev/ttyUSB0` (ESP32-WROOM-32U) or `/dev/ttyACM0` (ESP32-S3 native USB) on
Linux, `/dev/cu.usbserial-*` / `/dev/cu.usbmodem*` on macOS, `COMx` on Windows.

### Full upgrade (factory state)

Use it on a new board or to start from scratch. The single image fills the NVS area with `0xFF`, so the gateway
goes back to the factory settings, MQTT certificates included (Soft AP `lorawan-gateway-sx1302`, page at
`http://192.168.101.101`, login `admin` / `lorawan101`):
```shell
esptool.py --chip esp32   -p /dev/ttyUSB0 write_flash 0x0 Gateway_ESP32_SX1302_LR1302_HAT_Elecrow-<version>-esp32-full.bin
esptool.py --chip esp32s3 -p /dev/ttyACM0 write_flash 0x0 Gateway_ESP32_SX1302_LR1302_HAT_Elecrow-<version>-esp32s3-full.bin
```

### Application upgrade (keeps the configuration)

Writes only the application, so the configuration saved in NVS (Wi-Fi, server, MQTT and certificates, radio,
GPS, login) is kept:
```shell
esptool.py --chip esp32   -p /dev/ttyUSB0 write_flash 0x10000 Gateway_ESP32_SX1302_LR1302_HAT_Elecrow-<version>-esp32-app.bin
esptool.py --chip esp32s3 -p /dev/ttyACM0 write_flash 0x10000 Gateway_ESP32_SX1302_LR1302_HAT_Elecrow-<version>-esp32s3-app.bin
```

### Separate parts

Extract the `-parts.zip` and, inside the extracted folder, run `esptool.py --chip <board> -p <port> write_flash @flash_args`.

**Note:** if you get `Failed to connect to ESP32: Timed out waiting for packet header` or `Wrong boot mode detected`,
hold the **BOOT** button of the DevKit, run the command again and release the button when the writing starts.
