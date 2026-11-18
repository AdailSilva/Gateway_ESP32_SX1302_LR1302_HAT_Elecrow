/*
 * gw_mdns.h - mDNS responder of the gateway (option GW_MDNS, ESP32-S3 build).
 *
 * Announces http://<host>.local/ and the service _http._tcp (port 80) with
 * TXT type=gateway, so the Android app finds the gateway on the Wi-Fi network.
 * Built without GW_MDNS (classic ESP32), both functions do nothing.
 *
 * License: Revised BSD License, see LICENSE.TXT file include in the project
 */
#ifndef _GW_MDNS_H
#define _GW_MDNS_H

#include <stdbool.h>

/* starts the responder once (the default event loop and the netifs must exist) */
void gw_mdns_start(void);

/* true when the responder is running */
bool gw_mdns_running(void);

/* host name announced, without ".local" ("" when mDNS is not built or not running) */
const char *gw_mdns_hostname(void);

#endif
