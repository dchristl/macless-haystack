#ifdef S130
/**
 * Copyright (c) 2012 - 2017, Nordic Semiconductor ASA
 * 
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 * 
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 * 
 * 2. Redistributions in binary form, except as embedded into a Nordic
 *    Semiconductor ASA integrated circuit in a product or a software update for
 *    such product, must reproduce the above copyright notice, this list of
 *    conditions and the following disclaimer in the documentation and/or other
 *    materials provided with the distribution.
 * 
 * 3. Neither the name of Nordic Semiconductor ASA nor the names of its
 *    contributors may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 * 
 * 4. This software, with or without modification, must only be used with a
 *    Nordic Semiconductor ASA integrated circuit.
 * 
 * 5. Any software provided in binary form under this license must not be reverse
 *    engineered, decompiled, modified and/or disassembled.
 * 
 * THIS SOFTWARE IS PROVIDED BY NORDIC SEMICONDUCTOR ASA "AS IS" AND ANY EXPRESS
 * OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY, NONINFRINGEMENT, AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL NORDIC SEMICONDUCTOR ASA OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 * GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
 * OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 */

/* Attention!
*  To maintain compliance with Nordic Semiconductor ASA�s Bluetooth profile
*  qualification listings, this section of source code must not be modified.
*/
#include "nrf51_battery.h"


#define INVALID_BATTERY_LEVEL 255


#define BATTERY_VOLTAGE_MIN 1800.0
#define BATTERY_VOLTAGE_MAX 3000.0


/**@brief Function for handling the Connect event.
 *
 * @param[in]   p_bas       Battery Service structure.
 * @param[in]   p_ble_evt   Event received from the BLE stack.
 */
static void on_connect(ble_bas_t * p_bas, ble_evt_t * p_ble_evt)
{
    p_bas->conn_handle = p_ble_evt->evt.gap_evt.conn_handle;
}


/**@brief Function for handling the Disconnect event.
 *
 * @param[in]   p_bas       Battery Service structure.
 * @param[in]   p_ble_evt   Event received from the BLE stack.
 */
static void on_disconnect(ble_bas_t * p_bas, ble_evt_t * p_ble_evt)
{
    UNUSED_PARAMETER(p_ble_evt);
    p_bas->conn_handle = BLE_CONN_HANDLE_INVALID;
}




uint16_t battery_voltage_get (void)
{
  // Configure ADC
  NRF_ADC->CONFIG = (ADC_CONFIG_RES_8bit << ADC_CONFIG_RES_Pos) |
    (ADC_CONFIG_INPSEL_SupplyOneThirdPrescaling << ADC_CONFIG_INPSEL_Pos) |
    (ADC_CONFIG_REFSEL_VBG << ADC_CONFIG_REFSEL_Pos) |
    (ADC_CONFIG_PSEL_Disabled << ADC_CONFIG_PSEL_Pos) |
    (ADC_CONFIG_EXTREFSEL_None << ADC_CONFIG_EXTREFSEL_Pos);
  NRF_ADC->EVENTS_END = 0;
  NRF_ADC->ENABLE = ADC_ENABLE_ENABLE_Enabled;

  NRF_ADC->EVENTS_END = 0;	// Stop any running conversions.
  NRF_ADC->TASKS_START = 1;

  while (!NRF_ADC->EVENTS_END);

  uint16_t vbg_in_mv = 1200;
  uint8_t adc_max = 255;
  uint16_t vbat_current_in_mv = (NRF_ADC->RESULT * 3 * vbg_in_mv) / adc_max;

  NRF_ADC->EVENTS_END = 0;
  NRF_ADC->TASKS_STOP = 1;
    
  return vbat_current_in_mv;
}

uint8_t level_get(uint16_t voltage){
  return (uint8_t) ((voltage -
		     BATTERY_VOLTAGE_MIN) / (BATTERY_VOLTAGE_MAX -
					     BATTERY_VOLTAGE_MIN) * 100.0);
}

uint8_t get_current_level(void){
  return level_get(battery_voltage_get());
}

void on_authorize(ble_bas_t * p_bas, ble_evt_t * p_ble_evt) {
    uint8_t * data = NULL;
    uint8_t len = 0;
    uint8_t level;
    
    ble_gatts_evt_read_t evt = p_ble_evt->evt.gatts_evt.params.authorize_request.request.read;
    
    uint16_t uuid = evt.uuid.uuid;
    
    uint16_t voltage = battery_voltage_get();
    
    
    if(uuid == 0x2A19){
        len = 1;
        level = MIN(100, level_get(voltage));
        data = &level;
    }else if(uuid == 0x3A19){
        len = 2;
        data = (uint8_t*) &voltage;
    }
    
    
    ble_gatts_rw_authorize_reply_params_t reply;
    
    reply.params.read.gatt_status = BLE_GATT_STATUS_SUCCESS;
    reply.type = BLE_GATTS_AUTHORIZE_TYPE_READ;
    reply.params.read.len = len;
    reply.params.read.offset = 0;
    reply.params.read.update = 1;
    reply.params.read.p_data = data;
    
    sd_ble_gatts_rw_authorize_reply(p_bas->conn_handle, &reply);
}


