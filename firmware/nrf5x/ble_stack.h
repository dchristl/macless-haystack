#include "softdevice_handler.h"
#include "boards.h"
#include "ble.h"
#include "ble_gap.h"
#include "app_error.h"

#ifndef uint8_t
typedef __uint8_t uint8_t;
typedef __uint16_t uint16_t;
typedef __uint32_t uint32_t;
typedef __uint64_t uint64_t;
#endif

/*
 *  init_ble will initialize the ble stack, it will use the crystal definition based on NRF_CLOCK_LFCLKSRC.
 *  In devices with no external crystal you should use the internal rc. You can look at the e104bt5032a_board.h file
 */
void init_ble();

/**
 * setMacAddress will set the bluetooth address
 */
void setMacAddress(uint8_t *addr);

/**
 * setAdvertisementData will set the data to be advertised
 */
void setAdvertisementData(uint8_t *data, uint8_t dlen);

/**
 * Start advertising at the specified interval
 *
 * @param[in] interval advertising interval in milliseconds
 */
void startAdvertisement(int interval);

/**
 * Function for the Power manager.
 */
void power_manage(void);