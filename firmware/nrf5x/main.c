#include <stdbool.h>
#include <stdint.h>
#include <string.h>
#include "ble_stack.h"
#include "openhaystack.h"
#include "nrf.h"

/**
 * advertising interval in milliseconds
 */
#define ADVERTISING_INTERVAL 5000

#define MAX_KEYS 50

static char public_key[MAX_KEYS][28] = {
    "OFFLINEFINDINGPUBLICKEYHERE!",
};

/**
 * main function
 */
int main(void)
{
    // Variable to hold the data to advertise
    uint8_t *ble_address;
    uint8_t *raw_data;
    uint8_t data_len;

    // Find the last filled index

    int last_filled_index = -1;

    for (int i = MAX_KEYS - 1; i >= 0; i--)
    {
        if (strlen(public_key[i]) > 0)
        {
            last_filled_index = i;
            break;
        }
    }
    // Select a random string and copy its value
    
    srand(NRF_RTC1->COUNTER);
    char copy[28];

    int randomValue = rand() % (last_filled_index + 1);

    strncpy(copy, public_key[randomValue], 28);

    // Set key to be advertised
    data_len = setAdvertisementKey(copy, &ble_address, &raw_data);

    // Init BLE stack
    init_ble();

    // Set bluetooth address
    setMacAddress(ble_address);

    // Set advertisement data
    setAdvertisementData(raw_data, data_len);

    // Start advertising
    startAdvertisement(ADVERTISING_INTERVAL);

    // Go to low power mode
    while (1)
    {
        power_manage();
    }
}
