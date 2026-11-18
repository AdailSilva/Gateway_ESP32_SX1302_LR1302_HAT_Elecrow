#!/usr/bin/env python3
"""Mapa das barras do U1 para as três DevKits: em que pino de cada placa cada rede da placa adaptadora é soldada.

Vista de cima, USB para baixo (a mesma das figuras de pinagem em doc/images/).
Ordem: ESP32-WROOM-32U, ESP32-S3-WROOM-1U-N16R8, ESP32-S3-WROOM-2-N32R16V.

uso:  python3 gen_devkit_map.py   (gera esp32_lr1302_adapter_devkit_pins.svg)
"""
import os
from gen_adapter import NETS, C, SANS, MONO, T

HERE = os.path.dirname(os.path.abspath(__file__))

# barras de cada DevKit, de cima para baixo (USB embaixo): (número impresso no doc, nome)
WROOM32U_L = [(1, "3V3"), (2, "EN"), (3, "GPIO36"), (4, "GPIO39"), (5, "GPIO34"), (6, "GPIO35"), (7, "GPIO32"), (8, "GPIO33"),
              (9, "GPIO25"), (10, "GPIO26"), (11, "GPIO27"), (12, "GPIO14"), (13, "GPIO12"), (14, "GND"), (15, "GPIO13"),
              (16, "GPIO9"), (17, "GPIO10"), (18, "GPIO11"), (19, "5V")]
WROOM32U_R = [(38, "GND"), (37, "GPIO23"), (36, "GPIO22"), (35, "GPIO1"), (34, "GPIO3"), (33, "GPIO21"), (32, "GND"),
              (31, "GPIO19"), (30, "GPIO18"), (29, "GPIO5"), (28, "GPIO17"), (27, "GPIO16"), (26, "GPIO4"), (25, "GPIO0"),
              (24, "GPIO2"), (23, "GPIO15"), (22, "GPIO8"), (21, "GPIO7"), (20, "GPIO6")]
S3_L = [(i + 1, n) for i, n in enumerate(["3V3", "3V3", "RST", "GPIO4", "GPIO5", "GPIO6", "GPIO7", "GPIO15", "GPIO16", "GPIO17",
                                          "GPIO18", "GPIO8", "GPIO3", "GPIO46", "GPIO9", "GPIO10", "GPIO11", "GPIO12",
                                          "GPIO13", "GPIO14", "5V", "GND"])]
S3_R = [(i + 1, n) for i, n in enumerate(["GND", "GPIO43", "GPIO44", "GPIO1", "GPIO2", "GPIO42", "GPIO41", "GPIO40", "GPIO39",
                                          "GPIO38", "GPIO37", "GPIO36", "GPIO35", "GPIO0", "GPIO45", "GPIO48", "GPIO47",
                                          "GPIO21", "GPIO20", "GPIO19", "GND", "GND"])]

BOARDS = [
    ("ESP32-WROOM-32U", "esp32 · DevKitC 38 pinos (2 × 19)", "pinos 1–38", 4, WROOM32U_L, WROOM32U_R, ("", ""), "#334155"),
    ("ESP32-S3-WROOM-1U-N16R8", "esp32s3_n16r8 · DevKitC-1 (2 × 22)", "J1 1–22 · J3 1–22", 5, S3_L, S3_R, ("J1-", "J3-"), "#1d4ed8"),
    ("ESP32-S3-WROOM-2-N32R16V", "esp32s3_n32r16v · DevKitC-1 (2 × 22)", "J1 1–22 · J3 1–22", 6, S3_L, S3_R, ("J1-", "J3-"), "#4338ca"),
]

SHORT = {"MOSI": "MOSI", "MISO": "MISO", "SCLK": "SCLK", "CS_SX1302": "CS 1302", "RESET_SX1302": "RESET",
         "CS_SX1261": "CS 1261", "I2C_SDA": "SDA", "I2C_SCL": "SCL", "GPS_RXD": "GPS RXD", "GPS_TXD": "GPS TXD"}


def usage(col):
    """nome do pino → (cor, rótulo) para a coluna de GPIO `col` (4, 5 ou 6 em NETS)."""
    u = {}
    for n in NETS:
        u[n[col]] = (C[n[1]], f"{SHORT[n[0]]} → {n[2]}")
    u["5V"] = (C["pwr"], "+5V_DEVKIT (JP1)")
    u["GND"] = (C["gnd"], "GND")
    u["3V3"] = (C["v33"], "3V3 → R2–R5, J3")
    return u


