#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include "openhaystack.h"

static uint8_t addr[6] = { 0xFF, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF };

static uint8_t offline_finding_adv_template[] = {
	0x1e, /* Length (30) */
	0xff, /* Manufacturer Specific Data (type 0xff) */
	0x4c, 0x00, /* Company ID (Apple) */
	0x12, 0x19, /* Offline Finding type and length */
	0x00, /* State */
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, /* First two bits */
	0x00, /* Hint (0x00) */
};

/*
 * set_addr_from_key will set the bluetooth address from the first 6 bytes of the key used to be advertised
 */
void set_addr_from_key(char key[28]) {
	/* copy first 6 bytes */
	addr[5] = key[0] | 0b11000000;
	addr[4] = key[1];
	addr[3] = key[2];
	addr[2] = key[3];
	addr[1] = key[4];
	addr[0] = key[5];
}

/*
 * fill_adv_template_from_key will set the advertising data based on the remaining bytes from the advertised key
 */
void fill_adv_template_from_key(char key[28]) {
	/* copy last 22 bytes */
	memcpy(&offline_finding_adv_template[7], &key[6], 22);
	/* append two bits of public key */
	offline_finding_adv_template[29] = key[0] >> 6;
}

/*
 * setAdvertisementKey will setup the key to be advertised
 *
 * @param[in] key public key to be advertised
 * @param[out] bleAddr bluetooth address to setup
 * @param[out] data raw data to advertise
 * 
 * @returns raw data size
 */
uint8_t setAdvertisementKey(char *key, uint8_t **bleAddr, uint8_t **data) {
    set_addr_from_key(key);
	fill_adv_template_from_key(key);

    *bleAddr = malloc(sizeof(key));
    memcpy(*bleAddr, addr, sizeof(addr));

    *data = malloc(sizeof(offline_finding_adv_template));
    memcpy(*data, offline_finding_adv_template, sizeof(offline_finding_adv_template));

    return sizeof(offline_finding_adv_template);
}
