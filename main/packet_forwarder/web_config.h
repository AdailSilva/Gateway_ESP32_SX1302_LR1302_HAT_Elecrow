/*
 / _____)             _              | |
( (____  _____ ____ _| |_ _____  ____| |__
 \____ \| ___ |    (_   _) ___ |/ ___)  _ \
 _____) ) ____| | | || |_| ____( (___| | | |
(______/|_____)_|_|_| \__)_____)\____)_| |_|
  (C)2023 Semtech

Description:
    Head file for processing configure settings

License: Revised BSD License, see LICENSE.TXT file include in the project
*/


#ifndef _WEB_CONFIG_H
#define _WEB_CONFIG_H

#include "esp_log.h"
#include "esp_err.h"
#include <stdbool.h>


#define NTP_SERVER_ADDR  "br.pool.ntp.org"

typedef enum {
    WIFI_SSID  = 0,
    WIFI_PASSWORD,
    NS_HOST,
    NS_PORT,
    GW_ID,          /* Gateway EUI override: 16 hex; empty = automatic (Wi-Fi MAC + FFFE) */
    WIFI_MODE,
    FREQ_REGION,
    FREQ_RADIO0,
    FREQ_RADIO1,
    NTP_SERVER,
    MQTT_EN,        /* "on" / "off" */
    MQTT_URI,       /* mqtt://host:1883 or mqtts://host:8883 */
    MQTT_USER,
    MQTT_PSWD,
    MQTT_TOPIC,     /* base topic, default gateway/<gateway id> */
    WEB_USER,       /* web page login */
    WEB_PSWD,
    MQTT_FMT,       /* "semtech" (mirror, default) / "chirpstack" (ChirpStack v4 gateway protocol) */
    MQTT_ENC,       /* ChirpStack encoding: "json" (default) / "protobuf" */
    IP_MODE,        /* station address: "dhcp" (default) / "static" */
    IP_ADDR,        /* static IPv4 address */
    IP_MASK,        /* static netmask */
    IP_GW,          /* static default gateway */
    IP_DNS1,        /* static main DNS (empty = the gateway address) */
    IP_DNS2,        /* static backup DNS (optional) */
    GPS_EN,         /* GPS of the HAT: "on" / "off" (default, also when not set); applied when saved */
    CONFIG_NUM,
    CONFIG_END = 254,
    CONFIG_ERR = 255
} tag_e;

typedef enum {
    WIFI_MODE_SOFT_AP  = 0,
    WIFI_MODE_STATION
} wifi_mode_e;

typedef struct {
    tag_e tag;
    char name[16];
    char *val;
    int len;  // length of the string pointed by val
} config_s;

tag_e name2tag(char *name);
esp_err_t init_config_storage(void);
int update_config(char *str, int len);
void dump_config(void);
esp_err_t read_config(void);
int save_config(void);
void extract_data_items(char *str);
int config_wifi_mode(wifi_mode_e mode);
void config_register_console(void);   /* console commands "config" and "reboot" */

/* Gateway EUI (Gateway ID, 64 bits as 16 upper case hex characters).
 * Automatic by default: the ESP32 Wi-Fi station MAC (48 bits) expanded to EUI-64 by
 * inserting FFFE in the middle, the convention of LoRaWAN gateways
 * (AA:BB:CC:DD:EE:FF -> AABBCCFFFEDDEEFF). A valid value saved in GW_ID overrides it. */
#define GW_EUI_LEN  16
bool gw_eui_valid(const char *v);       /* exactly 16 hex characters */
const char *gw_eui_auto(void);          /* derived from the MAC (always available) */
bool gw_eui_is_auto(void);              /* true when no valid override is saved */
const char *gw_eui_saved(void);         /* saved override or the automatic one (changes when saved) */
const char *gw_eui(void);               /* EUI in use: latched at boot, kept until the next reboot */

#endif
