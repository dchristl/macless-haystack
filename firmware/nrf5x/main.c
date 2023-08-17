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

#define MAX_KEYS 50

static char public_key[MAX_KEYS][28] = {
    "OFFLINEFINDINGPUBLICKEYHERE!",
};

char *getRandomKey(uint8_t last_filled_index)
{
    uint8_t random_buffer[sizeof(int)];
    int random_integer;
    sd_rand_application_vector_get(random_buffer, sizeof(int));
    memcpy(&random_integer, random_buffer, sizeof(int));

    int randomValue = abs(random_integer % (last_filled_index + 1));

    return public_key[randomValue];
}
void sleep_for_seconds(uint32_t seconds)
{
    // Konfigurieren Sie den Timer
    NRF_TIMER0->MODE = TIMER_MODE_MODE_Timer;
    NRF_TIMER0->BITMODE = TIMER_BITMODE_BITMODE_32Bit;
    NRF_TIMER0->PRESCALER = 4;             // Teiler für 1 MHz (2^4 = 16)
    NRF_TIMER0->CC[0] = seconds * 1000000; // Konvertieren von Sekunden in Mikrosekunden
    NRF_TIMER0->INTENSET = TIMER_INTENSET_COMPARE0_Msk;
    NRF_TIMER0->TASKS_START = 1;

    // Setzen Sie den Mikrocontroller in den System-On-Sleep-Modus
    APP_ERROR_CHECK(sd_app_evt_wait());

    // Mikrocontroller wurde aufgeweckt, Timer-Interrupt zurücksetzen
    NRF_TIMER0->TASKS_STOP = 1;
    NRF_TIMER0->EVENTS_COMPARE[0] = 0;
}

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
    while (1)
    {

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

        char *selected_public_key = getRandomKey(last_filled_index);

        // Kopiere den ausgewählten öffentlichen Schlüssel in die neue Variable
        char buf[50];
        sprintf(buf, "0x%X 0x%X 0x%X 0x%X ", (unsigned int)selected_public_key[0], (unsigned int)selected_public_key[1], (unsigned int)selected_public_key[2], (unsigned int)selected_public_key[27]);

        // Set key to be advertised
        data_len = setAdvertisementKey(selected_public_key, &ble_address, &raw_data);

        // Init BLE stack
        init_ble();

        // Set bluetooth address
        setMacAddress(ble_address);

        // Set advertisement data
        setAdvertisementData(raw_data, data_len);

        // Start advertising
        startAdvertisement();
        // advertise for 200ms
        nrf_delay_ms(200);

        // Go to low power mode
        sleep_for_seconds(ADVERTISING_INTERVAL / 1000);
    }
}
