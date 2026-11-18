#!/usr/bin/env python3
"""Caixa paramétrica do ESP32_SX1302 (Elecrow LR1302 LoRaWAN HAT + DevKit ESP32/ESP32-S3).

Montagem prevista (vista de cima, x para a direita, y para cima):

                    DC (parede +y, acima do HAT)
    y=90 ┌──────────────────────────────────────┐
         │   LR1302 HAT (65 × 57,2 mm)          │ ◄─ SMA LoRa (y ≈ 79)
 ar  ◄──│   empilhado na placa adaptadora      │
 (rasgos)│   (header 2×20 macho, espaçadores    │
         │    M2.5 × 11 mm); ventoinha embaixo  │ ◄─ SMA GPS (y ≈ 44)
    y≈33 ├──────────────────────────────────────┤
  USB ◄──│   DevKit ESP32 / ESP32-S3 em barras  │
         │   fêmeas (faixa de 70 × 33 mm)       │
    y=0  └──────────────────────────────────────┘
         x=0                                  x=70     (placa perfurada 70 × 90 mm)

Gera, na pasta deste script:
  esp32_sx1302_bottom_case.step / .stl
  esp32_sx1302_top_case.step / .stl
  esp32_sx1302_top_case.dxf          (contorno 2D da tampa, para corte a laser em acrílico)

uso:  pip install cadquery   &&   python3 case_sx1302.py

⚠️ O contorno do HAT (65 × 57,2 mm) é do datasheet da Elecrow; a posição dos SMA foi medida na figura 1
   do datasheet (± 1 mm), e as medidas marcadas com "CONFERIR" vêm do padrão Raspberry Pi HAT.
   Meça o seu HAT e a sua DevKit com paquímetro e ajuste antes de imprimir.
"""
import os
import cadquery as cq

# ------------------------------------------------------------------ parâmetros
WALL = 2.2          # espessura das paredes
FLOOR = 2.0         # espessura do fundo
CLR = 1.5           # folga entre a placa perfurada e a parede
END = 8.0           # espaço extra nas pontas em y, onde ficam as torres dos parafusos da tampa

PERF_X, PERF_Y = 70.0, 90.0       # placa perfurada padrão 7 × 9 cm
PERF_HOLE_INSET = 2.5             # CONFERIR: centro dos furos de canto a partir da borda
PERF_STANDOFF = 5.0               # altura dos pinos de apoio da placa perfurada
PERF_T = 1.6

HAT_X, HAT_Y = 65.0, 57.2         # datasheet Elecrow LR1302 HAT (65 × 57,2 mm)
HAT_X0 = (PERF_X - HAT_X) / 2     # posição do shield sobre a placa perfurada
HAT_Y0 = PERF_Y - HAT_Y
HAT_STACK = 11.0                  # espaçador M2.5 × 11 mm (header 2×20 empilhado)
SMA_Y = (78.8, 44.0)              # SMA LoRa e SMA GPS na borda +x (em y), medidos na figura 1 do datasheet (± 1 mm)
SMA_SLOT_W = 7.0                  # largura do rasgo em U (rosca 1/4" = 6,35 mm)

DEVKIT_FEMALE_H = 8.5             # barra fêmea 2,54 mm
USB_W, USB_H = 32.0, 11.0         # abertura para o(s) USB da DevKit (S3 tem 2 USB-C)
USB_Y = 16.5                      # centro da abertura (meio da faixa da DevKit)
DC_D = 8.0                        # furo do jack DC 5,5 × 2,1 de painel
DC_X = 30.0                       # jack DC na parede de cima (+y), acima do HAT (longe do USB-C do HAT, x ≈ 54)
SIDE_VENTS = (45.0, 80.0, 6)      # rasgos na parede x = 0, entre a placa e o HAT: entrada de ar da ventoinha

INNER_H = 38.0                    # altura interna (até a tampa): HAT + módulo LR1302 (a ventoinha fica embaixo do HAT)
LID_T = 2.2
LIP = 1.6                         # aba da tampa que entra na caixa
SCREW_BOSS_D = 7.0
SCREW_PILOT = 2.5                 # M3 autoatarraxante (ou 4,0 para inserto)
LID_SCREW = 3.4

OLED_WIN = (26.0, 15.0)           # janela opcional para o OLED SSD1306 0,96"
OLED_POS = (PERF_X / 2, 16.5)     # sobre a faixa da DevKit
VENT_N, VENT_W, VENT_L = 9, 2.0, 40.0   # ventilação sobre o módulo LR1302

