#!/usr/bin/env python3
"""Desenho de posicionamento (vista de cima, componentes) da placa adaptadora na placa perfurada 70 × 90 mm.
Escala 1 mm = 8 px. Coordenadas em mm a partir do canto inferior esquerdo da placa perfurada.

Medidas do Elecrow LR1302 HAT tiradas do datasheet (../lr1302_hat/LR1302_LoRaWAN_Hat_for_RPI_DataSheet.pdf,
figuras 1 e 4). Coordenadas do HAT: x a partir da borda esquerda, y a partir da borda do header (vista de cima,
header embaixo, SMA à direita). Contorno 65 × 57,2 mm do datasheet; o resto foi medido nas fotos (± 1 mm):
CONFERIR encaixando o HAT antes de soldar.
"""
import os
HERE = os.path.dirname(os.path.abspath(__file__))
SANS = "'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif"
MONO = "ui-monospace, SFMono-Regular, Menlo, Consolas, 'Liberation Mono', monospace"
K = 8.0
PX, PY = 70.0, 90.0
OX, OY = 120, 210          # margem do desenho (px)

# ---- LR1302 HAT (mm, coordenadas do HAT) -------------------------------------------------
HAT_W, HAT_H = 65.0, 57.2
HAT_X0, HAT_Y0 = (PX - HAT_W) / 2, PY - HAT_H          # posição do HAT na placa perfurada
HAT_HOLES = [(3.5, 3.5), (61.5, 3.5), (3.5, 52.5), (61.5, 52.5)]   # padrão HAT, 58 × 49 mm
HDR_Y = 3.5                                            # centro do header entre as duas fileiras
PIN1_X = 32.5 + 24.13                                  # pino 1 na ponta da DIREITA (lado dos SMA)
SMA = [("LoRa", 46.0), ("GPS", 11.2)]                  # centro dos SMA na borda direita (y no HAT)
FAN = (20.8, 11.3, 45.8, 36.3)                         # ventoinha 25 × 25 × 7 mm, face de BAIXO do HAT
BAT = (0.5, 18.0, 15.0, 39.0)                          # suporte da CR1220, face de BAIXO do HAT
FAN_SOCKET = (10.0, 44.0, 14.0, 48.0)                  # conector da ventoinha, face de baixo
MPCIE_SCREWS = [(54.2, 16.9), (54.2, 41.0)]            # parafusos do módulo LR1302 (cabeça embaixo)
USBC_X = 51.7                                          # USB-C do HAT na borda de cima (não usado)


def X(mm): return OX + mm * K
def Y(mm): return OY + (PY - mm) * K   # y para cima
def hx(x): return HAT_X0 + x
def hy(y): return HAT_Y0 + y


def esc(s): return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def T(x, y, s, size=13, fill="#0f172a", anchor="middle", weight="normal", font=SANS):
    return f'<text x="{x:.1f}" y="{y:.1f}" font-family="{font}" font-size="{size}" fill="{fill}" text-anchor="{anchor}" font-weight="{weight}">{esc(s)}</text>'


def rect(x0, y0, x1, y1, fill, stroke, dash="", rx=4, op=1, sw=2):
    d = f' stroke-dasharray="{dash}"' if dash else ""
    return (f'<rect x="{X(x0):.1f}" y="{Y(y1):.1f}" width="{(x1-x0)*K:.1f}" height="{(y1-y0)*K:.1f}" rx="{rx}" '
            f'fill="{fill}" fill-opacity="{op}" stroke="{stroke}" stroke-width="{sw}"{d}/>')


W = int(OX * 2 + PX * K + 560)
H = int(OY + PY * K + 140)
o = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}" role="img" aria-label="Posicionamento na placa perfurada">',
     '<title>Placa adaptadora ESP32 ↔ LR1302 HAT — posicionamento na placa perfurada 70 × 90 mm</title>',
     '<defs><marker id="a" viewBox="0 0 10 10" refX="5" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse"><path d="M0 0L10 5L0 10z" fill="#334155"/></marker>'
     '<pattern id="ko" width="10" height="10" patternUnits="userSpaceOnUse" patternTransform="rotate(45)"><rect width="10" height="10" fill="#fee2e2"/><line x1="0" y1="0" x2="0" y2="10" stroke="#f87171" stroke-width="3"/></pattern></defs>',
     f'<rect x="1" y="1" width="{W-2}" height="{H-2}" rx="14" fill="#fff" stroke="#e2e8f0" stroke-width="2"/>',
     T(W / 2, 44, "Placa adaptadora — posicionamento na placa perfurada 70 × 90 mm (vista de cima)", 22, "#0f172a", "middle", "700"),
     T(W / 2, 72, "Medidas em mm · LR1302 HAT 65 × 57,2 mm (datasheet Elecrow) · áreas hachuradas: ventoinha e CR1220 ficam EMBAIXO do HAT, 11 mm acima da placa", 13.5, "#475569")]

