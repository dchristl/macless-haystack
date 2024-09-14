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
#define KEY_CHANGE_INTERVAL_DAYS 14  // how often to update battery status in days
#define MAX_KEYS 20  // maximum number of keys to rotate through

#define KEY_CHANGE_INTERVAL_MS (KEY_CHANGE_INTERVAL_MINUTES * 60 * 1000)
#define BATTERY_STATUS_UPDATES_INTERVAL_MS (KEY_CHANGE_INTERVAL_DAYS * 24 * 60 * 60 * 1000)

#define APP_TIMER_PRESCALER 0
#define APP_TIMER_MAX_TIMERS 2
#define KEY_CHANGE_TIMER_TICKS APP_TIMER_TICKS(KEY_CHANGE_INTERVAL_MS, APP_TIMER_PRESCALER)
#define BATTERY_STATUS_UPDATE_TIMER_TICKS APP_TIMER_TICKS(BATTERY_STATUS_UPDATES_INTERVAL_MS, APP_TIMER_PRESCALER)
#define APP_TIMER_OP_QUEUE_SIZE 4 

int last_filled_index = -1;
int current_index = 0;

APP_TIMER_DEF(m_key_change_timer_id);
APP_TIMER_DEF(m_battery_status_timer_id);

// Create space for MAX_KEYS public keys
static char public_key[MAX_KEYS][28] = { 
    "OFFLINEFINDINGPUBLICKEYHERE!",
};

uint8_t *raw_data; // Initialized by setAndAdvertiseNextKey() -> setAdvertisementKey()

void setAndAdvertiseNextKey()
{
    // Variable to hold the data to advertise
    uint8_t *ble_address;
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

void battery_status_update_timeout_handler(void *p_context)
{
    updateBatteryLevel(raw_data);
}


static void key_change_timer_config(void)
{
    uint32_t err_code;

    APP_TIMER_INIT(APP_TIMER_PRESCALER, APP_TIMER_OP_QUEUE_SIZE, NULL);

    // Create timer
    err_code = app_timer_create(&m_key_change_timer_id, APP_TIMER_MODE_REPEATED, key_change_timeout_handler);
    APP_ERROR_CHECK(err_code);

    // Set timer interval 
    err_code = app_timer_start(m_key_change_timer_id, KEY_CHANGE_TIMER_TICKS, NULL);
    APP_ERROR_CHECK(err_code);
}

static void battery_status_update_timer_config(void)
{
    uint32_t err_code;

    APP_TIMER_INIT(APP_TIMER_PRESCALER, APP_TIMER_OP_QUEUE_SIZE, NULL);

    // Create timer
    err_code = app_timer_create(&m_battery_status_timer_id, APP_TIMER_MODE_REPEATED, battery_status_update_timeout_handler);
    APP_ERROR_CHECK(err_code);

    // Set timer interval 
    err_code = app_timer_start(m_battery_status_timer_id, BATTERY_STATUS_UPDATE_TIMER_TICKS, NULL);
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
        key_change_timer_config();
    }
    
    if (last_filled_index >= 0) {
        setAndAdvertiseNextKey();
        battery_status_update_timer_config();
    }

    while (1){
        power_manage();
    }
}
