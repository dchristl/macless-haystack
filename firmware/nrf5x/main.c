#include <stdbool.h>
#include <stdint.h>
#include <string.h>
#include "ble_stack.h"
#include "openhaystack.h"
#include "nrf.h"
#include "nrf_delay.h"
#include "nrf_soc.h"
#include <time.h>
/**
 * advertising interval in milliseconds
 */
#define ADVERTISING_INTERVAL 5000

#define KEY_CHANGE_INTERVAL 2 // FIXME

#define MAX_KEYS 50

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

void TIMER2_IRQHandler(void)
{
    if ((NRF_TIMER2->EVENTS_COMPARE[0] != 0) && ((NRF_TIMER2->INTENSET & TIMER_INTENSET_COMPARE0_Msk) != 0))
    {
        NRF_TIMER2->EVENTS_COMPARE[0] = 0; // Clear compare register 0 event
    }

    if ((NRF_TIMER2->EVENTS_COMPARE[1] != 0) && ((NRF_TIMER2->INTENSET & TIMER_INTENSET_COMPARE1_Msk) != 0))
    {
        NRF_TIMER2->EVENTS_COMPARE[1] = 0; // Clear compare register 1 event
    }
}

void sleep_and_awake_in_s(uint32_t seconds)
{
    /*     SOFTDEVICE_HANDLER_INIT(NRF_CLOCK_LFCLKSRC_RC_250_PPM_8000MS_CALIBRATION, NULL);

        NRF_TIMER2->MODE = TIMER_MODE_MODE_Timer;          // Set the timer in Counter Mode
        NRF_TIMER2->TASKS_CLEAR = 1;                       // clear the task first to be usable for later
        NRF_TIMER2->PRESCALER = 6;                         // Set prescaler. Higher number gives slower timer. Prescaler = 0 gives 16MHz timer
        NRF_TIMER2->BITMODE = TIMER_BITMODE_BITMODE_16Bit; // Set counter to 16 bit resolution
        NRF_TIMER2->CC[0] = 25000;                         // Set value for TIMER2 compare register 0
        NRF_TIMER2->CC[1] = 5;                             // Set value for TIMER2 compare register 1

        // Enable interrupt on Timer 2, both for CC[0] and CC[1] compare match events
        NRF_TIMER2->INTENSET = (TIMER_INTENSET_COMPARE0_Enabled << TIMER_INTENSET_COMPARE0_Pos) | (TIMER_INTENSET_COMPARE1_Enabled << TIMER_INTENSET_COMPARE1_Pos);
        NVIC_EnableIRQ(TIMER2_IRQn);
        SOFTDEVICE_HANDLER_INIT(NRF_CLOCK_LFCLKSRC_XTAL_20_PPM)

        NRF_TIMER2->TASKS_START = 1; */
    APP_ERROR_CHECK(sd_app_evt_wait());
}

void mainLoop()
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

    ble_gap_addr_t public_address;

    // Lies die öffentliche MAC-Adresse mit der Funktion sd_ble_gap_addr_get
    sd_ble_gap_address_get(&public_address);

    char blubb[100];
    sprintf(blubb, "Public MAC Address: %02X:%02X:%02X:%02X:%02X:%02X|",
            public_address.addr[5], public_address.addr[4], public_address.addr[3],
            public_address.addr[2], public_address.addr[1], public_address.addr[0]);

    // Set advertisement data
    setAdvertisementData(raw_data, data_len);

    // Start advertising
    startAdvertisement(ADVERTISING_INTERVAL);

    // Do only wake up again if more than one key is used
    if (last_filled_index == 0)
    {
        power_manage();
    }
    else
    {
        // Go to low power mode
        // sleep_and_awake_in_s(KEY_CHANGE_INTERVAL);
        nrf_delay_ms(KEY_CHANGE_INTERVAL * 1000);
    }
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

    while (1)
    {
        mainLoop();
    }
    return 0;
}
