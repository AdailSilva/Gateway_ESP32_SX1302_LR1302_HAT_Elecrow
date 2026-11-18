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

#ifndef _LORAGW_I2C_H
#define _LORAGW_I2C_H

#include <stdint.h>        /* C99 types*/

#include "config.h"
/* New I2C master driver (driver/i2c_master.h, ESP-IDF >= 5.2). The legacy
 * driver/i2c.h is end-of-life since ESP-IDF v6.0 and is removed in v7.0. */
#include <stdbool.h>
#include <stddef.h>
#include "esp_err.h"
#include "driver/gpio.h"
#include "freertos/FreeRTOS.h"


#define LGW_I2C_SUCCESS      0
#define LGW_I2C_ERROR       -1

#ifndef I2C_MASTER_SCL_IO
#define I2C_MASTER_SCL_IO   22      /* gpio number for I2C master clock */
#endif

#ifndef I2C_MASTER_SDA_IO
#define I2C_MASTER_SDA_IO   21      /* gpio number for I2C master data  */
#endif

#define I2C_MASTER_NUM       0      /* I2C port number for master dev */

#define I2C_MASTER_FREQ_HZ         100000   /* I2C master clock frequency */


/**
@brief Open I2C port
@return 0 if I2C port was open successfully, -1 else
*/
esp_err_t i2c_esp32_open(void);

/**
@brief Close I2C port
@return 0 if I2C port was closed successfully, -1 else
*/
esp_err_t i2c_esp32_close(void);

/**
@brief Read data from an I2C port
@param device_addr  I2C device address
@param reg_addr     Address of the register to be read
@param data         Pointer to a buffer to store read data
@return 0 if I2C data read is successful, -1 else
*/
esp_err_t i2c_esp32_read(uint8_t device_addr, uint8_t reg_addr, uint8_t *data);

/**
@brief Write data to an I2C port
@param device_addr  I2C device address
@param reg_addr     Address of the register to write to
@param data         byte to write in the register
@return 0 if I2C data write is successful, -1 else
*/
esp_err_t i2c_esp32_write(uint8_t device_addr, uint8_t reg_addr, uint8_t data);

/**
@brief Write a raw buffer to an I2C port
@param device_addr  I2C device address
@param data         byte to write in the register
@param size         Size of the buffer to be written
@return 0 if I2C data write is successful, -1 else
*/
esp_err_t i2c_esp32_write_buf(uint8_t device_addr, uint8_t *data, size_t size);

/**
@brief Scan the I2C bus (addresses 0x08-0x77) and print what answers (diagnostic)
@param found  array filled with the addresses that acknowledged (may be NULL)
@param max    size of found
@return number of devices that acknowledged
*/
int i2c_esp32_scan(uint8_t *found, int max);

#endif
