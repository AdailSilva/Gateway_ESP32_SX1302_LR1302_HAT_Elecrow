#!/usr/bin/env python3
"""Placa adaptadora ESP32 ↔ Elecrow LR1302 LoRaWAN HAT (SX1302): esquema (SVG), netlist e BOM (CSV).

Serve para as três placas do projeto, nesta ordem:
  esp32            ESP32-WROOM-32U DevKitC (38 pinos)
  esp32s3_n16r8    ESP32-S3-WROOM-1U-N16R8 DevKitC-1 (2 × 22)
  esp32s3_n32r16v  ESP32-S3-WROOM-2-N32R16V DevKitC-1 (2 × 22)

A pinagem é a de main/CMakeLists.txt. Se mudar lá, mude aqui (tabela NETS) e rode de novo:
    python3 gen_adapter.py && python3 gen_layout.py && python3 gen_devkit_map.py
"""
import csv, os

HERE = os.path.dirname(os.path.abspath(__file__))
SANS = "'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif"
MONO = "ui-monospace, SFMono-Regular, Menlo, Consolas, 'Liberation Mono', monospace"
C = dict(spi="#2563eb", ctl="#ea580c", i2c="#16a34a", gps="#9333ea", pwr="#dc2626", gnd="#1f2937", v33="#b45309")

# rede, cor, pino J1 (header RPi do HAT), nome no HAT, esp32, esp32s3_n16r8, esp32s3_n32r16v, sentido (ESP → HAT = ">")
NETS = [
    ("MOSI", "spi", "19", "MOSI", "GPIO23", "GPIO11", "GPIO11", ">"),
    ("MISO", "spi", "21", "MISO", "GPIO19", "GPIO13", "GPIO13", "<"),
    ("SCLK", "spi", "23", "SCLK", "GPIO18", "GPIO12", "GPIO12", ">"),
    ("CS_SX1302", "spi", "24", "CE0", "GPIO5", "GPIO10", "GPIO10", ">"),
    ("RESET_SX1302", "ctl", "11", "RESET", "GPIO4", "GPIO6", "GPIO6", ">"),
    ("CS_SX1261", "ctl", "31", "SX1262_CSN", "GPIO25", "GPIO7", "GPIO7", ">"),
    ("I2C_SDA", "i2c", "3", "SDA", "GPIO21", "GPIO4", "GPIO4", "<>"),
    ("I2C_SCL", "i2c", "5", "SCL", "GPIO22", "GPIO5", "GPIO5", ">"),
    ("GPS_RXD", "gps", "8", "GPS_RXD", "GPIO17", "GPIO17", "GPIO17", ">"),
    ("GPS_TXD", "gps", "10", "GPS_TXD", "GPIO16", "GPIO18", "GPIO18", "<"),
]

# observação de cada rede no esquema (resistores da placa)
NOTE = {
    "CS_SX1302": "R2 10 kΩ → 3V3_DEVKIT (opcional)",
    "RESET_SX1302": "R1 10 kΩ → GND (opcional)",
    "CS_SX1261": "R3 10 kΩ → 3V3_DEVKIT (recomendado)",
    "I2C_SDA": "R4 4,7 kΩ → 3V3_DEVKIT · J3.4 (OLED)",
    "I2C_SCL": "R5 4,7 kΩ → 3V3_DEVKIT · J3.3 (OLED)",
}

