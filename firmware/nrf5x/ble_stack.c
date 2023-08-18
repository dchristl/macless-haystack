#include <stdbool.h>
#include <stdint.h>
#include <string.h>
#include "ble_stack.h"

/*******************************************************************************
 *   BLE stack specific functions
 ******************************************************************************/

/*
 *  init_ble will initialize the ble stack, it will use the crystal definition based on NRF_CLOCK_LFCLKSRC.
 *  In devices with no external crystal you should use the internal rc. You can look at the e104bt5032a_board.h file
 */
void init_ble()
{
    uint32_t err_code;
    nrf_clock_lf_cfg_t clock_lf_cfg = NRF_CLOCK_LFCLKSRC;

    // Initialize the SoftDevice handler module.
    SOFTDEVICE_HANDLER_INIT(&clock_lf_cfg, NULL);

    ble_enable_params_t ble_enable_params;
    err_code = softdevice_enable_get_default_config(CENTRAL_LINK_COUNT,    // central link count
                                                    PERIPHERAL_LINK_COUNT, // peripheral link count
                                                    &ble_enable_params);
    ble_enable_params.common_enable_params.vs_uuid_count = BLE_UUID_VS_COUNT_MIN;
    APP_ERROR_CHECK(err_code);

    // Check the ram settings against the used number of links
    CHECK_RAM_START_ADDR(CENTRAL_LINK_COUNT, PERIPHERAL_LINK_COUNT);

    // Enable BLE stack.
    err_code = softdevice_enable(&ble_enable_params);
    APP_ERROR_CHECK(err_code);

    // Use max power.
    sd_ble_gap_tx_power_set(4);
}

/**
 * setMacAddress will set the bluetooth address
 */
void setMacAddress(uint8_t *addr)
{
    ble_gap_addr_t gap_addr;
    uint32_t err_code;

    memcpy(gap_addr.addr, addr, sizeof(gap_addr.addr));
    gap_addr.addr_type = BLE_GAP_ADDR_TYPE_PUBLIC;
    err_code = sd_ble_gap_address_set(BLE_GAP_ADDR_CYCLE_MODE_NONE, &gap_addr);
    APP_ERROR_CHECK(err_code);
}

/**
 * setAdvertisementData will set the data to be advertised
 */
void setAdvertisementData(uint8_t *data, uint8_t dlen)
{
    uint32_t err_code;

    err_code = sd_ble_gap_adv_data_set(data, dlen, NULL, 0);
    APP_ERROR_CHECK(err_code);
}

/**
 * Start advertising at the specified interval
 *
 * @param[in] interval advertising interval in milliseconds
 */
void startAdvertisement(int interval)
{
    ble_gap_adv_params_t m_adv_params;
    memset(&m_adv_params, 0, sizeof(m_adv_params));
    m_adv_params.type = BLE_GAP_ADV_TYPE_ADV_NONCONN_IND;
    m_adv_params.p_peer_addr = NULL;
    m_adv_params.fp = BLE_GAP_ADV_FP_ANY;
    m_adv_params.interval = MSEC_TO_UNITS(interval, UNIT_0_625_MS);
    m_adv_params.timeout = 0;
    sd_ble_gap_adv_start(&m_adv_params);
}

/**
 * Function for the Power manager.
 */
void power_manage(void)
{
    uint32_t err_code = sd_app_evt_wait();
    APP_ERROR_CHECK(err_code);
}