void ble_bas_on_ble_evt(ble_bas_t * p_bas, ble_evt_t * p_ble_evt)
{
    if (p_bas == NULL || p_ble_evt == NULL)
    {
        return;
    }

    switch (p_ble_evt->header.evt_id)
    {
        case BLE_GAP_EVT_CONNECTED:
            on_connect(p_bas, p_ble_evt);
            break;

        case BLE_GAP_EVT_DISCONNECTED:
            on_disconnect(p_bas, p_ble_evt);
            break;
        
        case BLE_GATTS_EVT_RW_AUTHORIZE_REQUEST:
            on_authorize(p_bas, p_ble_evt);
            break;

        default:
            // No implementation needed.
            break;
    }
}


/**@brief Function for adding the Battery Level characteristic.
 *
 * @param[in]   p_bas        Battery Service structure.
 * @param[in]   p_bas_init   Information needed to initialize the service.
 *
 * @return      NRF_SUCCESS on success, otherwise an error code.
 */
static uint32_t battery_level_char_add(ble_bas_t * p_bas, const ble_bas_init_t * p_bas_init)
{
    uint32_t            err_code;
    ble_uuid_t          ble_uuid;
    
    ble_gatts_char_md_t char_md = {
        .char_props.read   = 1,
        .char_props.notify = 0,
        .char_props.write  = 0
    };

    BLE_UUID_BLE_ASSIGN(ble_uuid, BLE_UUID_BATTERY_LEVEL_CHAR);
    
    ble_gatts_attr_md_t attr_md = {
        .read_perm  = p_bas_init->battery_level_char_attr_md.read_perm,
        .write_perm = p_bas_init->battery_level_char_attr_md.write_perm,
        .vloc       = BLE_GATTS_VLOC_STACK,
        .rd_auth    = 1,
        .wr_auth    = 0,
        .vlen       = 0
    };
    
    ble_gatts_attr_t attr_char_value = {
        .p_uuid    = &ble_uuid,
        .p_attr_md = &attr_md,
        .init_len  = sizeof(uint8_t),
        .init_offs = 0,
        .max_len   = sizeof(uint8_t),
    };

    err_code = sd_ble_gatts_characteristic_add(p_bas->service_handle, 
                                               &char_md,
                                               &attr_char_value,
                                               &p_bas->battery_level_handles
    );
    return err_code;
}


/**@brief Function for adding the Battery Level characteristic.
 *
 * @param[in]   p_bas        Battery Service structure.
 * @param[in]   p_bas_init   Information needed to initialize the service.
 *
 * @return      NRF_SUCCESS on success, otherwise an error code.
 */
static uint32_t battery_voltage_char_add(ble_bas_t * p_bas, const ble_bas_init_t * p_bas_init)
{
    uint32_t            err_code;
    ble_uuid_t          ble_uuid;
    
    ble_gatts_char_md_t char_md = {
        .char_props.read   = 1,
        .char_props.notify = 0,
        .char_props.write  = 0
    };

    BLE_UUID_BLE_ASSIGN(ble_uuid, 0x3A19);
    
    ble_gatts_attr_md_t attr_md = {
        .read_perm  = p_bas_init->battery_level_char_attr_md.read_perm,
        .write_perm = p_bas_init->battery_level_char_attr_md.write_perm,
        .vloc       = BLE_GATTS_VLOC_STACK,
        .rd_auth    = 1,
        .wr_auth    = 0,
        .vlen       = 0
    };
    
    ble_gatts_attr_t attr_char_value = {
        .p_uuid    = &ble_uuid,
        .p_attr_md = &attr_md,
        .init_len  = sizeof(uint16_t),
        .init_offs = 0,
        .max_len   = sizeof(uint16_t),
    };

    err_code = sd_ble_gatts_characteristic_add(p_bas->service_handle, 
                                               &char_md,
                                               &attr_char_value,
                                               &p_bas->battery_voltage_handles
    );
    return err_code;
}

uint32_t ble_bas_init(ble_bas_t * p_bas, const ble_bas_init_t * p_bas_init)
{
    if (p_bas == NULL || p_bas_init == NULL)
    {
        return NRF_ERROR_NULL;
    }

    uint32_t   err_code;
    ble_uuid_t ble_uuid;

    // Initialize service structure
    p_bas->evt_handler               = p_bas_init->evt_handler;
    p_bas->conn_handle               = BLE_CONN_HANDLE_INVALID;
    p_bas->is_notification_supported = p_bas_init->support_notification;
    p_bas->battery_level_last        = INVALID_BATTERY_LEVEL;

    // Add service
    BLE_UUID_BLE_ASSIGN(ble_uuid, BLE_UUID_BATTERY_SERVICE);

    err_code = sd_ble_gatts_service_add(BLE_GATTS_SRVC_TYPE_PRIMARY, &ble_uuid, &p_bas->service_handle);
    if (err_code != NRF_SUCCESS)
    {
        return err_code;
    }

    // Add battery level characteristic
    battery_level_char_add(p_bas, p_bas_init);
    battery_voltage_char_add(p_bas, p_bas_init);
    
    return NRF_SUCCESS;
}
#endif