# ------------------------------------------------------------------ derivadas
IN_X = PERF_X + 2 * CLR
IN_Y = PERF_Y + 2 * CLR + 2 * END
OUT_X = IN_X + 2 * WALL
OUT_Y = IN_Y + 2 * WALL
OUT_H = FLOOR + INNER_H
OX, OY = WALL + CLR, WALL + CLR + END      # origem da placa perfurada no sistema da caixa

z_perf_top = FLOOR + PERF_STANDOFF + PERF_T
z_hat_pcb = z_perf_top + HAT_STACK
z_sma = z_hat_pcb + PERF_T / 2
z_usb = z_perf_top + DEVKIT_FEMALE_H + PERF_T + 2.0
z_dc = z_hat_pcb + PERF_T + 7.0                # acima do HAT (os componentes da borda de cima do HAT têm ≤ 3 mm)


def bottom():
    box = (cq.Workplane("XY").box(OUT_X, OUT_Y, OUT_H, centered=False)
           .edges("|Z").fillet(3.0))
    cavity = (cq.Workplane("XY").workplane(offset=FLOOR)
              .center(WALL, WALL).rect(IN_X, IN_Y, centered=False).extrude(INNER_H + 1)
              .edges("|Z").fillet(1.5))
    body = box.cut(cavity)

    # apoios da placa perfurada
    pts = [(OX + PERF_HOLE_INSET, OY + PERF_HOLE_INSET), (OX + PERF_X - PERF_HOLE_INSET, OY + PERF_HOLE_INSET),
           (OX + PERF_HOLE_INSET, OY + PERF_Y - PERF_HOLE_INSET), (OX + PERF_X - PERF_HOLE_INSET, OY + PERF_Y - PERF_HOLE_INSET)]
    posts = (cq.Workplane("XY").workplane(offset=FLOOR).pushPoints(pts)
             .circle(3.2).circle(SCREW_PILOT / 2).extrude(PERF_STANDOFF))
    body = body.union(posts)

    # torres dos parafusos da tampa (cantos internos)
    c = 4.0
    tpts = [(WALL + c, WALL + c), (WALL + IN_X - c, WALL + c), (WALL + c, WALL + IN_Y - c), (WALL + IN_X - c, WALL + IN_Y - c)]
    towers = (cq.Workplane("XY").workplane(offset=FLOOR).pushPoints(tpts)
              .circle(SCREW_BOSS_D / 2).extrude(INNER_H - LIP))
    holes = (cq.Workplane("XY").workplane(offset=FLOOR + 3).pushPoints(tpts)
             .circle(SCREW_PILOT / 2).extrude(INNER_H))
    body = body.union(towers).cut(holes)

    # rasgos em U para os SMA (parede +x), abertos para cima
    for y in SMA_Y:
        yy = OY + y
        u = (cq.Workplane("YZ").workplane(offset=OUT_X - WALL - 1)
             .center(yy, z_sma).circle(SMA_SLOT_W / 2).extrude(WALL + 2))
        u2 = (cq.Workplane("YZ").workplane(offset=OUT_X - WALL - 1)
              .center(yy, (z_sma + OUT_H) / 2 + 1).rect(SMA_SLOT_W, OUT_H - z_sma + 2).extrude(WALL + 2))
        body = body.cut(u).cut(u2)

    # USB da DevKit e jack DC (parede x = 0)
    usb = (cq.Workplane("YZ").workplane(offset=-1).center(OY + USB_Y, z_usb)
           .rect(USB_W, USB_H).extrude(WALL + 2).edges("|X").fillet(2.0))
    dc = cq.Workplane("XY").add(cq.Solid.makeCylinder(DC_D / 2, WALL + 4, cq.Vector(OX + DC_X, OUT_Y - WALL - 2, z_dc), cq.Vector(0, 1, 0)))
    body = body.cut(usb).cut(dc)

    # entrada de ar da ventoinha (parede x = 0, entre a placa perfurada e o HAT)
    y0, y1, n = SIDE_VENTS
    zc = (z_perf_top + z_hat_pcb) / 2
    for i in range(n):
        yy = OY + y0 + i * (y1 - y0) / (n - 1)
        v = (cq.Workplane("YZ").workplane(offset=-1).center(yy, zc)
             .slot2D(HAT_STACK - 3.0, 2.2, angle=90).extrude(WALL + 2))
        body = body.cut(v)

    # furos de fixação na parede/mesa (fundo)
    feet = (cq.Workplane("XY").workplane(offset=-1).pushPoints([(OUT_X / 2, OUT_Y * 0.25), (OUT_X / 2, OUT_Y * 0.75)])
            .circle(2.2).extrude(FLOOR + 2))
    return body.cut(feet)


