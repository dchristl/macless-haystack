#include <stdint.h>
#include <string.h>
#include <stdbool.h>
#include <stdio.h>

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

#include "nvs_flash.h"
#include "esp_partition.h"

#include "esp_bt.h"
#include "esp_gap_ble_api.h"
#include "esp_gattc_api.h"
#include "esp_gatt_defs.h"
#include "esp_bt_main.h"
#include "esp_bt_defs.h"
#include "esp_log.h"
#include "esp_sleep.h"
#include "esp_random.h"

/* Delay between advertisement. Advertisment will only be transmitted for a short period of time (20ms) and the device will go to sleep.
Higher delay = less power consumption, but more inaccurate tracking
 */
#define DELAY_IN_S 60
/* Define how often (long) a key will be reused after switching to the next one
This is for using less keys after all. The interval for one key is (DELAY_IN_S * REUSE_CYCLES => 60s * 30 cycles = changes key every 30 min)
Smaller number of cycles = key changes more often, but more keys needed.
 */
#define REUSE_CYCLES 30

static const char *LOG_TAG = "macless_haystack";

/** Callback function for BT events */
static void esp_gap_cb(esp_gap_ble_cb_event_t event, esp_ble_gap_cb_param_t *param);

/** Random device address */
static esp_bd_addr_t rnd_addr = {0xFF, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF};

/** Advertisement payload */
static uint8_t adv_data[31] = {
    0x1e,       /* Length (30) */
    0xff,       /* Manufacturer Specific Data (type 0xff) */
    0x4c, 0x00, /* Company ID (Apple) */
    0x12, 0x19, /* Offline Finding type and length */
    0x00,       /* State */
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, /* First two bits */
    0x00, /* Hint (0x00) */
};

/* https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-reference/bluetooth/esp_gap_ble.html#_CPPv420esp_ble_adv_params_t */
static esp_ble_adv_params_t ble_adv_params = {
    // Advertising min interval:
    // Minimum advertising interval for undirected and low duty cycle
    // directed advertising. Range: 0x0020 to 0x4000 Default: N = 0x0800
    // (1.28 second) Time = N * 0.625 msec Time Range: 20 ms to 10.24 sec
    .adv_int_min = 0x0020, // 20ms
    // Advertising max interval:
    // Maximum advertising interval for undirected and low duty cycle
    // directed advertising. Range: 0x0020 to 0x4000 Default: N = 0x0800
    // (1.28 second) Time = N * 0.625 msec Time Range: 20 ms to 10.24 sec
    .adv_int_max = 0x0020, // 20ms
    // Advertisement type
    .adv_type = ADV_TYPE_NONCONN_IND,
    // Use the random address
    .own_addr_type = BLE_ADDR_TYPE_RANDOM,
    // All channels
    .channel_map = ADV_CHNL_ALL,
    // Allow both scan and connection requests from anyone.
    .adv_filter_policy = ADV_FILTER_ALLOW_SCAN_ANY_CON_ANY,
};

int load_bytes_from_partition(uint8_t *dst, size_t size, int offset)
{
    const esp_partition_t *keypart = esp_partition_find_first(ESP_PARTITION_TYPE_DATA, ESP_PARTITION_SUBTYPE_DATA_NVS_KEYS, "key");
    if (keypart == NULL)
    {
        ESP_LOGE(LOG_TAG, "Could not find key partition");
        return 1;
    }
    esp_err_t status;
    status = esp_partition_read(keypart, offset, dst, size);
    if (status != ESP_OK)
    {
        ESP_LOGE(LOG_TAG, "Could not read key from partition: %s", esp_err_to_name(status));
    }
    return status;
}

static void esp_gap_cb(esp_gap_ble_cb_event_t event, esp_ble_gap_cb_param_t *param)
{
    esp_err_t err;

    switch (event)
    {
    case ESP_GAP_BLE_ADV_DATA_RAW_SET_COMPLETE_EVT:
        esp_ble_gap_start_advertising(&ble_adv_params);
        break;

    case ESP_GAP_BLE_ADV_START_COMPLETE_EVT:
        // adv start complete event to indicate adv start successfully or failed
        if ((err = param->adv_start_cmpl.status) != ESP_BT_STATUS_SUCCESS)
        {
            ESP_LOGE(LOG_TAG, "advertising start failed: %s", esp_err_to_name(err));
        }
        else
        {
            ESP_LOGI(LOG_TAG, "advertising has started.");
        }
        break;

    case ESP_GAP_BLE_ADV_STOP_COMPLETE_EVT:
        if ((err = param->adv_stop_cmpl.status) != ESP_BT_STATUS_SUCCESS)
        {
            ESP_LOGE(LOG_TAG, "adv stop failed: %s", esp_err_to_name(err));
        }
        else
        {
            ESP_LOGI(LOG_TAG, "stop adv successfully");
        }
        break;
    default:
        break;
    }
}

