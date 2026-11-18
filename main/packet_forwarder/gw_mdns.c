/*
 * gw_mdns.c - mDNS responder of the gateway (option GW_MDNS, ESP32-S3 build).
 *
 * License: Revised BSD License, see LICENSE.TXT file include in the project
 */
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include "sdkconfig.h"
#include "esp_log.h"
#include "gw_mdns.h"

#if CONFIG_GW_MDNS

#include "esp_mac.h"
#include "mdns.h"
#include "branding.h"
#include "loragw_version.h"

static const char *TAG = "gw_mdns";
static char s_host[32];
static bool s_running;

/* host name: GW_MDNS_HOSTNAME when set, else "esp32-sx1302-" + the last 3 bytes of the MAC */
static void make_hostname(void)
{
    const char *cfg = CONFIG_GW_MDNS_HOSTNAME;
    size_t j = 0;

    for (; *cfg && j < sizeof(s_host) - 1; cfg++) {
        char c = (char)tolower((unsigned char)*cfg);
        if ((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '-')
            s_host[j++] = c;
    }
    s_host[j] = '\0';
    if (s_host[0] == '\0') {
        uint8_t mac[6] = {0};
        esp_read_mac(mac, ESP_MAC_WIFI_STA);
        snprintf(s_host, sizeof(s_host), "esp32-sx1302-%02x%02x%02x", mac[3], mac[4], mac[5]);
    }
}

void gw_mdns_start(void)
{
    esp_err_t err;

    if (s_running)
        return;
    make_hostname();

    err = mdns_init();
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "mdns_init failed: %s", esp_err_to_name(err));
        return;
    }
    mdns_hostname_set(s_host);
    mdns_instance_name_set(GW_NAME);

    mdns_txt_item_t txt[] = {
        { "type",   "gateway" },
        { "fw",     ESP32_SX1302_VERSION },
        { "target", CONFIG_IDF_TARGET },
        { "board",  CONFIG_GW_BOARD_ID },
        { "info",   "/info" },
    };
    err = mdns_service_add(GW_NAME, "_http", "_tcp", 80, txt, sizeof(txt) / sizeof(txt[0]));
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "mdns_service_add failed: %s", esp_err_to_name(err));
        mdns_free();
        return;
    }
    s_running = true;
    ESP_LOGI(TAG, "mDNS: http://%s.local/ (service _http._tcp, port 80)", s_host);
}

bool gw_mdns_running(void)
{
    return s_running;
}

const char *gw_mdns_hostname(void)
{
    return s_running ? s_host : "";
}

#else  /* !CONFIG_GW_MDNS */

void gw_mdns_start(void)
{
}

bool gw_mdns_running(void)
{
    return false;
}

const char *gw_mdns_hostname(void)
{
    return "";
}

#endif