# placa perfurada com grade
o.append(rect(0, 0, PX, PY, "#fef3c7", "#b45309", rx=6))
g = []
x = 1.27
while x < PX:
    y = 1.27
    while y < PY:
        g.append(f'<circle cx="{X(x):.1f}" cy="{Y(y):.1f}" r="1.3" fill="#d6b36a"/>')
        y += 2.54
    x += 2.54
o.append("".join(g))
for cx, cy in ((2.5, 2.5), (PX - 2.5, 2.5), (2.5, PY - 2.5), (PX - 2.5, PY - 2.5)):
    o.append(f'<circle cx="{X(cx):.1f}" cy="{Y(cy):.1f}" r="{1.6*K:.1f}" fill="#fff" stroke="#92400e" stroke-width="2"/>')

# áreas proibidas sob o HAT (ventoinha, CR1220, conector da ventoinha, parafusos do módulo)
o.append(rect(hx(FAN[0]), hy(FAN[1]), hx(FAN[2]), hy(FAN[3]), "url(#ko)", "#dc2626", rx=4, op=0.9))
o.append(T(X(hx((FAN[0] + FAN[2]) / 2)), Y(hy((FAN[1] + FAN[3]) / 2)) - 6, "ventoinha 25×25×7", 12, "#991b1b", "middle", "700"))
o.append(T(X(hx((FAN[0] + FAN[2]) / 2)), Y(hy((FAN[1] + FAN[3]) / 2)) + 12, "nada com mais de 2 mm", 11, "#991b1b", "middle", "600"))
o.append(rect(hx(BAT[0]), hy(BAT[1]), hx(BAT[2]), hy(BAT[3]), "url(#ko)", "#dc2626", rx=4, op=0.9))
o.append(T(X(hx((BAT[0] + BAT[2]) / 2)), Y(hy((BAT[1] + BAT[3]) / 2)) - 4, "CR1220", 12, "#991b1b", "middle", "700"))
o.append(T(X(hx((BAT[0] + BAT[2]) / 2)), Y(hy((BAT[1] + BAT[3]) / 2)) + 12, "≤ 5 mm", 11, "#991b1b", "middle", "600"))
o.append(rect(hx(FAN_SOCKET[0]), hy(FAN_SOCKET[1]), hx(FAN_SOCKET[2]), hy(FAN_SOCKET[3]), "url(#ko)", "#dc2626", rx=2, op=0.9))
for sx, sy in MPCIE_SCREWS:
    o.append(f'<circle cx="{X(hx(sx)):.1f}" cy="{Y(hy(sy)):.1f}" r="{2.5*K:.1f}" fill="url(#ko)" stroke="#dc2626" stroke-width="2"/>')

# contorno do HAT (tracejado, fica 11 mm acima)
o.append(rect(HAT_X0, HAT_Y0, HAT_X0 + HAT_W, PY, "#7e22ce", "#7e22ce", dash="10 6", op=0.07))
o.append(T(X(hx(32.5)), Y(hy(54.0)) + 2, "Elecrow LR1302 HAT (65 × 57,2 mm)", 14, "#7e22ce", "middle", "700"))
o.append(T(X(hx(32.5)), Y(hy(54.0)) + 18, "11 mm acima, em espaçadores M2.5", 11, "#7e22ce"))
for x_, y_ in HAT_HOLES:
    o.append(f'<circle cx="{X(hx(x_)):.1f}" cy="{Y(hy(y_)):.1f}" r="{1.4*K:.1f}" fill="#fff" stroke="#7e22ce" stroke-width="2.5"/>')
    o.append(T(X(hx(x_)), Y(hy(y_)) + 4, "M2.5", 9.5, "#7e22ce", "middle", "700"))
