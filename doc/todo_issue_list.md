# Todo List

Below are potential improvements (contributions are welcome). The ESP32-S3 items are in the README roadmap.

- A simple online user guide (just a page linked to the web UI).
- improve the safety of Wifi by encrypting both ssid and password.
- GPS of the LR1302 HAT (Quectel L76K): wire the PPS pulse to a GPIO and use the GPS time reference (Class B, `tmms`).
- Verify/update/merge test code under `main/libloragw-test/` and `main/test`.

Already done in v0.0.1: web login reset (`web_auth --reset`), factory defaults (web page and
`factory_reset --yes`), configuration export/import as JSON (web page and Android app).


# Issue List

Below are limitations or issues of the gateway:

- Wifi username and password only work with ASCII characters, doesn't support other UTF-8 characters.
