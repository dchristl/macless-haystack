OpenHaystack alternative firmware
=================================

This is an alternative firmware to https://github.com/seemoo-lab/openhaystack/tree/main/Firmware/Microbit_v1/offline-finding but using the Softdevice from Nordic Semiconductors.

It is using SDK 11 which uses the Softdevice S130/S132 v2.0.0 that is compatible with both nRF51 and nRF52 platforms. It has been tested with the following modules:

 - E104-BT5032A board from EBYTE which can be purchased here https://www.aliexpress.com/item/4000538644215.html
 - "AliExpress beacon" which can be purchased here https://www.aliexpress.com/item/32826502025.html

By default it will compile for nRF52 platform. If you want to make a firmware for nRF51822 you can add the `NRF_MODEL` environment variable like this

```
NRF_MODEL=nrf51 make
```

Please keep in mind that, by default, the resulting binaries on `_build` will not include the Softdevice. You can generate a full binary by issuing

```
make build
```
or
```
NRF_MODEL=nrf51 make build
```

this command will create a full binary to be flashed on the `compiled` directory.

A compiled binary for both platforms is included for convenience.

In case you can't or don't want to build the firmware,
you can just patch existing firmware with your advertisement key from OpenHaystack app:

```
NRF_MODEL=nrf51 BOARD=BOARD_ALIEXPRESS ADV_KEY_BASE64=YOUR_ADVERTISEMENT_KEY make patch
```

this command will create the new patched binary (`nrf51_firmware_patched.bin`) with provided key on the `compiled` directory.