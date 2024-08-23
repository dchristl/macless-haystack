#define STATUS_FLAG_BATTERY_MASK           0b11000000
#define STATUS_FLAG_COUNTER_MASK           0b00111111
#define STATUS_FLAG_MEDIUM_BATTERY         0b01000000
#define STATUS_FLAG_LOW_BATTERY            0b10000000
#define STATUS_FLAG_CRITICALLY_LOW_BATTERY 0b11000000

#if NRF_MODEL == nrf51
    #include "nrf51_battery.h"
#else
    uint8_t get_current_level() {return 0};
#endif

void updateBatteryLevel(uint8_t * data)
{
    uint8_t * status_flag_ptr = data + 6;

    /*
    static uint16_t battery_counter = BATTERY_COUNTER_THRESHOLD;
    if((++battery_counter) < BATTERY_COUNTER_THRESHOLD){
        return;
    }
    battery_counter = 0;
    */
    
    uint8_t battery_level = get_current_level();

    *status_flag_ptr &= (~STATUS_FLAG_BATTERY_MASK);
    if(battery_level > 80){
        // do nothing
    }else if(battery_level > 50){
        *status_flag_ptr |= STATUS_FLAG_MEDIUM_BATTERY;
    }else if(battery_level > 30){
        *status_flag_ptr |= STATUS_FLAG_LOW_BATTERY;
    }else{
        *status_flag_ptr |= STATUS_FLAG_CRITICALLY_LOW_BATTERY;
    }
}