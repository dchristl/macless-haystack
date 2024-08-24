#ifdef S130
#ifndef BLE_BAS_H__
#define BLE_BAS_H__

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
#include "ble.h"
#include "ble_srv_common.h"
#include "nrf_log.h"
#include "nrf51_bitfields.h"
#include "nrf51.h"

#ifdef __cplusplus
extern "C" {
#endif

/**@brief Battery Service event type. */
typedef enum
{
    BLE_BAS_EVT_NOTIFICATION_ENABLED,                             /**< Battery value notification enabled event. */
    BLE_BAS_EVT_NOTIFICATION_DISABLED                             /**< Battery value notification disabled event. */
} ble_bas_evt_type_t;

/**@brief Battery Service event. */
typedef struct
{
    ble_bas_evt_type_t evt_type;                                  /**< Type of event. */
} ble_bas_evt_t;

// Forward declaration of the ble_bas_t type.
typedef struct ble_bas_s ble_bas_t;

/**@brief Battery Service event handler type. */
typedef void (*ble_bas_evt_handler_t) (ble_bas_t * p_bas, ble_bas_evt_t * p_evt);

/**@brief Battery Service init structure. This contains all options and data needed for
 *        initialization of the service.*/
typedef struct
{
    ble_bas_evt_handler_t         evt_handler;                    /**< Event handler to be called for handling events in the Battery Service. */
    bool                          support_notification;           /**< TRUE if notification of Battery Level measurement is supported. */
    ble_srv_report_ref_t *        p_report_ref;                   /**< If not NULL, a Report Reference descriptor with the specified value will be added to the Battery Level characteristic */
    uint8_t                       initial_batt_level;             /**< Initial battery level */
    ble_srv_cccd_security_mode_t  battery_level_char_attr_md;     /**< Initial security level for battery characteristics attribute */
    ble_gap_conn_sec_mode_t       battery_level_report_read_perm; /**< Initial security level for battery report read attribute */
} ble_bas_init_t;

/**@brief Battery Service structure. This contains various status information for the service. */
struct ble_bas_s
{
    ble_bas_evt_handler_t         evt_handler;                    /**< Event handler to be called for handling events in the Battery Service. */
    uint16_t                      service_handle;                 /**< Handle of Battery Service (as provided by the BLE stack). */
    ble_gatts_char_handles_t      battery_level_handles;          /**< Handles related to the Battery Level characteristic. */
    ble_gatts_char_handles_t      battery_voltage_handles;          /**< Handles related to the Battery Level characteristic. */
    uint16_t                      report_ref_handle;              /**< Handle of the Report Reference descriptor. */
    uint8_t                       battery_level_last;             /**< Last Battery Level measurement passed to the Battery Service. */
    uint16_t                      conn_handle;                    /**< Handle of the current connection (as provided by the BLE stack, is BLE_CONN_HANDLE_INVALID if not in a connection). */
    bool                          is_notification_supported;      /**< TRUE if notification of Battery Level is supported. */
};

/**@brief Function for initializing the Battery Service.
 *
 * @param[out]  p_bas       Battery Service structure. This structure will have to be supplied by
 *                          the application. It will be initialized by this function, and will later
 *                          be used to identify this particular service instance.
 * @param[in]   p_bas_init  Information needed to initialize the service.
 *
 * @return      NRF_SUCCESS on successful initialization of service, otherwise an error code.
 */
uint32_t ble_bas_init(ble_bas_t * p_bas, const ble_bas_init_t * p_bas_init);

/**@brief Function for handling the Application's BLE Stack events.
 *
 * @details Handles all events from the BLE stack of interest to the Battery Service.
 *
 * @note For the requirements in the BAS specification to be fulfilled,
 *       ble_bas_battery_level_update() must be called upon reconnection if the
 *       battery level has changed while the service has been disconnected from a bonded
 *       client.
 *
 * @param[in]   p_bas      Battery Service structure.
 * @param[in]   p_ble_evt  Event received from the BLE stack.
 */
void ble_bas_on_ble_evt(ble_bas_t * p_bas, ble_evt_t * p_ble_evt);

uint8_t get_current_level (void);

#ifdef __cplusplus
}
#endif

#endif // BLE_BAS_H__

/** @} */
#endif