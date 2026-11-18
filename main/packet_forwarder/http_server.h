/*
 / _____)             _              | |
( (____  _____ ____ _| |_ _____  ____| |__
 \____ \| ___ |    (_   _) ___ |/ ___)  _ \
 _____) ) ____| | | || |_| ____( (___| | | |
(______/|_____)_|_|_| \__)_____)\____)_| |_|
  (C)2023 Semtech

Description:
    Http service head file

License: Revised BSD License, see LICENSE.TXT file include in the project
*/

#ifndef _HTTP_SERVER_H
#define _HTTP_SERVER_H

#include <stddef.h>


/* default login of the web page (can be changed in the page or with the console command "web_auth") */
#define BASIC_AUTH_USERNAME "admin"
#define BASIC_AUTH_PASSWORD "lorawan101"
/* factory password of older firmware versions: if it is still saved in NVS (with the default user),
 * it is replaced by BASIC_AUTH_PASSWORD at boot; custom logins are kept */
#define BASIC_AUTH_PASSWORD_OLD "lorawan"

/* Soft AP network of the gateway (factory defaults, BOOT button, Wi-Fi fallback).
 * Same pattern as the nodes: lorawan-node-abp / lorawan-node-otaa. */
#define GW_SOFTAP_SSID      "lorawan-gateway-sx1302"
#define GW_SOFTAP_PASS      "lorawan101"

/* fake login used only by the "Sair" (logout) button; the web user can not be this one */
#define WEB_LOGOUT_USER "_logout_"
#define WEB_LOGOUT_PASS "_logout_"
#define WEB_AUTH_MAX_LEN    31

/* loads the saved login (or the defaults) into the running web server */
void web_auth_apply(void);
/* console command "web_auth" */
void web_auth_register_console(void);
/* console command "factory_reset" */
void factory_register_console(void);

#define HTTPD_401      "401 UNAUTHORIZED"           /*!< HTTP Response 401 */

void http_server_task(void *pvParameters);

/* status of the gateway as JSON (uptime, heap, Wi-Fi, packet counters since boot),
 * implemented in lora_pkt_fwd.c; returns what snprintf returns */
int pkt_fwd_status_json(char *buf, size_t size);

/* GPS of the HAT, switched on/off at run time (lora_pkt_fwd.c).
 * pkt_fwd_gps_apply_config() applies the saved config[GPS_EN] ("on"/"off") now. */
#define GPS_APPLY_OK          0    /* applied now */
#define GPS_APPLY_AT_BOOT     1    /* forwarder not running (Soft AP mode...): applied at the next boot */
#define GPS_APPLY_NOT_BUILT  -1    /* firmware built with GPS_DISABLE */
#define GPS_APPLY_ERR        -2    /* UART or RAM (thread) failure, see the log */
#define GPS_APPLY_WAIT        2    /* switched on, starts after the MQTT connection (TLS needs the RAM first) */
int pkt_fwd_gps_apply_config(void);
/* GPS status for the web page (GET /status, "gps" object); returns what snprintf returns */
int pkt_fwd_gps_status_json(char *buf, size_t size);

#endif