NETLIST = [
    # rede, J1, esp32, esp32s3_n16r8, esp32s3_n32r16v, outros
    ("MOSI", "19", "GPIO23", "GPIO11", "GPIO11", ""),
    ("MISO", "21", "GPIO19", "GPIO13", "GPIO13", ""),
    ("SCLK", "23", "GPIO18", "GPIO12", "GPIO12", ""),
    ("CS_SX1302", "24", "GPIO5", "GPIO10", "GPIO10", "R2 (10 kΩ pull-up para 3V3_DEVKIT, opcional)"),
    ("RESET_SX1302", "11", "GPIO4", "GPIO6", "GPIO6", "R1 (10 kΩ pull-down, opcional); ativo alto"),
    ("CS_SX1261", "31", "GPIO25", "GPIO7", "GPIO7", "R3 (10 kΩ pull-up para 3V3_DEVKIT, recomendado); não pode ficar solto"),
    ("I2C_SDA", "3", "GPIO21", "GPIO4", "GPIO4", "R4 (4,7 kΩ pull-up para 3V3_DEVKIT); J3.4 (OLED SDA); STTS751 no módulo LR1302"),
    ("I2C_SCL", "5", "GPIO22", "GPIO5", "GPIO5", "R5 (4,7 kΩ pull-up para 3V3_DEVKIT); J3.3 (OLED SCL)"),
    ("GPS_RXD", "8", "GPIO17", "GPIO17", "GPIO17", "TX do ESP32 → RX do GPS (L76K)"),
    ("GPS_TXD", "10", "GPIO16", "GPIO18", "GPIO18", "TX do GPS → RX do ESP32"),
    ("+5V", "2, 4", "", "", "", "F1.2; C1+; C2; JP1.1"),
    ("+5V_DEVKIT", "", "5V / VIN", "5V", "5V", "JP1.2"),
    ("+5V_IN", "", "", "", "", "J2 (pino central do jack DC); F1.1"),
    ("3V3_DEVKIT", "— (NÃO ligar aos pinos 1 e 17)", "3V3", "3V3", "3V3", "J3.1 (OLED VCC); R2; R3; R4; R5"),
    ("GND", "6, 9, 14, 20, 25, 30, 34, 39", "GND", "GND", "GND", "J2 (corpo); C1−; C2; R1; J3.2"),
    ("NC", "1, 17 (NC no HAT)", "", "", "", "não ligar"),
    ("NC", "12 (SX1262_BUSY), 16 (SX1262_IO1), 18 (SX1262_IO2), 29 (SX1262_RST)", "", "", "", "não ligar: o SX1262 fica desligado do SPI pelo pino 31"),
    ("NC", "22 (GPS_RST, ativo baixo), 32 (GPS_WAKE_UP)", "", "", "", "não ligar: o firmware não usa"),
    ("NC", "27, 28 (ID_SD / ID_SC da EEPROM de ID do HAT)", "", "", "", "não ligar"),
    ("NC", "7, 13, 15, 26, 33, 35–38, 40 (NC no HAT)", "", "", "", "não ligar"),
]

BOM = [
    ("J1", 1, "Barra de pinos macho 2×20, passo 2,54 mm (pinos longos, 11 mm acima da placa)", "2×20", "recebe o LR1302 HAT como num Raspberry Pi"),
    ("U1", 2, "Barra de pinos fêmea 1×19 (ESP32-WROOM-32U DevKitC) ou 1×22 (ESP32-S3-DevKitC-1: N16R8 e N32R16V)", "1×19 / 1×22", "meça a distância entre as fileiras da sua DevKit antes de soldar"),
    ("J2", 1, "Jack DC fêmea 5,5 × 2,1 mm de painel", "5 V", "entrada da fonte 5 V / 2 A (centro positivo); fica na parede de cima da caixa, acima do HAT"),
    ("F1", 1, "Fusível rearmável (PTC) 2 A, ou fio direto", "2 A hold", "opcional"),
    ("C1", 1, "Capacitor eletrolítico (Ø 8 mm, montado deitado)", "470 µF / 10 V", "picos de corrente no TX do SX1250 (PA); fora da área da ventoinha"),
    ("C2", 1, "Capacitor cerâmico", "100 nF", "junto ao J1"),
    ("JP1", 1, "Barra 1×2 + jumper", "5V_DEVKIT", "fechado: a fonte alimenta a DevKit; aberto: a DevKit usa o USB do PC (GND continua comum)"),
    ("R1", 1, "Resistor 1/4 W", "10 kΩ", "opcional: segura o RESET do SX1302 em nível baixo enquanto o ESP32 inicia"),
    ("R2", 1, "Resistor 1/4 W", "10 kΩ", "opcional: CS do SX1302 em nível alto durante o boot"),
    ("R3", 1, "Resistor 1/4 W", "10 kΩ", "recomendado: CS do SX1261 em nível alto (não disputa o SPI)"),
    ("R4, R5", 2, "Resistor 1/4 W", "4,7 kΩ", "pull-ups do I2C (o HAT não tem; no RPi eles ficam no Pi)"),
    ("J3", 1, "Barra fêmea 1×4 (VCC, GND, SCL, SDA)", "OLED", "opcional: display SSD1306 0,96\" I2C, no mesmo barramento do STTS751"),
    ("PCB", 1, "Placa perfurada (ilhada) 70 × 90 mm, furos de canto de 3 mm", "7×9 cm", "cabe na caixa de ../case/"),
    ("H1–H4", 4, "Espaçador M2.5 × 11 mm + parafusos M2.5", "M2.5 × 11", "fixa o HAT sobre a placa (padrão HAT, furos 58 × 49 mm)"),
    ("H5–H8", 4, "Parafuso M3 × 6 mm autoatarraxante", "M3", "placa perfurada nos apoios da caixa"),
    ("—", 1, "Fio rígido AWG 26–28 (ou cabinho) para as ligações na face de solda", "", "ligações SPI curtas (< 5 cm na placa)"),
]