def panel(x0, y0, b):
    name, sub, num, col, L, R, pre, accent = b
    u = usage(col)
    PW, ROW = 600, 34
    n = max(len(L), len(R))
    o = [f'<rect x="{x0}" y="{y0}" width="{PW}" height="{200 + n*ROW + 40}" rx="14" fill="#f8fafc" stroke="#e2e8f0" stroke-width="2"/>',
         f'<rect x="{x0}" y="{y0}" width="{PW}" height="8" rx="4" fill="{accent}"/>',
         T(x0 + PW / 2, y0 + 42, name, 19, "#0f172a", "middle", "700"),
         T(x0 + PW / 2, y0 + 66, sub, 12.5, "#475569", "middle", "normal", MONO),
         T(x0 + PW / 2, y0 + 86, f"numeração: {num}", 11.5, "#64748b")]
    bx, bw = x0 + PW / 2 - 70, 140
    by = y0 + 160
    bh = n * ROW + 40
    o.append(f'<rect x="{bx}" y="{by-58}" width="{bw}" height="{bh+58}" rx="10" fill="#0f172a"/>')
    o.append(f'<rect x="{bx+22}" y="{by-48}" width="{bw-44}" height="44" rx="4" fill="#94a3b8" fill-opacity="0.35" stroke="#cbd5e1"/>')
    o.append(T(bx + bw / 2, by - 22, "módulo", 11, "#e2e8f0"))
    o.append(f'<rect x="{bx+bw/2-22}" y="{by+bh-6}" width="44" height="20" rx="4" fill="#94a3b8"/>')
    o.append(T(bx + bw / 2, by + bh + 30, "USB", 11.5, "#334155", "middle", "700"))
    for side, pins in (("L", L), ("R", R)):
        for i, (num_, pin) in enumerate(pins):
            y = by + 26 + i * ROW
            cx = bx + 12 if side == "L" else bx + bw - 12
            used = u.get(pin)
            fill = used[0] if used else "#475569"
            o.append(f'<circle cx="{cx}" cy="{y}" r="{7 if used else 5}" fill="{fill}" stroke="#fff" stroke-width="{2 if used else 1}"/>')
            numtxt = f"{pre[0] if side == 'L' else pre[1]}{num_}"
            o.append(T(cx + (18 if side == "L" else -18), y + 4, numtxt, 9.5, "#94a3b8", "start" if side == "L" else "end", "normal", MONO))
            if side == "L":
                o.append(T(bx - 8, y + 4.5, pin, 12, "#0f172a" if used else "#94a3b8", "end", "700" if used else "normal", MONO))
                if used:
                    o.append(T(bx - 78, y + 4.5, used[1], 11.5, used[0], "end", "700"))
            else:
                o.append(T(bx + bw + 8, y + 4.5, pin, 12, "#0f172a" if used else "#94a3b8", "start", "700" if used else "normal", MONO))
                if used:
                    o.append(T(bx + bw + 78, y + 4.5, used[1], 11.5, used[0], "start", "700"))
    return "\n".join(o), 200 + n * ROW + 40


def main():
    W = 1900
    o = []
    x = 25
    hmax = 0
    body = []
    for b in BOARDS:
        s, h = panel(x, 120, b)
        body.append(s)
        hmax = max(hmax, h)
        x += 625
    H = 120 + hmax + 170
    o.append(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}" role="img" aria-label="Pinos de cada DevKit na placa adaptadora">')
    o.append('<title>Placa adaptadora ESP32 ↔ LR1302 HAT — onde soldar cada rede nas barras do U1, para as três DevKits</title>')
    o.append(f'<rect x="1" y="1" width="{W-2}" height="{H-2}" rx="14" fill="#fff" stroke="#e2e8f0" stroke-width="2"/>')
    o.append(T(W / 2, 46, "U1 · onde soldar cada fio na barra de cada DevKit", 25, "#0f172a", "middle", "700"))
    o.append(T(W / 2, 76, "Vista de cima, USB para baixo · rótulo = rede → pino do J1 (header do LR1302 HAT) · os dois S3 usam a mesma DevKitC-1 e os mesmos pinos; só o firmware muda", 14, "#475569"))
    o.extend(body)
    ly = 120 + hmax + 40
    items = [("spi", "SPI (SX1302)"), ("ctl", "RESET / CS do SX1261"), ("i2c", "I2C (STTS751 + OLED)"), ("gps", "UART do GPS"),
             ("pwr", "+5V_DEVKIT (via JP1)"), ("v33", "3V3 da DevKit (só R2–R5 e J3)"), ("gnd", "GND")]
    lx = 60
    for k, lbl in items:
        o.append(f'<circle cx="{lx}" cy="{ly}" r="7" fill="{C[k]}"/>' + T(lx + 14, ly + 4.5, lbl, 13, "#334155", "start", "600"))
        lx += 40 + len(lbl) * 7.4
    notes = ["• Ligue pelo menos dois GND da DevKit ao GND da placa (um de cada barra), para o retorno do SPI ficar curto.",
             "• WROOM-32U: quase tudo fica na barra da direita (VSPI 18/19/23/5). Nos S3, tudo fica na barra J1 (esquerda), menos o GND.",
             "• O 3V3 da DevKit nunca vai ao J1: no LR1302 HAT os pinos 1 e 17 são NC; o HAT gera os próprios 3,3 V a partir dos 5 V."]
    for i, s in enumerate(notes):
        o.append(T(60, ly + 38 + i * 24, s, 13, "#475569", "start"))
    o.append("</svg>\n")
    open(os.path.join(HERE, "esp32_lr1302_adapter_devkit_pins.svg"), "w", encoding="utf-8").write("\n".join(o))
    print("ok")


if __name__ == "__main__":
    main()
