#include <stdbool.h>
#include <stdint.h>
#include <string.h>
#include "ble_stack.h"
#include "openhaystack.h"
#include "nrf.h"
#include "nrf51.h"
#include "nrf_delay.h"
#include "nrf_soc.h"
/**
 * advertising interval in milliseconds
 */
#define ADVERTISING_INTERVAL 5000

#define MAX_KEYS 50

static char public_key[MAX_KEYS][28] = {
    "OFFLINEFINDINGPUBLICKEYHERE!",
};

void saveStringAsHex(const char *str, char *hexBuffer)
{
    char *buf = hexBuffer;

    for (int i = 0; i < 28; i++)
    {
        buf += sprintf(buf, "H:0x%X_", (unsigned char)str[i]);
    }
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

        srand(NRF_RTC1->COUNTER);

        int randomValue = rand() % (last_filled_index + 1);

        char hexBuffer[1000];

        saveStringAsHex(public_key[randomValue], hexBuffer);

        // Set key to be advertised
        data_len = setAdvertisementKey(public_key[randomValue], &ble_address, &raw_data);

        // Init BLE stack
        init_ble();

        // Set bluetooth address
        setMacAddress(ble_address);

        // Set advertisement data
        setAdvertisementData(raw_data, data_len);

        // Start advertising
        startAdvertisement();
        //
        nrf_delay_ms(200);

        // Go to low power mode
        sleep_for_seconds(ADVERTISING_INTERVAL / 1000);
    }
}
