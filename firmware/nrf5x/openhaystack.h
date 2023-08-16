#include <stdbool.h>
#include <stdint.h>
#include <string.h>

/*
 * set_addr_from_key will set the bluetooth address from the first 6 bytes of the key used to be advertised
 */
void set_addr_from_key(char key[28]);

/*
 * fill_adv_template_from_key will set the advertising data based on the remaining bytes from the advertised key
 */
void fill_adv_template_from_key(char key[28]);

/*
 * setAdvertisementKey will setup the key to be advertised
 *
 * @param[in] key public key to be advertised
 * @param[out] bleAddr bluetooth address to setup
 * @param[out] data raw data to advertise
 * 
 * @returns raw data size
 */
uint8_t setAdvertisementKey(char *key, uint8_t **bleAddr, uint8_t **data);
