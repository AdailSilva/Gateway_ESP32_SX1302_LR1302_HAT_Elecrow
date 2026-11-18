/*
 / _____)             _              | |
( (____  _____ ____ _| |_ _____  ____| |__
 \____ \| ___ |    (_   _) ___ |/ ___)  _ \
 _____) ) ____| | | || |_| ____( (___| | | |
(______/|_____)_|_|_| \__)_____)\____)_| |_|
  (C)2019 Semtech

Description:
    Basic driver for ST ts751 temperature sensor

License: Revised BSD License, see LICENSE.TXT file include in the project
*/

#ifndef _LORAGW_STTS751_H
#define _LORAGW_STTS751_H


#include <stdint.h>     /* C99 types */
#include <stdbool.h>    /* bool type */
#include "config.h"     /* library configuration options (dynamically generated) */


/*
  0x39: STTS751-0DP3F
  0x3B: STTS751-1DP3F
  0x38: STTS751-0DP3F on full duplex CN490 ref design
  The address is set by the pull-up on the Addr/Therm pin (ST datasheet, table 1):
  STTS751-0: 0x48 (7.5k), 0x49 (12k), 0x38 (20k), 0x39 (33k)
  STTS751-1: 0x4A (7.5k), 0x4B (12k), 0x3A (20k), 0x3B (33k)
  The Semtech reference designs use the first three; other boards (e.g. the Elecrow LR1302
  module) may use any of them, so all 8 are probed. stts751_configure() only writes to a
  chip that answers with the ST product and manufacturer IDs.
  */
static const uint8_t I2C_PORT_TEMP_SENSOR[] = {0x39, 0x3B, 0x38, 0x3A, 0x48, 0x49, 0x4A, 0x4B};

/**
@brief Configure the temperature sensor (ST TS751)
@param i2c_addr the I2C device address of the sensor
@return LGW_I2C_ERROR if fails, LGW_I2C_SUCCESS otherwise
*/
int stts751_configure(uint8_t i2c_addr);

/**
@brief Get the temperature from the sensor
@param i2c_addr the I2C device address of the sensor
@param temperature pointer to store the temerature read from sensor
@return LGW_I2C_ERROR if fails, LGW_I2C_SUCCESS otherwise
*/
int stts751_get_temperature(uint8_t i2c_addr, float * temperature);

#endif