def top():
    plate = (cq.Workplane("XY").box(OUT_X, OUT_Y, LID_T, centered=False).edges("|Z").fillet(3.0))
    lip = (cq.Workplane("XY").workplane(offset=-LIP).center(WALL + 0.25, WALL + 0.25)
           .rect(IN_X - 0.5, IN_Y - 0.5, centered=False).extrude(LIP)
           .faces("<Z").shell(-1.4))
    lid = plate.union(lip)
    c = 4.0
    tpts = [(WALL + c, WALL + c), (WALL + IN_X - c, WALL + c), (WALL + c, WALL + IN_Y - c), (WALL + IN_X - c, WALL + IN_Y - c)]
    # recortes da aba em volta das torres + furos dos parafusos
    clear = (cq.Workplane("XY").workplane(offset=-LIP - 1).pushPoints(tpts).circle(SCREW_BOSS_D / 2 + 0.6).extrude(LIP + 1))
    screws = (cq.Workplane("XY").workplane(offset=-LIP - 1).pushPoints(tpts).circle(LID_SCREW / 2).extrude(LID_T + LIP + 2))
    lid = lid.cut(clear).cut(screws)
    # janela do OLED
    win = (cq.Workplane("XY").workplane(offset=-1).center(OX + OLED_POS[0], OY + OLED_POS[1])
           .rect(*OLED_WIN).extrude(LID_T + 2))
    # ventilação sobre o LR1302 HAT
    vy0 = OY + HAT_Y0 + HAT_Y / 2
    vents = (cq.Workplane("XY").workplane(offset=-1)
             .pushPoints([(OX + PERF_X / 2 + (i - (VENT_N - 1) / 2) * 5.0, vy0) for i in range(VENT_N)])
             .slot2D(VENT_L, VENT_W, angle=90).extrude(LID_T + 2))
    return lid.cut(win).cut(vents)


def lid_outline():
    """Contorno 2D da tampa (sem a aba), para corte a laser."""
    c = 4.0
    tpts = [(WALL + c, WALL + c), (WALL + IN_X - c, WALL + c), (WALL + c, WALL + IN_Y - c), (WALL + IN_X - c, WALL + IN_Y - c)]
    vy0 = OY + HAT_Y0 + HAT_Y / 2
    s = (cq.Workplane("XY").rect(OUT_X, OUT_Y, centered=False).extrude(LID_T).edges("|Z").fillet(3.0)
         .faces(">Z").workplane().pushPoints([(x - OUT_X / 2, y - OUT_Y / 2) for x, y in tpts]).hole(LID_SCREW))
    s = s.cut(cq.Workplane("XY").workplane(offset=-1).center(OX + OLED_POS[0], OY + OLED_POS[1]).rect(*OLED_WIN).extrude(LID_T + 2))
    s = s.cut(cq.Workplane("XY").workplane(offset=-1)
              .pushPoints([(OX + PERF_X / 2 + (i - (VENT_N - 1) / 2) * 5.0, vy0) for i in range(VENT_N)])
              .slot2D(VENT_L, VENT_W, angle=90).extrude(LID_T + 2))
    return s.section(LID_T / 2)


if __name__ == "__main__":
    here = os.path.dirname(os.path.abspath(__file__))
    b, t = bottom(), top()
    for name, obj in (("esp32_sx1302_bottom_case", b), ("esp32_sx1302_top_case", t)):
        cq.exporters.export(obj, os.path.join(here, name + ".step"))
        cq.exporters.export(obj, os.path.join(here, name + ".stl"), tolerance=0.05, angularTolerance=0.1)
    cq.exporters.export(lid_outline(), os.path.join(here, "esp32_sx1302_top_case.dxf"))
    print(f"caixa externa: {OUT_X:.1f} × {OUT_Y:.1f} × {OUT_H + LID_T:.1f} mm")
    print(f"centro dos SMA: z = {z_sma:.1f} mm do fundo · USB: z = {z_usb:.1f} mm · DC (parede +y): z = {z_dc:.1f} mm")