void set_addr_from_key(esp_bd_addr_t addr, uint8_t *public_key)
{
    addr[0] = public_key[0] | 0b11000000;
    addr[1] = public_key[1];
    addr[2] = public_key[2];
    addr[3] = public_key[3];
    addr[4] = public_key[4];
    addr[5] = public_key[5];
}

void set_payload_from_key(uint8_t *payload, uint8_t *public_key)
{
    /* copy last 22 bytes */
    memcpy(&payload[7], &public_key[6], 22);
    /* append two bits of public key */
    payload[29] = public_key[0] >> 6;
}

uint get_key_count()
{
    uint8_t keyCount[1];
    if (load_bytes_from_partition(keyCount, sizeof(keyCount), 0) != ESP_OK)
    {
        ESP_LOGE(LOG_TAG, "Could not read the key count, stopping.");
        return 0;
    }
    ESP_LOGE(LOG_TAG, "Found %i keys", keyCount[0]);
    return keyCount[0];
}
static uint8_t public_key[28];
void app_main(void)
{
    ESP_ERROR_CHECK(nvs_flash_init());
    ESP_ERROR_CHECK(esp_bt_controller_mem_release(ESP_BT_MODE_CLASSIC_BT));
    esp_bt_controller_config_t bt_cfg = BT_CONTROLLER_INIT_CONFIG_DEFAULT();
    esp_bt_controller_init(&bt_cfg);
    esp_bt_controller_enable(ESP_BT_MODE_BLE);
    esp_bluedroid_config_t bluedroid_cfg = BT_BLUEDROID_INIT_CONFIG_DEFAULT();
    esp_bluedroid_init_with_cfg(&bluedroid_cfg);
    esp_ble_tx_power_set(ESP_BLE_PWR_TYPE_ADV, ESP_PWR_LVL_P9);
    esp_bluedroid_enable();

    ESP_LOGI(LOG_TAG, "application initialized");

    /* Start with a random index */
    uint key_count = get_key_count();
    uint key_index = (esp_random() % key_count);
    uint8_t cycle = 0;
    while (true)
    {
        esp_err_t status;
        // Shift for keycount size + keylength * index
        int address = 1 + (key_index * sizeof(public_key));
        ESP_LOGI(LOG_TAG, "Loading key with index %d at address %d", key_index, address);
        if (load_bytes_from_partition(public_key, sizeof(public_key), address) != ESP_OK)
        {
            ESP_LOGE(LOG_TAG, "Could not read the key, stopping.");
            return;
        }
        ESP_LOGI(LOG_TAG, "using key with start %02x %02x", public_key[0], public_key[1]);
        set_addr_from_key(rnd_addr, public_key);
        set_payload_from_key(adv_data, public_key);

        ESP_LOGI(LOG_TAG, "using device address: %02x %02x %02x %02x %02x %02x", rnd_addr[0], rnd_addr[1], rnd_addr[2], rnd_addr[3], rnd_addr[4], rnd_addr[5]);
        // register the scan callback function to the gap module
        if ((status = esp_ble_gap_register_callback(esp_gap_cb)) != ESP_OK)
        {
            ESP_LOGE(LOG_TAG, "gap register error: %s", esp_err_to_name(status));
            return;
        }

        if ((status = esp_ble_gap_set_rand_addr(rnd_addr)) != ESP_OK)
        {
            ESP_LOGE(LOG_TAG, "couldn't set random address: %s", esp_err_to_name(status));
            return;
        }
        if ((esp_ble_gap_config_adv_data_raw((uint8_t *)&adv_data, sizeof(adv_data))) != ESP_OK)
        {
            ESP_LOGE(LOG_TAG, "couldn't configure BLE adv: %s", esp_err_to_name(status));
            return;
        }
        ESP_LOGI(LOG_TAG, "Sending beacon (with key index %d)", key_index);
        vTaskDelay(10);
        esp_ble_gap_stop_advertising(); // Stop immediately after first beacon

        vTaskDelay(10);
        ESP_LOGI(LOG_TAG, "Going to sleep");
        vTaskDelay(10);
        esp_sleep_enable_timer_wakeup(DELAY_IN_S * 1000000); // sleep
        esp_light_sleep_start();

        // Execution continues here after wakeup
        ESP_LOGI(LOG_TAG, "Returned from light sleep");
        if (cycle >= REUSE_CYCLES)
        {
            ESP_LOGI(LOG_TAG, "Max cycles %d are reached. Changing key ", cycle);
            key_index = (key_index + 1) % key_count; // Back to zero if out of range
            cycle = 0;
        }
        else
        {
            ESP_LOGI(LOG_TAG, "Current cycle is %d. Reusing key. ", cycle);
            cycle++;
        }
    }
}
