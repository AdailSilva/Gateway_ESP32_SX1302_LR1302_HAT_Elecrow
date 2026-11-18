# Projeto de referência SX1302 (Semtech CoreCell)

O módulo LR1302 do HAT da Elecrow segue o **CoreCell** da Semtech: SX1302 (banda base digital) + SX1250 (rádios) + rádio auxiliar SX1261/SX1262 (LBT e *spectral scan*; no LR1302 é um SX1262, segundo o datasheet da Elecrow). O projeto original deste porte trazia nesta pasta o pacote de produção do CoreCell na versão **CN470**. Aqui vale a versão de **915 MHz**, a do LR1302 usado no gateway.

> O pacote (esquema, Gerber e BOM) não está nesta pasta porque a Semtech o distribui na própria página do produto, com cadastro. Se você baixar, coloque o arquivo aqui (`hardware_design/sx1302/`) para ficar junto do projeto.

| Item | Valor |
|---|---|
| Projeto de referência | Semtech CoreCell (SX1302 + SX1250), 915 MHz |
| Concentrador | SX1302: 8 canais LoRa multi-SF + 1 LoRa de serviço + 1 FSK |
| Rádios | 2 × SX1250 (`radio_0` transmite; `radio_1` só recebe) |
| Clock | 32 MHz do `radio_0` (`clksrc` = 0) |
| Rádio auxiliar | SX1261/SX1262, CS no pino 31 do HAT (o firmware o mantém desligado do SPI) |
| Interface com o host | SPI (o firmware usa 8 MHz) + RESET ativo alto |
| Temperatura | STTS751 no I2C, usado na compensação de RSSI (`rssi_tcomp`) |

## Onde está cada coisa no firmware

| Parâmetro do projeto de referência | Onde fica |
|---|---|
| `clksrc`, `rssi_offset` (−215,4 dB), `rssi_tcomp`, `tx_gain_lut` (12–27 dBm) | `main/packet_forwarder/global_conf.json/global_conf.*.json`, seção `SX130x_conf` |
| Firmware do AGC/ARB do SX1302 | embutidos na HAL portada (`main/libloragw/`) |
| Pulso de RESET (equivalente ao `reset_lgw.sh`) | `main/libloragw/` (pino `SX1302_RESET_PIN` de `main/CMakeLists.txt`) |
| CS do SX1261 em nível alto antes do reset | `main/libloragw/` (pino `SX1261_NSS_PIN` de `main/CMakeLists.txt`) |
| Leitura do STTS751 (0x38–0x3B, 0x48–0x4B) | `main/libloragw/loragw_stts751.c` (pinos `I2C_MASTER_SDA_IO` / `I2C_MASTER_SCL_IO`) |

Os valores de `rssi_offset`, `rssi_tcomp` e `tx_gain_lut` são os do CoreCell de 915 MHz, iguais nos JSON de AU915 e US915. Se a Elecrow publicar valores próprios para o LR1302, eles prevalecem.

## Links

- SX1302 na Semtech (folha de dados e projetos de referência): <https://www.semtech.com/products/wireless-rf/lora-core/sx1302>
- HAL original (`sx1302_hal`, base do porte, v2.1.0): <https://github.com/Lora-net/sx1302_hal>
- LR1302 HAT da Elecrow: [`../lr1302_hat/README.md`](../lr1302_hat/README.md)
