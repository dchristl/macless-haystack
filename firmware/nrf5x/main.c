#include <stdbool.h>
#include <stdint.h>
#include <string.h>
#include "ble_stack.h"
#include "openhaystack.h"
#include "nrf.h"
#include "nrf_delay.h"
#include "nrf_soc.h"
#include <time.h>
#include "nrf_drv_rtc.h"
#include "nrf_drv_clock.h"
#include "nrf_gpio.h"
/**
 * advertising interval in milliseconds
 */
#define ADVERTISING_INTERVAL 5000
#define LED_GPIO 10

#define KEY_CHANGE_INTERVAL_MINUTES 30

#define MAX_KEYS 50

const nrf_drv_rtc_t rtc1 = NRF_DRV_RTC_INSTANCE(1);

int last_filled_index = -1;
int key_index = -1;

static char public_key[MAX_KEYS][28] = {
    "OFFLINEFINDINGPUBLICKEYHERE!",
};

void setRandomIndex()
{
    uint8_t random_buffer[sizeof(int)];
    int random_integer;
    sd_rand_application_vector_get(random_buffer, sizeof(int));
    memcpy(&random_integer, random_buffer, sizeof(int));

    key_index = abs(random_integer % (last_filled_index + 1));
    printf("%d", key_index);
}

char *getCurrentKey()
{
    uint8_t random_buffer[sizeof(int)];
    int random_integer;
    sd_rand_application_vector_get(random_buffer, sizeof(int));
    memcpy(&random_integer, random_buffer, sizeof(int));

    int randomValue = abs(random_integer % (last_filled_index + 1));

    return public_key[randomValue];
}

void setAndAdvertiseNextKey()
{
    // Variable to hold the data to advertise
    uint8_t *ble_address;
    uint8_t *raw_data;
    uint8_t data_len;
    // Disable advertising
    sd_ble_gap_adv_stop();
    sd_ble_gap_adv_data_set(NULL, 0, NULL, 0);
    key_index = (key_index + 1) % (last_filled_index + 1); // Back to zero if out of range
    // Set key to be advertised
    data_len = setAdvertisementKey(public_key[key_index], &ble_address, &raw_data);

    // Set bluetooth address
    setMacAddress(ble_address);

    // Set advertisement data
    setAdvertisementData(raw_data, data_len);

    // Start advertising
    startAdvertisement(ADVERTISING_INTERVAL);
}

static void rtc1_handler(nrf_drv_rtc_int_type_t int_type)
{

    if (int_type == NRF_DRV_RTC_INT_COMPARE0)
    { // Interrupt from COMPARE0 event.
        // nrf_gpio_pin_toggle(LED_GPIO);
        setAndAdvertiseNextKey();                               // next key
        nrf_drv_rtc_int_enable(&rtc1, RTC_CHANNEL_INT_MASK(0)); // re-enable
        nrf_drv_rtc_counter_clear(&rtc1);                       // reset the counter
    }
    else if (int_type == NRF_DRV_RTC_INT_TICK)
    { // Tick off
      // This is an error
    }
}

/** @brief Function starting the HFCLK oscillator.
 */
static void lfclk_config(void)
{
    ret_code_t err_code = nrf_drv_clock_init();
    APP_ERROR_CHECK(err_code);

    nrf_drv_clock_lfclk_request(NULL);
}

static void gpio_config(void)
{
    // Configure LED-pin as outputs and clear.
    nrf_gpio_cfg_output(LED_GPIO);
    nrf_gpio_pin_clear(LED_GPIO);
    nrf_gpio_pin_toggle(LED_GPIO);
    nrf_delay_ms(200); // Flash the pin on startup
    nrf_gpio_pin_clear(LED_GPIO);
}

/** @brief Function initialization and configuration of timer driver instance.
 */
static void timer_config(void)
{
    uint32_t err_code;

    // Initialize RTC instance
    err_code = nrf_drv_rtc_init(&rtc1, NULL, rtc1_handler);
    APP_ERROR_CHECK(err_code);

    // Disable tick event & interrupt
    nrf_drv_rtc_tick_enable(&rtc1, false);

    // Set compare channel 0 to trigger interrupt after RTC1_CC_VALUE*125ms
    err_code = nrf_drv_rtc_cc_set(&rtc1, 0, KEY_CHANGE_INTERVAL_MINUTES * 60 * RTC1_CONFIG_FREQUENCY, true);
    APP_ERROR_CHECK(err_code);

    // Power on RTC instance
    nrf_drv_rtc_enable(&rtc1);
}

/**
 * main function
 */
int main(void)
{
    // Find the last filled index
    for (int i = MAX_KEYS - 1; i >= 0; i--)
    {
        if (strlen(public_key[i]) > 0)
        {
            last_filled_index = i;
            break;
        }
    }

    // Select a random index as start
    setRandomIndex();

    // Init BLE stack
    init_ble();
    gpio_config();
    if (last_filled_index > 0)
    {
        // Start timer
        lfclk_config();
        timer_config();
    }

    setAndAdvertiseNextKey();

    while (1)
    {
        power_manage();
    }
    return 0;
}