# USB-C do HAT (borda de cima, sem uso)
o.append(rect(hx(USBC_X) - 4.5, PY - 1.5, hx(USBC_X) + 4.5, PY + 1.5, "#cbd5e1", "#64748b", rx=2))
o.append(T(X(hx(USBC_X)), Y(PY) - 22, "USB-C do HAT (não usar)", 10.5, "#475569", "middle", "600"))
# SMA na borda direita
for lbl, sy in SMA:
    yy = hy(sy)
    o.append(f'<rect x="{X(HAT_X0 + HAT_W):.1f}" y="{Y(yy)-3.2*K:.1f}" width="{10*K:.1f}" height="{6.4*K:.1f}" rx="3" fill="#d4af37" stroke="#92400e" stroke-width="1.5"/>')
    o.append(T(X(HAT_X0 + HAT_W + 11), Y(yy) + 4.5, f"SMA {lbl}", 12, "#92400e", "start", "700"))
    o.append(T(X(HAT_X0 + HAT_W + 11), Y(yy) + 20, f"y = {yy:.1f} mm", 10.5, "#92400e", "start", "normal", MONO))

# J1 2x20 — pino 1 na ponta da direita, fileira ímpar por dentro (lado do centro do HAT)
COL = {"spi": "#2563eb", "ctl": "#ea580c", "i2c": "#16a34a", "gps": "#9333ea", "pwr": "#dc2626", "gnd": "#9ca3af", "nc": "#111827"}
PINC = {19: "spi", 21: "spi", 23: "spi", 24: "spi", 11: "ctl", 31: "ctl", 3: "i2c", 5: "i2c", 8: "gps", 10: "gps",
        2: "pwr", 4: "pwr", 1: "nc", 17: "nc"}
for p_ in (6, 9, 14, 20, 25, 30, 34, 39):
    PINC[p_] = "gnd"
jy = hy(HDR_Y)
o.append(rect(hx(PIN1_X) - 48.26 - 1.3, jy - 2.6, hx(PIN1_X) + 1.3, jy + 2.6, "#111827", "#111827", rx=3))
for pin in range(1, 41):
    i = (pin - 1) // 2
    px_ = hx(PIN1_X) - i * 2.54
    py_ = jy + (1.27 if pin % 2 else -1.27)
    c = COL[PINC[pin]] if pin in PINC else "#fbbf24"
    o.append(f'<circle cx="{X(px_):.1f}" cy="{Y(py_):.1f}" r="3.6" fill="{c}" stroke="{"#fbbf24" if pin in (1, 17) else "none"}" stroke-width="1.5"/>')
o.append(T(X(hx(PIN1_X)) + 4, Y(jy + 1.27) - 12, "1", 12, "#111827", "middle", "800"))
o.append(T(X(hx(PIN1_X)) + 4, Y(jy - 1.27) + 22, "2", 12, "#111827", "middle", "800"))
o.append(T(X(hx(PIN1_X) - 48.26) - 6, Y(jy - 1.27) + 22, "40", 12, "#111827", "middle", "800"))
o.append(T(X(hx(PIN1_X) - 24), Y(jy - 2.6) + 18, "J1 (2×20) · pino 1 = ponta do lado dos SMA (quadrado, '3V3' = NC)", 11.5, "#111827", "middle", "700"))

# DevKit (faixa inferior)
o.append(rect(0.5, 3.5, 63.5, 29.5, "#0f172a", "#0f172a", op=0.88, rx=6))
o.append(T(X(32), Y(19), "U1 · DevKit ESP32 / ESP32-S3", 15, "#fff", "middle", "700"))
o.append(T(X(32), Y(19) + 20, "WROOM-32U (2×19) · S3 N16R8 / S3 N32R16V (2×22)", 12, "#cbd5e1"))
o.append(T(X(32), Y(19) + 38, "em 2 barras fêmeas (meça a distância entre fileiras)", 12, "#cbd5e1"))
o.append(rect(-3.5, 10, 4, 22, "#94a3b8", "#475569", rx=3))
o.append(T(X(0.25), Y(16) + 4, "USB", 12, "#1f2937", "middle", "700"))

