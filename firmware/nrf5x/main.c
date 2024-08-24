#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>
#include "ble_stack.h"
#include "openhaystack.h"
#include "app_timer.h"
#include "battery.h"


#define ADVERTISING_INTERVAL 5000  // advertising interval in milliseconds
#define KEY_CHANGE_INTERVAL_MINUTES 30  // how often to rotate to new key in minutes
#define MAX_KEYS 20  // maximum number of keys to rotate through
#define KEY_CHANGE_INTERVAL_MS (KEY_CHANGE_INTERVAL_MINUTES * 60 * 1000)

#define APP_TIMER_PRESCALER 0
#define APP_TIMER_MAX_TIMERS 1 
#define TIMER_TICKS APP_TIMER_TICKS(KEY_CHANGE_INTERVAL_MS, APP_TIMER_PRESCALER)
#define APP_TIMER_OP_QUEUE_SIZE 4 

int last_filled_index = -1;
int current_index = 0;

APP_TIMER_DEF(m_key_change_timer_id);

// Create space for MAX_KEYS public keys
static char public_key[MAX_KEYS][28] = { 
    "OFFLINEFINDINGPUBLICKEYHERE!",
};

void setAndAdvertiseNextKey()
{
    // Variable to hold the data to advertise
    uint8_t *ble_address;
    uint8_t *raw_data;
    uint8_t data_len;

    // Disable advertising
    sd_ble_gap_adv_stop();
    sd_ble_gap_adv_data_set(NULL, 0, NULL, 0);

    // Update key index for next advertisement...Back to zero if out of range
    current_index = (current_index + 1) % (last_filled_index + 1); 
    
    // Set key to be advertised
    data_len = setAdvertisementKey(public_key[current_index], &ble_address, &raw_data);

    // Set bluetooth address
    setMacAddress(ble_address);

    // Update battery information
    updateBatteryLevel(raw_data);

    // Set advertisement data
    setAdvertisementData(raw_data, data_len);

    // Start advertising
    startAdvertisement(ADVERTISING_INTERVAL);
}

void key_change_timeout_handler(void *p_context)
{
    setAndAdvertiseNextKey();
}

static void timer_config(void)
{
    uint32_t err_code;

    APP_TIMER_INIT(APP_TIMER_PRESCALER, APP_TIMER_OP_QUEUE_SIZE, NULL);

    // Create timer
    err_code = app_timer_create(&m_key_change_timer_id, APP_TIMER_MODE_REPEATED, key_change_timeout_handler);
    APP_ERROR_CHECK(err_code);

    // Set timer interval 
    err_code = app_timer_start(m_key_change_timer_id, TIMER_TICKS, NULL);
    APP_ERROR_CHECK(err_code);
}

/**
 * main function
 */
int main(void) {

    // Find the last filled index
    for (int i = MAX_KEYS - 1; i >= 0; i--)
    {
        if (strlen(public_key[i]) > 0)
        {
            last_filled_index = i;
            break;
        }
    }

    // Init BLE stack and softdevice
    init_ble();
    
    // Only use the app_timer to rotate keys if we need to
    if (last_filled_index > 0){
        timer_config();
    }
    
    if (last_filled_index >= 0) {
        setAndAdvertiseNextKey();
    }

    while (1){
        power_manage();
    }
}
