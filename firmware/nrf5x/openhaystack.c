#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include "openhaystack.h"
#include <stdio.h>

static uint8_t addr[6] = {0xFF, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF};

static uint8_t offline_finding_adv_template[] = {
	0x1e,		/* Length (30) */
	0xff,		/* Manufacturer Specific Data (type 0xff) */
	0x4c, 0x00, /* Company ID (Apple) */
	0x12, 0x19, /* Offline Finding type and length */
	0x00,		/* State */
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, /* First two bits */
	0x00, /* Hint (0x00) */
};

/*
 * set_addr_from_key will set the bluetooth address from the first 6 bytes of the key used to be advertised
 */
void set_addr_from_key(const char *key)
{
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
void fill_adv_template_from_key(const char *key)
{

	size_t key_size = 28;
	char key_hex[28 * 5 + 1];

	// Ausgabe des key-Arrays als Hexadezimalwerte
	for (size_t i = 0; i < key_size; i++)
	{
		snprintf(&key_hex[i * 5], 6, "0x%02X,", (unsigned char)key[i]);
	}

	memcpy(&offline_finding_adv_template[7], &key[6], 22);
	/* append two bits of public key */

	size_t offline_finding_adv_template_size = sizeof(offline_finding_adv_template);

	// Erstellen eines String-Puffers, der groß genug ist, um das Array aufzunehmen
	char string_buffer[offline_finding_adv_template_size * 5 + 1]; // Jeder Wert benötigt bis zu 4 Zeichen und ein Nullterminator

	// Umwandeln des offline_finding_adv_template-Arrays in einen String
	for (size_t i = 0; i < offline_finding_adv_template_size; i++)
	{
		snprintf(&string_buffer[i * 5], 6, "0x%02X,", offline_finding_adv_template[i]);
	}

	printf("%s\n", string_buffer);
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
uint8_t setAdvertisementKey(const char *key, uint8_t **bleAddr, uint8_t **data)
{
    set_addr_from_key(key);
	fill_adv_template_from_key(key);

    *bleAddr = malloc(sizeof(addr));
    memcpy(*bleAddr, addr, sizeof(addr));

    *data = malloc(sizeof(offline_finding_adv_template));
    memcpy(*data, offline_finding_adv_template, sizeof(offline_finding_adv_template));

    return sizeof(offline_finding_adv_template);
}