# componentes (fora das áreas proibidas)
items = [
    (4.0, 39.5, 20.0, 44.5, "#f8fafc", "#475569", "R1–R5 (deitados)", 10),
    (4.0, 45.5, 9.0, 48.5, "#fff7ed", "#dc2626", "JP1", 10),
    (49.0, 39.5, 61.0, 45.5, "#fee2e2", "#dc2626", "C1 470µF (deitado)", 10),
    (62.0, 43.0, 66.0, 45.5, "#fee2e2", "#dc2626", "C2", 9.5),
    (26.0, 78.0, 32.0, 82.5, "#fee2e2", "#dc2626", "F1", 10),
    (65.0, 6.0, 69.5, 17.0, "#dcfce7", "#16a34a", "J3", 11),
]
for x0, y0, x1, y1, f, s, lbl, fs in items:
    o.append(rect(x0, y0, x1, y1, f, s, rx=3))
    o.append(T(X((x0 + x1) / 2), Y((y0 + y1) / 2) + 4, lbl, fs, s, "middle", "700"))
# J2 na parede de cima (fora da placa)
o.append(rect(26.0, PY + 3.0, 34.0, PY + 11.0, "#fee2e2", "#dc2626", rx=3))
o.append(T(X(30), Y(PY + 7) + 4, "J2", 12, "#dc2626", "middle", "700"))
o.append(T(X(35), Y(PY + 7) + 4, "jack DC na parede de cima, acima do HAT · fios até F1", 11, "#dc2626", "start", "600"))
o.append(f'<path d="M{X(30)} {Y(PY+3)} V{Y(82.5)}" stroke="#dc2626" stroke-width="2" stroke-dasharray="5 4"/>')

# cotas
o.append(f'<path d="M{X(0)} {Y(0)+30} H{X(PX)}" stroke="#334155" stroke-width="1.5" marker-start="url(#a)" marker-end="url(#a)"/>')
o.append(T(X(PX / 2), Y(0) + 50, "70 mm", 13, "#334155", "middle", "700"))
o.append(f'<path d="M{X(0)-40} {Y(0)} V{Y(PY)}" stroke="#334155" stroke-width="1.5"/>')
o.append(T(X(0) - 50, Y(PY / 2), "90 mm", 13, "#334155", "end", "700"))

# legenda / passos
lx = X(PX) + 210
steps = ["1. Encaixe o LR1302 HAT no J1 (2×20 macho, pinos longos)",
         "   com os 4 espaçadores M2.5 × 11 mm e marque os furos.",
         "2. Fure a placa perfurada nos 4 furos M2.5 (Ø 2,7 mm).",
         "3. Solde o J1 com o HAT encaixado (alinhamento).",
         "   O pino 1 fica na ponta do lado dos SMA.",
         "4. Solde as barras fêmeas do U1 na distância da DevKit.",
         "5. Ligue pela face de solda, fios curtos:",
         "   MOSI, MISO, SCLK, CS, RESET, CS SX1261, I2C, GPS.",
         "   R3 no CS do SX1261 e R4/R5 no I2C (ao 3V3 da DevKit).",
         "6. +5V: J2 → F1 → pinos 2/4 do J1 e C1/C2;",
         "   JP1 leva o +5V ao 5V/VIN da DevKit.",
         "7. GND: todos os pinos GND do J1 + DevKit + J2.",
         "8. Nada alto nas áreas hachuradas: a ventoinha",
         "   (7 mm) e a CR1220 ficam embaixo do HAT.",
         "9. Antes de encaixar: confira com o multímetro que os",
         "   pinos 1 e 17 (NC no HAT) do J1 estão SEM ligação.",
         "",
         "Cores no J1:  azul SPI · laranja RESET (11) / CS SX1261 (31)",
         "verde I2C (3/5) · roxo GPS · vermelho 5V · cinza GND · preto NC"]
for k, s in enumerate(steps):
    o.append(T(lx, Y(PY) + 10 + k * 24, s, 13, "#475569" if s.startswith(("Cores", "verde")) else "#334155",
               "start", "600" if s[:2] in ("1.", "2.", "3.", "4.", "5.", "6.", "7.", "8.", "9.") else "normal"))
open(os.path.join(HERE, "esp32_lr1302_adapter_layout.svg"), "w", encoding="utf-8").write("\n".join(o) + "\n</svg>\n")
print("ok")
