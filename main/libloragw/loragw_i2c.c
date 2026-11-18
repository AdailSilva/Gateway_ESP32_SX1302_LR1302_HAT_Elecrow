/*
 / _____)             _              | |
( (____  _____ ____ _| |_ _____  ____| |__
 \____ \| ___ |    (_   _) ___ |/ ___)  _ \
 _____) ) ____| | | || |_| ____( (___| | | |
(______/|_____)_|_|_| \__)_____)\____)_| |_|
  (C)2019 Semtech

Description:
    Host specific functions to address the LoRa concentrator I2C peripherals.

License: Revised BSD License, see LICENSE.TXT file include in the project
*/


#include <stdint.h>     /* C99 types */
#include <stdio.h>      /* printf fprintf */
#include <unistd.h>     /* lseek, close */
#include <fcntl.h>      /* open */
#include <errno.h>      /* errno */

#include "loragw_i2c.h"
#include "driver/i2c_master.h"
#include "loragw_aux.h"


#if DEBUG_I2C == 1
    #define DEBUG_MSG(str)                fprintf(stdout, str)
    #define DEBUG_PRINTF(fmt, args...)    fprintf(stdout,"%s:%d: "fmt, __FUNCTION__, __LINE__, args)
    #define CHECK_NULL(a)                if(a==NULL){fprintf(stderr,"%s:%d: ERROR: NULL POINTER AS ARGUMENT\n", __FUNCTION__, __LINE__);return LGW_I2C_ERROR;}
#else
    #define DEBUG_MSG(str)
    #define DEBUG_PRINTF(fmt, args...)
    #define CHECK_NULL(a)                if(a==NULL){return LGW_I2C_ERROR;}
#endif


/* One bus (I2C_MASTER_NUM) and one device handle per 7-bit address, created on
 * first use (SSD1306, STTS751, AD5338R... share the bus). */
#define I2C_MAX_DEVICES     8
#define I2C_XFER_TIMEOUT_MS 1000

static i2c_master_bus_handle_t i2c_bus = NULL;
static struct {
    uint8_t addr;
    i2c_master_dev_handle_t dev;
} i2c_devs[I2C_MAX_DEVICES];
static int i2c_ndevs = 0;

static i2c_master_dev_handle_t i2c_dev(uint8_t device_addr)
{
    for (int i = 0; i < i2c_ndevs; i++) {
        if (i2c_devs[i].addr == device_addr)
            return i2c_devs[i].dev;
    }
    if (i2c_bus == NULL || i2c_ndevs >= I2C_MAX_DEVICES)
        return NULL;
    /* only devices that answer get a handle: an absent one (STTS751 probed at
     * several addresses, OLED not connected) fails quietly, as with the legacy
     * driver, instead of a "NACK" error log from the new driver on each access */
    if (i2c_master_probe(i2c_bus, device_addr, 50) != ESP_OK)
        return NULL;
    i2c_device_config_t cfg = {
        .dev_addr_length = I2C_ADDR_BIT_LEN_7,
        .device_address = device_addr,
        .scl_speed_hz = I2C_MASTER_FREQ_HZ,
    };
    i2c_master_dev_handle_t dev = NULL;
    if (i2c_master_bus_add_device(i2c_bus, &cfg, &dev) != ESP_OK)
        return NULL;
    i2c_devs[i2c_ndevs].addr = device_addr;
    i2c_devs[i2c_ndevs].dev = dev;
    i2c_ndevs++;
    return dev;
}

esp_err_t i2c_esp32_open(void)
{
    if (i2c_bus != NULL)
        return ESP_OK;

    i2c_master_bus_config_t conf = {
        .i2c_port = I2C_MASTER_NUM,
        .sda_io_num = I2C_MASTER_SDA_IO,
        .scl_io_num = I2C_MASTER_SCL_IO,
        .clk_source = I2C_CLK_SRC_DEFAULT,
        .glitch_ignore_cnt = 7,
        .flags.enable_internal_pullup = true,
    };
    esp_err_t ret = i2c_new_master_bus(&conf, &i2c_bus);
    if (ret == ESP_OK) {
        DEBUG_PRINTF("INFO: I2C port(%d) opened successfully\n", I2C_MASTER_NUM);
    } else {
        DEBUG_PRINTF("INFO: I2C port(%d) opened failed\n", I2C_MASTER_NUM);
        i2c_bus = NULL;
    }
    return ret;
}

esp_err_t i2c_esp32_read(uint8_t device_addr, uint8_t reg_addr, uint8_t *data)
{
    i2c_master_dev_handle_t dev = i2c_dev(device_addr);

    if (dev == NULL || data == NULL)
        return (i2c_bus == NULL) ? ESP_ERR_INVALID_STATE : ESP_ERR_NOT_FOUND;
    /* register address, repeated start, one byte */
    return i2c_master_transmit_receive(dev, &reg_addr, 1, data, 1, I2C_XFER_TIMEOUT_MS);
}

esp_err_t i2c_esp32_write(uint8_t device_addr, uint8_t reg_addr, uint8_t data)
{
    uint8_t buf[2];

    buf[0] = reg_addr;
    buf[1] = data;

    return i2c_esp32_write_buf(device_addr, buf, 2);
}

esp_err_t i2c_esp32_write_buf(uint8_t device_addr, uint8_t *data, size_t size)
{
    i2c_master_dev_handle_t dev = i2c_dev(device_addr);

    if (dev == NULL || data == NULL)
        return (i2c_bus == NULL) ? ESP_ERR_INVALID_STATE : ESP_ERR_NOT_FOUND;
    return i2c_master_transmit(dev, data, size, I2C_XFER_TIMEOUT_MS);
}

int i2c_esp32_scan(uint8_t *found, int max)
{
    int n = 0;

    if (i2c_bus == NULL)
        return 0;
    for (uint8_t a = 0x08; a <= 0x77; a++) {
        /* address only: a device acknowledges its address, nothing is read or written */
        esp_err_t ret = i2c_master_probe(i2c_bus, a, 20);
        if (ret == ESP_OK) {
            if (found != NULL && n < max)
                found[n] = a;
            n++;
        } else if (ret == ESP_ERR_TIMEOUT) {
            /* SDA or SCL held low: no pull-up, short circuit or a stuck device */
            printf("WARNING: [i2c] bus timeout at 0x%02X: SDA/SCL stuck low (pull-ups? wiring?)\n", a);
            return n;
        }
    }
    return n;
}

esp_err_t i2c_esp32_close(void)
{
    if (i2c_bus == NULL)
        return ESP_OK;
    for (int i = 0; i < i2c_ndevs; i++)
        i2c_master_bus_rm_device(i2c_devs[i].dev);
    i2c_ndevs = 0;
    esp_err_t ret = i2c_del_master_bus(i2c_bus);
    if (ret == ESP_OK)
        i2c_bus = NULL;
    return ret;
}