def esc(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def T(x, y, s, size=13, fill="#0f172a", anchor="middle", weight="normal", font=SANS):
    return (f'<text x="{x:.1f}" y="{y:.1f}" font-family="{font}" font-size="{size}" fill="{fill}" '
            f'text-anchor="{anchor}" font-weight="{weight}">{esc(s)}</text>')


def schematic():
    W, H = 1500, 1240
    o = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}" role="img" aria-label="Esquema da placa adaptadora ESP32 ↔ LR1302 HAT">',
         '<title>Placa adaptadora ESP32 ↔ Elecrow LR1302 LoRaWAN HAT (SX1302) — esquema</title>',
         '<defs><filter id="sh" x="-5%" y="-5%" width="110%" height="115%"><feDropShadow dx="0" dy="2" stdDeviation="3" flood-color="#0f172a" flood-opacity="0.18"/></filter>'
         '<linearGradient id="pcb" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#1e293b"/><stop offset="1" stop-color="#0f172a"/></linearGradient>'
         '<linearGradient id="hat" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#065f46"/><stop offset="1" stop-color="#022c22"/></linearGradient></defs>',
         f'<rect x="1" y="1" width="{W-2}" height="{H-2}" rx="14" fill="#fff" stroke="#e2e8f0" stroke-width="2"/>',
         T(W / 2, 44, "Placa adaptadora ESP32 ↔ Elecrow LR1302 LoRaWAN HAT — esquema", 24, "#0f172a", "middle", "700"),
         T(W / 2, 72, "Placa perfurada 70 × 90 mm · o HAT encaixa no J1 como num Raspberry Pi · a DevKit encaixa no U1 · lógica de 3,3 V", 14, "#475569")]

    # U1 (três colunas de GPIO) e J1
    ux, uw, jx, jw = 60, 420, 1120, 320
    top, bot = 110, 110 + 140 + len(NETS) * 54 + 30
    o.append(f'<rect x="{ux}" y="{top}" width="{uw}" height="{bot-top}" rx="12" fill="url(#pcb)" filter="url(#sh)"/>')
    o.append(T(ux + uw / 2, top + 26, "U1 · DevKit ESP32 / ESP32-S3", 15, "#fff", "middle", "700"))
    o.append(T(ux + uw / 2, top + 45, "barras fêmeas · um GPIO por placa (mesma rede, mesmo fio no J1)", 11.5, "#cbd5e1"))
    cols = [(ux + 120, "esp32", "WROOM-32U", "#ffffff"), (ux + 250, "esp32s3_n16r8", "S3 N16R8", "#93c5fd"), (ux + 380, "esp32s3_n32r16v", "S3 N32R16V", "#a5b4fc")]
    for cx, b, lbl, col in cols:
        o.append(T(cx, top + 78, lbl, 12, col, "end", "700"))
        o.append(T(cx, top + 94, b, 10, "#94a3b8", "end", "normal", MONO))
    o.append(f'<rect x="{jx}" y="{top}" width="{jw}" height="{bot-top}" rx="12" fill="url(#hat)" filter="url(#sh)"/>')
    o.append(T(jx + jw / 2, top + 26, "J1 · conector 2×20 (RPi)", 15, "#fff", "middle", "700"))
    o.append(T(jx + jw / 2, top + 45, "Elecrow LR1302 LoRaWAN HAT (SPI)", 11.5, "#a7f3d0"))
    o.append(T(jx + jw / 2, top + 62, "SX1302 + SX1250 · SX1261 · STTS751 · GPS L76K", 11, "#a7f3d0"))

    x0, x1 = ux + uw, jx
    xm = (x0 + x1) / 2
    y = top + 140
    for net, col, j1, hname, e32, n16, n32, d in NETS:
        c = C[col]
        for (cx, *_), g in zip(cols, (e32, n16, n32)):
            o.append(T(cx, y + 4.5, g, 12.5, _[2], "end", "700", MONO))
        dash = ' stroke-dasharray="8 6"' if col == "gps" else ""
        o.append(f'<circle cx="{x0}" cy="{y}" r="5.5" fill="{c}" stroke="#fff" stroke-width="2"/>')
        o.append(f'<line x1="{x0+6}" y1="{y}" x2="{x1-6}" y2="{y}" stroke="{c}" stroke-width="3.5"{dash}/>')
        if d in (">", "<>"):
            o.append(f'<path d="M{xm+46} {y} l-12 -7 v14 z" fill="{c}"/>')
        if d in ("<", "<>"):
            o.append(f'<path d="M{xm-46} {y} l12 -7 v14 z" fill="{c}"/>')
        w = len(net) * 6.8 + 20
        o.append(f'<rect x="{xm - w/2:.1f}" y="{y-26}" width="{w:.1f}" height="18" rx="9" fill="{c}"/>' + T(xm, y - 12.8, net, 11.5, "#fff", "middle", "600"))
        o.append(f'<circle cx="{x1}" cy="{y}" r="5.5" fill="{c}" stroke="#fff" stroke-width="2"/>')
        o.append(T(x1 + 16, y + 4.5, f"{j1:>2} · {hname}", 12.5, "#fff", "start", "700", MONO))
        if net in NOTE:
            # resistor desenhado sobre a linha
            rx = x0 + 70
            if net == "RESET_SX1302":
                o.append(f'<path d="M{rx} {y} V{y+6}" stroke="{c}" stroke-width="2"/><rect x="{rx-6}" y="{y+6}" width="12" height="18" rx="2" fill="#fff" stroke="{c}" stroke-width="2"/>'
                         f'<path d="M{rx} {y+24} V{y+28} M{rx-8} {y+28} H{rx+8} M{rx-5} {y+32} H{rx+5} M{rx-2} {y+36} H{rx+2}" stroke="{C["gnd"]}" stroke-width="2"/>')
            elif net in ("CS_SX1302", "CS_SX1261", "I2C_SDA", "I2C_SCL"):
                o.append(f'<path d="M{rx} {y} V{y+6}" stroke="{c}" stroke-width="2"/><rect x="{rx-6}" y="{y+6}" width="12" height="18" rx="2" fill="#fff" stroke="{c}" stroke-width="2"/>'
                         f'<path d="M{rx} {y+24} V{y+30}" stroke="{C["v33"]}" stroke-width="2"/><circle cx="{rx}" cy="{y+31}" r="2.6" fill="{C["v33"]}"/>')
            o.append(T(rx + 14, y + 22, NOTE[net], 11, "#475569", "start", "600"))
        y += 54
    # 5V e GND de U1
    o.append(f'<circle cx="{ux}" cy="{bot-34}" r="5" fill="{C["pwr"]}" stroke="#fff" stroke-width="2"/>')
    o.append(T(ux + 12, bot - 30, "5V / VIN", 12, "#fca5a5", "start", "700", MONO))
    o.append(T(ux + 12, bot - 12, "3V3_DEVKIT → R2–R5, J3 (nunca ao J1)", 11, "#fcd34d", "start", "600"))

    # alimentação
    yb = bot + 50
    o.append(T(60, yb, "ALIMENTAÇÃO", 13, C["pwr"], "start", "700"))
    o.append('<rect x="60" y="%d" width="140" height="70" rx="10" fill="#fef2f2" stroke="%s" stroke-width="2"/>' % (yb + 20, C["pwr"]))
    o.append(T(130, yb + 48, "J2 · jack DC", 13, C["pwr"], "middle", "700") + T(130, yb + 68, "5 V / 2 A (+ no centro)", 11, "#475569"))
    o.append(f'<line x1="200" y1="{yb+45}" x2="300" y2="{yb+45}" stroke="{C["pwr"]}" stroke-width="3.5"/>')
    o.append(f'<rect x="300" y="{yb+33}" width="60" height="24" rx="4" fill="#fff" stroke="{C["pwr"]}" stroke-width="2"/>' + T(330, yb + 50, "F1 2A", 11.5, C["pwr"], "middle", "700"))
    o.append(f'<line x1="360" y1="{yb+45}" x2="{x1-6}" y2="{yb+45}" stroke="{C["pwr"]}" stroke-width="3.5"/>')
    o.append(T(760, yb + 36, "+5V", 12, C["pwr"], "middle", "700"))
    o.append(f'<circle cx="{x1}" cy="{yb+45}" r="5.5" fill="{C["pwr"]}" stroke="#fff" stroke-width="2"/>' + T(x1 + 16, yb + 49.5, " 2 / 4 · 5V", 12.5, C["pwr"], "start", "700", MONO))
    for x, lbl in ((480, "C1 470µF/10V"), (620, "C2 100nF")):
        o.append(f'<path d="M{x} {yb+45} V{yb+80} M{x-14} {yb+80} H{x+14} M{x-14} {yb+88} H{x+14} M{x} {yb+88} V{yb+110} M{x-10} {yb+110} H{x+10} M{x-6} {yb+115} H{x+6} M{x-2} {yb+120} H{x+2}" stroke="#334155" stroke-width="2" fill="none"/>')
        o.append(T(x + 20, yb + 90, lbl, 11, "#475569", "start", "600"))
    o.append(f'<path d="M880 {yb+45} V{yb+95}" stroke="{C["pwr"]}" stroke-width="3"/>')
    o.append(f'<rect x="860" y="{yb+95}" width="40" height="26" rx="5" fill="#fff7ed" stroke="{C["pwr"]}" stroke-width="2"/>' + T(880, yb + 113, "JP1", 11.5, C["pwr"], "middle", "700"))
    o.append(f'<path d="M880 {yb+121} V{yb+150} H40 V{bot-34} H{ux-5}" fill="none" stroke="{C["pwr"]}" stroke-width="3"/>')
    o.append(T(460, yb + 166, "+5V_DEVKIT (via JP1)", 11.5, C["pwr"], "middle", "700"))
    o.append(T(910, yb + 113, "fechado: fonte → DevKit · aberto: DevKit pelo USB", 11, "#475569", "start"))
    # GND
    o.append(f'<path d="M60 {yb+195} H{x1-6}" stroke="{C["gnd"]}" stroke-width="3.5"/>')
    o.append(f'<circle cx="{x1}" cy="{yb+195}" r="5.5" fill="{C["gnd"]}" stroke="#fff" stroke-width="2"/>' + T(x1 + 16, yb + 199.5, "6,9,14,20,25,30,34,39 · GND", 12, C["gnd"], "start", "700", MONO))
    o.append(T(60, yb + 187, "GND comum: J2 (corpo), C1−, C2, R1, J3, GND da DevKit", 11.5, "#334155", "start", "600"))

    # OLED + avisos
    yo = yb + 228
    o.append('<rect x="60" y="%d" width="600" height="118" rx="10" fill="#f0fdf4" stroke="%s" stroke-width="2"/>' % (yo, C["i2c"]))
    o.append(T(80, yo + 24, "I2C · STTS751 do LR1302 + OLED opcional (J3)", 13, C["i2c"], "start", "700"))
    o.append(T(80, yo + 48, "J3.1 VCC ← 3V3_DEVKIT · J3.2 GND · J3.3 SCL · J3.4 SDA", 12, "#14532d", "start", "600"))
    o.append(T(80, yo + 70, "SDA = GPIO21 / GPIO4 / GPIO4 · SCL = GPIO22 / GPIO5 / GPIO5", 12, "#14532d", "start", "600", MONO))
    o.append(T(80, yo + 94, "o barramento vai também aos pinos 3/5 do J1 · R4/R5 4,7 kΩ: o HAT não tem pull-ups", 11.5, "#475569", "start"))
    o.append('<rect x="690" y="%d" width="750" height="118" rx="10" fill="#fffbeb" stroke="#f59e0b" stroke-width="1.5"/>' % yo)
    for k, s in enumerate(["⚠ Não ligar os pinos 1 e 17 (3V3) do J1: no LR1302 HAT eles são NC.",
                           "   12, 16, 18, 22, 27–29 e 32 também ficam sem ligação (firmware não usa).",
                           "⚠ CS do SX1261 (pino 31) nunca solto: sem ele o SX1261 disputa o SPI.",
                           "⚠ Com JP1 fechado e o USB do PC ligado, a fonte fica em paralelo com o",
                           "   VBUS: abra o JP1 no desenvolvimento, se a DevKit não tiver diodo no VBUS."]):
        o.append(T(708, yo + 24 + k * 21, s, 12, "#78350f", "start", "600" if s.startswith("⚠") else "normal"))
    return "\n".join(o) + "\n</svg>\n"


def write_csv(name, header, rows):
    with open(os.path.join(HERE, name), "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(header)
        w.writerows(rows)


if __name__ == "__main__":
    open(os.path.join(HERE, "esp32_lr1302_adapter_schematic.svg"), "w", encoding="utf-8").write(schematic())
    write_csv("esp32_lr1302_adapter_netlist.csv",
              ["rede", "J1 (pino do header RPi)", "U1 esp32 (ESP32-WROOM-32U)", "U1 esp32s3_n16r8 (ESP32-S3-WROOM-1U-N16R8)",
               "U1 esp32s3_n32r16v (ESP32-S3-WROOM-2-N32R16V)", "outros"], NETLIST)
    write_csv("esp32_lr1302_adapter_bom.csv", ["ref", "qtd", "descrição", "valor", "observação"], BOM)
    print("ok")
